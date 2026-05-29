import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/data/confession_eve_events.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/character_state.dart';
import 'package:tokimemo/models/ending.dart';
import 'package:tokimemo/models/ending_resolver.dart';
import 'package:tokimemo/models/event.dart';
import 'package:tokimemo/models/event_resolver.dart';
import 'package:tokimemo/models/game_state.dart';

void main() {
  group('ConfessionEveCatalog', () {
    test('5 キャラ全員分のイベントが揃っている', () {
      expect(ConfessionEveCatalog.all, hasLength(5));
      for (final id in CharacterId.values) {
        expect(ConfessionEveCatalog.forCharacter(id), isNotNull,
            reason: '$id 用の告白前夜イベントが定義されていない');
      }
    });

    test('全 ID がユニークで confession_eve.* の命名規約に従う', () {
      final ids = ConfessionEveCatalog.all.map((e) => e.id).toSet();
      expect(ids.length, 5);
      for (final ev in ConfessionEveCatalog.all) {
        expect(ev.id, startsWith('confession_eve.'));
        expect(ev.category, EventCategory.individual);
        expect(ev.cgKey, isNotNull);
        expect(ev.choice, isNotNull);
      }
    });

    test('idFor が enum 名と一致する', () {
      for (final id in CharacterId.values) {
        final ev = ConfessionEveCatalog.forCharacter(id)!;
        expect(ev.id, ConfessionEveCatalog.idFor(id));
      }
    });
  });

  group('EventResolver.resolveConfessionEve', () {
    const r = EventResolver();

    Map<CharacterId, CharacterState> states({
      Map<CharacterId, ({int affinity, int trueAffinity, bool isMet})>?
          overrides,
    }) {
      return <CharacterId, CharacterState>{
        for (final id in CharacterId.values)
          id: () {
            final o = overrides?[id];
            return CharacterState(
              isMet: o?.isMet ?? false,
              affinity: o?.affinity ?? 0,
              trueAffinity: o?.trueAffinity ?? 0,
            );
          }(),
      };
    }

    test('閾値ぴったり（表面 75 / 真 15）で発火する', () {
      final cs = states(overrides: {
        CharacterId.akari: (affinity: 75, trueAffinity: 15, isMet: true),
      });
      final ev =
          r.resolveConfessionEve(characterStates: cs, unlockedEventIds: {});
      expect(ev, isNotNull);
      expect(ev!.id, 'confession_eve.akari');
    });

    test('表面 74 では発火しない', () {
      final cs = states(overrides: {
        CharacterId.akari: (affinity: 74, trueAffinity: 50, isMet: true),
      });
      final ev =
          r.resolveConfessionEve(characterStates: cs, unlockedEventIds: {});
      expect(ev, isNull);
    });

    test('真 14 では発火しない', () {
      final cs = states(overrides: {
        CharacterId.akari: (affinity: 90, trueAffinity: 14, isMet: true),
      });
      final ev =
          r.resolveConfessionEve(characterStates: cs, unlockedEventIds: {});
      expect(ev, isNull);
    });

    test('未会いキャラには発火しない', () {
      final cs = states(overrides: {
        CharacterId.akari: (affinity: 90, trueAffinity: 50, isMet: false),
      });
      final ev =
          r.resolveConfessionEve(characterStates: cs, unlockedEventIds: {});
      expect(ev, isNull);
    });

    test('既に解放済みなら同じイベントは返らない', () {
      final cs = states(overrides: {
        CharacterId.akari: (affinity: 90, trueAffinity: 50, isMet: true),
      });
      final ev = r.resolveConfessionEve(
        characterStates: cs,
        unlockedEventIds: {'confession_eve.akari'},
      );
      expect(ev, isNull);
    });

    test('複数候補があれば宣言順で先頭を返す（akari が最初）', () {
      final cs = states(overrides: {
        CharacterId.akari: (affinity: 80, trueAffinity: 20, isMet: true),
        CharacterId.uta: (affinity: 90, trueAffinity: 30, isMet: true),
      });
      final ev =
          r.resolveConfessionEve(characterStates: cs, unlockedEventIds: {});
      expect(ev!.id, 'confession_eve.akari');
    });
  });

  group('GameState.findConfessionEveEvent', () {
    test('条件を満たすと該当キャラのイベントを返す', () {
      final gs = GameState();
      gs.recordEncounter(CharacterId.sayo);
      gs.bumpAffinity(CharacterId.sayo, 80);
      gs.bumpTrueAffinity(CharacterId.sayo, 20);
      final ev = gs.findConfessionEveEvent();
      expect(ev, isNotNull);
      expect(ev!.id, 'confession_eve.sayo');
    });

    test('markEventCompleted で消化すれば次は返らない', () {
      final gs = GameState();
      gs.recordEncounter(CharacterId.yui);
      gs.bumpAffinity(CharacterId.yui, 80);
      gs.bumpTrueAffinity(CharacterId.yui, 20);
      final ev = gs.findConfessionEveEvent();
      expect(ev, isNotNull);
      gs.markEventCompleted(ev!);
      final after = gs.findConfessionEveEvent();
      expect(after, isNull);
    });
  });

  group('EndingResolver と告白前夜の AND 条件', () {
    const r = EndingResolver();

    CharacterState csWith({
      required int affinity,
      required int trueAffinity,
      bool isMet = true,
      Set<String>? unlockedEventIds,
    }) {
      return CharacterState(
        isMet: isMet,
        affinity: affinity,
        trueAffinity: trueAffinity,
        unlockedEventIds: unlockedEventIds,
      );
    }

    test('表面 85 + 真 25 でも、告白前夜が未解放なら個別 ED 不発', () {
      final result = r.resolve(
        characterStates: {
          for (final id in CharacterId.values)
            id: id == CharacterId.akari
                ? csWith(affinity: 85, trueAffinity: 25)
                : csWith(affinity: 0, trueAffinity: 0),
        },
        stress: 50,
        career: 30,
        cgUnlockCount: 3,
      );
      expect(result, EndingKind.normalEd);
    });

    test('告白前夜を解放済みなら、表面 80 + 真 20 で個別 ED 発火', () {
      final result = r.resolve(
        characterStates: {
          for (final id in CharacterId.values)
            id: id == CharacterId.uta
                ? csWith(
                    affinity: 80,
                    trueAffinity: 20,
                    unlockedEventIds: {'confession_eve.uta'},
                  )
                : csWith(affinity: 0, trueAffinity: 0),
        },
        stress: 50,
        career: 30,
        cgUnlockCount: 3,
      );
      expect(result, EndingKind.utaEd);
    });

    test('複数候補が AND を満たした場合は表面好感度の高い方を採用', () {
      final result = r.resolve(
        characterStates: {
          CharacterId.akari: csWith(
            affinity: 85,
            trueAffinity: 25,
            unlockedEventIds: {'confession_eve.akari'},
          ),
          CharacterId.uta: csWith(
            affinity: 92,
            trueAffinity: 25,
            unlockedEventIds: {'confession_eve.uta'},
          ),
          for (final id in [
            CharacterId.toru,
            CharacterId.sayo,
            CharacterId.yui,
          ])
            id: csWith(affinity: 0, trueAffinity: 0),
        },
        stress: 50,
        career: 30,
        cgUnlockCount: 3,
      );
      expect(result, EndingKind.utaEd);
    });
  });
}
