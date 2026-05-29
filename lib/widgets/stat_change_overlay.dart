import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/stats.dart';

/// Sprint 10: 能力値変動の小ポップアップ。
///
/// 仕様書 Sprint 10「能力値が変動した時に「知性+3」などのポップアップが
/// 画面右上に短時間表示される」に対応。
///
/// 設計:
/// - `Overlay` を使わず、ホーム画面の Stack の右上に [StatChangeOverlayHost] を
///   設置する方式。Overlay 経由だと Hero/Navigator 周りの状態管理が複雑になるため、
///   親 Widget が ChangeNotifier ベースの [StatChangeOverlayController] を持つ。
/// - 通知は最大 4 件まで縦積み。新規が来たら末尾追加、各通知は 2 秒で自動消滅。
/// - スライドイン (右→中央) → 0.5 秒滞在 → フェードアウト (合計 2 秒)。
class StatChangeNotice {
  StatChangeNotice({
    required this.id,
    required this.kind,
    required this.delta,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int id;
  final StatKind kind;
  final int delta;
  final DateTime createdAt;

  /// 表示文言（例: 「知性 +3」「ストレス -5」）。
  String get label {
    final sign = delta > 0 ? '+' : '';
    return '${kind.label} $sign$delta';
  }
}

/// 通知の追加・自動消滅を管理するコントローラ。
///
/// GameState や HomeScreen から `push(StatKind.intellect, 3)` で発火する。
class StatChangeOverlayController extends ChangeNotifier {
  StatChangeOverlayController({
    this.maxVisible = 4,
    this.lifespan = const Duration(seconds: 2),
  });

  /// 同時に表示できる通知の最大数。
  final int maxVisible;

  /// 1 件の通知の表示期間（スライドイン + 滞在 + フェードアウトの合計）。
  final Duration lifespan;

  final Queue<StatChangeNotice> _notices = Queue<StatChangeNotice>();
  final Map<int, Timer> _timers = <int, Timer>{};
  int _nextId = 0;
  bool _disposed = false;

  List<StatChangeNotice> get notices =>
      List<StatChangeNotice>.unmodifiable(_notices);

  /// 通知を追加する。`delta == 0` は無視する。
  void push(StatKind kind, int delta) {
    if (_disposed) return;
    if (delta == 0) return;
    final id = _nextId++;
    final notice = StatChangeNotice(id: id, kind: kind, delta: delta);
    _notices.add(notice);
    // 上限超過分を頭から削る。
    while (_notices.length > maxVisible) {
      final removed = _notices.removeFirst();
      _timers.remove(removed.id)?.cancel();
    }
    _timers[id] = Timer(lifespan, () => _expire(id));
    notifyListeners();
  }

  void _expire(int id) {
    if (_disposed) return;
    _timers.remove(id);
    _notices.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  /// 全通知をすぐにクリア（画面遷移時など）。
  void clear() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    _notices.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    _notices.clear();
    super.dispose();
  }
}

/// ホーム画面の Stack の右上に置く Overlay 描画ホスト。
///
/// 画面全体を覆わず、右上の 200px 程度の領域に通知チップを縦積みする。
class StatChangeOverlayHost extends StatelessWidget {
  const StatChangeOverlayHost({
    super.key,
    required this.controller,
    this.alignment = Alignment.topRight,
    this.padding = const EdgeInsets.only(top: 8, right: 8),
  });

  final StatChangeOverlayController controller;
  final Alignment alignment;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final notices = controller.notices;
            return Column(
              key: const ValueKey('statChangeOverlay.column'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final n in notices)
                  _StatChangeChip(
                    key: ValueKey('statChangeOverlay.chip.${n.id}'),
                    notice: n,
                    lifespan: controller.lifespan,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatChangeChip extends StatefulWidget {
  const _StatChangeChip({
    super.key,
    required this.notice,
    required this.lifespan,
  });

  final StatChangeNotice notice;
  final Duration lifespan;

  @override
  State<_StatChangeChip> createState() => _StatChangeChipState();
}

class _StatChangeChipState extends State<_StatChangeChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: widget.lifespan)..forward();
    // 0.0-0.2: スライドイン（右→中央）+ フェードイン
    // 0.2-0.75: 滞在（不透明）
    // 0.75-1.0: フェードアウト
    _slide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.4, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween(Offset.zero),
        weight: 80,
      ),
    ]).animate(_ac);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_ac);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = widget.notice;
    final isUp = n.delta > 0;
    final color = isUp
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  n.label,
                  key: ValueKey('statChangeOverlay.chip.${n.id}.label'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
