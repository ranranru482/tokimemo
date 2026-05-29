/// 仕事ミニ判定と給料計算に関するロジック。
///
/// バランス調整しやすいよう、すべてのマジックナンバーをこのファイル先頭に
/// 集約する。Sprint 05 以降のチューニング時はここを書き換えるだけでよい。
library;

import 'dart:math';

import 'stats.dart';

// ===========================================================================
// 仕事ミニ判定: 成功率の式
// ===========================================================================
//
// 基準: 仕事評価 25 で成功率 60%、評価 +1 ごとに +1%。
// 下限 30% / 上限 90% でクランプする。
const int kWorkBaseCareer = 25;
const int kWorkBaseSuccessPercent = 60;
const int kWorkSuccessSlopePerPoint = 1;
const int kWorkMinSuccessPercent = 30;
const int kWorkMaxSuccessPercent = 90;

// ===========================================================================
// 仕事判定の効果
// ===========================================================================
const int kWorkSuccessCareerDelta = 5;
const int kWorkFailureStressDelta = 5;

// ===========================================================================
// 残業（夕方枠）の効果
// ===========================================================================
const int kOvertimeCareerDelta = 3;
const int kOvertimeStressDelta = 5;

// ===========================================================================
// 給料計算
// ===========================================================================
//
// 月初に「基本給 + 仕事評価 × 単価」を所持金に加算する。
// 下限 / 上限でクランプして、評価が極端でも給料の振れ幅を制限する。
const int kSalaryBase = 200000;
const int kSalaryPerCareerPoint = 2000;
const int kSalaryMin = 180000;
const int kSalaryMax = 350000;

/// 仕事判定の結果。
enum WorkOutcome {
  /// 成功（仕事評価 +5）。
  success,

  /// 失敗（ストレス +5）。
  failure,
}

/// 仕事ミニ判定の解決ロジック。
///
/// `Random` を依存注入できる形にしてテストでは固定 seed を渡す。
/// 既定の `Random()` は実プレイ時の本物のランダム源として使う。
class WorkResolver {
  const WorkResolver();

  /// 仕事評価 [careerValue] に応じた成功率（%）。
  int successPercent(int careerValue) {
    final raw = kWorkBaseSuccessPercent +
        (careerValue - kWorkBaseCareer) * kWorkSuccessSlopePerPoint;
    if (raw < kWorkMinSuccessPercent) return kWorkMinSuccessPercent;
    if (raw > kWorkMaxSuccessPercent) return kWorkMaxSuccessPercent;
    return raw;
  }

  /// 仕事ミニ判定を 1 回解決する。
  ///
  /// [rng] は依存注入。テスト時は `Random(42)` のように seed を渡す。
  WorkOutcome resolve(Random rng, int careerValue) {
    final p = successPercent(careerValue);
    final roll = rng.nextInt(100); // 0..99
    return roll < p ? WorkOutcome.success : WorkOutcome.failure;
  }

  /// この成功率に対して、与えられた seed のロールが成功か。
  /// テストや UI プレビューで「もし今ロールしたら…」を表示する用途に。
  bool wouldSucceedAtRoll(int careerValue, int roll) {
    return roll < successPercent(careerValue);
  }
}

/// 仕事判定の結果が能力値に与える差分を返す。
///
/// `GameState.applyWorkOutcome` から使われる。マジックナンバーは
/// このファイル先頭の `kWork*` 定数に集約。
Map<StatKind, int> workOutcomeDeltas(WorkOutcome outcome) {
  switch (outcome) {
    case WorkOutcome.success:
      return const <StatKind, int>{StatKind.career: kWorkSuccessCareerDelta};
    case WorkOutcome.failure:
      return const <StatKind, int>{StatKind.stress: kWorkFailureStressDelta};
  }
}

/// 仕事評価 [careerValue] から、月初に受け取る給料額（円）を計算する。
int computeSalary(int careerValue) {
  final raw = kSalaryBase + careerValue * kSalaryPerCareerPoint;
  if (raw < kSalaryMin) return kSalaryMin;
  if (raw > kSalaryMax) return kSalaryMax;
  return raw;
}
