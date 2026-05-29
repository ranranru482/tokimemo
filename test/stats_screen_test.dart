import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/stats.dart';
import 'package:tokimemo/screens/stats_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('能力値画面に 7 パラメータすべての行が表示される', (tester) async {
    final settings = await createTestSettings();
    final gameState = GameState();
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const StatsScreen(),
        settings: settings,
        gameState: gameState,
      ),
    );

    expect(StatKind.values.length, 7);
    final listView = find.byType(ListView);
    for (final kind in StatKind.values) {
      // ListView は遅延ビルドなので、必要なら該当行までスクロールしてから検証する
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('stats.row.${kind.name}')),
        100,
        scrollable: find.descendant(
          of: listView,
          matching: find.byType(Scrollable),
        ),
      );

      expect(
        find.byKey(ValueKey('stats.row.${kind.name}')),
        findsOneWidget,
        reason: '${kind.label} の行が存在するはず',
      );
      expect(
        find.byKey(ValueKey('stats.bar.${kind.name}')),
        findsOneWidget,
        reason: '${kind.label} のバーが存在するはず',
      );
      expect(
        find.byKey(ValueKey('stats.value.${kind.name}')),
        findsOneWidget,
        reason: '${kind.label} の数値が存在するはず',
      );
      // ラベルが画面に出ている
      expect(find.text(kind.label), findsWidgets);
    }
  });

  testWidgets('各バーの value が現在値に対応した正規化値（0〜1）になっている',
      (tester) async {
    final settings = await createTestSettings();
    final gameState = GameState(); // vitality 80/100, money 50000, stress 20
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const StatsScreen(),
        settings: settings,
        gameState: gameState,
      ),
    );

    Future<LinearProgressIndicator> barAt(String name) async {
      final finder = find.byKey(ValueKey('stats.bar.$name'));
      await tester.scrollUntilVisible(
        finder,
        100,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      return tester.widget<LinearProgressIndicator>(finder);
    }

    expect((await barAt('vitality')).value, closeTo(0.8, 1e-9));
    expect((await barAt('stress')).value, closeTo(0.2, 1e-9));
    // 所持金は 200,000 円キャップで正規化（50,000 / 200,000 = 0.25）
    expect((await barAt('wallet')).value, closeTo(0.25, 1e-9));
  });

  testWidgets('所持金は「円」付きでカンマ区切り、その他は「現在値 / 100」表示', (tester) async {
    final settings = await createTestSettings();
    final gameState = GameState();
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const StatsScreen(),
        settings: settings,
        gameState: gameState,
      ),
    );

    Future<Text> textAt(String name) async {
      final finder = find.byKey(ValueKey('stats.value.$name'));
      await tester.scrollUntilVisible(
        finder,
        100,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      return tester.widget<Text>(finder);
    }

    expect((await textAt('wallet')).data, '50,000円');
    expect((await textAt('vitality')).data, '80 / 100');
    expect((await textAt('stress')).data, '20 / 100');
    expect((await textAt('intellect')).data, '25 / 100');
  });
}
