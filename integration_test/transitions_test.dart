import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/screens/name_input_screen.dart';
import 'package:tokimemo/services/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'タイトル → 名前入力 でフェードトランジションが入る',
    (tester) async {
      final settings = await SettingsRepository.load();
      await tester.pumpWidget(MugenSiritoriApp(settings: settings));
      await tester.pumpAndSettle();

      // 「はじめから」を押すと FadeTransition が画面に出現する。
      await tester.tap(find.byKey(const ValueKey('title.startButton')));

      // トランジション途中のフレーム（一定の経過時間後）には FadeTransition が
      // 複数存在しているはず（PageRouteBuilder + 内部のもの）。
      await tester.pump(const Duration(milliseconds: 125));
      expect(find.byType(FadeTransition), findsWidgets);

      // 完了後は名前入力画面に到達。
      await tester.pumpAndSettle();
      expect(find.byType(NameInputScreen), findsOneWidget);
    },
  );
}
