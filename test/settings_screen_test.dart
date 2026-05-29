import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/screens/settings_screen.dart';
import 'package:tokimemo/screens/title_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('タイトル → 設定 → 戻る でタイトルに戻る', (tester) async {
    final settings = await createTestSettings();
    await tester.pumpWidget(
      wrapWithAppScope(child: const TitleScreen(), settings: settings),
    );

    await tester.tap(find.byKey(const ValueKey('title.settingsButton')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('BGM音量'), findsOneWidget);
    expect(find.text('テキスト速度'), findsOneWidget);

    // AppBar の戻るボタン（Sprint 11 で tooltip を '戻る' に変更し、SE を再生する）
    await tester.tap(find.byKey(const ValueKey('settings.backButton')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.byType(TitleScreen), findsOneWidget);
  });

  testWidgets('スライダー3種が初期値で描画される', (tester) async {
    final settings = await createTestSettings(
      bgmVolume: 0.3,
      seVolume: 0.55,
      textSpeed: 0.8,
    );
    await tester.pumpWidget(
      wrapWithAppScope(child: const SettingsScreen(), settings: settings),
    );

    // Sprint 11: BGM / SE / テキスト速度の3本になった。
    final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    expect(sliders.length, 3);
    final bgm = tester.widget<Slider>(find.byKey(const ValueKey('settings.bgmVolume')));
    final se = tester.widget<Slider>(find.byKey(const ValueKey('settings.seVolume')));
    final text = tester.widget<Slider>(find.byKey(const ValueKey('settings.textSpeed')));
    expect(bgm.value, closeTo(0.3, 1e-9));
    expect(se.value, closeTo(0.55, 1e-9));
    expect(text.value, closeTo(0.8, 1e-9));
  });
}
