import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app.dart';
import '../data/character_repository.dart';
import '../data/work_events.dart';
import '../models/actions.dart';
import '../models/audio_keys.dart';
import '../models/calendar.dart';
import '../models/dialogue.dart';
import '../models/event_resolver.dart';
import '../models/game_state.dart';
import '../models/stats.dart';
import '../models/work.dart';
import '../widgets/action_sheet.dart';
import '../widgets/dialogue_modal.dart';
import '../widgets/event_player.dart';
import '../widgets/invite_sheet.dart';
import '../widgets/page_transitions.dart';
import '../widgets/salary_dialog.dart';
import '../widgets/scenic_background.dart';
import '../widgets/stat_change_overlay.dart';
import '../widgets/work_event_dialog.dart';
import '../widgets/work_judgment_dialog.dart';
import 'cg_reveal_screen.dart';
import 'christmas_choice_screen.dart';
import 'ending_screen.dart';
import 'save_load_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'title_screen.dart';
import 'weekly_review_screen.dart';

/// ホーム画面（拠点）。
///
/// Sprint 02 で以下を追加：
/// - 上部ステータスバー（日付・体力・所持金・ストレス表情アイコン）
/// - 4枠タイムライン（朝・日中・夕方・夜、ラベル付き）
///
/// Sprint 03 で以下を追加：
/// - 各タイムライン枠をタップで [showActionSheet] を起動
/// - 枠の状態 ([SlotState]) に応じて「未実行 / 実行済 / 就寝でスキップ」を表示
/// - 行動実行後の能力値変動と日付進行
///
/// Sprint 04 で以下を追加：
/// - 平日日中は「仕事」固定スロット表示。タップで仕事ミニ判定。
/// - 平日夕方の行動シートに「残業」を追加。
/// - 日曜終了時に週次ふりかえり画面をモーダル表示し、閉じた後で
///   `GameState.resetWeekSnapshot` を呼んで次週へ進める。
/// - 月初に給料ダイアログを表示。
///
/// 下部の 5 タブナビゲーションは [MainScaffold] が提供するため、
/// この画面自身は AppBar・BottomNavigationBar を持たない。
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.workRng,
    this.randomEventRng,
    this.workEventRng,
  });

  /// 仕事ミニ判定用の Random。null なら `Random()` を使う（実プレイ）。
  /// 統合テストや決定論的テストでは seed 固定の Random を渡せる。
  final Random? workRng;

  /// Sprint 08: ランダム遭遇の確率判定 + 抽選で使う Random。
  /// null なら `Random()` を使う（実プレイ）。テストでは seed を渡して固定化する。
  final Random? randomEventRng;

  /// Sprint C: 仕事中イベントの発火判定 + 抽選で使う Random。
  /// null なら **判定そのものをスキップ**（従来通り即ロール）する。
  /// 既存テストが workEventRng 未指定で従来の即ロール挙動に依存しているため、
  /// safe-default は null（イベント発生なし）。
  final Random? workEventRng;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  VoidCallback? _unsubscribe;
  VoidCallback? _unsubscribeStat;
  late Random _rng;

  /// Sprint 08: ランダム遭遇判定用の Random。
  /// `widget.randomEventRng` が null（テストなど明示的にランダム挙動を望まない場合）
  /// はランダム遭遇判定をスキップする。実プレイ時は MainScaffold 側で
  /// `Random()` を渡すことで確率発火を有効化する。
  Random? _randomEventRng;

  /// Sprint C: 仕事中イベントの判定用 Random。null ならイベント発火なし。
  Random? _workEventRng;
  static const EventResolver _resolver = EventResolver();

  /// Sprint 10: 能力値変動ポップアップのコントローラ。HomeScreen の Stack の
  /// 右上に [StatChangeOverlayHost] を置く。
  final StatChangeOverlayController _statOverlay =
      StatChangeOverlayController();

  /// Sprint 10: イベント発火時の白フラッシュ用コントローラ。
  bool _flashing = false;

  /// Sprint 12: 白フラッシュの解除タイマ。dispose 時に cancel してリーク回避。
  Timer? _flashTimer;

  /// Hotfix 2026-05-18: DayAdvanceEvent を直列処理するためのキュー。
  /// `_advanceDay` 内で複数イベント（weeklyReview→salary→encounter…）が同フレームに
  /// 積まれても、Navigator を 1 つずつ await して push し、スタック破壊を防ぐ。
  final Queue<DayAdvanceEvent> _eventQueue = Queue<DayAdvanceEvent>();
  bool _processingEvents = false;

  @override
  void initState() {
    super.initState();
    _rng = widget.workRng ?? Random();
    _randomEventRng = widget.randomEventRng;
    _workEventRng = widget.workEventRng;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_unsubscribe != null) return;
    final scope = AppScope.of(context);
    _unsubscribe = scope.gameState.addDayAdvanceListener(_onDayAdvanceEvent);
    _unsubscribeStat = scope.gameState.addStatChangeListener((kind, delta) {
      _statOverlay.push(kind, delta);
      // Sprint 11: 能力値上昇時に statUp SE。所持金・ストレス減少も「上昇感」
      // としては前向きだが、ここでは「正の差分のみ」に絞る（連発防止）。
      if (delta > 0 && kind != StatKind.stress) {
        scope.audio.playSe(AudioKeys.seStatUp);
      }
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _unsubscribe?.call();
    _unsubscribeStat?.call();
    _statOverlay.dispose();
    _eventQueue.clear();
    super.dispose();
  }

  /// Sprint 10: イベント発火直前に画面全体に薄い白フラッシュ（200ms）。
  /// Sprint 11: 同時に eventFire SE を再生要求。
  /// Sprint 12: Future.delayed を Timer に置き換え、dispose 時 cancel でリーク回避。
  void _triggerEventFlash() {
    if (!mounted) return;
    try {
      AppScope.of(context).audio.playSe(AudioKeys.seEventFire);
    } catch (e) {
      debugPrint('[HomeScreen] AudioService unavailable for flash: $e');
    }
    setState(() => _flashing = true);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _flashing = false);
      }
    });
  }

  /// `GameState._advanceDay` 内で発火予約されたイベントを UI 側で処理する。
  ///
  /// Hotfix 2026-05-18: 同フレームに複数イベントが積まれた場合に Navigator 操作が
  /// 並列に走ってスタックが壊れる問題を回避するため、Queue に積んで 1 個ずつ
  /// await で順に処理する直列キュー方式へ変更。
  void _onDayAdvanceEvent(DayAdvanceEvent event) {
    _eventQueue.add(event);
    if (_processingEvents) return;
    _processingEvents = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _drainEventQueue();
    });
  }

  /// キューを 1 個ずつ取り出し、await で順に処理する。
  /// `mounted=false` になった時点で残りは破棄して安全終了する。
  Future<void> _drainEventQueue() async {
    try {
      while (_eventQueue.isNotEmpty) {
        if (!mounted) {
          _eventQueue.clear();
          return;
        }
        final event = _eventQueue.removeFirst();
        await _handleSingleEvent(event);
      }
    } finally {
      _processingEvents = false;
    }
  }

  /// 1 個の DayAdvanceEvent を実際に処理する。Navigator/SnackBar を含む。
  Future<void> _handleSingleEvent(DayAdvanceEvent event) async {
      if (!mounted) return;
      final scope = AppScope.of(context);
      switch (event) {
        case DayAdvanceEvent.weeklyReview:
          final deltas = scope.gameState.weeklyDeltas;
          final current = scope.gameState.allStats;
          // weeklyReview は「日曜終了直後」なので、_currentDate は既に
          // 月曜に進んでいる。週末日付 = currentDate - 1日 で算出。
          final monday = scope.gameState.currentDate;
          final sunday = monday.subtract(const Duration(days: 1));
          await Navigator.of(context).push<void>(
            slideUpRoute<void>(
              (_) => WeeklyReviewScreen(
                weekStartDate: scope.gameState.weekStartDate,
                weekEndDate: sunday,
                deltas: deltas,
                currentStats: current,
              ),
            ),
          );
          if (!mounted) return;
          scope.gameState.resetWeekSnapshot();
          break;
        case DayAdvanceEvent.salary:
          final amount = scope.gameState.lastSalaryAmount;
          await showSalaryDialog(
            context,
            amount: amount,
            date: scope.gameState.currentDate,
          );
          break;
        case DayAdvanceEvent.encounter:
          // Sprint 06: 出会いイベント発火。DialogueModal で発話を順に表示し、
          // 閉じたら consumePendingEncounter で対象キャラを「出会い済」確定。
          final ev = scope.gameState.pendingEncounter;
          if (ev == null) break;
          _triggerEventFlash();
          final character = CharacterRepository.byId(ev.targetId);
          await DialogueModal.show(
            context,
            character: character,
            locationLabel: ev.locationLabel,
            lines: ev.lines,
          );
          if (!mounted) return;
          scope.gameState.consumePendingEncounter();
          break;
        case DayAdvanceEvent.estrangement:
          // Sprint 07: 疎遠ペナルティ発火。複数キャラまとめて SnackBar で通知。
          final ids = scope.gameState.pendingEstrangements;
          if (ids.isEmpty) break;
          final names = [
            for (final id in ids) CharacterRepository.byId(id).displayName,
          ].join('・');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              key: const ValueKey('home.snackBar.estrangement'),
              content: Text('$names としばらく会っていない…'),
            ),
          );
          scope.gameState.consumePendingEstrangements();
          break;
        case DayAdvanceEvent.common:
          // Sprint 08: 共通イベント（健康診断・夏祭り等）が日付ベースで自動発火。
          final ev = scope.gameState.pendingCommonEvent;
          if (ev == null) break;
          _triggerEventFlash();
          final wasCgUnlocked = ev.cgKey != null &&
              !scope.gameState.cgLibrary.has(ev.cgKey!);
          final picked = await EventPlayer.show(context, event: ev);
          if (!mounted) return;
          if (picked != null) {
            // 共通イベントの選択肢は対象キャラがいないため、
            // ストレス差分のみ反映する（ChoiceOutcome.affinityDelta は無視）。
            _applyOutcomeStandalone(scope.gameState, picked.outcome);
          }
          scope.gameState.markEventCompleted(ev);
          scope.gameState.consumePendingCommonEvent();
          // Sprint 10: 新規 CG 解放時は CgRevealScreen でフェードイン全画面表示。
          if (wasCgUnlocked && ev.cgKey != null && mounted) {
            await CgRevealScreen.show(
              context,
              cgKey: ev.cgKey!,
              title: ev.title,
              themeColor: Theme.of(context).colorScheme.primary,
              caption: ev.locationLabel,
            );
          }
          if (ev.unlockMessage != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ev.unlockMessage!)),
            );
          }
          break;
        case DayAdvanceEvent.autosave:
          // Sprint 09: オートセーブのフック。SaveRepository に最新状態を書き出す。
          final trigger = scope.gameState.pendingAutosaveTrigger;
          if (trigger == null) break;
          final repo = scope.saveRepository;
          if (repo != null) {
            await repo.writeAuto(scope.gameState);
            if (!mounted) break;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                key: const ValueKey('home.snackBar.autosave'),
                content: Text(_autosaveLabel(trigger)),
                duration: const Duration(seconds: 1),
              ),
            );
          }
          scope.gameState.consumePendingAutosaveTrigger();
          break;
        case DayAdvanceEvent.endingReached:
          // Sprint 09: 1 年プレイ完了 → エンディング再生 → 図鑑に記録 → タイトルへ。
          final kind = scope.gameState.pendingEnding;
          if (kind == null) break;
          final arc = scope.endingArchive;
          if (arc != null) {
            await arc.recordAchievement(kind, DateTime.now());
          }
          if (!mounted) break;
          await EndingScreen.show(
            context,
            kind: kind,
            onComplete: () => popToTitle(context),
          );
          if (!mounted) break;
          scope.gameState.consumePendingEnding();
          break;
        case DayAdvanceEvent.milestone:
          // Sprint 08: 節目イベント（クリスマス等）。「誰と過ごすか」選択を経由。
          final ev = scope.gameState.pendingMilestoneEvent;
          if (ev == null) break;
          if (ev.id == 'common.christmas.dec') {
            // 12/24 専用: ChristmasChoiceScreen → 選んだキャラ用シーン再生。
            final result = await ChristmasChoiceScreen.show(context);
            if (!mounted) return;
            scope.gameState.markEventCompleted(ev);
            if (result != null) {
              final cg = result.cgKey;
              if (cg != null) {
                scope.gameState.cgLibrary.unlock(cg);
              }
              // 選択結果に応じて、本人の好感度を大幅プラス（一人なら何もしない）。
              final picked = result.pickedCharacter;
              if (picked != null) {
                scope.gameState.applyChoiceOutcome(
                  target: picked,
                  outcome: const ChoiceOutcome(
                    label: 'クリスマスを共に過ごす',
                    affinityDelta: 4,
                    trueAffinityDelta: 6,
                  ),
                );
              }
            }
            scope.gameState.consumePendingMilestoneEvent();
          } else {
            // その他の節目イベント: 通常の EventPlayer 経由で再生。
            final picked = await EventPlayer.show(context, event: ev);
            if (!mounted) return;
            if (picked != null) {
              _applyOutcomeStandalone(scope.gameState, picked.outcome);
            }
            scope.gameState.markEventCompleted(ev);
            scope.gameState.consumePendingMilestoneEvent();
          }
          break;
      }
  }

  /// 共通/ランダムイベントなど、対象キャラがいないイベントで効果を反映する補助。
  /// 表面/真の好感度は無視し、主人公のストレスのみを動かす。
  void _applyOutcomeStandalone(GameState state, ChoiceOutcome outcome) {
    if (outcome.stressDelta == 0) return;
    state.bumpStress(outcome.stressDelta);
  }

  /// オートセーブの SnackBar 文言。
  static String _autosaveLabel(AutosaveTrigger trigger) {
    switch (trigger) {
      case AutosaveTrigger.monthStart:
        return 'オートセーブしました（月初）';
      case AutosaveTrigger.weekEnd:
        return 'オートセーブしました（週末）';
      case AutosaveTrigger.beforeEvent:
        return 'オートセーブしました（節目イベント前）';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: scope.gameState,
      builder: (context, _) {
        final state = scope.gameState;
        return Scaffold(
          key: const ValueKey('scaffold.home'),
          // Hotfix 2026-05-18 (B5): セーブ/ロードを画面下の FAB に配置。
          // 設定/ショップは AppBar 残し（頻度が低いため）。
          floatingActionButton: FloatingActionButton.small(
            key: const ValueKey('home.saveFab'),
            tooltip: 'セーブ/ロード',
            onPressed: () {
              scope.audio.playSe(AudioKeys.seTap);
              SaveLoadScreen.push(context);
            },
            child: const Icon(Icons.save_outlined),
          ),
          appBar: AppBar(
            title: Text(formatHomeDate(state.currentDate)),
            actions: [
              // Sprint 12: ショップ画面への導線。
              IconButton(
                key: const ValueKey('home.shopButton'),
                icon: const Icon(Icons.storefront_outlined),
                tooltip: 'ショップ',
                onPressed: () {
                  scope.audio.playSe(AudioKeys.seTap);
                  ShopScreen.push(context);
                },
              ),
              // Hotfix 2026-05-18 (B5): セーブは片手操作のため画面下 FAB に移動。
              IconButton(
                key: const ValueKey('home.settingsButton'),
                icon: const Icon(Icons.settings),
                tooltip: '設定',
                onPressed: () {
                  scope.audio.playSe(AudioKeys.seTap);
                  Navigator.of(context).push(
                    fadeRoute<void>((_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // Sprint 10: 背景は最下層に置く。透明度低めなので前景は読みやすい。
              Positioned.fill(
                child: Opacity(
                  opacity: 0.35,
                  child: ScenicBackground(
                    key: const ValueKey('home.scenicBackground'),
                    currentDate: state.currentDate,
                    progressSlot: _resolveProgressSlot(state),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StatusBar(
                        key: const ValueKey('home.statusBar'),
                        date: state.currentDate,
                        vitality: state.vitality,
                        vitalityMax: state.vitalityMax,
                        money: state.money,
                        mood: state.stressMood,
                      ),
                      const SizedBox(height: 12),
                      _HeroHeader(name: state.heroName),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: SlotIndex.values.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final slot = SlotIndex.values[index];
                            return _TimelineSlot(
                              slot: slot,
                              state: state.slotStateOf(slot),
                              isWeekdayWork: _isWeekdayMidday(state, slot),
                              onTap: () => _onSlotTap(context, slot),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Sprint 10: 能力値変動ポップアップ（右上）。
              SafeArea(
                child: StatChangeOverlayHost(
                  key: const ValueKey('home.statChangeOverlay'),
                  controller: _statOverlay,
                ),
              ),
              // Sprint 10: イベント発火時の白フラッシュ。
              if (_flashing)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(color: Color(0x55FFFFFF)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 進行中のスロット（最初の pending 枠）を返す。全枠終了なら night を返す。
  SlotIndex _resolveProgressSlot(GameState state) {
    for (final s in SlotIndex.values) {
      if (state.slotStateOf(s) == SlotState.pending) return s;
    }
    return SlotIndex.night;
  }

  bool _isWeekdayMidday(GameState state, SlotIndex slot) {
    return slot == SlotIndex.midday && isWeekday(state.currentDate);
  }

  Future<void> _onSlotTap(BuildContext context, SlotIndex slot) async {
    final gameState = AppScope.of(context).gameState;
    if (gameState.slotStateOf(slot) != SlotState.pending) {
      return;
    }

    // Sprint 08: 朝の出勤枠（平日朝）でのランダム遭遇判定（先頭で行う）。
    // 個別イベント・予約・通常行動より前にチェックする。
    // randomEventRng が null のときはスキップ（テスト時の挙動安定のため）。
    final rng = _randomEventRng;
    if (rng != null &&
        slot == SlotIndex.morning &&
        isWeekday(gameState.currentDate) &&
        _resolver.shouldFireRandom(
          rng,
          currentDate: gameState.currentDate,
          slot: slot,
        )) {
      final ev = _resolver.pickRandom(rng);
      final picked = await EventPlayer.show(context, event: ev);
      if (!context.mounted) return;
      if (picked != null) {
        _applyOutcomeStandalone(gameState, picked.outcome);
      }
      gameState.markEventCompleted(ev);
      if (ev.unlockMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ev.unlockMessage!)),
        );
      }
      // ランダム遭遇は枠を消費しない（仕様: 短い小ネタ）。通常フローに続行。
    }
    if (!context.mounted) return;

    // 告白前夜イベントの優先発火判定（個別イベントよりさらに先）。
    // 表面好感度 ≥75 + 真の好感度 ≥15 を満たすキャラがいれば、
    // 通常フローを差し置いて発火する。日中（平日仕事）枠以外で許可。
    if (!_isWeekdayMidday(gameState, slot)) {
      final confEv = gameState.findConfessionEveEvent();
      if (confEv != null) {
        _triggerEventFlash();
        final wasCgUnlocked = confEv.cgKey != null &&
            !gameState.cgLibrary.has(confEv.cgKey!);
        final picked = await EventPlayer.show(context, event: confEv);
        if (!context.mounted) return;
        final target = confEv.target;
        if (picked != null && target != null) {
          gameState.applyChoiceOutcome(target: target, outcome: picked.outcome);
        }
        gameState.markEventCompleted(confEv);
        if (wasCgUnlocked && confEv.cgKey != null && context.mounted) {
          final color = target != null
              ? CharacterRepository.byId(target).themeColor
              : Theme.of(context).colorScheme.primary;
          await CgRevealScreen.show(
            context,
            cgKey: confEv.cgKey!,
            title: confEv.title,
            themeColor: color,
            caption: confEv.locationLabel,
          );
        }
        if (!context.mounted) return;
        gameState.consumeIndividualEventSlot(slot);
        if (confEv.unlockMessage != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(confEv.unlockMessage!)),
          );
        }
        return;
      }
    }

    // Sprint 08: 個別イベントの優先発火判定。条件を満たすイベントがあれば
    // 通常の行動シートよりも先に再生する。再生後は枠を done にして、
    // 既存の applyAction とは独立に状態を進める。
    if (!_isWeekdayMidday(gameState, slot)) {
      final indEv = gameState.findIndividualEventFor(slot);
      if (indEv != null) {
        _triggerEventFlash();
        final wasCgUnlocked = indEv.cgKey != null &&
            !gameState.cgLibrary.has(indEv.cgKey!);
        final picked = await EventPlayer.show(context, event: indEv);
        if (!context.mounted) return;
        final target = indEv.target;
        if (picked != null && target != null) {
          gameState.applyChoiceOutcome(target: target, outcome: picked.outcome);
        }
        gameState.markEventCompleted(indEv);
        // Sprint 10: 新規 CG 解放時は全画面プレビュー。
        if (wasCgUnlocked && indEv.cgKey != null && context.mounted) {
          final color = target != null
              ? CharacterRepository.byId(target).themeColor
              : Theme.of(context).colorScheme.primary;
          await CgRevealScreen.show(
            context,
            cgKey: indEv.cgKey!,
            title: indEv.title,
            themeColor: color,
            caption: indEv.locationLabel,
          );
        }
        if (!context.mounted) return;
        // 枠を done にする。全枠解消なら advanceDayIfAllSlotsDone を呼ぶ。
        gameState.consumeIndividualEventSlot(slot);
        if (indEv.unlockMessage != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(indEv.unlockMessage!)),
          );
        }
        return;
      }
    }

    // Sprint 05: 予約があれば自動実行。平日日中（仕事固定）は予約対象外。
    if (!_isWeekdayMidday(gameState, slot) &&
        gameState.schedule.reservationOf(gameState.currentDate, slot) != null) {
      final result = gameState.applyScheduledActionFor(slot);
      if (!context.mounted) return;
      switch (result) {
        case ScheduledActionResult.applied:
          // 何もしない。能力値変動は AnimatedBuilder 経由で反映される。
          return;
        case ScheduledActionResult.skippedInsufficientMoney:
          // Sprint 11: 所持金不足のエラーは error SE で通知。
          AppScope.of(context).audio.playSe(AudioKeys.seError);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('所持金不足のため予約をスキップしました'),
            ),
          );
          // 通常の選択シートにフォールバックさせる（payable な行動を選べる）。
          break;
        case ScheduledActionResult.skippedSlotResolved:
        case ScheduledActionResult.noReservation:
          // ここには通常到達しない（事前に検査済み）。
          return;
      }
    }

    // 平日日中 → 仕事ミニ判定フロー
    // Hotfix 2026-05-18 (B4): 確認ダイアログを廃止し、日中枠タップで即ロール
    // → 結果ダイアログ 1 つに短縮。月 20 タップ → 月 20 タップ（旧 60 タップ）。
    // Sprint C: workEventRng が渡されている場合、35% で仕事中イベントに分岐。
    if (_isWeekdayMidday(gameState, slot)) {
      final weRng = _workEventRng;
      if (weRng != null && WorkEventCatalog.shouldFire(weRng)) {
        final ev = WorkEventCatalog.pick(weRng);
        _triggerEventFlash();
        final picked = await showWorkEventDialog(context, event: ev);
        if (!context.mounted) return;
        if (picked != null) {
          gameState.applyWorkChoice(picked.effect);
        } else {
          // 中断（barrierDismissible=false なので実質起こらない）。安全のため
          // フォールバックで即ロール扱いに戻す。
          final career = gameState.allStats[StatKind.career] ?? 0;
          final outcome = const WorkResolver().resolve(_rng, career);
          gameState.applyWorkOutcome(outcome);
        }
        return;
      }
      final career = gameState.allStats[StatKind.career] ?? 0;
      final outcome =
          const WorkResolver().resolve(_rng, career);
      gameState.applyWorkOutcome(outcome);
      if (!context.mounted) return;
      await showWorkResultDialog(context, outcome: outcome);
      return;
    }

    // 行動リストの選択:
    // - 平日夕方:   kWeekdayEveningActionList（自宅3 + 残業）
    // - 休日全枠:   kHolidayActionList（自宅3 + 外出4）
    // - 平日朝/夜: kHomeActionList（自宅3）
    final isHolidayToday = isHoliday(gameState.currentDate);
    final List<ActionEffect> actions;
    if (isHolidayToday) {
      actions = kHolidayActionList;
    } else if (slot == SlotIndex.evening) {
      actions = kWeekdayEveningActionList;
    } else {
      actions = kHomeActionList;
    }

    final selected = await showActionSheet(
      context,
      slotLabel: slot.label,
      actions: actions,
      currentMoney: gameState.money,
    );
    if (selected == null) {
      return;
    }
    // Sprint 06: 「誘う」は applyAction を通さず、専用フローへ分岐する。
    // invite_sheet.dart の runInviteFlow が成否判定と枠消費まで担う。
    if (selected == ActionKind.invite) {
      if (!context.mounted) return;
      await runInviteFlow(context, slot: slot);
      return;
    }
    gameState.applyAction(slot, selected);
  }
}

/// ホーム画面の日付フォーマッタ。例: 「4月1日（水）」。
String formatHomeDate(DateTime date) {
  const weekdayNames = ['月', '火', '水', '木', '金', '土', '日'];
  final wd = weekdayNames[date.weekday - 1];
  return '${date.month}月${date.day}日（$wd）';
}

/// 上部ステータスバー。
///
/// 日付・体力（現在値/最大値）・所持金（円）・ストレス表情の4要素を
/// 1行で表示する。SafeArea の中に配置される前提。
/// 画面幅が狭い場合の崩れ防止に [Wrap] を使い、要素ごとに折り返せるようにする。
class StatusBar extends StatelessWidget {
  const StatusBar({
    super.key,
    required this.date,
    required this.vitality,
    required this.vitalityMax,
    required this.money,
    required this.mood,
  });

  final DateTime date;
  final int vitality;
  final int vitalityMax;
  final int money;
  final StressMood mood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _StatusChip(
            keyValue: 'statusBar.date',
            icon: Icons.calendar_today,
            label: formatHomeDate(date),
          ),
          _StatusChip(
            keyValue: 'statusBar.vitality',
            icon: Icons.favorite,
            label: '$vitality/$vitalityMax',
          ),
          _StatusChip(
            keyValue: 'statusBar.money',
            icon: Icons.payments,
            label: '${_formatYen(money)}円',
          ),
          _StatusChip(
            keyValue: 'statusBar.mood',
            icon: _moodIcon(mood),
            label: _moodLabel(mood),
          ),
        ],
      ),
    );
  }

  static String _formatYen(int yen) {
    final s = yen.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write(',');
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static IconData _moodIcon(StressMood mood) {
    switch (mood) {
      case StressMood.satisfied:
        return Icons.sentiment_satisfied;
      case StressMood.neutral:
        return Icons.sentiment_neutral;
      case StressMood.dissatisfied:
        return Icons.sentiment_dissatisfied;
    }
  }

  static String _moodLabel(StressMood mood) {
    switch (mood) {
      case StressMood.satisfied:
        return '良好';
      case StressMood.neutral:
        return '普通';
      case StressMood.dissatisfied:
        return '疲労';
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.keyValue,
    required this.icon,
    required this.label,
  });

  final String keyValue;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      key: ValueKey(keyValue),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('home.heroHeader'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            name.isEmpty ? '名無し' : name,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _TimelineSlot extends StatelessWidget {
  const _TimelineSlot({
    required this.slot,
    required this.state,
    required this.onTap,
    required this.isWeekdayWork,
  });

  final SlotIndex slot;
  final SlotState state;
  final VoidCallback onTap;

  /// 平日日中で「仕事」固定スロットとして描画するか。
  final bool isWeekdayWork;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isResolved = state != SlotState.pending;
    final statusText = _statusText(state, isWeekdayWork: isWeekdayWork);
    final statusIcon = _statusIcon(state, isWeekdayWork: isWeekdayWork);
    final fg = isResolved
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('home.timelineSlot.${slot.label}.tap'),
        borderRadius: BorderRadius.circular(12),
        onTap: isResolved ? null : onTap,
        child: Container(
          key: ValueKey('home.timelineSlot.${slot.label}'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isResolved
                ? theme.colorScheme.surfaceContainerLow
                : null,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  slot.label,
                  style: theme.textTheme.titleMedium?.copyWith(color: fg),
                ),
              ),
              const SizedBox(width: 12),
              if (statusIcon != null) ...[
                Icon(statusIcon, size: 18, color: fg),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  statusText,
                  key: ValueKey('home.timelineSlot.${slot.label}.status'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusText(SlotState state, {required bool isWeekdayWork}) {
    switch (state) {
      case SlotState.pending:
        return isWeekdayWork ? '仕事' : '未実行';
      case SlotState.done:
        return isWeekdayWork ? '仕事（実行済）' : '実行済';
      case SlotState.skipped:
        return '就寝でスキップ';
    }
  }

  static IconData? _statusIcon(SlotState state, {required bool isWeekdayWork}) {
    switch (state) {
      case SlotState.pending:
        return isWeekdayWork ? Icons.work : null;
      case SlotState.done:
        return Icons.check_circle;
      case SlotState.skipped:
        return Icons.bedtime;
    }
  }
}
