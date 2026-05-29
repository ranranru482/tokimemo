import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/widgets/affinity_hearts.dart';

void main() {
  Future<void> pumpHearts(WidgetTester tester, int stage) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: AffinityHearts(stage: stage))),
      ),
    );
  }

  testWidgets('stage=0 で 5 個すべて outline', (tester) async {
    await pumpHearts(tester, 0);
    for (int i = 0; i < 5; i++) {
      expect(
        find.byKey(ValueKey('affinityHearts.icon.$i.outline')),
        findsOneWidget,
      );
    }
  });

  testWidgets('stage=1 で 1個 filled / 4個 outline', (tester) async {
    await pumpHearts(tester, 1);
    expect(
      find.byKey(const ValueKey('affinityHearts.icon.0.filled')),
      findsOneWidget,
    );
    for (int i = 1; i < 5; i++) {
      expect(
        find.byKey(ValueKey('affinityHearts.icon.$i.outline')),
        findsOneWidget,
      );
    }
  });

  testWidgets('stage=3 で 3個 filled / 2個 outline', (tester) async {
    await pumpHearts(tester, 3);
    for (int i = 0; i < 3; i++) {
      expect(
        find.byKey(ValueKey('affinityHearts.icon.$i.filled')),
        findsOneWidget,
      );
    }
    for (int i = 3; i < 5; i++) {
      expect(
        find.byKey(ValueKey('affinityHearts.icon.$i.outline')),
        findsOneWidget,
      );
    }
  });

  testWidgets('stage=5 で 5 個すべて filled', (tester) async {
    await pumpHearts(tester, 5);
    for (int i = 0; i < 5; i++) {
      expect(
        find.byKey(ValueKey('affinityHearts.icon.$i.filled')),
        findsOneWidget,
      );
    }
  });

  testWidgets('rootKey に stage 値が含まれる', (tester) async {
    await pumpHearts(tester, 2);
    expect(find.byKey(const ValueKey('affinityHearts.stage.2')), findsOneWidget);
  });
}
