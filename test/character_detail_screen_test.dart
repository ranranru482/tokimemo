import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/data/character_repository.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/screens/character_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('出会い済キャラの詳細画面に立ち絵・プロフィール・5段階ハート（1段階目）が出る',
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

    // 立ち絵
    expect(
      find.byKey(const ValueKey('characterDetail.akari.portrait')),
      findsOneWidget,
    );
    // プロフィール（名前・年齢・役職）
    final nameText = tester.widget<Text>(
      find.byKey(const ValueKey('characterDetail.akari.name')),
    );
    expect(nameText.data, '七瀬 灯');

    final roleText = tester.widget<Text>(
      find.byKey(const ValueKey('characterDetail.akari.role')),
    );
    expect(roleText.data, contains('25歳'));
    expect(roleText.data, contains('カフェ研究員'));

    // bioShort と bioLong
    expect(
      find.byKey(const ValueKey('characterDetail.akari.bioShort')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('characterDetail.akari.bioLong')),
      findsOneWidget,
    );
    final bioLong = tester.widget<Text>(
      find.byKey(const ValueKey('characterDetail.akari.bioLong')),
    );
    expect(bioLong.data, contains(CharacterRepository.byId(CharacterId.akari).bioLong));

    // 5段階ハート（1段階目 = 1個塗り、4個outline）
    expect(
      find.byKey(const ValueKey('characterDetail.akari.hearts')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('affinityHearts.icon.0.filled')),
      findsOneWidget,
    );
    for (int i = 1; i < 5; i++) {
      expect(
        find.byKey(ValueKey('affinityHearts.icon.$i.outline')),
        findsOneWidget,
        reason: '$i 番目は outline のはず',
      );
    }

    // 「誘う」ボタンは存在し、有効
    expect(
      find.byKey(const ValueKey('characterDetail.akari.inviteButton')),
      findsOneWidget,
    );
    final btn = tester.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('characterDetail.akari.inviteButton')),
    );
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('未会いキャラの詳細画面はシルエット表示で「誘う」ボタンが disable', (tester) async {
    final settings = await createTestSettings();
    final gs = GameState();

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const CharacterDetailScreen(characterId: CharacterId.akari),
        settings: settings,
        gameState: gs,
      ),
    );

    // 名前は「？？？」
    final nameText = tester.widget<Text>(
      find.byKey(const ValueKey('characterDetail.akari.name')),
    );
    expect(nameText.data, '？？？');

    // シルエット portrait
    expect(
      find.byKey(const ValueKey('characterPortrait.akari.silhouette')),
      findsOneWidget,
    );

    // 「誘う」ボタンは disable
    final btn = tester.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('characterDetail.akari.inviteButton')),
    );
    expect(btn.onPressed, isNull);
  });
}
