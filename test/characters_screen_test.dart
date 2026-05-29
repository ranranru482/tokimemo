import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/data/character_repository.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/screens/characters_screen.dart';
import 'package:tokimemo/widgets/character_portrait.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// GridView は viewport 外の子をビルドしないため、テストの物理サイズを
  /// 縦長にして 5 名分のカードがすべて見える状態にする。
  void useTallTestView(WidgetTester tester) {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('5 名のキャラカードがグリッドに表示される', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const CharactersScreen(),
        settings: settings,
        gameState: GameState(),
      ),
    );

    expect(find.byKey(const ValueKey('characters.grid')), findsOneWidget);
    for (final c in CharacterRepository.all) {
      expect(
        find.byKey(ValueKey('characters.card.${c.id.name}')),
        findsOneWidget,
        reason: '${c.displayName} のカードが見つからない',
      );
    }
  });

  testWidgets('未会いキャラはシルエット＋「？？？」表示', (tester) async {
    final settings = await createTestSettings();
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const CharactersScreen(),
        settings: settings,
        gameState: GameState(),
      ),
    );

    // 未会いの灯：「？？？」表示が出る
    final nameText = tester.widget<Text>(
      find.byKey(const ValueKey('characters.card.akari.name')),
    );
    expect(nameText.data, '？？？');

    // シルエット用 portrait key が存在
    expect(
      find.byKey(const ValueKey('characterPortrait.akari.silhouette')),
      findsOneWidget,
    );
  });

  testWidgets('出会い済キャラは displayName と role が表示される', (tester) async {
    final settings = await createTestSettings();
    final gs = GameState();
    gs.recordEncounter(CharacterId.akari);

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const CharactersScreen(),
        settings: settings,
        gameState: gs,
      ),
    );

    final nameText = tester.widget<Text>(
      find.byKey(const ValueKey('characters.card.akari.name')),
    );
    expect(nameText.data, '七瀬 灯');

    // normal portrait の key（出会い済 → silhouette ではない）
    expect(
      find.byKey(const ValueKey('characterPortrait.akari.normal')),
      findsOneWidget,
    );
    // 1 段階目のハート（1個塗り）
    expect(
      find.byKey(const ValueKey('affinityHearts.stage.1')),
      findsWidgets,
    );
  });

  testWidgets('カードタップで詳細画面に遷移する', (tester) async {
    final settings = await createTestSettings();
    final gs = GameState();
    gs.recordEncounter(CharacterId.uta);

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const CharactersScreen(),
        settings: settings,
        gameState: gs,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('characters.card.uta')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('scaffold.characterDetail.uta')),
      findsOneWidget,
    );
  });

  testWidgets('CharacterPortrait は size=72 のサイズで描画される（カード上の small サイズ）',
      (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const CharactersScreen(),
        settings: settings,
        gameState: GameState(),
      ),
    );

    final portraits = tester.widgetList<CharacterPortrait>(
      find.byType(CharacterPortrait),
    );
    // 5 名分の portrait があるはず
    expect(portraits.length, 5);
    for (final p in portraits) {
      expect(p.size, 72);
    }
  });
}
