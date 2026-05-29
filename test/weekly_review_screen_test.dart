import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/stats.dart';
import 'package:tokimemo/screens/weekly_review_screen.dart';

void main() {
  testWidgets('週間変動の +N / -N / 0 が能力値ごとに表示される', (tester) async {
    final deltas = <StatKind, int>{
      StatKind.intellect: 12,
      StatKind.vitality: -10,
      StatKind.sensibility: 0,
      StatKind.sociability: 3,
      StatKind.career: 5,
      StatKind.wallet: 100000,
      StatKind.stress: -7,
    };
    final current = <StatKind, int>{
      StatKind.intellect: 37,
      StatKind.vitality: 70,
      StatKind.sensibility: 20,
      StatKind.sociability: 33,
      StatKind.career: 25,
      StatKind.wallet: 150000,
      StatKind.stress: 13,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: WeeklyReviewScreen(
          weekStartDate: DateTime(2026, 4, 1),
          weekEndDate: DateTime(2026, 4, 5),
          deltas: deltas,
          currentStats: current,
        ),
      ),
    );

    // タイトル
    expect(find.text('週次ふりかえり'), findsOneWidget);
    // 期間表示
    expect(find.text('4月1日〜4月5日'), findsOneWidget);

    // 各能力値の delta テキスト
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('weeklyReview.delta.intellect')),
          )
          .data,
      '+12',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('weeklyReview.delta.vitality')),
          )
          .data,
      '-10',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('weeklyReview.delta.sensibility')),
          )
          .data,
      '0',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('weeklyReview.delta.wallet')),
          )
          .data,
      '+100000',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('weeklyReview.delta.stress')),
          )
          .data,
      '-7',
    );

    // 「閉じる」ボタンの存在
    expect(
      find.byKey(const ValueKey('weeklyReview.close')),
      findsOneWidget,
    );
  });

  testWidgets('「閉じる」ボタンで pop される', (tester) async {
    bool popped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => WeeklyReviewScreen(
                        weekStartDate: DateTime(2026, 4, 1),
                        weekEndDate: DateTime(2026, 4, 5),
                        deltas: const <StatKind, int>{},
                        currentStats: const <StatKind, int>{},
                      ),
                    ),
                  );
                  popped = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('weeklyReview.scaffold')), findsOneWidget);
    // 閉じるボタンはリスト末尾にあるため、ListView をドラッグして可視化する
    final closeFinder = find.byKey(const ValueKey('weeklyReview.close'));
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(closeFinder);
    await tester.pumpAndSettle();
    expect(popped, isTrue);
  });
}
