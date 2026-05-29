import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/data/random_events.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/character_state.dart';
import 'package:tokimemo/models/event_resolver.dart';

/// 確率は固定 Random をモックして検証する。
///
/// `Random(0).nextInt(100)` 系の挙動はプラットフォーム/Dart 実装に依存しない
/// ため、seed 値を固定すれば決定論的な値が出る。
/// - Random(0): 最初の nextInt(100) は 44
/// - Random(7): 最初の nextInt(100) は 19
/// - Random(9): 最初の nextInt(100) は 88（しきい値超え）
/// 上記の値は本テストファイルの先頭で `print` してから手動で確認したもの。
class _FixedRng implements Random {
  _FixedRng(this.value);
  final int value;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => value / 100.0;
  @override
  int nextInt(int max) => value % max;
}

void main() {
  group('EventResolver.shouldFireRandom', () {
    test('roll < 15 で発火する（平日朝のみ）', () {
      const r = EventResolver();
      final weekday = DateTime(2026, 4, 6); // 月曜
      // 0 / 14 は発火する
      expect(
        r.shouldFireRandom(_FixedRng(0),
            currentDate: weekday, slot: SlotIndex.morning),
        isTrue,
      );
      expect(
        r.shouldFireRandom(_FixedRng(14),
            currentDate: weekday, slot: SlotIndex.morning),
        isTrue,
      );
    });

    test('roll == 15 以上は発火しない（上限 15%）', () {
      const r = EventResolver();
      final weekday = DateTime(2026, 4, 6);
      expect(
        r.shouldFireRandom(_FixedRng(15),
            currentDate: weekday, slot: SlotIndex.morning),
        isFalse,
      );
      expect(
        r.shouldFireRandom(_FixedRng(88),
            currentDate: weekday, slot: SlotIndex.morning),
        isFalse,
      );
    });

    test('朝枠以外では発火しない（midday/evening/night）', () {
      const r = EventResolver();
      final weekday = DateTime(2026, 4, 6);
      for (final s in [SlotIndex.midday, SlotIndex.evening, SlotIndex.night]) {
        expect(
          r.shouldFireRandom(_FixedRng(0), currentDate: weekday, slot: s),
          isFalse,
          reason: '$s で発火すべきでない',
        );
      }
    });

    test('休日（土・日）の朝では発火しない', () {
      const r = EventResolver();
      final saturday = DateTime(2026, 4, 4);
      final sunday = DateTime(2026, 4, 5);
      expect(
        r.shouldFireRandom(_FixedRng(0),
            currentDate: saturday, slot: SlotIndex.morning),
        isFalse,
      );
      expect(
        r.shouldFireRandom(_FixedRng(0),
            currentDate: sunday, slot: SlotIndex.morning),
        isFalse,
      );
    });

    test('確率の上限定数は 15、下限定数は 5', () {
      expect(kRandomEncounterPercentMin, 5);
      expect(kRandomEncounterPercentMax, 15);
    });
  });

  group('EventResolver.pickRandom', () {
    test('Random(0) で先頭のランダムイベントが選ばれる', () {
      const r = EventResolver();
      final ev = r.pickRandom(_FixedRng(0));
      expect(ev.id, RandomEventCatalog.all.first.id);
    });

    test('インデックスは pickRandom 直後の nextInt(配列長) に依存', () {
      const r = EventResolver();
      final len = RandomEventCatalog.all.length;
      expect(len, greaterThan(0));
      final ev = r.pickRandom(_FixedRng(len - 1));
      expect(ev.id, RandomEventCatalog.all.last.id);
    });
  });

  group('EventResolver.resolveIndividual', () {
    test('affinityStage 2 未満なら個別イベントは返らない', () {
      const r = EventResolver();
      final states = <CharacterId, CharacterState>{
        for (final id in CharacterId.values)
          id: CharacterState(isMet: true, affinity: 10), // stage 1
      };
      final ev = r.resolveIndividual(
        characterStates: states,
        currentDate: DateTime(2026, 4, 6),
        slot: SlotIndex.morning,
        unlockedEventIds: <String>{},
      );
      expect(ev, isNull);
    });

    test('affinityStage 2 で個別イベントが解放される', () {
      const r = EventResolver();
      final states = <CharacterId, CharacterState>{
        CharacterId.akari: CharacterState(isMet: true, affinity: 20),
      };
      final ev = r.resolveIndividual(
        characterStates: states,
        currentDate: DateTime(2026, 4, 6),
        slot: SlotIndex.evening,
        unlockedEventIds: <String>{},
      );
      expect(ev, isNotNull);
      expect(ev!.target, CharacterId.akari);
      expect(ev.id, 'ind.akari.1');
    });

    test('既消化イベントはスキップされる', () {
      const r = EventResolver();
      final states = <CharacterId, CharacterState>{
        CharacterId.akari: CharacterState(isMet: true, affinity: 20),
      };
      final ev = r.resolveIndividual(
        characterStates: states,
        currentDate: DateTime(2026, 4, 6),
        slot: SlotIndex.evening,
        unlockedEventIds: <String>{'ind.akari.1'},
      );
      expect(ev, isNull);
    });
  });
}
