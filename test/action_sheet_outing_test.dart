import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/screens/home_screen.dart';
import 'package:tokimemo/widgets/action_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Sprint 05 受け入れ基準3 + 補強:
/// - 休日に外出4種が出る、平日には出ない
/// - 所持金不足で映画が disabled になる
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ActionSheetContent: 休日リストには外出4種が出る', () {
    testWidgets('kHolidayActionList で 7 行動が全部表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionSheetContent(
              slotLabel: '朝',
              actions: kHolidayActionList,
              currentMoney: 50000,
            ),
          ),
        ),
      );

      // 自宅3 + 外出4 = 7
      expect(find.byKey(const ValueKey('actionSheet.action.read')), findsOneWidget);
      expect(find.byKey(const ValueKey('actionSheet.action.exercise')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('actionSheet.action.sleep')), findsOneWidget);
      expect(find.byKey(const ValueKey('actionSheet.action.cafe')), findsOneWidget);
      expect(find.byKey(const ValueKey('actionSheet.action.movie')), findsOneWidget);
      expect(find.byKey(const ValueKey('actionSheet.action.museum')), findsOneWidget);
      expect(find.byKey(const ValueKey('actionSheet.action.gym')), findsOneWidget);
    });

    testWidgets('kHomeActionList（平日朝/夜）には外出4種が含まれない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionSheetContent(
              slotLabel: '朝',
              actions: kHomeActionList,
              currentMoney: 50000,
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('actionSheet.action.cafe')), findsNothing);
      expect(find.byKey(const ValueKey('actionSheet.action.movie')), findsNothing);
      expect(find.byKey(const ValueKey('actionSheet.action.museum')), findsNothing);
      expect(find.byKey(const ValueKey('actionSheet.action.gym')), findsNothing);
    });
  });

  group('所持金不足のグレーアウト', () {
    testWidgets('所持金 500 円で休日シートを開くと映画が disabled になる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionSheetContent(
              slotLabel: '朝',
              actions: kHolidayActionList,
              currentMoney: 500,
            ),
          ),
        ),
      );

      // 映画 (cost 2000) は disabled
      final movieTile = tester.widget<ListTile>(
        find.byKey(const ValueKey('actionSheet.action.movie')),
      );
      expect(movieTile.enabled, isFalse);
      expect(movieTile.onTap, isNull);

      // 美術館 (cost 1800) も disabled
      final museumTile = tester.widget<ListTile>(
        find.byKey(const ValueKey('actionSheet.action.museum')),
      );
      expect(museumTile.enabled, isFalse);

      // ジム (cost 1500) も disabled
      final gymTile = tester.widget<ListTile>(
        find.byKey(const ValueKey('actionSheet.action.gym')),
      );
      expect(gymTile.enabled, isFalse);

      // カフェ (cost 800) は disabled (500 < 800)
      final cafeTile = tester.widget<ListTile>(
        find.byKey(const ValueKey('actionSheet.action.cafe')),
      );
      expect(cafeTile.enabled, isFalse);

      // 読書はコスト 0 なので有効
      final readTile = tester.widget<ListTile>(
        find.byKey(const ValueKey('actionSheet.action.read')),
      );
      expect(readTile.enabled, isTrue);
    });

    testWidgets('所持金 1000 円ならカフェのみ有効、映画は disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionSheetContent(
              slotLabel: '朝',
              actions: kHolidayActionList,
              currentMoney: 1000,
            ),
          ),
        ),
      );

      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('actionSheet.action.cafe')))
            .enabled,
        isTrue,
      );
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('actionSheet.action.movie')))
            .enabled,
        isFalse,
      );
    });

    testWidgets('disabled な映画タイルをタップしてもシートは閉じない', (tester) async {
      ActionKind? selected;
      late BuildContext sheetContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (ctx) {
              sheetContext = ctx;
              return ElevatedButton(
                onPressed: () async {
                  selected = await showActionSheet(
                    sheetContext,
                    slotLabel: '朝',
                    actions: kHolidayActionList,
                    currentMoney: 500,
                  );
                },
                child: const Text('open'),
              );
            }),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      // シートが開いている
      expect(find.byKey(const ValueKey('actionSheet.root')), findsOneWidget);

      // 映画をタップしても何も起きない（disabled）。warnIfMissed=false で
      // ヒット判定の警告を抑制（disabled なので onTap が null）。
      await tester.tap(
        find.byKey(const ValueKey('actionSheet.action.movie')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('actionSheet.root')), findsOneWidget);
      expect(selected, isNull);
    });
  });

  group('HomeScreen 連動: 休日の朝枠で外出が出る', () {
    testWidgets('4/4 土 朝タップ → 休日リストが出る（カフェが見える）', (tester) async {
      final settings = await createTestSettings();
      // 4/4 は土曜
      final gameState = GameState(currentDate: DateTime(2026, 4, 4));
      await tester.pumpWidget(
        wrapWithAppScope(
          child: HomeScreen(workRng: Random(0)),
          settings: settings,
          gameState: gameState,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('home.timelineSlot.朝.tap')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('actionSheet.action.cafe')), findsOneWidget);
      expect(find.byKey(const ValueKey('actionSheet.action.movie')), findsOneWidget);
    });

    testWidgets('4/1 水 朝タップ → 平日リスト（外出は出ない）', (tester) async {
      final settings = await createTestSettings();
      final gameState = GameState(currentDate: DateTime(2026, 4, 1));
      await tester.pumpWidget(
        wrapWithAppScope(
          child: HomeScreen(workRng: Random(0)),
          settings: settings,
          gameState: gameState,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('home.timelineSlot.朝.tap')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('actionSheet.action.cafe')), findsNothing);
      expect(find.byKey(const ValueKey('actionSheet.action.movie')), findsNothing);
    });

    testWidgets('4/4 土 朝（所持金 500 円）→ 映画は disabled になる', (tester) async {
      final settings = await createTestSettings();
      final gameState = GameState(
        currentDate: DateTime(2026, 4, 4),
        money: 500,
      );
      await tester.pumpWidget(
        wrapWithAppScope(
          child: HomeScreen(workRng: Random(0)),
          settings: settings,
          gameState: gameState,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('home.timelineSlot.朝.tap')));
      await tester.pumpAndSettle();

      final movieTile = tester.widget<ListTile>(
        find.byKey(const ValueKey('actionSheet.action.movie')),
      );
      expect(movieTile.enabled, isFalse);
    });
  });
}
