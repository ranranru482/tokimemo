import 'package:flutter/material.dart';

import '../app.dart';
import '../widgets/page_transitions.dart';
import 'main_scaffold.dart';
import 'tutorial_screen.dart';

/// 主人公の名前入力画面。
///
/// 入力が空でない時のみ「決定」ボタンが有効化される。
/// 決定後はホーム画面に置き換え遷移する（戻るで名前入力には戻らない想定）。
class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }
    final scope = AppScope.of(context);
    scope.gameState.setHeroName(_controller.text);
    // Hotfix 2026-05-18 (B3): 初回のみチュートリアルを挟む。
    final tutorialShown = await TutorialScreen.hasShown();
    if (!mounted) return;
    if (tutorialShown) {
      Navigator.of(context).pushReplacement(
        fadeRoute<void>((_) => const MainScaffold()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        fadeRoute<void>(
          (_) => TutorialScreen(
            onFinished: () {
              Navigator.of(context).pushReplacement(
                fadeRoute<void>((_) => const MainScaffold()),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主人公の登録'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '主人公の名前を入力してください',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('nameInput.field'),
                controller: _controller,
                autofocus: true,
                maxLength: 12,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '例: あなたの名前',
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('nameInput.submitButton'),
                onPressed: _canSubmit ? _submit : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('決定'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
