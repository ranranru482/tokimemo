import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/screens/character_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Sprint 07 受け入れ基準5:
/// キャラ詳細画面のハート数が現在の表面好感度段階と一致する。
///
/// 加えて、GameState の affinity を動的に変更したらハート段階表示も
/// AnimatedBuilder 経由で即時更新されることを検証する。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GameState で affinity を 0 → 25 に上げると 2段階目に切替わる',
      (tester) async {
    final settings = await createTestSettings();
    final gs = GameState();
    gs.recordEncounter(CharacterId.akari);

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const CharacterDetailScreen(characterId: CharacterId.akari),
        settings: settings,
        gameState: gs,
      ),
    );
    // 初期: 1 段階目（0 番目だけ filled）
    expect(
      find.byKey(const ValueKey('affinityHearts.icon.0.filled')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('affinityHearts.icon.1.outline')),
      findsOneWidget,
    );

    // affinity を 25 に押し上げる → 2 段階目
    gs.bumpAffinity(CharacterId.akari, 25);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('affinityHearts.icon.0.filled')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('affinityHearts.icon.1.filled')),
      findsOneWidget,
      reason: '2 段階目に進んだので 2 個目も filled になる',
    );
    expect(
      find.byKey(const ValueKey('affinityHearts.icon.2.outline')),
      findsOneWidget,
    );
  });

  testWidgets('affinity の各段階でハートの塗りつぶし数が一致する', (tester) async {
    final settings = await createTestSettings();
    final gs = GameState();
    gs.recordEncounter(CharacterId.akari);

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const CharacterDetailScreen(characterId: CharacterId.akari),
        settings: settings,
        gameState: gs,
      ),
    );

    // 各段階の境界値で検証：20→2, 40→3, 60→4, 80→5
    final cases = <int, int>{
      0: 1,
      19: 1,
      20: 2,
      39: 2,
      40: 3,
      59: 3,
      60: 4,
      79: 4,
      80: 5,
      100: 5,
    };

    for (final entry in cases.entries) {
      // 一旦リセット
      final cur = gs.characterStateOf(CharacterId.akari).affinity;
      gs.bumpAffinity(CharacterId.akari, entry.key - cur);
      await tester.pumpAndSettle();

      // stage 個 filled、(5 - stage) 個 outline
      final stage = entry.value;
      for (int i = 0; i < stage; i++) {
        expect(
          find.byKey(ValueKey('affinityHearts.icon.$i.filled')),
          findsOneWidget,
          reason: 'affinity=${entry.key}: icon $i should be filled (stage=$stage)',
        );
      }
      for (int i = stage; i < 5; i++) {
        expect(
          find.byKey(ValueKey('affinityHearts.icon.$i.outline')),
          findsOneWidget,
          reason: 'affinity=${entry.key}: icon $i should be outline (stage=$stage)',
        );
      }
    }
  });

  testWidgets('真の好感度を動かしてもハート段階は変わらない', (tester) async {
    final settings = await createTestSettings();
    final gs = GameState();
    gs.recordEncounter(CharacterId.akari);

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const CharacterDetailScreen(characterId: CharacterId.akari),
        settings: settings,
        gameState: gs,
      ),
    );

    // 真の好感度を +50 してもハート段階は 1 段階目のまま
    gs.bumpTrueAffinity(CharacterId.akari, 50);
    await tester.pumpAndSettle();

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
}
