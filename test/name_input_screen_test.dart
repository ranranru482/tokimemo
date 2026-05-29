import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/screens/home_screen.dart';
import 'package:tokimemo/screens/main_scaffold.dart';
import 'package:tokimemo/screens/name_input_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    // Hotfix 2026-05-18 (B3): チュートリアル経由を避けるため shown=true で
    // 初期化し、既存の遷移期待値を維持する。
    SharedPreferences.setMockInitialValues({'tutorial.shown': true});
  });

  testWidgets('名前未入力時は決定ボタンが無効化されている', (tester) async {
    final settings = await createTestSettings();
    await tester.pumpWidget(
      wrapWithAppScope(child: const NameInputScreen(), settings: settings),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('nameInput.submitButton')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('名前を入力 → 決定でホーム画面に遷移し、入力名が反映される', (tester) async {
    final settings = await createTestSettings();
    final gameState = GameState();
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const NameInputScreen(),
        settings: settings,
        gameState: gameState,
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('nameInput.field')),
      'テスト太郎',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('nameInput.submitButton')));
    await tester.pumpAndSettle();

    // 名前入力後は MainScaffold（タブ付き）に遷移し、初期タブのホーム画面が見える
    expect(find.byType(MainScaffold), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('テスト太郎'), findsOneWidget);
    // 4月1日は AppBar とステータスバーの両方に出るため findsWidgets で確認
    expect(find.textContaining('4月1日'), findsWidgets);
    expect(gameState.heroName, equals('テスト太郎'));
  });
}
