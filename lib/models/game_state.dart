import 'package:flutter/foundation.dart';

import '../data/character_repository.dart';
import '../data/encounter_repository.dart';
import '../data/work_events.dart';
import 'actions.dart';
import 'calendar.dart';
import 'cg_state.dart';
import 'character.dart';
import 'character_state.dart';
import 'dialogue.dart';
import 'encounter.dart';
import 'ending.dart';
import 'ending_resolver.dart';
import 'event.dart';
import 'event_resolver.dart';
import 'inventory.dart';
import 'invite_balance.dart';
import 'schedule.dart';
import 'stats.dart';
import 'work.dart';

/// 日付進行時に発火されるイベント種別。
///
/// Sprint 04 で導入：
/// - [weeklyReview]: 日曜日終了直前（翌日に進む前）。
///   `weekStartSnapshot` を使って週間変動を集計し、画面側がモーダル表示する。
/// - [salary]: 翌日が月の1日に進んだ直後。
///   給料額は [GameState.lastSalaryAmount] で参照する。
///
/// Sprint 06 で追加：
/// - [encounter]: 翌日が出会いイベントの発火日に一致したとき。
///   発火対象のキャラは [GameState.pendingEncounter] で参照する。
///
/// Sprint 07 で追加：
/// - [estrangement]: 出会い済キャラのうち最後に交流してから
///   `kEstrangementThresholdDays` 日以上経過したものが見つかったとき。
///   対象キャラリストは [GameState.pendingEstrangements] で参照する。
///
/// Sprint 08 で追加：
/// - [common]: 翌日に進んだとき、共通イベントの発火日に一致したもの。
///   対象は [GameState.pendingCommonEvent] で参照する。
/// - [milestone]: 翌日に進んだとき、節目イベントの発火日に一致したもの。
///   対象は [GameState.pendingMilestoneEvent] で参照する。
///
/// Sprint 09 で追加：
/// - [autosave]: オートセーブのトリガ（月初・週末ふりかえり後・節目イベント前）。
///   アプリ層 (HomeScreen) が `SaveRepository.writeAuto` を呼ぶ。
/// - [endingReached]: 3/31 に到達したとき。
///   `GameState.pendingEnding` が判定結果の [EndingKind] を保持する。
///
/// `HomeScreen` 側がコールバックで購読する。フック内で再帰的に
/// `applyAction` / `_advanceDay` を呼ばないこと（仕様メモ参照）。
enum DayAdvanceEvent {
  weeklyReview,
  salary,
  encounter,
  estrangement,
  common,
  milestone,
  autosave,
  endingReached,
}

/// Sprint 09: オートセーブの発火理由。HomeScreen が SaveRepository へ
/// 渡す際の「なぜ保存したか」のラベル化に使う。
enum AutosaveTrigger {
  monthStart,
  weekEnd,
  beforeEvent,
}

/// Sprint 05: 予約自動実行の結果。
///
/// - [applied]: 予約された行動を実際に適用できた（コスト充足、枠 pending）。
/// - [skippedInsufficientMoney]: コスト不足でスキップ（予約はクリアする）。
/// - [skippedSlotResolved]: 枠が既に done/skipped でスキップ。
/// - [noReservation]: そもそも予約がなかった（呼び出し側の前処理ミス）。
enum ScheduledActionResult {
  applied,
  skippedInsufficientMoney,
  skippedSlotResolved,
  noReservation,
}

/// 1 日進行（[GameState._advanceDay]）の前後で呼ばれるリスナ。
///
/// 1 回の `applyAction` で 1 日進む場合、最大で
/// `weeklyReview` → `salary` の順に複数イベントが連続発火することがある。
typedef DayAdvanceListener = void Function(DayAdvanceEvent event);

/// プレイ中のゲーム状態。
///
/// Sprint 02 で 7 能力値・体力・所持金・ストレスを追加。
/// Sprint 03 で行動枠の状態 ([SlotState]) と行動適用ロジック
/// ([applyAction] / [sleepSkipRemaining] / [advanceDayIfAllSlotsDone]) を追加。
/// Sprint 04 で以下を追加：
/// - 週初スナップショット ([weekStartSnapshot]) と週間変動 ([weeklyDeltas])
/// - 仕事ミニ判定結果の適用 ([applyWorkOutcome])
/// - 月初給料受領 ([receiveSalary]) と直近給料額 ([lastSalaryAmount])
/// - 日付進行時イベントのコールバック ([addDayAdvanceListener])
///
/// 「体力」と「所持金」と「ストレス」は仕様書 §3 上は能力値の一部だが、
/// UI/UX 上はそれぞれ独立した扱いをするため、ここでは
/// - 体力: 現在値 (_vitality) と 1日の上限 (_vitalityMax) を持つ
/// - 所持金: 円単位の整数 (_money)
/// - ストレス: 0〜100 の隠しゲージ (_stress)
/// - その他4能力値 (知性・感性・社交・仕事評価): _stats マップで管理
/// として保持する。能力値詳細画面では7項目すべてを一覧表示する。
class GameState extends ChangeNotifier {
  GameState({
    String heroName = '',
    DateTime? currentDate,
    int vitality = _defaultVitality,
    int vitalityMax = _defaultVitalityMax,
    int money = _defaultMoney,
    int stress = _defaultStress,
    Map<StatKind, int>? stats,
    Map<SlotIndex, SlotState>? slotStates,
    ScheduleStore? schedule,
  })  : _heroName = heroName,
        _currentDate = currentDate ?? _defaultStartDate(),
        _vitality = vitality.clamp(StatRange.min, vitalityMax),
        _vitalityMax = vitalityMax,
        _money = money,
        _stress = stress.clamp(StatRange.min, StatRange.max),
        _stats = {..._defaultStats(), if (stats != null) ...stats},
        _slotStates = {
          ..._defaultSlotStates(),
          if (slotStates != null) ...slotStates,
        },
        _schedule = schedule ?? ScheduleStore(),
        _cgLibrary = CgLibrary(),
        _inventory = Inventory() {
    // 初期化直後の値を「今週の週初スナップショット」として保持する。
    _weekStartSnapshot = _snapshotStats();
    _weekStartDate = _currentDate;
  }

  /// 物語の開始日（4月1日）。年は実装時の現在年度をもとに固定する。
  static DateTime _defaultStartDate() => DateTime(2026, 4, 1);

  static const int _defaultVitality = 80;
  static const int _defaultVitalityMax = 100;
  static const int _defaultMoney = 50000;
  static const int _defaultStress = 20;

  /// 知性・感性・社交・仕事評価のデフォルト値。
  ///
  /// 体力・所持金・ストレスは別フィールドで管理するため、ここには含めない。
  static Map<StatKind, int> _defaultStats() => <StatKind, int>{
        StatKind.intellect: 25,
        StatKind.sensibility: 20,
        StatKind.sociability: 30,
        StatKind.career: 20,
      };

  /// 全枠 [SlotState.pending] のマップ。
  static Map<SlotIndex, SlotState> _defaultSlotStates() => <SlotIndex, SlotState>{
        for (final s in SlotIndex.values) s: SlotState.pending,
      };

  String _heroName;
  DateTime _currentDate;
  int _vitality;
  int _vitalityMax;
  int _money;
  int _stress;
  final Map<StatKind, int> _stats;
  final Map<SlotIndex, SlotState> _slotStates;
  final ScheduleStore _schedule;

  /// Sprint 08: 解放済 CG ライブラリ。`unlockEvent` 経由でイベント完了時に
  /// 解放される。メモリーアルバム画面が `AnimatedBuilder` で購読する。
  final CgLibrary _cgLibrary;

  /// Sprint 12: 所持アイテム（プレゼント）の在庫。ショップ画面で購入されると
  /// `purchaseGift` 経由で +1 される。`Inventory` は ChangeNotifier。
  final Inventory _inventory;

  /// Sprint 08: 共通・節目・ランダムイベントの「解放済 ID」集合。
  /// （個別イベントは CharacterState 側で持つ。）
  final Set<String> _unlockedGlobalEventIds = <String>{};

  /// Sprint 08: 次に再生すべき共通イベント / 節目イベント / ランダムイベント。
  /// それぞれ UI 側が読んで EventPlayer を起動し、終了後に
  /// [consumePendingCommonEvent] 等でクリアする。
  GameEvent? _pendingCommonEvent;
  GameEvent? _pendingMilestoneEvent;

  /// Sprint 09: 直近の `_advanceDay` で 3/31 を迎えたときに保存される
  /// エンディング種別。UI 側は `DayAdvanceEvent.endingReached` を受けて
  /// EndingScreen を起動する。
  EndingKind? _pendingEnding;

  /// Sprint 09: 直近の `_advanceDay` で発火予約されたオートセーブの理由。
  /// 月初なら [AutosaveTrigger.monthStart]、週末なら weekEnd、
  /// 節目イベント前なら beforeEvent。UI 側で 1 度読んだら null に戻す。
  AutosaveTrigger? _pendingAutosaveTrigger;

  /// Sprint 06: キャラごとの実行時状態。全 5 名分を初期化時に確保し、
  /// `isMet=false / affinity=0 / trueAffinity=0` で開始する。
  final Map<CharacterId, CharacterState> _characterStates = <CharacterId, CharacterState>{
    for (final c in CharacterRepository.all) c.id: CharacterState(),
  };

  /// 直近に発火予約された出会いイベント。`DayAdvanceEvent.encounter` を
  /// 受け取った UI 側がこれを参照して [DialogueModal] を開く。
  /// 表示が終わったら UI 側が [consumePendingEncounter] でクリアする。
  EncounterEvent? _pendingEncounter;

  /// Sprint 07: 直近の `_advanceDay` で疎遠ペナルティの対象となったキャラの
  /// リスト（ペナルティ適用「後」の状態を反映済み）。
  /// UI 側は `DayAdvanceEvent.estrangement` を受けて SnackBar 等で通知する。
  /// 一度読んだら [consumePendingEstrangements] でクリアする想定。
  final List<CharacterId> _pendingEstrangements = <CharacterId>[];

  // --- Sprint 04 追加フィールド --------------------------------------------

  /// 今週の月曜（または週の開始相当）時点の能力値スナップショット。
  /// 日曜終了時の週次ふりかえり画面で「+N / -N」表示に使う。
  late Map<StatKind, int> _weekStartSnapshot;

  /// 上記スナップショットを採取した日付。週次ふりかえり画面の
  /// 「今週の期間」表示に使う。
  late DateTime _weekStartDate;

  /// 直近で受け取った給料額（円）。0 ならまだ受け取っていない。
  int _lastSalaryAmount = 0;

  /// 日付進行時イベントのリスナ。HomeScreen が UI 側のフックを登録する。
  final List<DayAdvanceListener> _dayAdvanceListeners = <DayAdvanceListener>[];

  /// `_advanceDay` 内で発火が予約されたイベントの配列。
  /// `_advanceDay` 完了後、`notifyListeners` の直前にまとめて発火する。
  final List<DayAdvanceEvent> _pendingEvents = <DayAdvanceEvent>[];

  String get heroName => _heroName;
  DateTime get currentDate => _currentDate;
  int get vitality => _vitality;
  int get vitalityMax => _vitalityMax;
  int get money => _money;
  int get stress => _stress;

  /// 各枠の現在状態。読み取り専用ビュー。
  Map<SlotIndex, SlotState> get slotStates =>
      Map<SlotIndex, SlotState>.unmodifiable(_slotStates);

  SlotState slotStateOf(SlotIndex slot) =>
      _slotStates[slot] ?? SlotState.pending;

  /// 全枠が pending 以外（done または skipped）か。
  bool get areAllSlotsResolved =>
      _slotStates.values.every((s) => s != SlotState.pending);

  /// ホーム画面のストレス表情アイコンに使う区分。
  StressMood get stressMood => StressMood.fromStress(_stress);

  /// 7能力値すべての現在値を返す。表示順は [StatKind.values] の宣言順。
  Map<StatKind, int> get allStats {
    return <StatKind, int>{
      for (final kind in StatKind.values) kind: _statValueFor(kind),
    };
  }

  // --- Sprint 04 公開 API --------------------------------------------------

  /// 今週の週初スナップショット（読み取り専用）。
  Map<StatKind, int> get weekStartSnapshot =>
      Map<StatKind, int>.unmodifiable(_weekStartSnapshot);

  /// 今週の週初日付。
  DateTime get weekStartDate => _weekStartDate;

  /// 今週の各能力値の変動量（現在値 - 週初値）。
  Map<StatKind, int> get weeklyDeltas {
    final current = allStats;
    return <StatKind, int>{
      for (final kind in StatKind.values)
        kind: (current[kind] ?? 0) - (_weekStartSnapshot[kind] ?? 0),
    };
  }

  /// 直近で受け取った給料額（円）。給料ダイアログの表示に使う。
  int get lastSalaryAmount => _lastSalaryAmount;

  // --- Sprint 05 公開 API: 予約システム ------------------------------------

  /// 予約データのストア（読み取り中心）。UI 側から `reserve` / `cancel` を
  /// 直接叩く際は [reserveAction] / [cancelReservation] 経由が望ましい
  /// （`notifyListeners` を確実に呼ぶため）。
  ScheduleStore get schedule => _schedule;

  /// 指定日付・枠の予約を追加する。同枠に既に予約があれば上書き。
  void reserveAction(DateTime date, SlotIndex slot, ActionKind action) {
    _schedule.reserve(date, slot, action);
    notifyListeners();
  }

  /// 指定日付・枠の予約をキャンセルする。
  void cancelReservation(DateTime date, SlotIndex slot) {
    _schedule.cancel(date, slot);
    notifyListeners();
  }

  /// 行動が「今すぐ実行可能か」を判定する。
  ///
  /// Sprint 05 時点では「所持金が `effect.requiredMoney` 以上か」のみを
  /// 見る。将来は体力コストや解放条件もここに集約する想定。
  bool canAfford(ActionKind kind) {
    final effect = kActionCatalog[kind];
    if (effect == null) return false;
    return _money >= effect.requiredMoney;
  }

  /// 「今日のこの枠」に予約があれば自動実行する。
  ///
  /// 副作用は [applyAction] と同じ（能力値変動・枠 done 化・全枠解消で日付進行）。
  /// 戻り値で「適用済 / コスト不足でスキップ / 枠解消済 / 予約なし」を返す。
  /// コスト不足の場合は予約をクリアして「払えない予約は次回以降も自動的に
  /// 飛ばされる」状態にする（UI 側で通知することを想定）。
  ScheduledActionResult applyScheduledActionFor(SlotIndex slot) {
    if (slotStateOf(slot) != SlotState.pending) {
      return ScheduledActionResult.skippedSlotResolved;
    }
    final reserved = _schedule.reservationOf(_currentDate, slot);
    if (reserved == null) {
      return ScheduledActionResult.noReservation;
    }
    if (!canAfford(reserved)) {
      _schedule.cancel(_currentDate, slot);
      notifyListeners();
      return ScheduledActionResult.skippedInsufficientMoney;
    }
    final ok = applyAction(slot, reserved);
    if (!ok) {
      return ScheduledActionResult.skippedSlotResolved;
    }
    // 適用済の予約は履歴扱いとして残してもよいが、Sprint 05 では
    // 「過去日の予約は不要」のため当該枠だけクリアしておく。
    _schedule.cancel(_currentDate, slot);
    return ScheduledActionResult.applied;
  }

  /// Sprint C: 仕事中イベントの選択肢結果を適用する。
  ///
  /// `WorkResolver` を経由せず、選択肢で確定した [WorkChoiceEffect] を直接
  /// 能力値・好感度に反映し、日中枠を done にする。出会い済みのキャラが
  /// `affinityTarget` に指定されている場合のみ好感度を加算する。
  bool applyWorkChoice(WorkChoiceEffect effect) {
    if (slotStateOf(SlotIndex.midday) != SlotState.pending) {
      return false;
    }
    _applyDeltas(effect.toDeltas());
    final target = effect.affinityTarget;
    if (target != null) {
      final cs = characterStateOf(target);
      if (cs.isMet) {
        if (effect.affinityDelta != 0) cs.bumpAffinity(effect.affinityDelta);
        if (effect.trueAffinityDelta != 0) {
          cs.bumpTrueAffinity(effect.trueAffinityDelta);
        }
      }
    }
    _slotStates[SlotIndex.midday] = SlotState.done;
    if (areAllSlotsResolved) {
      _advanceDay();
    }
    _flushPendingEventsAndNotify();
    return true;
  }

  /// 平日日中の「仕事ミニ判定」を解決し、結果を能力値に反映する。
  ///
  /// 副作用順序: deltas を適用 → 日中枠を done → 全枠解消なら _advanceDay。
  /// 既に日中枠が解消済みなら何もせず false を返す。
  bool applyWorkOutcome(WorkOutcome outcome) {
    if (slotStateOf(SlotIndex.midday) != SlotState.pending) {
      return false;
    }
    _applyDeltas(workOutcomeDeltas(outcome));
    _slotStates[SlotIndex.midday] = SlotState.done;
    if (areAllSlotsResolved) {
      _advanceDay();
    }
    _flushPendingEventsAndNotify();
    return true;
  }

  /// 月初給料イベントから呼ばれる、所持金加算 + lastSalaryAmount 更新。
  ///
  /// 通常は `_advanceDay` 内で `DayAdvanceEvent.salary` 発火と同タイミングで
  /// 自動的に呼ばれるため、UI 側から明示的に呼ぶ必要はない。
  /// テストや特殊演出からの直叩きを許容するため public にしておく。
  void receiveSalary(int amount) {
    if (amount <= 0) return;
    _money += amount;
    _lastSalaryAmount = amount;
    notifyListeners();
  }

  /// 週次ふりかえり画面を閉じた後に、次週のスナップショットを採取し直す。
  ///
  /// 「日曜終了 → 月曜朝」の遷移直後に呼ぶ想定。
  /// 呼ばないと weeklyDeltas が前週と混ざってしまうので、HomeScreen 側で
  /// 確実に呼ぶこと。
  void resetWeekSnapshot() {
    _weekStartSnapshot = _snapshotStats();
    _weekStartDate = _currentDate;
    notifyListeners();
  }

  /// 日付進行時イベント (`DayAdvanceEvent`) のリスナを登録する。
  /// 戻り値は解除用のクロージャ。
  VoidCallback addDayAdvanceListener(DayAdvanceListener listener) {
    _dayAdvanceListeners.add(listener);
    return () => _dayAdvanceListeners.remove(listener);
  }

  // --- Sprint 06 公開 API: キャラ状態と出会いイベント ----------------------

  /// 全キャラの実行時状態（読み取り中心）。
  /// 直接書き換える代わりに [recordEncounter] / [bumpAffinity] 経由が望ましい。
  Map<CharacterId, CharacterState> get characterStates =>
      Map<CharacterId, CharacterState>.unmodifiable(_characterStates);

  CharacterState characterStateOf(CharacterId id) =>
      _characterStates[id] ?? (_characterStates[id] = CharacterState());

  /// 出会い済みかどうかの便利アクセサ。
  bool hasMet(CharacterId id) => characterStateOf(id).isMet;

  /// 出会いイベントの完了通知。`isMet=true` を立て、必要なら初期好感度を仮置きする。
  ///
  /// Sprint 07 から `lastInteractedDate` を「出会った当日」に初期化する。
  /// これにより、出会い直後から疎遠ペナルティの計測がスタートする。
  void recordEncounter(CharacterId id) {
    final s = characterStateOf(id);
    if (s.isMet) return;
    s.isMet = true;
    s.lastInteractedDate = _currentDate;
    notifyListeners();
  }

  /// 表面好感度を加算する低レベル API。クランプは [CharacterState.bumpAffinity] に委譲。
  /// 通常は [applyInviteOutcome] / [applyChoiceOutcome] 経由で動かす想定。
  void bumpAffinity(CharacterId id, int delta) {
    characterStateOf(id).bumpAffinity(delta);
    notifyListeners();
  }

  /// 真の好感度を加算する低レベル API。負値可。
  void bumpTrueAffinity(CharacterId id, int delta) {
    characterStateOf(id).bumpTrueAffinity(delta);
    notifyListeners();
  }

  /// Sprint 07: 「選択肢の結果」を対象キャラに適用する。
  ///
  /// 表面 / 真 / ストレス の差分を一括で当てる。`lastInteractedDate` も
  /// 同時に更新する（会話=交流とみなす）。
  void applyChoiceOutcome({
    required CharacterId target,
    required ChoiceOutcome outcome,
  }) {
    final s = characterStateOf(target);
    s.bumpAffinity(outcome.affinityDelta);
    s.bumpTrueAffinity(outcome.trueAffinityDelta);
    s.lastInteractedDate = _currentDate;
    if (outcome.stressDelta != 0) {
      _stress = (_stress + outcome.stressDelta)
          .clamp(StatRange.min, StatRange.max);
    }
    notifyListeners();
  }

  /// Sprint 06 → Sprint 07: 誘い行動の結果を適用する。
  ///
  /// - 所持金から `kInviteCostMoney` 円を引く（コスト不足ならスキップして false）。
  /// - 成否に応じて主人公のストレスと対象キャラの好感度を動かす：
  ///   - 成功時: ストレス -2 / 表面好感度 +[kInviteAffinityDeltaOnSuccess]（=+2）
  ///             / 真の好感度 +[kInviteTrueAffinityDeltaOnSuccess]（=+1）
  ///   - 失敗時: ストレス +3 / 表面は不変 / 真 -1（[kInviteTrueAffinityDeltaOnFailure]）
  /// - `lastInteractedDate` を当日に更新する（誘った時点で「交流した」とみなす）。
  /// - 枠を done にし、全枠解消なら日付を進める。
  bool applyInviteOutcome({
    required SlotIndex slot,
    required CharacterId target,
    required bool success,
  }) {
    if (slotStateOf(slot) != SlotState.pending) {
      return false;
    }
    if (_money < kInviteCostMoney) {
      return false;
    }
    _money -= kInviteCostMoney;
    final s = characterStateOf(target);
    s.lastInteractedDate = _currentDate;
    if (success) {
      _stress = (_stress + kInviteSuccessStressDelta)
          .clamp(StatRange.min, StatRange.max);
      s.bumpAffinity(kInviteAffinityDeltaOnSuccess);
      s.bumpTrueAffinity(kInviteTrueAffinityDeltaOnSuccess);
    } else {
      _stress = (_stress + kInviteFailureStressDelta)
          .clamp(StatRange.min, StatRange.max);
      s.bumpTrueAffinity(kInviteTrueAffinityDeltaOnFailure);
    }
    _slotStates[slot] = SlotState.done;
    if (areAllSlotsResolved) {
      _advanceDay();
    }
    _flushPendingEventsAndNotify();
    return true;
  }

  /// Sprint 07: 「ストレス連動の拒否シーン」を適用する。
  ///
  /// 成功/失敗の通常判定とは別経路で、誘いに対して相手が予定を理由に
  /// 断る（実質的にはストレスで主人公の態度が荒れている）シーン。
  /// - 所持金は通常コスト（カフェ代）を消費（誘った形になる）。
  /// - 主人公: ストレス +[kInviteRejectionStressDelta]
  /// - 対象キャラ: 表面 [kInviteRejectionAffinityDelta] / 真 [kInviteRejectionTrueAffinityDelta]
  /// - 枠は done になり、全枠解消なら日付進行。
  /// - `lastInteractedDate` も更新する（断られたとはいえ接触はしている）。
  ///
  /// コスト不足や枠不正なら false を返す。
  bool applyInviteRejection({
    required SlotIndex slot,
    required CharacterId target,
  }) {
    if (slotStateOf(slot) != SlotState.pending) {
      return false;
    }
    if (_money < kInviteCostMoney) {
      return false;
    }
    _money -= kInviteCostMoney;
    _stress = (_stress + kInviteRejectionStressDelta)
        .clamp(StatRange.min, StatRange.max);
    final s = characterStateOf(target);
    s.lastInteractedDate = _currentDate;
    s.bumpAffinity(kInviteRejectionAffinityDelta);
    s.bumpTrueAffinity(kInviteRejectionTrueAffinityDelta);
    _slotStates[slot] = SlotState.done;
    if (areAllSlotsResolved) {
      _advanceDay();
    }
    _flushPendingEventsAndNotify();
    return true;
  }

  /// 直近で発火予約された出会いイベント（未消費）。
  EncounterEvent? get pendingEncounter => _pendingEncounter;

  /// UI 側が出会いイベントを表示し終えたら呼ぶ。pending をクリアし、
  /// 対象キャラを「出会い済」に確定する。
  void consumePendingEncounter() {
    final ev = _pendingEncounter;
    if (ev == null) return;
    _pendingEncounter = null;
    recordEncounter(ev.targetId);
    // notifyListeners は recordEncounter 内で呼ばれる
  }

  /// Sprint 07: 直近の `_advanceDay` で疎遠ペナルティを受けたキャラ一覧。
  /// UI 側が「{キャラ名} としばらく会っていない…」と通知するために読む。
  List<CharacterId> get pendingEstrangements =>
      List<CharacterId>.unmodifiable(_pendingEstrangements);

  /// 上記の pending をクリアする（UI 側で通知を出し終わったタイミングで呼ぶ）。
  void consumePendingEstrangements() {
    if (_pendingEstrangements.isEmpty) return;
    _pendingEstrangements.clear();
    notifyListeners();
  }

  // --- Sprint 08 公開 API: イベントシステム + CG ---------------------------

  /// 解放済 CG ライブラリ。アルバム画面が購読する。
  CgLibrary get cgLibrary => _cgLibrary;

  /// Sprint 12: 所持アイテムストア。所持画面が `AnimatedBuilder` で購読する。
  Inventory get inventory => _inventory;

  /// Sprint 12: プレゼントを購入する。
  ///
  /// - 所持金 < [price] なら何もせず false を返す（呼び出し側で SnackBar 通知）。
  /// - 所持金 -= price、[Inventory.add] で +1、`notifyListeners` を 1 度だけ発火。
  ///
  /// 副作用: 能力値変動通知は出さない（プレゼント購入は「行動枠」に属さない）。
  bool purchaseGift({required String itemId, required int price}) {
    if (price < 0) return false;
    if (_money < price) return false;
    _money -= price;
    _inventory.add(itemId);
    notifyListeners();
    return true;
  }

  /// 解放済の共通/節目/ランダムイベント ID（読み取り専用）。
  Set<String> get unlockedGlobalEventIds =>
      Set<String>.unmodifiable(_unlockedGlobalEventIds);

  /// 指定キャラの解放済個別イベント ID（読み取り専用）。
  Set<String> unlockedEventsFor(CharacterId id) =>
      Set<String>.unmodifiable(characterStateOf(id).unlockedEventIds);

  /// 直近の `_advanceDay` で発火予約された共通イベント。なければ null。
  GameEvent? get pendingCommonEvent => _pendingCommonEvent;

  /// 直近の `_advanceDay` で発火予約された節目イベント。なければ null。
  GameEvent? get pendingMilestoneEvent => _pendingMilestoneEvent;

  /// 共通イベントを再生し終えたタイミングで呼び、ペンディングをクリアする。
  void consumePendingCommonEvent() {
    if (_pendingCommonEvent == null) return;
    _pendingCommonEvent = null;
    notifyListeners();
  }

  /// 節目イベントを再生し終えたタイミングで呼び、ペンディングをクリアする。
  void consumePendingMilestoneEvent() {
    if (_pendingMilestoneEvent == null) return;
    _pendingMilestoneEvent = null;
    notifyListeners();
  }

  /// イベントを「再生済み」として記録する。CG の解放もここで一括で行う。
  ///
  /// - 個別イベントなら [target] が必要。`CharacterState.unlockedEventIds` に追加。
  /// - 共通/節目/ランダムなら `_unlockedGlobalEventIds` に追加。
  /// - `cgKey` が指定されていれば [CgLibrary.unlock] を呼ぶ。
  ///
  /// 既に解放済みでも [CgLibrary.unlock] は冪等。
  void markEventCompleted(GameEvent event) {
    final target = event.target;
    if (event.category == EventCategory.individual && target != null) {
      characterStateOf(target).unlockedEventIds.add(event.id);
    } else {
      _unlockedGlobalEventIds.add(event.id);
    }
    final cg = event.cgKey;
    if (cg != null && cg.isNotEmpty) {
      _cgLibrary.unlock(cg);
    }
    notifyListeners();
  }

  /// Sprint 08: 個別イベントが再生されたときに枠を done として扱う API。
  ///
  /// `applyAction` を経由しないため、能力値差分は加算しない（イベント側で
  /// 既に [applyChoiceOutcome] を当てている前提）。全枠解消なら日付進行を
  /// 起動するため、`_advanceDay` の発火順序は通常の行動と同等。
  void consumeIndividualEventSlot(SlotIndex slot) {
    if (slotStateOf(slot) != SlotState.pending) return;
    _slotStates[slot] = SlotState.done;
    if (areAllSlotsResolved) {
      _advanceDay();
    }
    _flushPendingEventsAndNotify();
  }

  /// 共通/ランダムイベントの選択肢で、ストレス差分のみを反映する小ヘルパ。
  ///
  /// 対象キャラがいないイベントで `applyChoiceOutcome` を流用できないため、
  /// 主人公のストレス値のみ直接動かす低レベル API として用意する。
  void bumpStress(int delta) {
    if (delta == 0) return;
    _stress = (_stress + delta).clamp(StatRange.min, StatRange.max);
    notifyListeners();
  }

  /// HomeScreen が「朝枠タップ」時に呼ぶ：今この枠で個別イベントを優先発火
  /// すべきか判定し、該当があれば 1 件返す。
  ///
  /// [EventResolver.resolveIndividual] のラッパ。スコープ外の状態（既解放 ID 等）を
  /// GameState 側で組み立てて渡す責務を持つ。
  GameEvent? findIndividualEventFor(SlotIndex slot,
      {EventResolver resolver = const EventResolver()}) {
    final Set<String> unlocked = <String>{
      for (final entry in _characterStates.entries) ...entry.value.unlockedEventIds,
    };
    return resolver.resolveIndividual(
      characterStates: _characterStates,
      currentDate: _currentDate,
      slot: slot,
      unlockedEventIds: unlocked,
    );
  }

  /// HomeScreen が枠タップ時に呼ぶ：告白前夜イベントの優先発火判定。
  /// 個別イベントよりさらに先にチェックされる。
  GameEvent? findConfessionEveEvent(
      {EventResolver resolver = const EventResolver()}) {
    final Set<String> unlocked = <String>{
      for (final entry in _characterStates.entries) ...entry.value.unlockedEventIds,
    };
    return resolver.resolveConfessionEve(
      characterStates: _characterStates,
      unlockedEventIds: unlocked,
    );
  }

  // --- Sprint 09 公開 API: エンディング / オートセーブ ---------------------

  /// 直近の `_advanceDay` で 3/31 を迎えて判定されたエンディング（未消費）。
  EndingKind? get pendingEnding => _pendingEnding;

  /// 直近の `_advanceDay` で発火予約されたオートセーブの理由（未消費）。
  AutosaveTrigger? get pendingAutosaveTrigger => _pendingAutosaveTrigger;

  /// エンディング表示が完了した後に呼ぶ。pending をクリアする。
  void consumePendingEnding() {
    if (_pendingEnding == null) return;
    _pendingEnding = null;
    notifyListeners();
  }

  /// オートセーブを発行し終えたら UI 側で呼ぶ。pending をクリアする。
  void consumePendingAutosaveTrigger() {
    if (_pendingAutosaveTrigger == null) return;
    _pendingAutosaveTrigger = null;
    notifyListeners();
  }

  /// テスト用: 日付を一気に進めるための debug API。
  ///
  /// 通常の `_advanceDay` を経由しないため、イベント発火・給料・スナップショット
  /// の副作用は起きない。1 年プレイの integration test など、純粋に「日付を
  /// 3/31 にする」ためだけに使う想定。`notifyListeners()` を呼んで UI を更新する。
  void debugFastForward(int days) {
    if (days <= 0) return;
    _currentDate = _currentDate.add(Duration(days: days));
    _slotStates
      ..clear()
      ..addAll(_defaultSlotStates());
    notifyListeners();
  }

  /// テスト用: 任意の日付に直接ジャンプする。
  void debugJumpTo(DateTime date) {
    _currentDate = date;
    _slotStates
      ..clear()
      ..addAll(_defaultSlotStates());
    notifyListeners();
  }

  /// テスト用: 「3/31 終了時点でエンディング判定を起動」を呼び出す。
  ///
  /// 本来は `_advanceDay` の中で「翌日が 4/1 になったタイミング」で発火するが、
  /// 通常プレイの 1 年分は重いので、テスト用に直接トリガできる API を用意する。
  /// 結果は `pendingEnding` に格納される。
  void debugTriggerEndingResolution(
      {EndingResolver resolver = const EndingResolver()}) {
    _pendingEnding = resolveEndingFromGameState(this, resolver: resolver);
    notifyListeners();
  }

  // --- Sprint 09 公開 API: シリアライズ -----------------------------------

  /// セーブ用スナップショット。
  ///
  /// 形式は人間が読みやすい JSON 風 Map。`SaveRepository` が
  /// `jsonEncode` してから SharedPreferences に書き込む。
  /// バージョンフィールドを top-level に持たせて将来のスキーマ変更に備える。
  Map<String, dynamic> toMap() => <String, dynamic>{
        'version': 1,
        'heroName': _heroName,
        'currentDate': _currentDate.toIso8601String(),
        'vitality': _vitality,
        'vitalityMax': _vitalityMax,
        'money': _money,
        'stress': _stress,
        'stats': <String, int>{
          for (final entry in _stats.entries) entry.key.name: entry.value,
        },
        'slotStates': <String, String>{
          for (final entry in _slotStates.entries)
            entry.key.name: entry.value.name,
        },
        'weekStartSnapshot': <String, int>{
          for (final entry in _weekStartSnapshot.entries)
            entry.key.name: entry.value,
        },
        'weekStartDate': _weekStartDate.toIso8601String(),
        'lastSalaryAmount': _lastSalaryAmount,
        'characterStates': <String, dynamic>{
          for (final entry in _characterStates.entries)
            entry.key.name: entry.value.toMap(),
        },
        'unlockedGlobalEventIds': _unlockedGlobalEventIds.toList(),
        'cgLibrary': _cgLibrary.snapshot(),
        'schedule': _schedule.snapshot(),
        'inventory': _inventory.toMap(),
      };

  /// セーブ用スナップショットから状態を復元する。
  ///
  /// 既存内容は破棄して上書きする。デフォルト値が無いキーは
  /// 例外ではなくフォールバック値を採用する（前方互換重視）。
  void restoreFromMap(Map<String, dynamic> map) {
    _heroName = (map['heroName'] as String?) ?? '';
    final dateStr = map['currentDate'] as String?;
    _currentDate = (dateStr == null ? null : DateTime.tryParse(dateStr)) ??
        _defaultStartDate();
    _vitalityMax = (map['vitalityMax'] as int?) ?? _defaultVitalityMax;
    _vitality = ((map['vitality'] as int?) ?? _defaultVitality)
        .clamp(StatRange.min, _vitalityMax);
    _money = (map['money'] as int?) ?? _defaultMoney;
    _stress =
        ((map['stress'] as int?) ?? _defaultStress).clamp(StatRange.min, StatRange.max);
    _stats
      ..clear()
      ..addAll(_defaultStats());
    final rawStats = map['stats'];
    if (rawStats is Map) {
      rawStats.forEach((key, value) {
        if (key is String && value is int) {
          for (final kind in StatKind.values) {
            if (kind.name == key) {
              _stats[kind] = value;
              break;
            }
          }
        }
      });
    }
    _slotStates
      ..clear()
      ..addAll(_defaultSlotStates());
    final rawSlots = map['slotStates'];
    if (rawSlots is Map) {
      rawSlots.forEach((key, value) {
        if (key is String && value is String) {
          SlotIndex? slot;
          SlotState? state;
          for (final s in SlotIndex.values) {
            if (s.name == key) {
              slot = s;
              break;
            }
          }
          for (final st in SlotState.values) {
            if (st.name == value) {
              state = st;
              break;
            }
          }
          if (slot != null && state != null) {
            _slotStates[slot] = state;
          }
        }
      });
    }
    final rawSnap = map['weekStartSnapshot'];
    final newSnap = <StatKind, int>{
      for (final kind in StatKind.values) kind: _statValueFor(kind),
    };
    if (rawSnap is Map) {
      rawSnap.forEach((key, value) {
        if (key is String && value is int) {
          for (final kind in StatKind.values) {
            if (kind.name == key) {
              newSnap[kind] = value;
              break;
            }
          }
        }
      });
    }
    _weekStartSnapshot = newSnap;
    final wsDate = map['weekStartDate'] as String?;
    _weekStartDate =
        (wsDate == null ? null : DateTime.tryParse(wsDate)) ?? _currentDate;
    _lastSalaryAmount = (map['lastSalaryAmount'] as int?) ?? 0;
    _characterStates.clear();
    for (final c in CharacterRepository.all) {
      _characterStates[c.id] = CharacterState();
    }
    final rawChars = map['characterStates'];
    if (rawChars is Map) {
      rawChars.forEach((key, value) {
        if (key is String && value is Map) {
          for (final id in CharacterId.values) {
            if (id.name == key) {
              _characterStates[id] =
                  CharacterState.fromMap(value.cast<String, dynamic>());
              break;
            }
          }
        }
      });
    }
    _unlockedGlobalEventIds.clear();
    final rawIds = map['unlockedGlobalEventIds'];
    if (rawIds is List) {
      for (final v in rawIds) {
        if (v is String) _unlockedGlobalEventIds.add(v);
      }
    }
    final rawCg = map['cgLibrary'];
    if (rawCg is List) {
      _cgLibrary.restoreFrom(<String>[
        for (final v in rawCg)
          if (v is String) v,
      ]);
    } else {
      _cgLibrary.restoreFrom(const <String>[]);
    }
    final rawSchedule = map['schedule'];
    if (rawSchedule is List) {
      _schedule.restoreFrom(rawSchedule);
    } else {
      _schedule.clear();
    }
    // Sprint 12: 所持アイテム復元（旧セーブには無いキー）。
    final rawInventory = map['inventory'];
    if (rawInventory is Map) {
      _inventory.restoreFromMap(rawInventory.cast<String, dynamic>());
    } else {
      _inventory.clear();
    }
    _pendingEncounter = null;
    _pendingEstrangements.clear();
    _pendingCommonEvent = null;
    _pendingMilestoneEvent = null;
    _pendingEnding = null;
    _pendingAutosaveTrigger = null;
    _pendingEvents.clear();
    notifyListeners();
  }

  int _statValueFor(StatKind kind) {
    switch (kind) {
      case StatKind.vitality:
        return _vitality;
      case StatKind.wallet:
        return _money;
      case StatKind.stress:
        return _stress;
      case StatKind.intellect:
      case StatKind.sensibility:
      case StatKind.sociability:
      case StatKind.career:
        return _stats[kind] ?? 0;
    }
  }

  void setHeroName(String name) {
    final trimmed = name.trim();
    if (trimmed == _heroName) {
      return;
    }
    _heroName = trimmed;
    notifyListeners();
  }

  /// 行動を適用する。
  ///
  /// - [slot] の状態が pending 以外なら何もしない（重複適用防止）。
  /// - [kHomeActionList] / [kActionCatalog] の差分を能力値に加算する。
  ///   体力・ストレスは [StatRange.min] 〜上限でクランプ。
  /// - 当該枠を [SlotState.done] にする。
  /// - 行動が [ActionEffect.skipsRemainingSlots] を持つ場合、
  ///   この枠以降を [SlotState.skipped] にして翌日へ進める。
  /// - 全枠が解消されたら翌日へ進む。
  ///
  /// 戻り値: 実際に行動が適用されたかどうか。
  bool applyAction(SlotIndex slot, ActionKind action) {
    if (slotStateOf(slot) != SlotState.pending) {
      return false;
    }
    final effect = kActionCatalog[action];
    if (effect == null) {
      return false;
    }
    _applyDeltas(effect.deltas);
    _slotStates[slot] = SlotState.done;

    if (effect.skipsRemainingSlots) {
      _markRemainingSkipped(slot);
    }

    // 全枠解消なら日付進行。notifyListeners は内部で 1 回にまとめる。
    if (areAllSlotsResolved) {
      _advanceDay();
    }
    _flushPendingEventsAndNotify();
    return true;
  }

  /// 任意の枠以降を「就寝でスキップ」して翌日に進める明示的 API。
  ///
  /// [applyAction] が `sleep` で呼ばれたときに内部で使われるが、
  /// テストやデバッグ時に直接呼べるよう public にしておく。
  void sleepSkipRemaining(SlotIndex from) {
    if (slotStateOf(from) != SlotState.pending) {
      // 既に解消済みなら何もしない
      return;
    }
    final sleepEffect = kActionCatalog[ActionKind.sleep]!;
    _applyDeltas(sleepEffect.deltas);
    _slotStates[from] = SlotState.done;
    _markRemainingSkipped(from);
    if (areAllSlotsResolved) {
      _advanceDay();
    }
    _flushPendingEventsAndNotify();
  }

  /// 全枠が解消されていれば日付を翌日に進める。明示的に呼べるよう public。
  ///
  /// 通常は [applyAction] / [sleepSkipRemaining] 経由で自動的に呼ばれる。
  void advanceDayIfAllSlotsDone() {
    if (!areAllSlotsResolved) {
      return;
    }
    _advanceDay();
    _flushPendingEventsAndNotify();
  }

  /// 開始日に巻き戻す（タイトル「はじめから」で再利用予定）。
  void resetToStart() {
    _currentDate = _defaultStartDate();
    _vitality = _defaultVitality;
    _vitalityMax = _defaultVitalityMax;
    _money = _defaultMoney;
    _stress = _defaultStress;
    _stats
      ..clear()
      ..addAll(_defaultStats());
    _slotStates
      ..clear()
      ..addAll(_defaultSlotStates());
    _weekStartSnapshot = _snapshotStats();
    _weekStartDate = _currentDate;
    _lastSalaryAmount = 0;
    _pendingEvents.clear();
    _schedule.clear();
    // Sprint 06: キャラ状態と未消費イベントもリセット。
    // Sprint 07: 疎遠ペナルティ用の pending リストもリセット。
    _characterStates.clear();
    for (final c in CharacterRepository.all) {
      _characterStates[c.id] = CharacterState();
    }
    _pendingEncounter = null;
    _pendingEstrangements.clear();
    // Sprint 08: イベント/CG 状態もリセット。
    _unlockedGlobalEventIds.clear();
    _pendingCommonEvent = null;
    _pendingMilestoneEvent = null;
    _cgLibrary.clear();
    // Sprint 09: エンディング / オートセーブ pending もリセット。
    _pendingEnding = null;
    _pendingAutosaveTrigger = null;
    // Sprint 12: 所持アイテムもリセット。
    _inventory.clear();
    notifyListeners();
  }

  // --- Sprint 10: 能力値変動通知 (StatChangeOverlay 連動) -----------------

  /// 能力値変動を購読するリスナ。HomeScreen の Overlay コントローラが登録する。
  final List<void Function(StatKind kind, int delta)> _statChangeListeners =
      <void Function(StatKind kind, int delta)>[];

  /// 能力値変動リスナを登録し、解除用クロージャを返す。
  VoidCallback addStatChangeListener(
      void Function(StatKind kind, int delta) listener) {
    _statChangeListeners.add(listener);
    return () => _statChangeListeners.remove(listener);
  }

  void _emitStatChange(StatKind kind, int delta) {
    if (delta == 0) return;
    final listeners =
        List<void Function(StatKind kind, int delta)>.from(_statChangeListeners);
    for (final l in listeners) {
      l(kind, delta);
    }
  }

  /// Sprint 12: GameState 破棄時に内部 ChangeNotifier も解放する。
  ///
  /// `Inventory` は ChangeNotifier。アプリ層で `GameState.dispose()` が呼ばれた際に
  /// その内部リスナリストも一緒に破棄しないとメモリリーク要因になる。
  /// `_dayAdvanceListeners` / `_statChangeListeners` は単純な関数の List なので
  /// `clear()` で十分。dispose 重複呼び出しは ChangeNotifier 側で例外になるが、
  /// `app.dart` のフローでは 1 回のみ。
  @override
  void dispose() {
    _inventory.dispose();
    _dayAdvanceListeners.clear();
    _statChangeListeners.clear();
    super.dispose();
  }

  // --- private helpers -------------------------------------------------

  void _applyDeltas(Map<StatKind, int> deltas) {
    deltas.forEach((kind, delta) {
      switch (kind) {
        case StatKind.vitality:
          final next =
              (_vitality + delta).clamp(StatRange.min, _vitalityMax);
          final actual = next - _vitality;
          _vitality = next;
          _emitStatChange(kind, actual);
          break;
        case StatKind.stress:
          final next =
              (_stress + delta).clamp(StatRange.min, StatRange.max);
          final actual = next - _stress;
          _stress = next;
          _emitStatChange(kind, actual);
          break;
        case StatKind.wallet:
          // 所持金はマイナスを許容しない（Sprint 03 範囲外だが念のため）。
          final next = _money + delta;
          final clamped = next < 0 ? 0 : next;
          final actual = clamped - _money;
          _money = clamped;
          _emitStatChange(kind, actual);
          break;
        case StatKind.intellect:
        case StatKind.sensibility:
        case StatKind.sociability:
        case StatKind.career:
          final cur = _stats[kind] ?? 0;
          final next = (cur + delta).clamp(StatRange.min, StatRange.max);
          final actual = next - cur;
          _stats[kind] = next;
          _emitStatChange(kind, actual);
          break;
      }
    });
  }

  void _markRemainingSkipped(SlotIndex from) {
    final order = SlotIndex.values;
    final startIdx = order.indexOf(from);
    for (int i = startIdx + 1; i < order.length; i++) {
      if (_slotStates[order[i]] == SlotState.pending) {
        _slotStates[order[i]] = SlotState.skipped;
      }
    }
  }

  void _advanceDay() {
    // 1) 「今日」が日曜なら週次ふりかえりを発火予約（日付を進める前）。
    if (isWeekEnd(_currentDate)) {
      _pendingEvents.add(DayAdvanceEvent.weeklyReview);
    }

    // 2) 日付を翌日に進める。
    _currentDate = _currentDate.add(const Duration(days: 1));
    _slotStates
      ..clear()
      ..addAll(_defaultSlotStates());

    // 3) 翌日が月の1日なら、給料を即時加算し salary イベントを発火予約。
    //    給料額は仕事評価の現在値ベース。所持金更新は notifyListeners 前に
    //    反映するため、ここで直接 _money に加算する（receiveSalary は呼ばない）。
    if (isMonthStart(_currentDate)) {
      final salary = computeSalary(_stats[StatKind.career] ?? 0);
      _money += salary;
      _lastSalaryAmount = salary;
      _pendingEvents.add(DayAdvanceEvent.salary);
    }

    // 4) Sprint 06: 翌日が出会いイベント発火日と一致し、かつ対象キャラが
    //    未会いなら encounter イベントを発火予約。pending に対象を退避する。
    //    UI 側は DayAdvanceEvent.encounter を受けて pendingEncounter を読み、
    //    DialogueModal 表示後に consumePendingEncounter で isMet を確定する。
    final EncounterEvent? hit = EncounterRepository.eventOn(_currentDate);
    if (hit != null && !characterStateOf(hit.targetId).isMet) {
      _pendingEncounter = hit;
      _pendingEvents.add(DayAdvanceEvent.encounter);
    }

    // 5) Sprint 07: 出会い済みの各キャラについて、lastInteractedDate から
    //    kEstrangementThresholdDays 日以上経過していたら疎遠ペナルティを適用。
    //    一度適用したキャラは lastInteractedDate を「今日」に進めて、
    //    次の発火を更にもう 1 ヶ月後に繰り越す（連続発火防止）。
    _applyEstrangementPenalties();

    // 6) Sprint 08: 翌日が共通イベント / 節目イベントの発火日と一致するなら
    //    対応するイベントを pending に積む。EventResolver は静的データから
    //    引くだけなので副作用なし。HomeScreen 側で EventPlayer / 節目用画面を
    //    起動する。
    const resolver = EventResolver();
    final common = resolver.resolveCommon(
      currentDate: _currentDate,
      unlockedEventIds: _unlockedGlobalEventIds,
    );
    if (common != null) {
      _pendingCommonEvent = common;
      _pendingEvents.add(DayAdvanceEvent.common);
    }
    final milestone = resolver.resolveMilestone(
      currentDate: _currentDate,
      unlockedEventIds: _unlockedGlobalEventIds,
    );
    if (milestone != null) {
      _pendingMilestoneEvent = milestone;
      _pendingEvents.add(DayAdvanceEvent.milestone);
    }

    // 7) Sprint 09: オートセーブのトリガ判定。
    //    月初・日曜終了直後（既に翌日に進んでいるので「今日が月曜」で判定）・
    //    重要イベント発火前（節目イベントが pending した場合）。
    //    実体の保存は HomeScreen 側で SaveRepository.writeAuto を呼ぶ。
    //    優先順位: monthStart > beforeEvent > weekEnd。
    AutosaveTrigger? autosave;
    if (isMonthStart(_currentDate)) {
      autosave = AutosaveTrigger.monthStart;
    } else if (milestone != null || common != null) {
      // 節目イベント直前（あるいは重い共通イベント直前）に保険セーブ。
      autosave = AutosaveTrigger.beforeEvent;
    } else if (_currentDate.weekday == DateTime.monday) {
      // 「日曜終了 → 月曜開始」の遷移時に週末セーブ。
      autosave = AutosaveTrigger.weekEnd;
    }
    if (autosave != null) {
      _pendingAutosaveTrigger = autosave;
      _pendingEvents.add(DayAdvanceEvent.autosave);
    }

    // 8) Sprint 09: 年度末（3/31）に達したらエンディング判定を予約。
    //    通常の applyAction 経由で 4 枠を 3/31 中に消費し、_advanceDay で
    //    翌日が 4/1 に進む。ここでは「進んだ後の currentDate が 4/1」かつ
    //    「翌年（=開始から 1 年経過後）」のときにエンディング発火。
    //    debugFastForward 等で当日に直接ジャンプした場合は HomeScreen 側で
    //    debugTriggerEndingResolution を呼ぶ前提（spec 通り 3/31 終了時）。
    if (_currentDate.month == 4 && _currentDate.day == 1) {
      // 開始日が 2026/4/1。1 年経過後（2027/4/1）に到達したらエンディング判定。
      final start = _defaultStartDate();
      if (_currentDate.year > start.year) {
        _pendingEnding = resolveEndingFromGameState(this);
        _pendingEvents.add(DayAdvanceEvent.endingReached);
      }
    }
  }

  /// 出会い済キャラを走査し、疎遠ペナルティを適用する。
  /// 一括で `_pendingEstrangements` に対象を積み、`_advanceDay` 末尾で
  /// 1 度だけ `DayAdvanceEvent.estrangement` を発火する。
  void _applyEstrangementPenalties() {
    final affected = <CharacterId>[];
    for (final entry in _characterStates.entries) {
      final s = entry.value;
      if (!s.isMet) continue;
      final last = s.lastInteractedDate;
      if (last == null) continue;
      final diffDays = _currentDate.difference(last).inDays;
      if (diffDays >= kEstrangementThresholdDays) {
        s.bumpAffinity(kEstrangementAffinityDelta);
        s.bumpTrueAffinity(kEstrangementTrueAffinityDelta);
        // 次回発火を「今日」基準に繰り上げる。
        s.lastInteractedDate = _currentDate;
        affected.add(entry.key);
      }
    }
    if (affected.isNotEmpty) {
      _pendingEstrangements.addAll(affected);
      _pendingEvents.add(DayAdvanceEvent.estrangement);
    }
  }

  /// 発火予約済みのイベントを順にリスナへ通知してから `notifyListeners`。
  ///
  /// リスナ内で `applyAction` を再帰的に呼ばないこと（無限ループ防止）。
  /// UI 側の購読は「画面遷移」「ダイアログ表示」など副作用に限定する想定。
  void _flushPendingEventsAndNotify() {
    if (_pendingEvents.isNotEmpty) {
      final events = List<DayAdvanceEvent>.from(_pendingEvents);
      _pendingEvents.clear();
      for (final ev in events) {
        // リスナの破壊的変更に強くするためコピーを使ってイテレートする。
        final listeners = List<DayAdvanceListener>.from(_dayAdvanceListeners);
        for (final l in listeners) {
          l(ev);
        }
      }
    }
    notifyListeners();
  }

  /// 4能力値 + 体力 + 所持金 + ストレス の現スナップショット。
  Map<StatKind, int> _snapshotStats() {
    return <StatKind, int>{
      for (final kind in StatKind.values) kind: _statValueFor(kind),
    };
  }
}
