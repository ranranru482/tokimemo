import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/invite_balance.dart';
import 'package:tokimemo/widgets/invite_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Sprint 07 受け入れ基準4:
/// ストレス80超で誘いを断るシーンを発生させると、対象キャラの好感度が大きく減る。
///
/// ここでは unit / widget レベルで「ストレス100で拒否確率100%、affinity 大幅減」を
/// 確認する。end-to-end は `integration_test/stress_rejection_test.dart` で行う。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('applyInviteRejection (unit)', () {
    test('表面 -5 / 真 -3 / ストレス +5 / 所持金 -800 / 枠 done', () {
      final gs = GameState(
        currentDate: DateTime(2026, 4, 4),
        money: 5000,
        stress: 100,
      );
      gs.recordEncounter(CharacterId.akari);
      gs.bumpAffinity(CharacterId.akari, 50);
      gs.bumpTrueAffinity(CharacterId.akari, 50);

      final ok = gs.applyInviteRejection(
        slot: SlotIndex.morning,
        target: CharacterId.akari,
      );
      expect(ok, isTrue);
      final s = gs.characterStateOf(CharacterId.akari);
      expect(s.affinity, 50 + kInviteRejectionAffinityDelta);
      expect(s.trueAffinity, 50 + kInviteRejectionTrueAffinityDelta);
      expect(gs.stress, 100); // 既に上限
      expect(gs.money, 5000 - kInviteCostMoney);
      expect(gs.slotStateOf(SlotIndex.morning), SlotState.done);
    });
  });

  group('runInviteFlow widget: ストレス連動の拒否シーン', () {
    /// 「開く」ボタンを置いて runInviteFlow を起動するテストハーネス。
    Future<void> pumpHarness(
      WidgetTester tester, {
      required GameState gameState,
      Random? rng,
    }) async {
      final settings = await createTestSettings();
      await tester.pumpWidget(
        wrapWithAppScope(
          gameState: gameState,
          settings: settings,
          child: Scaffold(
            body: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  key: const ValueKey('test.openInviteFlow'),
                  onPressed: () => runInviteFlow(
                    ctx,
                    slot: SlotIndex.morning,
                    rng: rng,
                  ),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('ストレス 100 で 100% 拒否シーンが発生し、affinity が大幅減', (tester) async {
      final gs = GameState(
        currentDate: DateTime(2026, 4, 4),
        money: 5000,
        stress: 100,
      );
      gs.recordEncounter(CharacterId.akari);
      gs.bumpAffinity(CharacterId.akari, 50);
      gs.bumpTrueAffinity(CharacterId.akari, 50);

      // 確率 100% なので rng の値に関係なく拒否ルート
      await pumpHarness(tester, gameState: gs, rng: Random(0));
      await tester.tap(find.byKey(const ValueKey('test.openInviteFlow')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('inviteSheet.candidate.akari')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('inviteSheet.confirm.ok')));
      await tester.pumpAndSettle();

      // 拒否シーンのダイアログが出ている
      expect(
        find.byKey(const ValueKey('inviteSheet.rejectionDialog')),
        findsOneWidget,
      );
      // affinity 大幅減（-5）
      expect(
        gs.characterStateOf(CharacterId.akari).affinity,
        50 + kInviteRejectionAffinityDelta,
      );
      // 真の好感度も大幅減（-3）
      expect(
        gs.characterStateOf(CharacterId.akari).trueAffinity,
        50 + kInviteRejectionTrueAffinityDelta,
      );
      expect(gs.slotStateOf(SlotIndex.morning), SlotState.done);
      expect(gs.money, 5000 - kInviteCostMoney);
    });

    testWidgets('ストレス 30 のとき拒否シーンは発生せず通常成否判定に進む',
        (tester) async {
      final gs = GameState(
        currentDate: DateTime(2026, 4, 4),
        money: 5000,
        stress: 30,
      );
      gs.recordEncounter(CharacterId.akari);

      await pumpHarness(tester, gameState: gs, rng: Random(1));
      await tester.tap(find.byKey(const ValueKey('test.openInviteFlow')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('inviteSheet.candidate.akari')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('inviteSheet.confirm.ok')));
      await tester.pumpAndSettle();

      // 拒否シーンは出ない
      expect(
        find.byKey(const ValueKey('inviteSheet.rejectionDialog')),
        findsNothing,
      );
    });
  });
}
