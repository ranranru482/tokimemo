import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/dialogue.dart';
import 'package:tokimemo/models/event.dart';
import 'package:tokimemo/widgets/event_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  GameEvent sampleEvent({bool withChoice = true}) {
    return GameEvent(
      id: 'test.sample',
      category: EventCategory.individual,
      target: CharacterId.akari,
      title: 'テストイベント',
      locationLabel: 'テスト会場',
      script: const [
        EventLine(text: 'ナレーション1。'),
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.smile,
          text: '七瀬の台詞。',
        ),
        EventLine(text: 'ナレーション3。'),
      ],
      choice: withChoice
          ? const EventChoiceScene(
              prompt: 'どうする？',
              choices: [
                EventChoice(
                  label: 'A',
                  outcome: ChoiceOutcome(label: 'A', affinityDelta: 1),
                ),
                EventChoice(
                  label: 'B',
                  outcome: ChoiceOutcome(label: 'B', affinityDelta: 2),
                ),
              ],
            )
          : null,
    );
  }

  Future<void> pumpPlayer(WidgetTester tester, GameEvent event,
      {ValueChanged<EventChoice?>? onResult}) async {
    final settings = await createTestSettings();
    await tester.pumpWidget(
      wrapWithAppScope(
        settings: settings,
        child: Scaffold(
          body: Builder(
            builder: (ctx) {
              return ElevatedButton(
                key: const ValueKey('test.openEventPlayer'),
                onPressed: () async {
                  final r = await EventPlayer.show(ctx, event: event);
                  onResult?.call(r);
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('スクリプトが順に再生され、各 line index が表示される', (tester) async {
    await pumpPlayer(tester, sampleEvent());
    await tester.tap(find.byKey(const ValueKey('test.openEventPlayer')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('eventPlayer.text.0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('eventPlayer.next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('eventPlayer.text.1')), findsOneWidget);
    // 表情差分 smile
    expect(
      find.byKey(const ValueKey('characterPortrait.akari.expression.smile')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('eventPlayer.next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('eventPlayer.text.2')), findsOneWidget);
  });

  testWidgets('末尾の選択肢で選んだ結果が onResult に返る', (tester) async {
    EventChoice? captured;
    await pumpPlayer(
      tester,
      sampleEvent(),
      onResult: (r) => captured = r,
    );
    await tester.tap(find.byKey(const ValueKey('test.openEventPlayer')));
    await tester.pumpAndSettle();

    // 3 回 next で選択肢シーンへ
    await tester.tap(find.byKey(const ValueKey('eventPlayer.next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('eventPlayer.next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('eventPlayer.next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('eventPlayer.choice.prompt')), findsOneWidget);
    // 0 番目（A）を選ぶ
    await tester.tap(find.byKey(const ValueKey('eventPlayer.choice.0')));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.label, 'A');
    expect(captured!.outcome.affinityDelta, 1);
  });

  testWidgets('選択肢なしのイベントは末尾で閉じて null が返る', (tester) async {
    EventChoice? captured;
    bool resultSet = false;
    await pumpPlayer(
      tester,
      sampleEvent(withChoice: false),
      onResult: (r) {
        captured = r;
        resultSet = true;
      },
    );
    await tester.tap(find.byKey(const ValueKey('test.openEventPlayer')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('eventPlayer.next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('eventPlayer.next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('eventPlayer.next')));
    await tester.pumpAndSettle();

    expect(resultSet, isTrue);
    expect(captured, isNull);
  });

  testWidgets('閉じるアイコンで途中終了すると null が返る', (tester) async {
    EventChoice? captured;
    bool resultSet = false;
    await pumpPlayer(
      tester,
      sampleEvent(),
      onResult: (r) {
        captured = r;
        resultSet = true;
      },
    );
    await tester.tap(find.byKey(const ValueKey('test.openEventPlayer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('eventPlayer.test.sample.skip')));
    await tester.pumpAndSettle();
    expect(resultSet, isTrue);
    expect(captured, isNull);
  });
}
