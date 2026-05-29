import 'package:flutter/material.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/models/cg_state.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/settings_state.dart';
import 'package:tokimemo/services/audio_service.dart';
import 'package:tokimemo/services/ending_archive.dart';
import 'package:tokimemo/services/save_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hotfix 2026-05-18: アルバム widget test 用の CG 解放ヘルパ。
/// 旧 `lib/screens/album_screen.dart` のトップレベル関数を移植したもの。
/// 本番 import グラフから切り離すために test/ 配下へ移動した。
void debugUnlockForAlbumTest(CgLibrary library, String key) {
  library.unlock(key);
}

/// テストで AppScope に注入する SettingsState を生成する。
///
/// SharedPreferences への保存は [SharedPreferences.setMockInitialValues] で
/// 事前にモック化されている前提。
/// Sprint 11: seVolume を扱えるよう引数を追加（デフォルト値で後方互換）。
Future<SettingsState> createTestSettings({
  double bgmVolume = SettingsState.defaultBgmVolume,
  double seVolume = SettingsState.defaultSeVolume,
  double textSpeed = SettingsState.defaultTextSpeed,
  ThemeMode themeMode = SettingsState.defaultThemeMode,
}) async {
  return SettingsState(
    bgmVolume: bgmVolume,
    seVolume: seVolume,
    textSpeed: textSpeed,
    themeMode: themeMode,
    onPersist: (state) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('settings.bgmVolume', state.bgmVolume);
      await prefs.setDouble('settings.seVolume', state.seVolume);
      await prefs.setDouble('settings.textSpeed', state.textSpeed);
      await prefs.setString('settings.themeMode', state.themeMode.name);
    },
  );
}

/// Sprint 09: テスト用に SaveRepository を取得する小ヘルパ。
///
/// `SharedPreferences.setMockInitialValues({})` を事前に呼んだ上で利用する。
Future<SaveRepository> createTestSaveRepository() async {
  return SaveRepository.load();
}

/// Sprint 09: テスト用に EndingArchive を取得する小ヘルパ。
Future<EndingArchive> createTestEndingArchive() async {
  return EndingArchive.load();
}

/// テスト用に AppScope と MaterialApp で初期画面をラップする。
///
/// Sprint 03 でテーマ切替テストが必要になったため、[settings] の
/// `themeMode` を MaterialApp に反映できるようにしている。
/// Sprint 09 で SaveRepository / EndingArchive も AppScope に追加（optional）。
/// Sprint 11 で [AudioService] も注入可能に。null なら新規 LoggingAudioService。
/// audio の音量同期は SettingsState のリスナを通じてここでも実施する。
Widget wrapWithAppScope({
  required Widget child,
  required SettingsState settings,
  GameState? gameState,
  SaveRepository? saveRepository,
  EndingArchive? endingArchive,
  AudioService? audio,
}) {
  final resolvedAudio = audio ?? LoggingAudioService(
    bgmVolume: settings.bgmVolume,
    seVolume: settings.seVolume,
  );
  // Sprint 11: settings.bgmVolume / seVolume → audio.bgmVolume / seVolume 同期。
  settings.addListener(() {
    resolvedAudio.bgmVolume = settings.bgmVolume;
    resolvedAudio.seVolume = settings.seVolume;
  });
  return AppScope(
    gameState: gameState ?? GameState(),
    settings: settings,
    saveRepository: saveRepository,
    endingArchive: endingArchive,
    audio: resolvedAudio,
    child: AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4A2C2A),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4A2C2A),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: settings.themeMode,
          home: child,
        );
      },
    ),
  );
}
