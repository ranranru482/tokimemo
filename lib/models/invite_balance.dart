/// Sprint 07: 「誘う」行動の成功率と好感度効果を一元管理する定数群。
///
/// Sprint 06 までは `kInviteSuccessPercent = 70` の固定値だったが、
/// Sprint 07 で「表面好感度に応じて成功率が変動する」式に置き換えた。
/// マジックナンバーが UI（invite_sheet）と判定ロジック（GameState）の
/// 双方に散らばらないよう、ここに集約する。
///
/// 成功率の式（[inviteSuccessPercent] 参照）:
///   percent = clamp(
///     kInviteBaseSuccessPercent + (affinity * kInviteSuccessSlopeNumerator / kInviteSuccessSlopeDenominator).round(),
///     kInviteMinSuccessPercent,
///     kInviteMaxSuccessPercent,
///   );
///
/// 既定パラメータでは:
///   affinity=0  → 50%
///   affinity=20 → 60% （顔見知り）
///   affinity=40 → 70% （友人）
///   affinity=60 → 80% （特別な存在）
///   affinity=80 → 90% （大切な人）
///   affinity=100 → 95%（上限張り付き）
///
/// 失敗時の表面好感度は変化させず、真の好感度のみ -1。
/// 成功時は表面 +[kInviteAffinityDeltaOnSuccess]（=+2）、
/// 真の好感度 +[kInviteTrueAffinityDeltaOnSuccess]（=+1）。
/// 10 回連続成功すると表面 +20 で 2 段階目（spec §6: 20〜39 顔見知り）に到達する。
library;

/// 成功率のベース（％）。affinity = 0 のときの成功率。
const int kInviteBaseSuccessPercent = 50;

/// affinity 1 ポイントあたりの成功率上昇（％）。
/// 整数演算で扱うため分子/分母に分割。0.5% / point を表現したい場合は 1/2。
const int kInviteSuccessSlopeNumerator = 1;
const int kInviteSuccessSlopeDenominator = 2;

/// 成功率の下限・上限（％）。極端な affinity 値でも下限〜上限内に収める。
const int kInviteMinSuccessPercent = 25;
const int kInviteMaxSuccessPercent = 95;

/// 成功時の表面好感度の上昇量。
const int kInviteAffinityDeltaOnSuccess = 2;

/// 成功時の真の好感度の上昇量。
const int kInviteTrueAffinityDeltaOnSuccess = 1;

/// 失敗時の真の好感度の減少量（表面は不変）。
const int kInviteTrueAffinityDeltaOnFailure = -1;

/// ストレス連動の「拒否シーン」が発生したときの好感度の動き。
/// 表面・真ともに大きく減らす。spec §6 「ストレス80超で誘い断り → 好感度大幅減」。
const int kInviteRejectionAffinityDelta = -5;
const int kInviteRejectionTrueAffinityDelta = -3;

/// 拒否シーン発生時に主人公が追加で受けるストレス（気まずさ）。
const int kInviteRejectionStressDelta = 5;

/// ストレス連動の拒否シーン発生確率（％）。ストレス値の閾値とペア。
/// `stress >= threshold` で `percent` の確率で拒否シーンになる。
/// 配列は降順で並べる（先頭から評価し最初にヒットしたものを採用）。
const List<MapEntry<int, int>> kStressRejectionTable = <MapEntry<int, int>>[
  MapEntry(100, 100),
  MapEntry(90, 60),
  MapEntry(80, 30),
];

/// 表面好感度から成功率（％）を算出する。
///
/// 純粋関数なのでテストから直接呼べる。
int inviteSuccessPercent(int affinity) {
  final raw = kInviteBaseSuccessPercent +
      (affinity * kInviteSuccessSlopeNumerator) ~/
          kInviteSuccessSlopeDenominator;
  if (raw < kInviteMinSuccessPercent) return kInviteMinSuccessPercent;
  if (raw > kInviteMaxSuccessPercent) return kInviteMaxSuccessPercent;
  return raw;
}

/// 現在のストレス値から拒否シーンの発生確率（％）を返す。
/// 80 未満は 0%。
int stressRejectionPercent(int stress) {
  for (final entry in kStressRejectionTable) {
    if (stress >= entry.key) return entry.value;
  }
  return 0;
}

// ===========================================================================
// Sprint 07: 疎遠ペナルティ
// ===========================================================================
//
// spec §6: 「1ヶ月放置すると好感度が -3 される」。
// 出会い済キャラについて、lastInteractedDate から `kEstrangementThresholdDays`
// 日以上経過したタイミングで `affinity -3`, `trueAffinity -1` を適用する。
// 一度発火したら lastInteractedDate を再びそのタイミングまで進めて、
// 次の発火を更に 30 日後に繰り上げる。

/// 疎遠ペナルティが発火する未交流日数（日）。
const int kEstrangementThresholdDays = 30;

/// 疎遠ペナルティで適用する表面好感度の減少量。
const int kEstrangementAffinityDelta = -3;

/// 疎遠ペナルティで適用する真の好感度の減少量。
const int kEstrangementTrueAffinityDelta = -1;

// ===========================================================================
// Sprint 07: 真の好感度の選択肢効果
// ===========================================================================
//
// 誘い成功後の汎用ミニ会話で出す 2 択：
// - 「（無難な相づち）」: 表面 +1 / 真 0
// - 「（本音を話す）」 : 表面 0 / 真 +3
//
// データ駆動の ChoiceOutcome 型は lib/models/dialogue.dart に定義し、
// ここでは具体値だけを集約する。
const int kSafeChoiceAffinityDelta = 1;
const int kSafeChoiceTrueAffinityDelta = 0;

const int kHonestChoiceAffinityDelta = 0;
const int kHonestChoiceTrueAffinityDelta = 3;
