import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/services/audio_service.dart';
import 'package:tokimemo/services/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'BGM 音量を 0.7 → 0.3 に変更すると audio.bgmVolume が 0.3 になる',
    (tester) async {
      final settings = await SettingsRepository.load();
      final audio = LoggingAudioService(bgmVolume: 0.7);
      await tester.pumpWidget(
        MugenSiritoriApp(settings: settings, audio: audio),
      );
      await tester.pumpAndSettle();

      // 初期 BGM 音量 0.7（settings_state のデフォルト）
      expect(settings.bgmVolume, closeTo(0.7, 1e-9));
      expect(audio.bgmVolume, closeTo(0.7, 1e-9));

      // SettingsState から直接音量を 0.3 に変更。
      await settings.updateBgmVolume(0.3);
      await tester.pump();

      expect(settings.bgmVolume, closeTo(0.3, 1e-9));
      expect(audio.bgmVolume, closeTo(0.3, 1e-9));
    },
  );

  testWidgets(
    'SE 音量も同様に AudioService に同期する',
    (tester) async {
      final settings = await SettingsRepository.load();
      final audio = LoggingAudioService(seVolume: 0.7);
      await tester.pumpWidget(
        MugenSiritoriApp(settings: settings, audio: audio),
      );
      await tester.pumpAndSettle();

      await settings.updateSeVolume(0.1);
      await tester.pump();
      expect(audio.seVolume, closeTo(0.1, 1e-9));
    },
  );
}
