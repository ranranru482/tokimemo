import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/data/individual_events.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/event.dart';
import 'package:tokimemo/models/game_state.dart';

void main() {
  group('IndividualEventCatalog', () {
    test('各キャラ 7 本ずつ × 5名 = 計 35 本', () {
      expect(IndividualEventCatalog.all.length, 35);
      for (final id in CharacterId.values) {
        expect(IndividualEventCatalog.forCharacter(id).length, 7,
            reason: '$id の個別イベントが 7 本でない');
      }
    });

    test('各イベントは category=individual かつ target が一致', () {
      for (final id in CharacterId.values) {
        final list = IndividualEventCatalog.forCharacter(id);
        for (final ev in list) {
          expect(ev.category, EventCategory.individual);
          expect(ev.target, id);
        }
      }
    });

    test('Event 1 の requiredAffinityStage は 2', () {
      for (final id in CharacterId.values) {
        final list = IndividualEventCatalog.forCharacter(id);
        expect(list.first.requiredAffinityStage, 2,
            reason: '${id.name} の Event 1 は段階 2 で解放されるべき');
      }
    });

    test('全 ID がユニーク', () {
      final ids = IndividualEventCatalog.all.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('GameState.findIndividualEventFor', () {
    test('affinity 19 では Event 1 を返さない（段階 1）', () {
      final s = GameState(currentDate: DateTime(2026, 4, 11)); // 土曜
      s.recordEncounter(CharacterId.akari);
      s.bumpAffinity(CharacterId.akari, 19);
      final ev = s.findIndividualEventFor(SlotIndex.morning);
      expect(ev, isNull);
    });

    test('affinity 20 で段階 2 の個別イベントが返る', () {
      final s = GameState(currentDate: DateTime(2026, 4, 11)); // 土曜
      s.recordEncounter(CharacterId.akari);
      s.bumpAffinity(CharacterId.akari, 20);
      final ev = s.findIndividualEventFor(SlotIndex.evening);
      expect(ev, isNotNull);
      expect(ev!.target, CharacterId.akari);
      expect(ev.id, 'ind.akari.1');
    });

    test('markEventCompleted 後は同イベントが再度返らない', () {
      final s = GameState(currentDate: DateTime(2026, 4, 11));
      s.recordEncounter(CharacterId.akari);
      s.bumpAffinity(CharacterId.akari, 20);
      final ev = s.findIndividualEventFor(SlotIndex.evening);
      expect(ev, isNotNull);
      s.markEventCompleted(ev!);
      final ev2 = s.findIndividualEventFor(SlotIndex.evening);
      expect(ev2, isNull,
          reason: '解放済イベントが再発火してはいけない');
    });

    test('uta の Event 1 は preferredSlot=morning のみで返る', () {
      final s = GameState(currentDate: DateTime(2026, 4, 11));
      s.recordEncounter(CharacterId.uta);
      s.bumpAffinity(CharacterId.uta, 20);
      // Event 1 は morning 限定。evening では別イベント（Task #4 で追加した
      // ind.uta.6 など）が返る可能性はあるが、Event 1 そのものは返らない。
      final eve = s.findIndividualEventFor(SlotIndex.evening);
      expect(eve?.id, isNot('ind.uta.1'),
          reason: 'evening では Event 1 は返らない');
      final morn = s.findIndividualEventFor(SlotIndex.morning);
      expect(morn, isNotNull);
      expect(morn!.id, 'ind.uta.1');
    });

    test('characterState.unlockedEventIds に追加される', () {
      final s = GameState(currentDate: DateTime(2026, 4, 11));
      s.recordEncounter(CharacterId.akari);
      s.bumpAffinity(CharacterId.akari, 20);
      final ev = s.findIndividualEventFor(SlotIndex.evening);
      expect(ev, isNotNull);
      s.markEventCompleted(ev!);
      expect(
        s.characterStateOf(CharacterId.akari).unlockedEventIds,
        contains('ind.akari.1'),
      );
    });
  });
}
