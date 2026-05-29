import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/cg_view.dart';
import '../widgets/page_transitions.dart';

/// Sprint 10: CG 解放時の全画面プレビュー画面。
///
/// 仕様書 Sprint 10「CG 表示の演出」「CG解放シーンで全画面CGがフェードインで
/// 表示される」に対応。
///
/// 動作:
/// - 表示開始時にスケール 0.95 → 1.0 + フェードイン（500ms）。
/// - タップで即座に閉じる。
/// - [autoDismissAfter] が null でなければその時間後に自動で閉じる
///   （デフォルト 3 秒）。null を渡せばタップでのみ閉じる。
///
/// 呼び出しは `Navigator.push(fadeRoute(...))` を想定するが、簡便のため
/// [show] スタティックメソッドを提供。
class CgRevealScreen extends StatefulWidget {
  const CgRevealScreen({
    super.key,
    required this.cgKey,
    required this.title,
    required this.themeColor,
    this.caption,
    this.autoDismissAfter = const Duration(seconds: 3),
  });

  final String cgKey;
  final String title;
  final Color themeColor;
  final String? caption;
  final Duration? autoDismissAfter;

  static Future<void> show(
    BuildContext context, {
    required String cgKey,
    required String title,
    required Color themeColor,
    String? caption,
    Duration? autoDismissAfter = const Duration(seconds: 3),
  }) {
    return Navigator.of(context).push<void>(
      fadeRoute<void>(
        (_) => CgRevealScreen(
          cgKey: cgKey,
          title: title,
          themeColor: themeColor,
          caption: caption,
          autoDismissAfter: autoDismissAfter,
        ),
        duration: const Duration(milliseconds: 500),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<CgRevealScreen> createState() => _CgRevealScreenState();
}

class _CgRevealScreenState extends State<CgRevealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  /// Sprint 12: 自動クローズタイマ。手動タップで閉じた際に cancel しないと、
  /// Future.delayed が State 参照を保持し続けてリーク要因になる。
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    final eased = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(eased);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(eased);
    final auto = widget.autoDismissAfter;
    if (auto != null) {
      _autoDismissTimer = Timer(auto, () {
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey('cgReveal.${widget.cgKey}.root'),
      backgroundColor: Colors.black,
      body: GestureDetector(
        key: ValueKey('cgReveal.${widget.cgKey}.tapArea'),
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _opacity,
              child: ScaleTransition(
                scale: _scale,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: CgView(
                      cgKey: widget.cgKey,
                      title: widget.title,
                      themeColor: widget.themeColor,
                      caption: widget.caption,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
