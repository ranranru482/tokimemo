import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/screens/settings_screen.dart';
import 'package:tokimemo/services/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tutorial.shown': true});
  });

  testWidgets(
    '音量スライダーを動かして閉じても再度開いた時に値が保持されている',
    (tester) async {
      // 初回起動: 設定値はデフォルト
      final settings1 = await SettingsRepository.load();
      await tester.pumpWidget(MugenSiritoriApp(settings: settings1));
      await tester.pumpAndSettle();

      // タイトルから設定画面へ
      await tester.tap(find.byKey(const ValueKey('title.settingsButton')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // BGM 音量スライダーを動かす
      final sliderFinder = find.byKey(const ValueKey('settings.bgmVolume'));
      await tester.drag(sliderFinder, const Offset(-200, 0));
      await tester.pumpAndSettle();

      final movedValue =
          tester.widget<Slider>(sliderFinder).value;
      expect(movedValue, lessThan(0.7),
          reason: 'スライダーが左方向にドラッグされた結果 0.7 未満になっているはず');

      // 戻るで設定画面を閉じる
      await tester.tap(find.byKey(const ValueKey('settings.backButton')));
      await tester.pumpAndSettle();

      // 「再起動」相当: アプリツリーを破棄して新しいインスタンスを構築
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final settings2 = await SettingsRepository.load();
      await tester.pumpWidget(MugenSiritoriApp(settings: settings2));
      await tester.pumpAndSettle();

      // 再度設定画面を開く
      await tester.tap(find.byKey(const ValueKey('title.settingsButton')));
      await tester.pumpAndSettle();

      final reloadedValue = tester
          .widget<Slider>(find.byKey(const ValueKey('settings.bgmVolume')))
          .value;
      expect(reloadedValue, closeTo(movedValue, 1e-9),
          reason: '再起動後も保存された音量値が復元されているはず');
    },
  );
}
