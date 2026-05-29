import 'package:flutter/material.dart';

import '../app.dart';
import '../models/audio_keys.dart';

/// 設定画面。
///
/// Sprint 01: BGM 音量とテキスト速度を扱う。
/// Sprint 03: テーマモード（system/light/dark）の切替セグメントを追加。
/// Sprint 11: SE 音量スライダーを追加。BGM音量変更は即時に
/// `AppScope.audio.bgmVolume` に反映される（SettingsState の listener 経由）。
/// 戻るボタンタップに cancel SE を再生要求する。
/// 値の変更は即座に [SharedPreferences] に永続化される。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    final audio = scope.audio;
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        leading: IconButton(
          key: const ValueKey('settings.backButton'),
          icon: const Icon(Icons.arrow_back),
          tooltip: '戻る',
          onPressed: () {
            // Sprint 11: 戻るで cancel SE。
            audio.playSe(AudioKeys.seCancel);
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: settings,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                _SliderTile(
                  keyValue: 'settings.bgmVolume',
                  label: 'BGM音量',
                  value: settings.bgmVolume,
                  onChanged: settings.updateBgmVolume,
                ),
                const SizedBox(height: 16),
                _SliderTile(
                  keyValue: 'settings.seVolume',
                  label: 'SE音量',
                  value: settings.seVolume,
                  onChanged: settings.updateSeVolume,
                ),
                const SizedBox(height: 16),
                _SliderTile(
                  keyValue: 'settings.textSpeed',
                  label: 'テキスト速度',
                  value: settings.textSpeed,
                  onChanged: settings.updateTextSpeed,
                ),
                const SizedBox(height: 24),
                _ThemeModeTile(
                  value: settings.themeMode,
                  onChanged: settings.updateThemeMode,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.keyValue,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String keyValue;
  final String label;
  final double value;
  final Future<void> Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.titleMedium),
            Text(
              '${(value * 100).round()}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          key: ValueKey(keyValue),
          value: value,
          onChanged: (v) => onChanged(v),
        ),
      ],
    );
  }
}

/// テーマモード切替のセグメントタイル。
///
/// 仕様書 §10 画面11「ダーク/ライトテーマ切替」に対応。
/// system も含めた 3 択を [SegmentedButton] で提供する。
class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({required this.value, required this.onChanged});

  final ThemeMode value;
  final Future<void> Function(ThemeMode) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('テーマ', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            key: const ValueKey('settings.themeMode'),
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text('システム'),
                icon: Icon(Icons.brightness_auto),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text('ライト'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text('ダーク'),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: <ThemeMode>{value},
            onSelectionChanged: (Set<ThemeMode> set) {
              if (set.isEmpty) return;
              onChanged(set.first);
            },
          ),
        ),
      ],
    );
  }
}
