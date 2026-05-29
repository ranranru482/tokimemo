import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/widgets/page_transitions.dart';

void main() {
  testWidgets('fadeRoute は FadeTransition を生成する', (tester) async {
    final route = fadeRoute<void>((_) => const Scaffold(body: Text('next')));
    expect(route, isA<PageRouteBuilder<void>>());
    expect(route.transitionDuration, kPageTransitionDuration);

    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(context).push(route),
            child: const Text('go'),
          ),
        );
      }),
    ));
    await tester.tap(find.text('go'));
    // 即時には完了しない（FadeTransition 中）。
    await tester.pump(const Duration(milliseconds: 125));
    expect(find.byType(FadeTransition), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.text('next'), findsOneWidget);
  });

  testWidgets('slideUpRoute は SlideTransition + FadeTransition を生成する', (tester) async {
    final route = slideUpRoute<void>((_) => const Scaffold(body: Text('sheet')));
    expect(route, isA<PageRouteBuilder<void>>());
    expect(route.fullscreenDialog, isTrue);

    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(context).push(route),
            child: const Text('open'),
          ),
        );
      }),
    ));
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 125));
    expect(find.byType(SlideTransition), findsWidgets);
    expect(find.byType(FadeTransition), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget);
  });

  testWidgets('duration 0 を渡すとほぼ即時に遷移する', (tester) async {
    final route = fadeRoute<void>(
      (_) => const Scaffold(body: Text('done')),
      duration: Duration.zero,
    );
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(context).push(route),
            child: const Text('go'),
          ),
        );
      }),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('done'), findsOneWidget);
  });
}
