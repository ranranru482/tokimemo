import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/screens/settings_screen.dart';
import 'package:tokimemo/services/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SettingsState.bgmVolume の変更で AudioService.bgmVolume が同期する',
      (tester) async {
    final settings = await createTestSettings(bgmVolume: 0.7);
    final audio = LoggingAudioService(bgmVolume: 0.7);
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const SettingsScreen(),
        settings: settings,
        audio: audio,
      ),
    );

    expect(audio.bgmVolume, closeTo(0.7, 1e-9));
    await settings.updateBgmVolume(0.3);
    await tester.pump();
    expect(audio.bgmVolume, closeTo(0.3, 1e-9));
  });

  testWidgets('SettingsState.seVolume の変更で AudioService.seVolume が同期する',
      (tester) async {
    final settings = await createTestSettings(seVolume: 0.6);
    final audio = LoggingAudioService(seVolume: 0.6);
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const SettingsScreen(),
        settings: settings,
        audio: audio,
      ),
    );

    expect(audio.seVolume, closeTo(0.6, 1e-9));
    await settings.updateSeVolume(0.1);
    await tester.pump();
    expect(audio.seVolume, closeTo(0.1, 1e-9));
  });

  testWidgets('BGM スライダー操作で AudioService.bgmVolume が変化する', (tester) async {
    final settings = await createTestSettings(bgmVolume: 0.5);
    final audio = LoggingAudioService(bgmVolume: 0.5);
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const SettingsScreen(),
        settings: settings,
        audio: audio,
      ),
    );

    // Slider 全幅ドラッグ。drag で 0..1 の値が変わる。
    await tester.drag(
      find.byKey(const ValueKey('settings.bgmVolume')),
      const Offset(-200, 0),
    );
    await tester.pump();
    // 値は 0..1 範囲。元値より小さくなっているはず。
    expect(audio.bgmVolume, lessThan(0.5));
    expect(audio.bgmVolume, greaterThanOrEqualTo(0.0));
  });
}
