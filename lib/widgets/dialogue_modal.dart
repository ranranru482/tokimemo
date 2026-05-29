import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/audio_keys.dart';
import '../models/character.dart';
import '../models/encounter.dart';
import '../services/audio_service.dart';
import '../services/scene_bgm_router.dart';
import 'character_portrait.dart';
import 'page_transitions.dart';
import 'typewriter_text.dart';

/// 会話シーン（仕様書 §10 画面08 の最小実装）。
///
/// 全画面オーバーレイで `[立ち絵] + [テキスト] + [次へ] ボタン` を表示する。
/// 出会いイベントで使う。`lines` の各要素ごとに表情が切り替わる。
///
/// Sprint 06 ではタイプライター演出・選択肢・バックログは持たず、
/// 「テキストを順に進めて閉じる」だけのシンプルな実装。
/// Sprint 10 で 1 文字ずつの表示や演出が追加される予定。
class DialogueModal extends StatefulWidget {
  const DialogueModal({
    super.key,
    required this.character,
    required this.locationLabel,
    required this.lines,
    this.onCompleted,
  });

  final Character character;
  final String locationLabel;
  final List<DialogueLine> lines;

  /// 全発話を読み終わったタイミングのコールバック。null なら何もせず閉じる。
  final VoidCallback? onCompleted;

  /// 全画面ダイアログとして開く。`DialogueModal` 単体は Scaffold を持つので
  /// `Navigator.push` のルートとしてそのまま使える。
  ///
  /// Sprint 10: 遷移を `slideUpRoute` に置換し、下から上のスライドインで
  /// 出現する演出にする。
  static Future<void> show(
    BuildContext context, {
    required Character character,
    required String locationLabel,
    required List<DialogueLine> lines,
    VoidCallback? onCompleted,
  }) {
    return Navigator.of(context).push<void>(
      slideUpRoute<void>(
        (_) => DialogueModal(
          character: character,
          locationLabel: locationLabel,
          lines: lines,
          onCompleted: onCompleted,
        ),
      ),
    );
  }

  @override
  State<DialogueModal> createState() => _DialogueModalState();
}

/// 設定画面の `textSpeed` を取り出すヘルパ。AppScope が無い（テスト等）の
/// 場合はデフォルト値 0.5 を返す。
double _resolveTextSpeed(BuildContext context) {
  try {
    final scope = AppScope.of(context);
    return scope.settings.textSpeed;
  } catch (e) {
    debugPrint('[DialogueModal] textSpeed fallback (AppScope unavailable): $e');
    return 0.5;
  }
}

class _DialogueModalState extends State<DialogueModal> {
  int _index = 0;
  bool _lineCompleted = false;
  bool _bgmRequested = false;
  String? _previousBgm;

  /// Hotfix 2026-05-18 (B2): オート再生のオン/オフ。
  bool _autoPlay = false;
  Timer? _autoTimer;

  /// Hotfix 2026-05-18 (B2): オート再生の固定インターバル（1.5 秒）。
  static const Duration _autoInterval = Duration(milliseconds: 1500);

  /// Sprint 12: dispose 時に `AppScope.of(context)` を呼ぶのは
  /// 「ツリーから外された後で InheritedWidget が見えなくなる」ため危険。
  /// didChangeDependencies のタイミングで AudioService の参照を確保しておく。
  AudioService? _audio;

  DialogueLine get _currentLine => widget.lines[_index];

  bool get _isLast => _index >= widget.lines.length - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sprint 12: AppScope の AudioService 参照をキャッシュ（dispose 時に使う）。
    try {
      _audio = AppScope.of(context).audio;
    } catch (e) {
      debugPrint('[DialogueModal] AudioService unavailable: $e');
      _audio = null;
    }
    if (_bgmRequested) return;
    _bgmRequested = true;
    // Sprint 11: 会話シーン進入で bgm.dialogue にクロスフェード。
    // 抜けたときに直前 BGM に戻すため、現在の key を控える。
    final audio = _audio;
    if (audio != null) {
      _previousBgm = audio.currentBgmKey;
      SceneBgmRouter.enterWithService(audio, BgmScene.dialogue);
      // 1 発話目のボイスキーがあれば再生要求（実音はログのみ）。
      _maybePlayVoice(_currentLine.voiceKey);
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    // Sprint 11→12: 会話を抜けるときに直前 BGM へ戻す。
    // dispose では context 経由で InheritedWidget を引かず、キャッシュ済の
    // AudioService 参照を使う（リーク回避）。
    final prev = _previousBgm;
    final audio = _audio;
    if (prev != null && audio != null) {
      audio.crossfadeBgm(prev);
    }
    super.dispose();
  }

  /// Hotfix 2026-05-18 (B1): 「>>」全文スキップ。残り全行を読み飛ばし、
  /// onCompleted を呼んでモーダルを閉じる（イベント末ジャンプ）。
  void _skipToEnd() {
    _autoTimer?.cancel();
    widget.onCompleted?.call();
    Navigator.of(context).maybePop();
  }

  /// Hotfix 2026-05-18 (B2): オート再生トグル。
  void _toggleAutoPlay() {
    setState(() => _autoPlay = !_autoPlay);
    if (_autoPlay && _lineCompleted) {
      _scheduleAutoAdvance();
    } else {
      _autoTimer?.cancel();
    }
  }

  void _scheduleAutoAdvance() {
    _autoTimer?.cancel();
    if (!_autoPlay) return;
    _autoTimer = Timer(_autoInterval, () {
      if (!mounted || !_autoPlay) return;
      // タイプライター完了行 → 次の行 or 閉じる。
      if (_isLast) {
        widget.onCompleted?.call();
        Navigator.of(context).maybePop();
        return;
      }
      setState(() {
        _index += 1;
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
    // Sprint 10: タイプライター表示中はクリックで全文表示。
    // 全文表示後にもう一度押されたら次の発話 / 終了に進む。
    if (!_lineCompleted) {
      setState(() => _lineCompleted = true);
      return;
    }
    // Sprint 11: 次へ進む / 閉じるで confirm SE。
    _audio?.playSe(AudioKeys.seConfirm);
    if (_isLast) {
      widget.onCompleted?.call();
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _index += 1;
      _lineCompleted = false;
    });
    // Sprint 11: 次の発話のボイスキー再生。
    _maybePlayVoice(_currentLine.voiceKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = _currentLine;
    return Scaffold(
      key: const ValueKey('dialogueModal.root'),
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ヘッダ：場所表記と「閉じる」アイコン（途中スキップ用）
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.locationLabel,
                      key: const ValueKey('dialogueModal.location'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  // Hotfix 2026-05-18 (B2): オート再生トグル。
                  IconButton(
                    key: const ValueKey('dialogueModal.autoPlay'),
                    icon: Icon(_autoPlay ? Icons.pause : Icons.play_arrow),
                    tooltip: _autoPlay ? 'オート停止' : 'オート再生',
                    onPressed: _toggleAutoPlay,
                  ),
                  // Hotfix 2026-05-18 (B1): 全文スキップ（イベント末ジャンプ）。
                  IconButton(
                    key: const ValueKey('dialogueModal.skipAll'),
                    icon: const Icon(Icons.fast_forward),
                    tooltip: '全文スキップ',
                    onPressed: _skipToEnd,
                  ),
                  IconButton(
                    key: const ValueKey('dialogueModal.skip'),
                    icon: const Icon(Icons.close),
                    tooltip: '閉じる',
                    onPressed: () {
                      widget.onCompleted?.call();
                      Navigator.of(context).maybePop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 立ち絵（large）
              Expanded(
                child: Center(
                  child: CharacterPortrait(
                    character: widget.character,
                    expression: line.expression,
                    size: 200,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // キャラ名タグ
              Text(
                widget.character.displayName,
                key: const ValueKey('dialogueModal.speakerName'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: widget.character.themeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // テキストウィンドウ（Sprint 10: タイプライター表示）
              Container(
                key: const ValueKey('dialogueModal.textBox'),
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(minHeight: 96),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: TypewriterText(
                  key: ValueKey('dialogueModal.text.$_index'),
                  text: line.text,
                  textSpeed: _resolveTextSpeed(context),
                  textStyle: theme.textTheme.bodyLarge,
                  onComplete: () {
                    if (!mounted) return;
                    setState(() => _lineCompleted = true);
                    // Hotfix 2026-05-18 (B2): オート ON なら次行を 1.5 秒後に進める。
                    if (_autoPlay) _scheduleAutoAdvance();
                  },
                ),
              ),
              const SizedBox(height: 12),
              // 次へボタン
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const ValueKey('dialogueModal.next'),
                  onPressed: _onNext,
                  icon: Icon(_isLast ? Icons.done : Icons.arrow_forward),
                  label: Text(_isLast ? '閉じる' : '次へ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
