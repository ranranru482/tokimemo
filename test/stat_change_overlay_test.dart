import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/stats.dart';
import 'package:tokimemo/widgets/stat_change_overlay.dart';

void main() {
  testWidgets('push で右上にチップが表示される', (tester) async {
    final controller = StatChangeOverlayController(
      lifespan: const Duration(milliseconds: 500),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(children: [StatChangeOverlayHost(controller: controller)]),
      ),
    ));
    expect(find.textContaining('知性'), findsNothing);

    controller.push(StatKind.intellect, 3);
    await tester.pump();
    expect(find.text('知性 +3'), findsOneWidget);

    // Timer / AnimationController が pending のまま test を終えないために
    // lifespan を経過させてから controller を破棄する。
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    controller.dispose();
  });

  testWidgets('lifespan 経過で自動的に消える', (tester) async {
    final controller = StatChangeOverlayController(
      lifespan: const Duration(milliseconds: 300),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(children: [StatChangeOverlayHost(controller: controller)]),
      ),
    ));
    controller.push(StatKind.career, 5);
    await tester.pump();
    expect(find.text('仕事評価 +5'), findsOneWidget);

    // lifespan 経過 → 消える。
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('仕事評価 +5'), findsNothing);
    controller.dispose();
  });

  testWidgets('複数件は縦に積まれ、上限 4 件まで', (tester) async {
    final controller = StatChangeOverlayController(
      maxVisible: 4,
      lifespan: const Duration(milliseconds: 400),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(children: [StatChangeOverlayHost(controller: controller)]),
      ),
    ));
    controller.push(StatKind.intellect, 1);
    controller.push(StatKind.sensibility, 2);
    controller.push(StatKind.sociability, 3);
    controller.push(StatKind.career, 4);
    controller.push(StatKind.stress, -1); // 5 件目 → 1 件目が消える
    await tester.pump();

    expect(find.text('知性 +1'), findsNothing); // 上限超過で消えた
    expect(find.text('感性 +2'), findsOneWidget);
    expect(find.text('社交 +3'), findsOneWidget);
    expect(find.text('仕事評価 +4'), findsOneWidget);
    expect(find.text('ストレス -1'), findsOneWidget);

    // タイマを全て消化してから dispose。
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    controller.dispose();
  });

  test('delta 0 の push は無視される', () {
    final controller = StatChangeOverlayController();
    addTearDown(controller.dispose);
    controller.push(StatKind.intellect, 0);
    expect(controller.notices, isEmpty);
  });

  test('clear() で全件消える', () {
    final controller = StatChangeOverlayController(
      lifespan: const Duration(seconds: 5),
    );
    addTearDown(controller.dispose);
    controller.push(StatKind.intellect, 3);
    controller.push(StatKind.career, 5);
    expect(controller.notices.length, 2);
    controller.clear();
    expect(controller.notices, isEmpty);
  });
}
