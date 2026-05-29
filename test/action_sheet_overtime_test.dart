import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/stats.dart';
import 'package:tokimemo/screens/home_screen.dart';
import 'package:tokimemo/widgets/action_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ActionSheetContent: 行動リスト切替', () {
    testWidgets('kWeekdayEveningActionList には残業 4 行動が含まれる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionSheetContent(
              slotLabel: '夕方',
              actions: kWeekdayEveningActionList,
            ),
          ),
        ),
      );

      // 自宅3行動 + 残業 = 4
      expect(
        find.byKey(const ValueKey('actionSheet.action.read')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('actionSheet.action.exercise')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('actionSheet.action.sleep')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('actionSheet.action.overtime')),
        findsOneWidget,
      );
      expect(find.text('残業'), findsOneWidget);
    });

    testWidgets('kHomeActionList（休日用）には残業が含まれない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionSheetContent(
              slotLabel: '夕方',
              actions: kHomeActionList,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('actionSheet.action.overtime')),
        findsNothing,
      );
      expect(find.text('残業'), findsNothing);
    });
  });

  group('HomeScreen: 平日夕方タップで残業を含むシートが開く', () {
    testWidgets('平日（4/1 水）夕方タップ → 残業が出る', (tester) async {
      final settings = await createTestSettings();
      // 4/1 は水曜（平日）
      final gameState = GameState(currentDate: DateTime(2026, 4, 1));
      await tester.pumpWidget(
        wrapWithAppScope(
          child: HomeScreen(workRng: Random(0)),
          settings: settings,
          gameState: gameState,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('home.timelineSlot.夕方.tap')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('actionSheet.action.overtime')),
        findsOneWidget,
      );
    });

    testWidgets('休日（4/4 土）夕方タップ → 残業は出ない', (tester) async {
      final settings = await createTestSettings();
      // 4/4 は土曜（休日）
      final gameState = GameState(currentDate: DateTime(2026, 4, 4));
      await tester.pumpWidget(
        wrapWithAppScope(
          child: HomeScreen(workRng: Random(0)),
          settings: settings,
          gameState: gameState,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('home.timelineSlot.夕方.tap')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('actionSheet.action.overtime')),
        findsNothing,
      );
    });

    testWidgets('平日夕方で残業を選ぶと仕事評価+3 / ストレス+5 / 枠 done', (tester) async {
      final settings = await createTestSettings();
      final gameState = GameState(
        currentDate: DateTime(2026, 4, 1),
        stress: 20,
      );
      final careerBefore = gameState.allStats[StatKind.career]!;
      final stressBefore = gameState.stress;

      await tester.pumpWidget(
        wrapWithAppScope(
          child: HomeScreen(workRng: Random(0)),
          settings: settings,
          gameState: gameState,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('home.timelineSlot.夕方.tap')));
      await tester.pumpAndSettle();
      // 残業はリスト末尾。シート内の SingleChildScrollView をドラッグして可視化。
      final overtimeFinder =
          find.byKey(const ValueKey('actionSheet.action.overtime'));
      await tester.drag(
        find.descendant(
          of: find.byKey(const ValueKey('actionSheet.root')),
          matching: find.byType(SingleChildScrollView),
        ),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(overtimeFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(gameState.allStats[StatKind.career], careerBefore + 3);
      expect(gameState.stress, stressBefore + 5);
      expect(gameState.slotStateOf(SlotIndex.evening), SlotState.done);
    });
  });

  group('HomeScreen: 平日日中スロットの表示', () {
    testWidgets('平日（4/1 水）日中枠は「仕事」固定表示', (tester) async {
      final settings = await createTestSettings();
      final gameState = GameState(currentDate: DateTime(2026, 4, 1));
      await tester.pumpWidget(
        wrapWithAppScope(
          child: HomeScreen(workRng: Random(0)),
          settings: settings,
          gameState: gameState,
        ),
      );

      // 日中枠のステータステキストは「仕事」
      final statusFinder =
          find.byKey(const ValueKey('home.timelineSlot.日中.status'));
      expect(statusFinder, findsOneWidget);
      final statusWidget = tester.widget<Text>(statusFinder);
      expect(statusWidget.data, '仕事');
    });

    testWidgets('休日（4/4 土）日中枠は「未実行」表示（仕事固定にならない）', (tester) async {
      final settings = await createTestSettings();
      final gameState = GameState(currentDate: DateTime(2026, 4, 4));
      await tester.pumpWidget(
        wrapWithAppScope(
          child: HomeScreen(workRng: Random(0)),
          settings: settings,
          gameState: gameState,
        ),
      );
      final statusFinder =
          find.byKey(const ValueKey('home.timelineSlot.日中.status'));
      final statusWidget = tester.widget<Text>(statusFinder);
      expect(statusWidget.data, '未実行');
    });
  });
}
