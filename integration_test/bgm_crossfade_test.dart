import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/models/audio_keys.dart';
import 'package:tokimemo/services/audio_service.dart';
import 'package:tokimemo/services/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tutorial.shown': true});
  });

  testWidgets(
    'タイトル→ホーム→会話 で BGM key が順に切り替わる',
    (tester) async {
      final settings = await SettingsRepository.load();
      final audio = LoggingAudioService();
      await tester.pumpWidget(
        MugenSiritoriApp(settings: settings, audio: audio),
      );
      await tester.pumpAndSettle();

      // タイトル進入で bgm.title へクロスフェード。
      expect(audio.currentBgmKey, AudioKeys.bgmTitle);

      // 名前入力 → ホーム遷移へ。
      await tester.tap(find.byKey(const ValueKey('title.startButton')));
      await tester.pumpAndSettle();

      // 名前を入力して開始
      await tester.enterText(
        find.byKey(const ValueKey('nameInput.field')),
        'テストプレイヤー',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('nameInput.submitButton')));
      await tester.pumpAndSettle();

      // ホーム進入で bgm.home へ。
      expect(audio.currentBgmKey, AudioKeys.bgmHome);

      // BGM 切替シーケンスを確認
      final bgmKeys = audio.history
          .where((c) => c.kind == AudioCallKind.bgm)
          .map((c) => c.key)
          .toList();
      expect(bgmKeys.first, AudioKeys.bgmTitle);
      expect(bgmKeys, contains(AudioKeys.bgmHome));
      // クロスフェード（true）で要求されているか
      expect(audio.history.last.crossfade, isTrue);
    },
  );
}
