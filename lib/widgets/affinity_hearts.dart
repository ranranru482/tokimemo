import 'package:flutter/material.dart';

import '../app.dart';
import '../models/audio_keys.dart';
import '../services/audio_service.dart';

/// 5 段階の好感度ハート列。
///
/// 仕様書 §6 の段階構造（他人 / 顔見知り / 友人 / 特別な存在 / 大切な人）に
/// 対応する 5 個のハートを表示する。塗りつぶしの個数 = 現在の段階。
///
/// Sprint 06 では実値が動かないため、出会い済キャラはすべて 1 段階目を
/// 表示する。Sprint 07 で `CharacterState.affinityStage` が動的に変わる。
///
/// Sprint 10: stage が増えるとき、新しく塗られたハートを `_HeartPop` の
/// 0.4 秒のポップ＋光るアニメーションで強調する（既存テストは
/// `findsAtLeast(1)` で吸収可能）。
class AffinityHearts extends StatefulWidget {
  const AffinityHearts({
    super.key,
    required this.stage,
    this.iconSize = 20,
  }) : assert(stage >= 0 && stage <= 5, 'stage must be 0..5');

  /// 塗りつぶすハートの数（0〜5）。
  /// 0 は「他人未満」を意図的に表すために許容する（未会いキャラの一覧表示等）。
  final int stage;

  /// アイコンサイズ（px）。
  final double iconSize;

  @override
  State<AffinityHearts> createState() => _AffinityHeartsState();
}

class _AffinityHeartsState extends State<AffinityHearts> {
  int _lastStage = 0;

  /// Sprint 12: AudioService 参照を didChangeDependencies で確保し、
  /// didUpdateWidget では try/catch を避けて軽量化する。
  AudioService? _audio;

  @override
  void initState() {
    super.initState();
    _lastStage = widget.stage;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _audio = AppScope.of(context).audio;
    } catch (e) {
      debugPrint('[AffinityHearts] AudioService unavailable: $e');
      _audio = null;
    }
  }

  @override
  void didUpdateWidget(covariant AffinityHearts old) {
    super.didUpdateWidget(old);
    if (old.stage != widget.stage) {
      _lastStage = old.stage;
      // Sprint 11: ハート段階が増えるとき heartUp SE を再生要求。
      if (widget.stage > old.stage) {
        _audio?.playSe(AudioKeys.seHeartUp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stage = widget.stage;
    return Row(
      key: ValueKey('affinityHearts.stage.$stage'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: _HeartPop(
              // 段階が上がってこのハートが新規に塗られた時のみ animate=true。
              animate: i >= _lastStage && i < stage,
              child: Icon(
                key: ValueKey(
                  'affinityHearts.icon.$i.${i < stage ? 'filled' : 'outline'}',
                ),
                i < stage ? Icons.favorite : Icons.favorite_border,
                size: widget.iconSize,
                color: i < stage
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
      ],
    );
  }
}

/// 新規に塗られたハート向けの 0.4 秒ポップ + 光るアニメーション。
///
/// `animate=false` のときは通常表示（オーバーヘッドなし）。
class _HeartPop extends StatefulWidget {
  const _HeartPop({required this.child, required this.animate});

  final Widget child;
  final bool animate;

  @override
  State<_HeartPop> createState() => _HeartPopState();
}

class _HeartPopState extends State<_HeartPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_ac);
    _glow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 70),
    ]).animate(_ac);
    if (widget.animate) {
      _ac.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _HeartPop old) {
    super.didUpdateWidget(old);
    if (widget.animate && !old.animate) {
      _ac.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return widget.child;
    return AnimatedBuilder(
      animation: _ac,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: _glow.value,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
