import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/stats.dart';
import 'package:tokimemo/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ホーム画面: タイムライン', () {
    testWidgets('4枠（朝・日中・夕方・夜）が縦に表示される', (tester) async {
      final settings = await createTestSettings();
      final gameState = GameState()..setHeroName('太郎');
      await tester.pumpWidget(
        wrapWithAppScope(
          child: const HomeScreen(),
          settings: settings,
          gameState: gameState,
        ),
      );

      for (final label in ['朝', '日中', '夕方', '夜']) {
        expect(
          find.byKey(ValueKey('home.timelineSlot.$label')),
          findsOneWidget,
          reason: '$label 枠のタイムラインスロットが存在するはず',
        );
        // 各枠に時間帯ラベルが表示されている
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('SafeArea でラップされ、レイアウトが Wrap/Column で構成されている',
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

      expect(find.byType(SafeArea), findsWidgets);
      // ステータスバーは Wrap で組まれており、狭幅でも崩れにくい
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('home.statusBar')),
          matching: find.byType(Wrap),
        ),
        findsOneWidget,
      );
    });
  });

  group('ホーム画面: ステータスバー', () {
    testWidgets('日付・体力・所持金・ストレス表情アイコンが表示される', (tester) async {
      final settings = await createTestSettings();
      final gameState = GameState();
      await tester.pumpWidget(
        wrapWithAppScope(
          child: const HomeScreen(),
          settings: settings,
          gameState: gameState,
        ),
      );

      expect(find.byKey(const ValueKey('home.statusBar')), findsOneWidget);
      expect(find.byKey(const ValueKey('statusBar.date')), findsOneWidget);
      expect(find.byKey(const ValueKey('statusBar.vitality')), findsOneWidget);
      expect(find.byKey(const ValueKey('statusBar.money')), findsOneWidget);
      expect(find.byKey(const ValueKey('statusBar.mood')), findsOneWidget);

      // 体力は「80/100」形式
      expect(find.text('80/100'), findsOneWidget);
      // 所持金は「50,000円」形式
      expect(find.text('50,000円'), findsOneWidget);
    });

    testWidgets('ストレス値に応じて表情アイコンが3段階で切り替わる', (tester) async {
      final settings = await createTestSettings();

      // 低ストレス → 満足
      final low = GameState(stress: 10);
      await tester.pumpWidget(
        wrapWithAppScope(
          child: const HomeScreen(),
          settings: settings,
          gameState: low,
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('statusBar.mood')),
          matching: find.byIcon(Icons.sentiment_satisfied),
        ),
        findsOneWidget,
      );

      // 中ストレス → 無表情
      final mid = GameState(stress: 50);
      await tester.pumpWidget(
        wrapWithAppScope(
          child: const HomeScreen(),
          settings: settings,
          gameState: mid,
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('statusBar.mood')),
          matching: find.byIcon(Icons.sentiment_neutral),
        ),
        findsOneWidget,
      );

      // 高ストレス → 不満
      final high = GameState(stress: 85);
      await tester.pumpWidget(
        wrapWithAppScope(
          child: const HomeScreen(),
          settings: settings,
          gameState: high,
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('statusBar.mood')),
          matching: find.byIcon(Icons.sentiment_dissatisfied),
        ),
        findsOneWidget,
      );
    });
  });

  test('StressMood.fromStress の境界値', () {
    expect(StressMood.fromStress(0), StressMood.satisfied);
    expect(StressMood.fromStress(34), StressMood.satisfied);
    expect(StressMood.fromStress(35), StressMood.neutral);
    expect(StressMood.fromStress(69), StressMood.neutral);
    expect(StressMood.fromStress(70), StressMood.dissatisfied);
    expect(StressMood.fromStress(100), StressMood.dissatisfied);
  });
}
