import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../data/character_repository.dart';
import '../models/audio_keys.dart';
import '../models/event.dart';
import '../services/audio_service.dart';
import '../services/scene_bgm_router.dart';
import 'character_portrait.dart';
import 'page_transitions.dart';
import 'typewriter_text.dart';

/// Sprint 08: イベントスクリプトを順番に再生するモーダル。
///
/// 仕様書 §10 画面08「会話」の最小実装。
/// `DialogueModal` を再利用しなかった理由:
/// - DialogueModal は `EncounterEvent.lines`（`[Expression, String]` の 2 値）を
///   前提にしている。
/// - EventPlayer は「話者キャラあり / なし（地の文）」「末尾の選択肢シーン」
///   「完了後コールバックで選択結果を返す」を扱う必要があり、責務が異なる。
/// - 共存させて差替えポイントを単純に保つ。
///
/// 戻り値（[show] の Future）:
/// - 選択肢があるイベント: 選ばれた [EventChoice] を返す。途中キャンセル時は null。
/// - 選択肢がないイベント: 完了時に [EventChoice]（合成された空のもの）または null。
class EventPlayer extends StatefulWidget {
  const EventPlayer({super.key, required this.event});

  final GameEvent event;

  static Future<EventChoice?> show(
    BuildContext context, {
    required GameEvent event,
  }) {
    return Navigator.of(context).push<EventChoice>(
      slideUpRoute<EventChoice>((_) => EventPlayer(event: event)),
    );
  }

  @override
  State<EventPlayer> createState() => _EventPlayerState();
}

class _EventPlayerState extends State<EventPlayer> {
  int _lineIndex = 0;
  bool _showingChoice = false;
  bool _lineCompleted = false;
  bool _bgmRequested = false;
  String? _previousBgm;

  /// Hotfix 2026-05-18 (B2): オート再生のオン/オフ。
  bool _autoPlay = false;
  Timer? _autoTimer;
  static const Duration _autoInterval = Duration(milliseconds: 1500);

  /// Sprint 12: dispose 時に AppScope.of(context) を呼ぶのは危険なので
  /// didChangeDependencies のタイミングで AudioService の参照を確保。
  AudioService? _audio;

  EventLine get _currentLine => widget.event.script[_lineIndex];

  bool get _isLastLine => _lineIndex >= widget.event.script.length - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sprint 12: AppScope の AudioService 参照をキャッシュ。
    try {
      _audio = AppScope.of(context).audio;
    } catch (e) {
      debugPrint('[EventPlayer] AudioService unavailable: $e');
      _audio = null;
    }
    if (_bgmRequested) return;
    _bgmRequested = true;
    // Sprint 11: イベントシーン進入で bgm.event にクロスフェード。
    final audio = _audio;
    if (audio != null) {
      _previousBgm = audio.currentBgmKey;
      SceneBgmRouter.enterWithService(audio, BgmScene.event);
      _maybePlayVoice(_currentLine.voiceKey);
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    // Sprint 11→12: イベント終了時に直前 BGM に戻す（ホーム等）。
    // dispose では InheritedWidget を引かず、キャッシュ参照を使う。
    final prev = _previousBgm;
    final audio = _audio;
    if (prev != null && audio != null) {
      audio.crossfadeBgm(prev);
    }
    super.dispose();
  }

  /// Hotfix 2026-05-18 (B1): 「>>」全文スキップ。残りのスクリプトを飛ばし、
  /// 選択肢があれば選択肢へ、なければイベント終了。
  void _skipToEnd() {
    _autoTimer?.cancel();
    if (widget.event.choice != null) {
      setState(() {
        _lineIndex = widget.event.script.length - 1;
        _lineCompleted = true;
        _showingChoice = true;
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }

  /// Hotfix 2026-05-18 (B2): オート再生トグル。選択肢表示中は無効化される。
  void _toggleAutoPlay() {
    setState(() => _autoPlay = !_autoPlay);
    if (_autoPlay && _lineCompleted && !_showingChoice) {
      _scheduleAutoAdvance();
    } else {
      _autoTimer?.cancel();
    }
  }

  void _scheduleAutoAdvance() {
    _autoTimer?.cancel();
    if (!_autoPlay) return;
    if (_showingChoice) return;
    _autoTimer = Timer(_autoInterval, () {
      if (!mounted || !_autoPlay) return;
      if (_isLastLine) {
        // 選択肢があれば自動で選ばず、選択肢画面に切り替えてオート停止。
        if (widget.event.choice != null) {
          setState(() {
            _showingChoice = true;
            _autoPlay = false;
          });
        } else {
          Navigator.of(context).maybePop();
        }
        return;
      }
      setState(() {
        _lineIndex += 1;
        _lineCompleted = false;
      });
      _maybePlayVoice(_currentLine.voiceKey);
    });
  }

  void _maybePlayVoice(String? voiceKey) {
    if (voiceKey == null) return;
    _audio?.playSe(voiceKey);
  }

  void _onNext() {
    // Sprint 10: タイプライター進行中なら全文表示にだけ進む。
    if (!_lineCompleted) {
      setState(() => _lineCompleted = true);
      return;
    }
    // Sprint 11: 次へ / 選択肢へ進む操作で confirm SE。
    _audio?.playSe(AudioKeys.seConfirm);
    if (_isLastLine) {
      // スクリプト終端：選択肢があれば選択肢へ。なければ null を返して閉じる。
      if (widget.event.choice != null) {
        setState(() => _showingChoice = true);
      } else {
        Navigator.of(context).maybePop();
      }
      return;
    }
    setState(() {
      _lineIndex += 1;
      _lineCompleted = false;
    });
    _maybePlayVoice(_currentLine.voiceKey);
  }

  void _onPickChoice(EventChoice ch) {
    // Sprint 11: 選択肢決定で confirm SE。
    _audio?.playSe(AudioKeys.seConfirm);
    Navigator.of(context).pop(ch);
  }

  /// 「閉じる」ボタン: 途中で閉じる（null を返す）。Sprint 11 仕様。
  void _skipToClose() {
    // Sprint 11: 閉じる（途中スキップ）で cancel SE。
    _audio?.playSe(AudioKeys.seCancel);
    // 「途中で閉じる」: 選択肢があってもなくても null を返す（呼び出し側で
    // 「閉じた=好感度等を反映しない」と解釈できる）。
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = widget.event;

    Widget body;
    if (_showingChoice && event.choice != null) {
      body = _ChoicePanel(
        scene: event.choice!,
        onPicked: _onPickChoice,
      );
    } else {
      body = _ScriptPanel(
        line: _currentLine,
        lineIndex: _lineIndex,
        isLast: _isLastLine,
        onNext: _onNext,
        textSpeed: _resolveTextSpeed(context),
        onLineCompleted: () {
          if (!mounted) return;
          if (!_lineCompleted) {
            setState(() => _lineCompleted = true);
          }
          // Hotfix 2026-05-18 (B2): オート ON なら次行を 1.5 秒後に進める。
          if (_autoPlay) _scheduleAutoAdvance();
        },
      );
    }

    return Scaffold(
      key: ValueKey('eventPlayer.${event.id}.root'),
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          key: ValueKey('eventPlayer.${event.id}.title'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          event.locationLabel,
                          key: ValueKey('eventPlayer.${event.id}.location'),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Hotfix 2026-05-18 (B2): オート再生トグル。
                  IconButton(
                    key: ValueKey('eventPlayer.${event.id}.autoPlay'),
                    icon: Icon(_autoPlay ? Icons.pause : Icons.play_arrow),
                    tooltip: _autoPlay ? 'オート停止' : 'オート再生',
                    onPressed: _toggleAutoPlay,
                  ),
                  // Hotfix 2026-05-18 (B1): 全文スキップ（イベント末ジャンプ）。
                  IconButton(
                    key: ValueKey('eventPlayer.${event.id}.skipAll'),
                    icon: const Icon(Icons.fast_forward),
                    tooltip: '全文スキップ',
                    onPressed: _skipToEnd,
                  ),
                  IconButton(
                    key: ValueKey('eventPlayer.${event.id}.skip'),
                    icon: const Icon(Icons.close),
                    tooltip: '閉じる',
                    onPressed: _skipToClose,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScriptPanel extends StatelessWidget {
  const _ScriptPanel({
    required this.line,
    required this.lineIndex,
    required this.isLast,
    required this.onNext,
    required this.textSpeed,
    required this.onLineCompleted,
  });

  final EventLine line;
  final int lineIndex;
  final bool isLast;
  final VoidCallback onNext;
  final double textSpeed;
  final VoidCallback onLineCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final speakerId = line.speaker;
    final speakerCharacter =
        speakerId == null ? null : CharacterRepository.byId(speakerId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: speakerCharacter == null
                ? Icon(
                    Icons.brightness_2,
                    key: const ValueKey('eventPlayer.monologueIcon'),
                    size: 96,
                    color: theme.colorScheme.outlineVariant,
                  )
                : CharacterPortrait(
                    character: speakerCharacter,
                    expression: line.expression,
                    size: 200,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        if (speakerCharacter != null)
          Text(
            speakerCharacter.displayName,
            key: const ValueKey('eventPlayer.speakerName'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: speakerCharacter.themeColor,
              fontWeight: FontWeight.bold,
            ),
          )
        else
          Text(
            '（モノローグ）',
            key: const ValueKey('eventPlayer.monologueLabel'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 8),
        Container(
          key: const ValueKey('eventPlayer.textBox'),
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(minHeight: 96),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: TypewriterText(
            key: ValueKey('eventPlayer.text.$lineIndex'),
            text: line.text,
            textSpeed: textSpeed,
            textStyle: theme.textTheme.bodyLarge,
            onComplete: onLineCompleted,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            key: const ValueKey('eventPlayer.next'),
            onPressed: onNext,
            icon: Icon(isLast ? Icons.done : Icons.arrow_forward),
            label: Text(isLast ? '次へ' : '次へ'),
          ),
        ),
      ],
    );
  }
}

class _ChoicePanel extends StatelessWidget {
  const _ChoicePanel({
    required this.scene,
    required this.onPicked,
  });

  final EventChoiceScene scene;
  final void Function(EventChoice) onPicked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promptSpeakerId = scene.promptSpeaker;
    final character = promptSpeakerId == null
        ? null
        : CharacterRepository.byId(promptSpeakerId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scene.prompt != null)
          Container(
            key: const ValueKey('eventPlayer.choice.prompt'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                if (character != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CharacterPortrait(
                      character: character,
                      expression: scene.promptExpression,
                      size: 56,
                    ),
                  ),
                Expanded(
                  child: Text(
                    scene.prompt!,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: scene.choices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = scene.choices[i];
              return FilledButton(
                key: ValueKey('eventPlayer.choice.$i'),
                onPressed: () => onPicked(c),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.centerLeft,
                ),
                child: Text(c.label),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 設定画面の `textSpeed` を取り出すヘルパ。AppScope が無いテスト等では
/// デフォルト値 0.5 を返す。
double _resolveTextSpeed(BuildContext context) {
  try {
    final scope = AppScope.of(context);
    return scope.settings.textSpeed;
  } catch (e) {
    debugPrint('[EventPlayer] textSpeed fallback (AppScope unavailable): $e');
    return 0.5;
  }
}
