import 'dart:async';

import 'package:flutter/material.dart';

/// Sprint 10: 1 文字ずつ表示するタイプライター Widget。
///
/// 仕様書 Sprint 10 「テキスト1文字ずつのタイプライター表示」に対応。
///
/// 主要パラメータ:
/// - [text]: 表示する全文。null 安全のため空文字も許容。
/// - [textSpeed]: 0.0〜1.0 のスライダ値（`SettingsState.textSpeed`）。
///   0.0=遅い（50ms/char）, 1.0=瞬時表示（0ms）。
/// - [textStyle]: 任意の TextStyle。null なら親テーマの bodyLarge。
/// - [onComplete]: 全文表示完了時に 1 度だけ呼ばれるコールバック。
/// - [revealAllOnTap]: タップで全文即時表示にするか（デフォルト true）。
///   `DialogueModal` / `EventPlayer` / `EndingScreen` で使うときは true。
///
/// 内部設計:
/// - `Timer.periodic` を 1 文字進めるごとに使う。フレーム駆動より単純で、
///   テストの `pump(Duration)` で確実に時間を進められる。
/// - 速度マップ: `msPerChar = round((1 - textSpeed) * 50)`。
///   textSpeed=0.0 → 50ms/char、textSpeed=0.5 → 25ms/char、
///   textSpeed=1.0 → 0ms/char（=瞬時、Timer も走らせない）。
/// - `didUpdateWidget` で text が変わったら頭からやり直し。
///
/// テスト方針:
/// - `pumpWidget` 後 `pump()` で最初の 1 文字が出るのを確認。
/// - `pump(Duration(seconds: 2))` で全文表示完了 + onComplete 発火。
/// - タップで瞬時に全文表示されることを `pump()` 直後で確認。
class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.text,
    this.textSpeed = 0.5,
    this.textStyle,
    this.textAlign,
    this.onComplete,
    this.revealAllOnTap = true,
    this.maxMsPerChar = 50,
  });

  /// 表示する全文。
  final String text;

  /// 0.0〜1.0 のスライダ値。1.0 で瞬時。
  final double textSpeed;

  /// 任意の TextStyle。
  final TextStyle? textStyle;

  /// テキストの揃え。
  final TextAlign? textAlign;

  /// 全文表示完了時に 1 度だけ呼ばれる。
  final VoidCallback? onComplete;

  /// タップで全文を即時表示するか。
  final bool revealAllOnTap;

  /// textSpeed=0.0 のときの 1 文字あたりの最大表示間隔（ミリ秒）。
  final int maxMsPerChar;

  /// `SettingsState.textSpeed` (0.0〜1.0) を ms/char に変換する純粋関数。
  /// 0.0 → 50ms, 0.5 → 25ms, 1.0 → 0ms。
  static int msPerCharFor(double textSpeed, {int maxMsPerChar = 50}) {
    final clamped = textSpeed.clamp(0.0, 1.0);
    return ((1.0 - clamped) * maxMsPerChar).round();
  }

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? _timer;
  int _visibleChars = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _startReveal();
  }

  @override
  void didUpdateWidget(covariant TypewriterText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.textSpeed != widget.textSpeed) {
      _resetAndStart();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetAndStart() {
    _timer?.cancel();
    _visibleChars = 0;
    _completed = false;
    _startReveal();
  }

  void _startReveal() {
    final total = widget.text.length;
    if (total == 0) {
      _visibleChars = 0;
      _completed = true;
      // 空文字は即座に completed を発火。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onComplete?.call();
      });
      return;
    }
    final msPerChar = TypewriterText.msPerCharFor(
      widget.textSpeed,
      maxMsPerChar: widget.maxMsPerChar,
    );
    if (msPerChar <= 0) {
      // 瞬時表示モード。
      _visibleChars = total;
      _completed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onComplete?.call();
      });
      return;
    }
    _timer = Timer.periodic(Duration(milliseconds: msPerChar), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _visibleChars += 1;
        if (_visibleChars >= total) {
          _visibleChars = total;
          _completed = true;
          timer.cancel();
          widget.onComplete?.call();
        }
      });
    });
  }

  /// タップで全文を即時表示する。完了済みなら何もしない。
  void _revealAll() {
    if (_completed) return;
    _timer?.cancel();
    setState(() {
      _visibleChars = widget.text.length;
      _completed = true;
    });
    widget.onComplete?.call();
  }

  /// 進行中か（テスト用）。
  bool get _isAnimating => !_completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = widget.textStyle ?? theme.textTheme.bodyLarge;
    final shown = widget.text.substring(0, _visibleChars);
    final textWidget = Text(
      shown,
      key: const ValueKey('typewriter.text'),
      style: style,
      textAlign: widget.textAlign,
    );
    if (!widget.revealAllOnTap) {
      return textWidget;
    }
    return GestureDetector(
      key: const ValueKey('typewriter.tapArea'),
      behavior: HitTestBehavior.opaque,
      onTap: _isAnimating ? _revealAll : null,
      child: textWidget,
    );
  }
}
