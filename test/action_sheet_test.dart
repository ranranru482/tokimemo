import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/screens/home_screen.dart';
import 'package:tokimemo/widgets/action_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ActionSheetContent: 表示確認', () {
    testWidgets('3 種の行動（読書・運動・就寝）と効果プレビューが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionSheetContent(
              slotLabel: '朝',
              actions: kHomeActionList,
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('actionSheet.root')), findsOneWidget);
      expect(find.text('朝の行動を選ぶ'), findsOneWidget);

      // 3 種の項目（key と表示テキスト）
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

      expect(find.text('読書'), findsOneWidget);
      expect(find.text('運動'), findsOneWidget);
      expect(find.text('就寝'), findsOneWidget);

      // 効果プレビュー
      expect(find.text('知性+3 / 体力-2'), findsOneWidget);
      expect(find.text('体力+5 / ストレス-3'), findsOneWidget);
    });
  });

  group('ホーム画面からシートを開いて選択', () {
    testWidgets('朝枠をタップするとシートが開く', (tester) async {
      final settings = await createTestSettings();
      final gameState = GameState();
      await tester.pumpWidget(
        wrapWithAppScope(
          child: const HomeScreen(),
          settings: settings,
          gameState: gameState,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('home.timelineSlot.朝.tap')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('actionSheet.root')), findsOneWidget);
      expect(find.text('朝の行動を選ぶ'), findsOneWidget);
    });

    testWidgets('「読書」を選ぶと閉じる + 知性+3 / 体力-2 + 該当枠が「実行済」表示',
        (tester) async {
      final settings = await createTestSettings();
      final gameState = GameState();
      await tester.pumpWidget(
        wrapWithAppScope(
          child: const HomeScreen(),
          settings: settings,
          gameState: gameState,
        ),
      );

      final intellectBefore = gameState.allStats.values.elementAt(0);
      final vitalityBefore = gameState.vitality;

      await tester.tap(find.byKey(const ValueKey('home.timelineSlot.朝.tap')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('actionSheet.action.read')));
      await tester.pumpAndSettle();

      // シートが閉じている
      expect(find.byKey(const ValueKey('actionSheet.root')), findsNothing);

      // 能力値変動
      expect(gameState.slotStateOf(SlotIndex.morning), SlotState.done);
      expect(gameState.vitality, vitalityBefore - 2);
      // intellect は allStats の先頭（StatKind の宣言順）→ 0番目
      expect(gameState.allStats.values.elementAt(0), intellectBefore + 3);

      // 完了表示が出ている
      expect(
        find.byKey(const ValueKey('home.timelineSlot.朝.status')),
        findsOneWidget,
      );
      expect(find.text('実行済'), findsOneWidget);
    });

    testWidgets('既に実行済の枠をタップしてもシートは開かない', (tester) async {
      final settings = await createTestSettings();
      final gameState = GameState();
      gameState.applyAction(SlotIndex.morning, ActionKind.read);

      await tester.pumpWidget(
        wrapWithAppScope(
          child: const HomeScreen(),
          settings: settings,
          gameState: gameState,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('home.timelineSlot.朝.tap')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('actionSheet.root')), findsNothing);
    });
  });
}
