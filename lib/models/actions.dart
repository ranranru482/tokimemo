import 'stats.dart';
import 'work.dart';

/// 1 日の行動枠の識別子。
///
/// ホーム画面のタイムラインに表示される 4 枠（朝・日中・夕方・夜）に対応する。
/// 表示順は宣言順（[SlotIndex.values]）に従う。
enum SlotIndex {
  morning(label: '朝'),
  midday(label: '日中'),
  evening(label: '夕方'),
  night(label: '夜');

  const SlotIndex({required this.label});

  final String label;
}

/// 行動枠の状態。
///
/// Sprint 03 では「未実行 / 実行済 / 就寝でスキップ」の 3 状態を持つ。
/// 行動内容そのものを表すわけではなく、「タップ可能か」「日付進行に進めて
/// よいか」を判定するためのフラグとして使う。
enum SlotState {
  /// まだ何も実行していない（タップで行動選択シートが開く）。
  pending,

  /// 行動を実行済み（タップしてもシートは開かない）。
  done,

  /// 「就寝」によりスキップされた（実質 done と同等扱い）。
  skipped,
}

/// 主人公が取れる行動の種類。
///
/// Sprint 03 で自宅行動 3 種（読書・運動・就寝）を定義。
/// Sprint 04 で残業 ([overtime]) を追加（平日夕方枠でのみ選択可能）。
/// Sprint 05 で外出4種（カフェ・映画・美術館・ジム）を追加（休日のみ）。
/// Sprint 06 で誘い行動 ([invite]) を追加（休日のみ・カフェ1杯ぶんのコスト）。
enum ActionKind {
  read,
  exercise,
  sleep,
  overtime,
  cafe,
  movie,
  museum,
  gym,
  invite,
}

// ===========================================================================
// Sprint 05: 外出4行動の暫定マジックナンバー
// ===========================================================================
//
// 仕様書 §3 の能力値傾向（カフェ=感性、映画=感性/ストレス、美術館=感性/知性、
// ジム=体力/ストレス）に従って仮値を置く。バランス調整時はここを書き換える。
//
// `costMoney` は「行動実行に最低限必要な所持金（円）」で、グレーアウト判定や
// 予約自動実行のスキップ判定に使う。所持金の減少量は `deltas[StatKind.wallet]`
// に負数として記録する（コストと差分を別フィールドにすることで「金は払うが
// 別途バフが乗る」「コストだけかかって所持金変動なし」のような将来パターンに
// 対応できる）。
const int kCafeCostMoney = 800;
const int kCafeSensibilityDelta = 1;
const int kCafeStressDelta = -5;

const int kMovieCostMoney = 2000;
const int kMovieSensibilityDelta = 3;
const int kMovieStressDelta = -8;

const int kMuseumCostMoney = 1800;
const int kMuseumSensibilityDelta = 5;
const int kMuseumIntellectDelta = 2;

const int kGymCostMoney = 1500;
const int kGymVitalityDelta = 6;
const int kGymStressDelta = -4;

// ===========================================================================
// Sprint 06: 誘う行動の暫定マジックナンバー
// ===========================================================================
//
// 「誘う」はキャラを 1 名選んで休日に同行を提案する行動。Sprint 06 では
// 「カフェに誘う」が固定で、コストは `kCafeCostMoney` と同じ 800 円とする。
// 成功率は固定 70% で仮実装（好感度反映は Sprint 07）。
//
// 成否別の能力値変動：
// - 成功時: ストレス -2（楽しい時間を共有できた）。好感度の実値は Sprint 07。
// - 失敗時: ストレス +3（気まずさ）。
//
// 平日では選択肢に出さない。`kHolidayActionList` のみに含める。
const int kInviteCostMoney = kCafeCostMoney;
const int kInviteSuccessPercent = 70;
const int kInviteSuccessStressDelta = -2;
const int kInviteFailureStressDelta = 3;

/// Sprint 03 暫定の行動効果値。
///
/// 仕様書 §3 にある能力値の上昇傾向（読書=知性、運動=体力 等）に従って
/// 仮の値を置いている。Sprint 04 以降のバランス調整で変更される可能性あり。
/// マジックナンバーを散らさないよう、ここ 1 箇所に集約する。
class ActionEffect {
  const ActionEffect({
    required this.kind,
    required this.label,
    required this.description,
    required this.deltas,
    this.skipsRemainingSlots = false,
    this.requiredMoney = 0,
  });

  /// 対象の行動種別。
  final ActionKind kind;

  /// UI 表示用の名前（例：「読書」）。
  final String label;

  /// 効果プレビュー用の短い説明（例：「知性+3 / 体力-2」）。
  final String description;

  /// 行動実行時に [GameState] に適用される能力値の差分。
  ///
  /// キーが存在しない能力値は 0 として扱う。
  /// 体力・ストレスもここに含めて統一的に扱う。
  final Map<StatKind, int> deltas;

  /// true の場合、この行動は実行枠以降の全枠を「就寝でスキップ」扱いにして
  /// 翌日へ進める。Sprint 03 では [ActionKind.sleep] のみ。
  final bool skipsRemainingSlots;

  /// 行動実行に必要な最低所持金（円）。
  ///
  /// 0 ならコストなし。`deltas[StatKind.wallet]` の負数値とは別概念で、
  /// 「払えるか」を判定するためのチェック値。所持金がこの値未満の場合
  /// 行動シートでグレーアウトされ、予約自動実行でもスキップされる。
  final int requiredMoney;
}

/// Sprint 03 のカタログ。行動種別 → 効果定義のマッピング。
///
/// 値の出所は spec.md §3 と各 Sprint 仕様：
/// - 読書: 知性 +3 / 体力 -2
/// - 運動: 体力 +5 / ストレス -3
/// - 就寝: 体力 +10 / ストレス -5、その枠以降をスキップ
/// - 残業: 仕事評価 +3 / ストレス +5
/// - カフェ: ストレス -5 / 感性 +1 / 所持金 -800円
/// - 映画: ストレス -8 / 感性 +3 / 所持金 -2000円
/// - 美術館: 感性 +5 / 知性 +2 / 所持金 -1800円
/// - ジム: 体力 +6 / ストレス -4 / 所持金 -1500円
final Map<ActionKind, ActionEffect> kActionCatalog = <ActionKind, ActionEffect>{
  ActionKind.read: const ActionEffect(
    kind: ActionKind.read,
    label: '読書',
    description: '知性+3 / 体力-2',
    deltas: <StatKind, int>{
      StatKind.intellect: 3,
      StatKind.vitality: -2,
    },
  ),
  ActionKind.exercise: const ActionEffect(
    kind: ActionKind.exercise,
    label: '運動',
    description: '体力+5 / ストレス-3',
    deltas: <StatKind, int>{
      StatKind.vitality: 5,
      StatKind.stress: -3,
    },
  ),
  ActionKind.sleep: const ActionEffect(
    kind: ActionKind.sleep,
    label: '就寝',
    description: '体力+10 / ストレス-5（残り枠をスキップして翌日へ）',
    deltas: <StatKind, int>{
      StatKind.vitality: 10,
      StatKind.stress: -5,
    },
    skipsRemainingSlots: true,
  ),
  ActionKind.overtime: const ActionEffect(
    kind: ActionKind.overtime,
    label: '残業',
    description: '仕事評価+$kOvertimeCareerDelta / ストレス+$kOvertimeStressDelta',
    deltas: <StatKind, int>{
      StatKind.career: kOvertimeCareerDelta,
      StatKind.stress: kOvertimeStressDelta,
    },
  ),
  ActionKind.cafe: const ActionEffect(
    kind: ActionKind.cafe,
    label: 'カフェ',
    description: 'ストレス$kCafeStressDelta / 感性+$kCafeSensibilityDelta / -$kCafeCostMoney円',
    deltas: <StatKind, int>{
      StatKind.sensibility: kCafeSensibilityDelta,
      StatKind.stress: kCafeStressDelta,
      StatKind.wallet: -kCafeCostMoney,
    },
    requiredMoney: kCafeCostMoney,
  ),
  ActionKind.movie: const ActionEffect(
    kind: ActionKind.movie,
    label: '映画',
    description: 'ストレス$kMovieStressDelta / 感性+$kMovieSensibilityDelta / -$kMovieCostMoney円',
    deltas: <StatKind, int>{
      StatKind.sensibility: kMovieSensibilityDelta,
      StatKind.stress: kMovieStressDelta,
      StatKind.wallet: -kMovieCostMoney,
    },
    requiredMoney: kMovieCostMoney,
  ),
  ActionKind.museum: const ActionEffect(
    kind: ActionKind.museum,
    label: '美術館',
    description: '感性+$kMuseumSensibilityDelta / 知性+$kMuseumIntellectDelta / -$kMuseumCostMoney円',
    deltas: <StatKind, int>{
      StatKind.sensibility: kMuseumSensibilityDelta,
      StatKind.intellect: kMuseumIntellectDelta,
      StatKind.wallet: -kMuseumCostMoney,
    },
    requiredMoney: kMuseumCostMoney,
  ),
  ActionKind.gym: const ActionEffect(
    kind: ActionKind.gym,
    label: 'ジム',
    description: '体力+$kGymVitalityDelta / ストレス$kGymStressDelta / -$kGymCostMoney円',
    deltas: <StatKind, int>{
      StatKind.vitality: kGymVitalityDelta,
      StatKind.stress: kGymStressDelta,
      StatKind.wallet: -kGymCostMoney,
    },
    requiredMoney: kGymCostMoney,
  ),
  // Sprint 06: 誘う行動。実際の効果（成否判定・キャラ別の好感度反映）は
  // GameState 側ではなく、`invite_sheet.dart` のフローで動的に処理する。
  // ここでは「行動カタログに存在する」「コスト判定とグレーアウト判定が効く」
  // ためにエントリのみ作る。`deltas` は空にしておき、applyAction では使わない
  // 想定（誘い行動は `applyAction` 経由ではなく専用フローで枠を消費する）。
  ActionKind.invite: const ActionEffect(
    kind: ActionKind.invite,
    label: '誘う',
    description: '出会い済のキャラをカフェに誘う / -$kInviteCostMoney円',
    deltas: <StatKind, int>{},
    requiredMoney: kInviteCostMoney,
  ),
};

/// シート表示順を保証した自宅行動の [ActionEffect] のリスト。
///
/// Sprint 03 までは全枠でこのリストを使用していた。
/// Sprint 04 以降、平日夕方では [kWeekdayEveningActionList]（残業を含む）を
/// 使い、それ以外の枠では従来通り [kHomeActionList] を使う。
/// Sprint 05 以降、休日では [kHolidayActionList]（外出4種を追加）を使う。
List<ActionEffect> get kHomeActionList => <ActionEffect>[
      kActionCatalog[ActionKind.read]!,
      kActionCatalog[ActionKind.exercise]!,
      kActionCatalog[ActionKind.sleep]!,
    ];

/// 平日夕方で表示する行動一覧。自宅行動 3 種に「残業」が追加される。
///
/// 平日のみ表示する想定で、ホーム画面側で曜日判定して切り替える。
List<ActionEffect> get kWeekdayEveningActionList => <ActionEffect>[
      ...kHomeActionList,
      kActionCatalog[ActionKind.overtime]!,
    ];

/// 休日（土・日）で表示する行動一覧。自宅3種 + 外出4種（カフェ・映画・
/// 美術館・ジム）+ 誘う（Sprint 06）。
///
/// Sprint 05 で追加。平日では使われない（平日の朝・夜は [kHomeActionList]、
/// 平日夕方は [kWeekdayEveningActionList]、平日日中は仕事固定）。
/// Sprint 06 で [ActionKind.invite] を末尾に追加。
List<ActionEffect> get kHolidayActionList => <ActionEffect>[
      ...kHomeActionList,
      kActionCatalog[ActionKind.cafe]!,
      kActionCatalog[ActionKind.movie]!,
      kActionCatalog[ActionKind.museum]!,
      kActionCatalog[ActionKind.gym]!,
      kActionCatalog[ActionKind.invite]!,
    ];
