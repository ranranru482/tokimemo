import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/work.dart';

void main() {
  const r = WorkResolver();

  group('successPercent: 評価による確率変化', () {
    test('評価 25 で 60%', () {
      expect(r.successPercent(25), 60);
    });

    test('評価が +1 ごとに +1%', () {
      expect(r.successPercent(26), 61);
      expect(r.successPercent(30), 65);
    });

    test('下限 30% を下回らない', () {
      // 評価 0 の raw は 35（下限ぎりぎり上）。極端な負値で下限が効くことを検証。
      expect(r.successPercent(-100), kWorkMinSuccessPercent);
      expect(r.successPercent(-50), kWorkMinSuccessPercent);
      // 評価 0 は下限以上の素値（35）でクランプされない
      expect(r.successPercent(0), greaterThanOrEqualTo(kWorkMinSuccessPercent));
    });

    test('上限 90% を超えない', () {
      expect(r.successPercent(100), kWorkMaxSuccessPercent);
      expect(r.successPercent(80), kWorkMaxSuccessPercent);
    });
  });

  group('resolve: 決定論的検証（seed 固定）', () {
    test('seed 1 で評価 25 → success / failure が再現する', () {
      // 同じ seed・同じ評価値なら同じ結果になる
      final a = r.resolve(Random(1), 25);
      final b = r.resolve(Random(1), 25);
      expect(a, b);
    });

    test('1000 回ロールでおおむね理論成功率に近づく（評価 25 / 60%）', () {
      final rng = Random(42);
      int success = 0;
      const trials = 1000;
      for (int i = 0; i < trials; i++) {
        if (r.resolve(rng, 25) == WorkOutcome.success) success++;
      }
      // 60% ± 6%（誤差許容）
      final ratio = success / trials;
      expect(ratio, greaterThan(0.54));
      expect(ratio, lessThan(0.66));
    });

    test('評価 0 でも下限 30% を満たす（seed 固定で複数ロールに少なくとも 1 成功）', () {
      final rng = Random(7);
      int success = 0;
      for (int i = 0; i < 100; i++) {
        if (r.resolve(rng, 0) == WorkOutcome.success) success++;
      }
      // 100 回中に 1 回以上は成功するはず（30% で 100 回ならほぼ確実に成功多数）
      expect(success, greaterThan(10));
    });
  });

  group('wouldSucceedAtRoll の境界', () {
    test('評価 25 / 成功率 60 → roll 59 で成功、60 で失敗', () {
      expect(r.wouldSucceedAtRoll(25, 59), isTrue);
      expect(r.wouldSucceedAtRoll(25, 60), isFalse);
    });
  });

  group('workOutcomeDeltas', () {
    test('成功なら career +5、失敗なら stress +5', () {
      final s = workOutcomeDeltas(WorkOutcome.success);
      expect(s.length, 1);
      expect(s.values.first, kWorkSuccessCareerDelta);

      final f = workOutcomeDeltas(WorkOutcome.failure);
      expect(f.length, 1);
      expect(f.values.first, kWorkFailureStressDelta);
    });
  });

  group('computeSalary: 給料計算', () {
    test('評価 20 → 基本給 + 20×2000 = 240,000 円', () {
      expect(computeSalary(20), kSalaryBase + 20 * kSalaryPerCareerPoint);
    });

    test('下限 180,000 を下回らない', () {
      expect(computeSalary(0), greaterThanOrEqualTo(kSalaryMin));
      // 基本給 200,000 のため、評価 0 でも 200,000 だが、
      // 一応定数チェックも兼ねる
      expect(kSalaryMin, lessThanOrEqualTo(kSalaryBase));
    });

    test('上限 350,000 を超えない', () {
      expect(computeSalary(100), kSalaryMax);
      expect(computeSalary(1000), kSalaryMax);
    });
  });
}
