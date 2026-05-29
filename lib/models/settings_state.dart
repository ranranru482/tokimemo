import 'package:flutter/material.dart';

/// アプリ全体の設定値（音量・テキスト速度・テーマモード）。
///
/// Sprint 01: BGM 音量とテキスト速度。
/// Sprint 03: テーマモード (system/light/dark) を追加。
/// Sprint 11: SE 音量を追加。BGM 音量とは独立に管理する。
/// 値の変更は [SettingsRepository] 経由で永続化される。
class SettingsState extends ChangeNotifier {
  SettingsState({
    required this.onPersist,
    double bgmVolume = defaultBgmVolume,
    double seVolume = defaultSeVolume,
    double textSpeed = defaultTextSpeed,
    ThemeMode themeMode = defaultThemeMode,
  })  : _bgmVolume = bgmVolume,
        _seVolume = seVolume,
        _textSpeed = textSpeed,
        _themeMode = themeMode;

  static const double defaultBgmVolume = 0.7;
  static const double defaultSeVolume = 0.7;
  static const double defaultTextSpeed = 0.5;
  static const ThemeMode defaultThemeMode = ThemeMode.system;

  /// 値が変わった時に呼ばれる永続化コールバック。
  final Future<void> Function(SettingsState state) onPersist;

  double _bgmVolume;
  double _seVolume;
  double _textSpeed;
  ThemeMode _themeMode;

  double get bgmVolume => _bgmVolume;
  double get seVolume => _seVolume;
  double get textSpeed => _textSpeed;
  ThemeMode get themeMode => _themeMode;

  Future<void> updateBgmVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    if (clamped == _bgmVolume) {
      return;
    }
    _bgmVolume = clamped;
    notifyListeners();
    await onPersist(this);
  }

  Future<void> updateSeVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    if (clamped == _seVolume) {
      return;
    }
    _seVolume = clamped;
    notifyListeners();
    await onPersist(this);
  }

  Future<void> updateTextSpeed(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    if (clamped == _textSpeed) {
      return;
    }
    _textSpeed = clamped;
    notifyListeners();
    await onPersist(this);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    await onPersist(this);
  }
}
