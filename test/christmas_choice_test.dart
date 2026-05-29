import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/screens/christmas_choice_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pump(WidgetTester tester, GameState gs) async {
    final settings = await createTestSettings();
    await tester.pumpWidget(
      wrapWithAppScope(
        gameState: gs,
        settings: settings,
        child: const ChristmasChoiceScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('未会いキャラは選択肢に出ない、一人で過ごす常に出る', (tester) async {
    final gs = GameState();
    gs.recordEncounter(CharacterId.akari);
    gs.recordEncounter(CharacterId.uta);
    await pump(tester, gs);

    expect(find.byKey(const ValueKey('christmasChoice.title')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('christmasChoice.pick.akari')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('christmasChoice.pick.uta')),
      findsOneWidget,
    );
    // 未会い
    expect(
      find.byKey(const ValueKey('christmasChoice.pick.toru')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('christmasChoice.pick.sayo')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('christmasChoice.pick.yui')),
      findsNothing,
    );
    // 一人で過ごす
    expect(
      find.byKey(const ValueKey('christmasChoice.pick.alone')),
      findsOneWidget,
    );
  });

  testWidgets('キャラを選ぶと専用シーンが再生される', (tester) async {
    final gs = GameState();
    gs.recordEncounter(CharacterId.akari);
    await pump(tester, gs);

    await tester.tap(find.byKey(const ValueKey('christmasChoice.pick.akari')));
    await tester.pumpAndSettle();

    // EventPlayer が開く（タイトルに「七瀬さんと過ごすイブ」）
    expect(
      find.byKey(const ValueKey('eventPlayer.milestone.christmas.akari.title')),
      findsOneWidget,
    );
  });

  testWidgets('「一人で過ごす」を選ぶと alone シーンが再生される', (tester) async {
    final gs = GameState();
    gs.recordEncounter(CharacterId.akari);
    await pump(tester, gs);

    await tester.tap(find.byKey(const ValueKey('christmasChoice.pick.alone')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('eventPlayer.milestone.christmas.alone.title'),
      ),
      findsOneWidget,
    );
  });

  test('buildChristmasEventFor は全キャラ分のイベントを返す', () {
    for (final id in CharacterId.values) {
      final ev = buildChristmasEventFor(id);
      expect(ev.target, id);
      expect(ev.id, startsWith('milestone.christmas.'));
      expect(ev.cgKey, isNotNull);
    }
  });
}
