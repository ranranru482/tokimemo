import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/audio_keys.dart';
import 'package:tokimemo/services/audio_service.dart';

void main() {
  group('LoggingAudioService', () {
    test('playBgm で current key とログが更新される', () async {
      final svc = LoggingAudioService();
      expect(svc.currentBgmKey, isNull);
      await svc.playBgm(AudioKeys.bgmTitle);
      expect(svc.currentBgmKey, AudioKeys.bgmTitle);
      expect(svc.history.length, 1);
      expect(svc.history.first.kind, AudioCallKind.bgm);
      expect(svc.history.first.key, AudioKeys.bgmTitle);
      expect(svc.history.first.crossfade, isFalse);
    });

    test('同じ BGM key の連続呼び出しはログを増やさない', () async {
      final svc = LoggingAudioService();
      await svc.playBgm(AudioKeys.bgmTitle);
      await svc.playBgm(AudioKeys.bgmTitle);
      expect(svc.history.length, 1);
    });

    test('crossfadeBgm はクロスフェードフラグ付きでログされる', () async {
      final svc = LoggingAudioService();
      await svc.crossfadeBgm(AudioKeys.bgmHome);
      expect(svc.history.last.crossfade, isTrue);
      expect(svc.currentBgmKey, AudioKeys.bgmHome);
    });

    test('stopBgm で currentBgmKey が null に戻りログされる', () async {
      final svc = LoggingAudioService();
      await svc.playBgm(AudioKeys.bgmTitle);
      await svc.stopBgm();
      expect(svc.currentBgmKey, isNull);
      expect(svc.history.last.kind, AudioCallKind.stop);
    });

    test('playSe は BGM の current key に影響しない', () async {
      final svc = LoggingAudioService();
      await svc.playBgm(AudioKeys.bgmTitle);
      await svc.playSe(AudioKeys.seConfirm);
      expect(svc.currentBgmKey, AudioKeys.bgmTitle);
      expect(svc.history.last.kind, AudioCallKind.se);
      expect(svc.history.last.key, AudioKeys.seConfirm);
    });

    test('bgmVolume と seVolume は 0..1 にクランプされる', () {
      final svc = LoggingAudioService();
      svc.bgmVolume = 1.5;
      expect(svc.bgmVolume, 1.0);
      svc.seVolume = -0.5;
      expect(svc.seVolume, 0.0);
      // ログに音量変更が記録される（変化があった分のみ）
      final volumeCalls = svc.history
          .where((c) =>
              c.kind == AudioCallKind.bgmVolume ||
              c.kind == AudioCallKind.seVolume)
          .toList();
      expect(volumeCalls.length, 2);
    });

    test('同じ音量への再設定はログを増やさない', () {
      final svc = LoggingAudioService(bgmVolume: 0.5);
      svc.bgmVolume = 0.5;
      expect(svc.history.where((c) => c.kind == AudioCallKind.bgmVolume).length,
          0);
    });

    test('clearHistory で履歴がリセットされる', () async {
      final svc = LoggingAudioService();
      await svc.playSe(AudioKeys.seTap);
      svc.clearHistory();
      expect(svc.history, isEmpty);
    });
  });
}
