import 'package:flutter/material.dart';

import '../app.dart';
import '../models/audio_keys.dart';
import '../services/scene_bgm_router.dart';
import '../widgets/page_transitions.dart';
import 'ending_archive_screen.dart';
import 'name_input_screen.dart';
import 'save_load_screen.dart';
import 'settings_screen.dart';

/// タイトル画面。
///
/// Sprint 01: 「はじめから」「つづきから（未実装）」「設定」の3メニュー。
/// Sprint 09:
/// - 「つづきから」を有効化し、最新セーブが存在すれば即時ロード、
///   なければ Save/Load 画面（モード=load）に遷移する。
/// - 「エンディング図鑑」メニューを追加。
/// Sprint 11:
/// - 進入時に [SceneBgmRouter] 経由で `bgm.title` のクロスフェード再生を要求。
/// - 各メニューボタンタップで決定/通常タップ SE を再生要求。
class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  bool _bgmRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bgmRequested) return;
    _bgmRequested = true;
    // Sprint 11: タイトル進入時に専用 BGM をクロスフェードで起動。
    final audio = AppScope.of(context).audio;
    SceneBgmRouter.enterWithService(audio, BgmScene.title);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = AppScope.of(context);
    final repo = scope.saveRepository;
    final audio = scope.audio;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: repo ?? const _NullListenable(),
            builder: (context, _) {
              final latest = repo?.readLatest();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '月と珈琲',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tsuki to Kohi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        letterSpacing: 2,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 64),
                    _MenuButton(
                      key: const ValueKey('title.startButton'),
                      label: 'はじめから',
                      onPressed: () {
                        audio.playSe(AudioKeys.seConfirm);
                        Navigator.of(context).push(
                          fadeRoute<void>((_) => const NameInputScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      key: const ValueKey('title.continueButton'),
                      label: 'つづきから',
                      onPressed: latest == null
                          ? null
                          : () {
                              audio.playSe(AudioKeys.seConfirm);
                              SaveLoadScreen.push(
                                context,
                                mode: SaveLoadMode.load,
                              );
                            },
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      key: const ValueKey('title.archiveButton'),
                      label: 'エンディング図鑑',
                      onPressed: () {
                        audio.playSe(AudioKeys.seTap);
                        EndingArchiveScreen.push(context);
                      },
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      key: const ValueKey('title.settingsButton'),
                      label: '設定',
                      onPressed: () {
                        audio.playSe(AudioKeys.seTap);
                        Navigator.of(context).push(
                          fadeRoute<void>((_) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// テスト/UI 補助: タイトル画面に戻すヘルパ（EndingScreen の onComplete に渡す）。
void popToTitle(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
}

/// AppScope に SaveRepository が提供されていないテストケースでも
/// AnimatedBuilder が動くようにするフォールバック Listenable。
class _NullListenable extends Listenable {
  const _NullListenable();
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 48,
      child: FilledButton.tonal(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
