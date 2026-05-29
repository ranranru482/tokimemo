import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/data/individual_events.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/event.dart';
import 'package:tokimemo/models/game_state.dart';

void main() {
  group('Task #4: 個別イベント拡張（各キャラ +2 本）', () {
    test('追加分 10 本がカタログに含まれている', () {
      const newIds = [
        'ind.akari.6', 'ind.akari.7',
        'ind.uta.6', 'ind.uta.7',
        'ind.toru.6', 'ind.toru.7',
        'ind.sayo.6', 'ind.sayo.7',
        'ind.yui.6', 'ind.yui.7',
      ];
      final ids = IndividualEventCatalog.all.map((e) => e.id).toSet();
      for (final nid in newIds) {
        expect(ids, contains(nid), reason: '$nid が見つからない');
      }
    });

    test('全イベントが個別カテゴリ・target 一致・cgKey 設定済み', () {
      for (final ev in IndividualEventCatalog.all) {
        expect(ev.category, EventCategory.individual);
        expect(ev.target, isNotNull);
        expect(ev.cgKey, isNotNull);
        expect(ev.cgKey!.startsWith('cg.ind.'), isTrue,
            reason: '${ev.id} の cgKey 命名規約違反');
        expect(ev.choice, isNotNull, reason: '${ev.id} に選択肢がない');
        expect(ev.choice!.choices.length, greaterThanOrEqualTo(2),
            reason: '${ev.id} は 2 選択肢以上必要');
      }
    });

    test('cgKey が全イベントでユニーク', () {
      final keys = [
        for (final e in IndividualEventCatalog.all) e.cgKey,
      ];
      expect(keys.toSet().length, keys.length);
    });
  });

  group('発火条件: 季節・時間帯', () {
    GameEvent? find(GameState s, SlotIndex slot) =>
        s.findIndividualEventFor(slot);

    test('ind.akari.6 は 5 月に発火し、4 月では発火しない', () {
      final s = GameState(currentDate: DateTime(2026, 4, 11));
      s.recordEncounter(CharacterId.akari);
      s.bumpAffinity(CharacterId.akari, 40); // stage 3
      // 4 月: 過去のイベント (akari.1〜5) を解放済みにして akari.6 を候補に。
      for (int i = 1; i <= 5; i++) {
        s.characterStateOf(CharacterId.akari)
            .unlockedEventIds
            .add('ind.akari.$i');
      }
      expect(find(s, SlotIndex.evening)?.id, isNot('ind.akari.6'));
      // 5 月で発火する。
      s.debugJumpTo(DateTime(2026, 5, 2));
      expect(find(s, SlotIndex.evening)?.id, 'ind.akari.6');
    });

    test('ind.akari.7 は preferredSlot=night（夜）でのみ返る', () {
      final s = GameState(currentDate: DateTime(2026, 5, 2));
      s.recordEncounter(CharacterId.akari);
      s.bumpAffinity(CharacterId.akari, 65); // stage 4
      for (final i in [1, 2, 3, 4, 5, 6]) {
        s.characterStateOf(CharacterId.akari)
            .unlockedEventIds
            .add('ind.akari.$i');
      }
      expect(find(s, SlotIndex.morning)?.id, isNot('ind.akari.7'));
      expect(find(s, SlotIndex.night)?.id, 'ind.akari.7');
    });

    test('ind.uta.6 は preferredSlot=evening でのみ返る', () {
      final s = GameState(currentDate: DateTime(2026, 4, 11));
      s.recordEncounter(CharacterId.uta);
      s.bumpAffinity(CharacterId.uta, 25); // stage 2
      // uta.1 は morning 限定なので unlock せず、uta.6 が evening で先に返る。
      s.characterStateOf(CharacterId.uta).unlockedEventIds.add('ind.uta.1');
      expect(find(s, SlotIndex.morning)?.id, isNot('ind.uta.6'));
      expect(find(s, SlotIndex.evening)?.id, 'ind.uta.6');
    });

    test('ind.uta.7 は 7 月以降に発火', () {
      final s = GameState(currentDate: DateTime(2026, 6, 1));
      s.recordEncounter(CharacterId.uta);
      s.bumpAffinity(CharacterId.uta, 45); // stage 3
      for (int i = 1; i <= 6; i++) {
        s.characterStateOf(CharacterId.uta)
            .unlockedEventIds
            .add('ind.uta.$i');
      }
      expect(find(s, SlotIndex.evening)?.id, isNot('ind.uta.7'));
      s.debugJumpTo(DateTime(2026, 7, 5));
      expect(find(s, SlotIndex.evening)?.id, 'ind.uta.7');
    });

    test('ind.toru.6 は 11 月以降に発火', () {
      final s = GameState(currentDate: DateTime(2026, 10, 1));
      s.recordEncounter(CharacterId.toru);
      s.bumpAffinity(CharacterId.toru, 45);
      for (int i = 1; i <= 5; i++) {
        s.characterStateOf(CharacterId.toru)
            .unlockedEventIds
            .add('ind.toru.$i');
      }
      expect(find(s, SlotIndex.evening)?.id, isNot('ind.toru.6'));
      s.debugJumpTo(DateTime(2026, 11, 1));
      expect(find(s, SlotIndex.evening)?.id, 'ind.toru.6');
    });

    test('ind.sayo.6 は preferredSlot=night でのみ返る', () {
      final s = GameState(currentDate: DateTime(2026, 4, 11));
      s.recordEncounter(CharacterId.sayo);
      s.bumpAffinity(CharacterId.sayo, 25);
      // sayo.1 も night 固定なので unlock 済みにする。
      s.characterStateOf(CharacterId.sayo)
          .unlockedEventIds
          .add('ind.sayo.1');
      expect(find(s, SlotIndex.morning)?.id, isNot('ind.sayo.6'));
      expect(find(s, SlotIndex.night)?.id, 'ind.sayo.6');
    });

    test('ind.sayo.7 は 2 月以降に発火（冬縛り）', () {
      final s = GameState(currentDate: DateTime(2027, 1, 15));
      s.recordEncounter(CharacterId.sayo);
      s.bumpAffinity(CharacterId.sayo, 45);
      for (int i = 1; i <= 6; i++) {
        s.characterStateOf(CharacterId.sayo)
            .unlockedEventIds
            .add('ind.sayo.$i');
      }
      expect(find(s, SlotIndex.night)?.id, isNot('ind.sayo.7'));
      s.debugJumpTo(DateTime(2027, 2, 1));
      expect(find(s, SlotIndex.night)?.id, 'ind.sayo.7');
    });

    test('ind.yui.6 は 8 月以降に発火（夏縛り）', () {
      final s = GameState(currentDate: DateTime(2026, 7, 25));
      s.recordEncounter(CharacterId.yui);
      s.bumpAffinity(CharacterId.yui, 45);
      for (int i = 1; i <= 5; i++) {
        s.characterStateOf(CharacterId.yui)
            .unlockedEventIds
            .add('ind.yui.$i');
      }
      expect(find(s, SlotIndex.evening)?.id, isNot('ind.yui.6'));
      s.debugJumpTo(DateTime(2026, 8, 5));
      expect(find(s, SlotIndex.evening)?.id, 'ind.yui.6');
    });

    test('ind.yui.7 は preferredSlot=morning でのみ返る', () {
      final s = GameState(currentDate: DateTime(2026, 8, 10));
      s.recordEncounter(CharacterId.yui);
      s.bumpAffinity(CharacterId.yui, 65);
      for (int i = 1; i <= 6; i++) {
        s.characterStateOf(CharacterId.yui)
            .unlockedEventIds
            .add('ind.yui.$i');
      }
      expect(find(s, SlotIndex.night)?.id, isNot('ind.yui.7'));
      expect(find(s, SlotIndex.morning)?.id, 'ind.yui.7');
    });
  });

  group('再発火防止', () {
    test('追加分も markEventCompleted で再発火しない', () {
      final s = GameState(currentDate: DateTime(2026, 5, 2));
      s.recordEncounter(CharacterId.akari);
      s.bumpAffinity(CharacterId.akari, 40);
      for (int i = 1; i <= 5; i++) {
        s.characterStateOf(CharacterId.akari)
            .unlockedEventIds
            .add('ind.akari.$i');
      }
      final ev = s.findIndividualEventFor(SlotIndex.evening);
      expect(ev?.id, 'ind.akari.6');
      s.markEventCompleted(ev!);
      final after = s.findIndividualEventFor(SlotIndex.evening);
      expect(after?.id, isNot('ind.akari.6'));
    });
  });
}
