import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hotfix 2026-05-18 (B3): 初回チュートリアル（3 画面・最小実装）。
///
/// 名前入力完了直後の MainScaffold 遷移の間に挟む。
/// SharedPreferences `tutorial.shown` フラグで二回目以降は表示しない。
/// テキストのみ。イラスト無し。
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, this.onFinished});

  /// 全画面終了 or スキップ時に呼ばれる。通常はホーム画面への遷移を入れる。
  final VoidCallback? onFinished;

  static const String _prefsKey = 'tutorial.shown';

  /// 既にチュートリアルを完了したか。
  static Future<bool> hasShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefsKey) ?? false;
    } catch (e) {
      debugPrint('[TutorialScreen] hasShown failed: $e');
      return false;
    }
  }

  /// チュートリアル完了フラグを保存する。
  static Future<void> markShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, true);
    } catch (e) {
      debugPrint('[TutorialScreen] markShown failed: $e');
    }
  }

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _index = 0;

  static const List<_TutorialPage> _pages = <_TutorialPage>[
    _TutorialPage(
      title: '「枠」とは',
      body: '1 日は朝・日中・夕方・夜の 4 つの行動枠に分かれています。'
          '各枠で「読書」「運動」「外出」などの行動を 1 つ選び、'
          '能力値とストレスを管理しながら 1 年間を過ごしましょう。',
    ),
    _TutorialPage(
      title: '「誘う」とは',
      body: '出会ったキャラクターを行動枠でカフェに誘えます。'
          '成功すれば好感度が上がり、関係が深まります。'
          '誘いには所持金が必要で、ストレスが高いと断られることもあります。',
    ),
    _TutorialPage(
      title: '「stage」とは',
      body: '各キャラクターには 5 段階の関係 stage（他人 → 顔見知り → 友人 → '
          '特別な存在 → 大切な人）があります。'
          'stage が上がるごとに新しい個別イベントが解放されます。',
    ),
  ];

  Future<void> _finish() async {
    await TutorialScreen.markShown();
    if (!mounted) return;
    widget.onFinished?.call();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      setState(() => _index += 1);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = _pages[_index];
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      key: const ValueKey('tutorial.root'),
      appBar: AppBar(
        title: Text('はじめてのプレイ (${_index + 1}/${_pages.length})'),
        actions: [
          TextButton(
            key: const ValueKey('tutorial.skipButton'),
            onPressed: _finish,
            child: const Text('スキップ'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                page.title,
                key: ValueKey('tutorial.title.$_index'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    page.body,
                    key: ValueKey('tutorial.body.$_index'),
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < _pages.length; i++)
                    Container(
                      key: ValueKey('tutorial.dot.$i'),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _index
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('tutorial.nextButton'),
                onPressed: _next,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(isLast ? 'はじめる' : '次へ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialPage {
  const _TutorialPage({required this.title, required this.body});
  final String title;
  final String body;
}
