import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings_state.dart';

/// 設定値の永続化を担うリポジトリ。
///
/// 内部的に [SharedPreferences] を利用する。アプリ起動時に [load] を呼び、
/// 返ってきた [SettingsState] をアプリ全体で共有する。
class SettingsRepository {
  SettingsRepository._();

  static const String _keyBgmVolume = 'settings.bgmVolume';
  static const String _keySeVolume = 'settings.seVolume';
  static const String _keyTextSpeed = 'settings.textSpeed';
  static const String _keyThemeMode = 'settings.themeMode';

  /// 永続化された設定値を読み出して [SettingsState] を構築する。
  /// 値が存在しない場合はデフォルト値で初期化される。
  static Future<SettingsState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final bgmVolume =
        prefs.getDouble(_keyBgmVolume) ?? SettingsState.defaultBgmVolume;
    final seVolume =
        prefs.getDouble(_keySeVolume) ?? SettingsState.defaultSeVolume;
    final textSpeed =
        prefs.getDouble(_keyTextSpeed) ?? SettingsState.defaultTextSpeed;
    final themeMode = _decodeThemeMode(prefs.getString(_keyThemeMode));
    return SettingsState(
      onPersist: _persist,
      bgmVolume: bgmVolume,
      seVolume: seVolume,
      textSpeed: textSpeed,
      themeMode: themeMode,
    );
  }

  static Future<void> _persist(SettingsState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBgmVolume, state.bgmVolume);
    await prefs.setDouble(_keySeVolume, state.seVolume);
    await prefs.setDouble(_keyTextSpeed, state.textSpeed);
    await prefs.setString(_keyThemeMode, _encodeThemeMode(state.themeMode));
  }

  static String _encodeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  static ThemeMode _decodeThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return SettingsState.defaultThemeMode;
    }
  }
}
