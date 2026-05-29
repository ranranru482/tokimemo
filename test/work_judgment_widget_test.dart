import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/stats.dart';
import 'package:tokimemo/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('平日日中の仕事ミニ判定（widget test）', () {
    // Hotfix 2026-05-18 (B4): 確認ダイアログを廃止。
    // 日中枠タップで即ロールし、結果ダイアログのみ表示する。
    testWidgets('日中タップ → 即ロール → 成功ダイアログ + 仕事評価+5',
        (tester) async {
      final settings = await createTestSettings();
      // 4/1 水曜（平日）+ 仕事評価 90 で成功率上限近く + seed 0
      final boosted = GameState(
        currentDate: DateTime(2026, 4, 1),
        stats: <StatKind, int>{StatKind.career: 90},
      );
      final careerBefore = boosted.allStats[StatKind.career]!;

      await tester.pumpWidget(
        wrapWithAppScope(
          child: HomeScreen(workRng: Random(0)),
          settings: settings,
          gameState: boosted,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('home.timelineSlot.日中.tap')));
      await tester.pumpAndSettle();

      // 旧 work.confirmDialog は廃止された。
      expect(find.byKey(const ValueKey('work.confirmDialog')), findsNothing);

      // 成功ダイアログが出ているはず
      expect(
        find.byKey(const ValueKey('work.resultDialog.success')),
        findsOneWidget,
      );
      // 仕事評価 +5
      expect(boosted.allStats[StatKind.career], careerBefore + 5);
      // 閉じる
      await tester.tap(find.byKey(const ValueKey('work.resultDialog.close')));
      await tester.pumpAndSettle();

      expect(boosted.slotStateOf(SlotIndex.midday), SlotState.done);
    });

    testWidgets('仕事評価 0 + 大きいロール → 失敗ダイアログ + ストレス+5', (tester) async {
      final settings = await createTestSettings();
      final gameState = GameState(
        currentDate: DateTime(2026, 4, 1),
        stats: <StatKind, int>{StatKind.career: 0},
        stress: 10,
      );
      final stressBefore = gameState.stress;

      // seed=2, career=0 の場合の決定論的ロール
      final probe = Random(2).nextInt(100);
      final expectFailure = probe >= 30;

      await tester.pumpWidget(
        wrapWithAppScope(
          child: HomeScreen(workRng: Random(2)),
          settings: settings,
          gameState: gameState,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('home.timelineSlot.日中.tap')));
      await tester.pumpAndSettle();

      if (expectFailure) {
        expect(
          find.byKey(const ValueKey('work.resultDialog.failure')),
          findsOneWidget,
          reason: 'seed=2 / career=0 では失敗側を期待（probe=$probe）',
        );
        expect(gameState.stress, stressBefore + 5);
      } else {
        expect(
          find.byKey(const ValueKey('work.resultDialog.success')),
          findsOneWidget,
        );
      }

      await tester.tap(find.byKey(const ValueKey('work.resultDialog.close')));
      await tester.pumpAndSettle();
    });
  });
}
