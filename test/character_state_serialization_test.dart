import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/character_state.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/save_snapshot.dart';
import 'package:tokimemo/models/schedule.dart';
import 'package:tokimemo/models/stats.dart';

/// Sprint 09: 各モデルの toMap/fromMap 完全往復テスト。
void main() {
  group('CharacterState: toMap/fromMap', () {
    test('全フィールドが往復で保存される', () {
      final src = CharacterState(
        isMet: true,
        affinity: 47,
        trueAffinity: -10,
        lastInteractedDate: DateTime(2026, 7, 12),
        unlockedEventIds: {'ind.akari.1', 'ind.akari.2'},
      );
      final map = src.toMap();
      final restored = CharacterState.fromMap(map);
      expect(restored.isMet, true);
      expect(restored.affinity, 47);
      expect(restored.trueAffinity, -10);
      expect(restored.lastInteractedDate, DateTime(2026, 7, 12));
      expect(restored.unlockedEventIds,
          containsAll(<String>{'ind.akari.1', 'ind.akari.2'}));
    });

    test('lastInteractedDate が null でも壊れない', () {
      final src = CharacterState(
        isMet: false,
        affinity: 0,
        trueAffinity: 0,
      );
      final map = src.toMap();
      final restored = CharacterState.fromMap(map);
      expect(restored.lastInteractedDate, isNull);
    });
  });

  group('GameState: toMap/fromMap', () {
    test('全フィールドが往復で保存される', () {
      final src = GameState(heroName: 'シリアライズ太郎');
      src.applyAction(SlotIndex.morning, ActionKind.read);
      src.bumpAffinity(CharacterId.akari, 15);
      src.bumpTrueAffinity(CharacterId.uta, -5);
      src.cgLibrary.unlock('cg.test.serialize');
      src.reserveAction(
          DateTime(2026, 5, 9), SlotIndex.evening, ActionKind.movie);

      final map = src.toMap();
      final restored = GameState();
      restored.restoreFromMap(map);

      expect(restored.heroName, 'シリアライズ太郎');
      expect(restored.currentDate, src.currentDate);
      expect(restored.vitality, src.vitality);
      expect(restored.money, src.money);
      expect(restored.stress, src.stress);
      expect(restored.allStats[StatKind.intellect],
          src.allStats[StatKind.intellect]);
      expect(restored.slotStateOf(SlotIndex.morning), SlotState.done);
      expect(restored.characterStateOf(CharacterId.akari).affinity, 15);
      expect(restored.characterStateOf(CharacterId.uta).trueAffinity, -5);
      expect(restored.cgLibrary.has('cg.test.serialize'), isTrue);
      expect(
        restored.schedule
            .reservationOf(DateTime(2026, 5, 9), SlotIndex.evening),
        ActionKind.movie,
      );
    });

    test('空 GameState を save → restore しても初期状態と一致', () {
      final src = GameState();
      final map = src.toMap();
      final restored = GameState();
      restored.restoreFromMap(map);
      expect(restored.heroName, '');
      expect(restored.currentDate, DateTime(2026, 4, 1));
      for (final slot in SlotIndex.values) {
        expect(restored.slotStateOf(slot), SlotState.pending);
      }
    });
  });

  group('ScheduleStore: snapshot/restoreFrom', () {
    test('予約データを完全に往復できる', () {
      final src = ScheduleStore()
        ..reserve(DateTime(2026, 4, 12), SlotIndex.morning, ActionKind.cafe)
        ..reserve(DateTime(2026, 4, 12), SlotIndex.evening, ActionKind.gym)
        ..reserve(DateTime(2026, 5, 9), SlotIndex.night, ActionKind.read);
      final snap = src.snapshot();
      final restored = ScheduleStore();
      restored.restoreFrom(snap);
      expect(
        restored.reservationOf(DateTime(2026, 4, 12), SlotIndex.morning),
        ActionKind.cafe,
      );
      expect(
        restored.reservationOf(DateTime(2026, 4, 12), SlotIndex.evening),
        ActionKind.gym,
      );
      expect(
        restored.reservationOf(DateTime(2026, 5, 9), SlotIndex.night),
        ActionKind.read,
      );
    });
  });

  group('SaveSnapshot: toMap/fromMap', () {
    test('SaveSnapshot のラウンドトリップ', () {
      final src = SaveSnapshot(
        slot: SaveSlotKey.manual(2),
        heroName: '太郎',
        savedAt: DateTime(2026, 4, 1, 12, 30),
        inGameDate: DateTime(2026, 4, 1),
        summary: '4月1日 / 体力80 / 出会い済0名',
        payload: <String, dynamic>{'foo': 'bar'},
      );
      final map = src.toMap();
      final restored =
          SaveSnapshot.fromMap(SaveSlotKey.manual(2), map);
      expect(restored, isNotNull);
      expect(restored!.heroName, '太郎');
      expect(restored.savedAt, DateTime(2026, 4, 1, 12, 30));
      expect(restored.inGameDate, DateTime(2026, 4, 1));
      expect(restored.summary, '4月1日 / 体力80 / 出会い済0名');
      expect(restored.payload['foo'], 'bar');
    });
  });
}
