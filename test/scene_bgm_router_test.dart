import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/audio_keys.dart';
import 'package:tokimemo/services/audio_service.dart';
import 'package:tokimemo/services/scene_bgm_router.dart';

void main() {
  group('SceneBgmRouter', () {
    test('全シーンに BGM キーが対応する', () {
      for (final scene in BgmScene.values) {
        expect(SceneBgmRouter.bgmKeyOf(scene), isNotEmpty);
      }
    });

    test('シーンごとに正しい BGM キーが割り当てられている', () {
      expect(SceneBgmRouter.bgmKeyOf(BgmScene.title), AudioKeys.bgmTitle);
      expect(SceneBgmRouter.bgmKeyOf(BgmScene.home), AudioKeys.bgmHome);
      expect(SceneBgmRouter.bgmKeyOf(BgmScene.dialogue), AudioKeys.bgmDialogue);
      expect(SceneBgmRouter.bgmKeyOf(BgmScene.event), AudioKeys.bgmEvent);
      expect(SceneBgmRouter.bgmKeyOf(BgmScene.ending), AudioKeys.bgmEnding);
      expect(SceneBgmRouter.bgmKeyOf(BgmScene.album), AudioKeys.bgmAlbum);
    });

    test('enterWithService で AudioService に crossfadeBgm が要求される', () async {
      final svc = LoggingAudioService();
      await SceneBgmRouter.enterWithService(svc, BgmScene.title);
      expect(svc.currentBgmKey, AudioKeys.bgmTitle);
      expect(svc.history.last.crossfade, isTrue);
    });

    test('順次タイトル→ホーム→会話で正しい BGM key が要求される', () async {
      final svc = LoggingAudioService();
      await SceneBgmRouter.enterWithService(svc, BgmScene.title);
      await SceneBgmRouter.enterWithService(svc, BgmScene.home);
      await SceneBgmRouter.enterWithService(svc, BgmScene.dialogue);
      final keys = svc.history
          .where((c) => c.kind == AudioCallKind.bgm)
          .map((c) => c.key)
          .toList();
      expect(keys, [AudioKeys.bgmTitle, AudioKeys.bgmHome, AudioKeys.bgmDialogue]);
    });
  });
}
