import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/screens/settings_screen.dart';
import 'package:tokimemo/services/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 03 受け入れ基準1:
/// 設定画面でテーマを切り替えると即座に全画面の色味が変わる。
///
/// MaterialApp の解決済み ThemeData の brightness を、テーマ切替前後で比較し、
/// 設定操作のみで dark に切り替わることを確認する。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('設定画面でテーマを「ダーク」に切り替えると MaterialApp の themeMode が dark になる',
      (tester) async {
    final settings = await SettingsRepository.load();
    await tester.pumpWidget(MugenSiritoriApp(settings: settings));
    await tester.pumpAndSettle();

    // 初期は system テーマ
    MaterialApp materialApp =
        tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.system);

    // タイトル画面 → 設定
    await tester.tap(find.byKey(const ValueKey('title.settingsButton')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    // 「ダーク」を選択
    await tester.tap(find.text('ダーク'));
    await tester.pumpAndSettle();

    // MaterialApp が rebuild され themeMode が dark になる
    materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);

    // 設定画面自身の Theme.of も dark を解決していることを確認
    final settingsContext = tester.element(find.byType(SettingsScreen));
    expect(Theme.of(settingsContext).brightness, Brightness.dark);

    // 「ライト」に戻すと light になる
    await tester.tap(find.text('ライト'));
    await tester.pumpAndSettle();
    materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.light);
    expect(Theme.of(settingsContext).brightness, Brightness.light);
  });
}
