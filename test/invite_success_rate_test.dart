import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/invite_balance.dart';

/// Sprint 07: 誘い成功率の式（inviteSuccessPercent）と
/// ストレス連動の拒否確率の境界値テスト。
void main() {
  group('inviteSuccessPercent', () {
    test('affinity=0 で base (50%) を返す', () {
      expect(inviteSuccessPercent(0), kInviteBaseSuccessPercent);
      expect(inviteSuccessPercent(0), 50);
    });

    test('affinity=40 で 70% （0.5%/point の式）', () {
      // base 50 + 40*1/2 = 70
      expect(inviteSuccessPercent(40), 70);
    });

    test('affinity=80 で 90%', () {
      expect(inviteSuccessPercent(80), 90);
    });

    test('上限クランプ: affinity=100 で 95% にクランプされる', () {
      // base 50 + 100*1/2 = 100 だが、上限は kInviteMaxSuccessPercent=95
      expect(inviteSuccessPercent(100), kInviteMaxSuccessPercent);
      expect(inviteSuccessPercent(100), 95);
    });

    test('下限クランプ: 仮に負の affinity を渡しても 25% を下回らない', () {
      // 通常クランプ済みだが、純粋関数として下限を保証することを確認。
      expect(inviteSuccessPercent(-200), kInviteMinSuccessPercent);
    });

    test('段階境界（20 / 40 / 60 / 80）で連続的に上昇する', () {
      expect(inviteSuccessPercent(20), 60);
      expect(inviteSuccessPercent(40), 70);
      expect(inviteSuccessPercent(60), 80);
      expect(inviteSuccessPercent(80), 90);
    });
  });

  group('stressRejectionPercent', () {
    test('stress < 80 は 0%', () {
      expect(stressRejectionPercent(0), 0);
      expect(stressRejectionPercent(50), 0);
      expect(stressRejectionPercent(79), 0);
    });

    test('stress >= 80 で 30%', () {
      expect(stressRejectionPercent(80), 30);
      expect(stressRejectionPercent(85), 30);
      expect(stressRejectionPercent(89), 30);
    });

    test('stress >= 90 で 60%', () {
      expect(stressRejectionPercent(90), 60);
      expect(stressRejectionPercent(95), 60);
      expect(stressRejectionPercent(99), 60);
    });

    test('stress = 100 で 100%', () {
      expect(stressRejectionPercent(100), 100);
    });
  });
}
