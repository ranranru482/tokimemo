import 'package:flutter/material.dart';

/// Sprint 10: 画面遷移アニメーション用のヘルパ。
///
/// 既存の `Navigator.push(MaterialPageRoute(...))` を、Sprint 10 の主要画面
/// 遷移で [fadeRoute] や [slideUpRoute] に置き換えるためのルートビルダ。
///
/// 設計方針:
/// - 依存パッケージ追加禁止のため、Flutter SDK の [PageRouteBuilder] のみで実装。
/// - アニメーション期間は 250ms（速すぎず遅すぎず、テンポ重視）。
/// - `MaterialPageRoute` と同等に Future ベースで結果を受け取れるよう Generic。
/// - フルスクリーンダイアログ風の遷移には [fullscreenDialog] フラグを露出。
///
/// テスト容易性:
/// `transitionDurationMs` は引数で上書き可能。テストでは 0 を渡して
/// `tester.pump()` 1 回で遷移完了させる。
const Duration kPageTransitionDuration = Duration(milliseconds: 250);

/// フェードでスタックに積むルート。
///
/// 戻り遷移も逆向きのフェードになる（[reverseTransitionDuration] 同値）。
PageRouteBuilder<T> fadeRoute<T>(
  WidgetBuilder builder, {
  Duration duration = kPageTransitionDuration,
  bool fullscreenDialog = false,
  RouteSettings? settings,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final eased = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
      return FadeTransition(opacity: eased, child: child);
    },
  );
}

/// 下から上にスライドしてスタックに積むルート（フルスクリーンダイアログ向け）。
///
/// `MaterialPageRoute(fullscreenDialog: true)` の代替として使う想定。
PageRouteBuilder<T> slideUpRoute<T>(
  WidgetBuilder builder, {
  Duration duration = kPageTransitionDuration,
  bool fullscreenDialog = true,
  RouteSettings? settings,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final eased = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final offset = Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(eased);
      return FadeTransition(
        opacity: eased,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}
