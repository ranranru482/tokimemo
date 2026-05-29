import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/screens/name_input_screen.dart';
import 'package:tokimemo/screens/title_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('タイトル画面の主要メニューが表示される', (tester) async {
    final settings = await createTestSettings();
    await tester.pumpWidget(
      wrapWithAppScope(child: const TitleScreen(), settings: settings),
    );

    expect(find.text('月と珈琲'), findsOneWidget);
    expect(find.byKey(const ValueKey('title.startButton')), findsOneWidget);
    expect(find.byKey(const ValueKey('title.continueButton')), findsOneWidget);
    expect(find.byKey(const ValueKey('title.settingsButton')), findsOneWidget);
  });

  testWidgets('「はじめから」タップで名前入力画面に遷移する', (tester) async {
    final settings = await createTestSettings();
    await tester.pumpWidget(
      wrapWithAppScope(child: const TitleScreen(), settings: settings),
    );

    await tester.tap(find.byKey(const ValueKey('title.startButton')));
    await tester.pumpAndSettle();

    expect(find.byType(NameInputScreen), findsOneWidget);
    expect(find.text('主人公の名前を入力してください'), findsOneWidget);
  });

  testWidgets('「つづきから」は Sprint 01 ではグレーアウトされている', (tester) async {
    final settings = await createTestSettings();
    await tester.pumpWidget(
      wrapWithAppScope(child: const TitleScreen(), settings: settings),
    );

    final continueButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('title.continueButton')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(continueButton.onPressed, isNull);
  });
}
