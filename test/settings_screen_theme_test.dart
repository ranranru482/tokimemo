import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('テーマ切替セグメントが存在し、3 つの選択肢を持つ', (tester) async {
    final settings = await createTestSettings();
    await tester.pumpWidget(
      wrapWithAppScope(child: const SettingsScreen(), settings: settings),
    );

    expect(find.byKey(const ValueKey('settings.themeMode')), findsOneWidget);
    expect(find.text('テーマ'), findsOneWidget);
    expect(find.text('システム'), findsOneWidget);
    expect(find.text('ライト'), findsOneWidget);
    expect(find.text('ダーク'), findsOneWidget);
  });

  testWidgets('「ダーク」をタップすると SettingsState.themeMode が dark に変わる',
      (tester) async {
    final settings = await createTestSettings();
    await tester.pumpWidget(
      wrapWithAppScope(child: const SettingsScreen(), settings: settings),
    );

    expect(settings.themeMode, ThemeMode.system);

    await tester.tap(find.text('ダーク'));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.dark);
  });

  testWidgets('「ライト」「システム」も同様に反映される', (tester) async {
    final settings = await createTestSettings(themeMode: ThemeMode.dark);
    await tester.pumpWidget(
      wrapWithAppScope(child: const SettingsScreen(), settings: settings),
    );

    await tester.tap(find.text('ライト'));
    await tester.pumpAndSettle();
    expect(settings.themeMode, ThemeMode.light);

    await tester.tap(find.text('システム'));
    await tester.pumpAndSettle();
    expect(settings.themeMode, ThemeMode.system);
  });
}
