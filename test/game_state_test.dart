import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/stats.dart';

void main() {
  group('GameState 初期状態', () {
    test('全枠が pending で開始日は 4月1日', () {
      final s = GameState();
      expect(s.currentDate, DateTime(2026, 4, 1));
      for (final slot in SlotIndex.values) {
        expect(s.slotStateOf(slot), SlotState.pending);
      }
      expect(s.areAllSlotsResolved, isFalse);
    });
  });

  group('applyAction: 読書', () {
    test('知性+3 / 体力-2、当該枠が done になる', () {
      final s = GameState();
      final beforeIntellect = s.allStats[StatKind.intellect]!;
      final beforeVitality = s.vitality;

      final ok = s.applyAction(SlotIndex.morning, ActionKind.read);

      expect(ok, isTrue);
      expect(s.allStats[StatKind.intellect], beforeIntellect + 3);
      expect(s.vitality, beforeVitality - 2);
      expect(s.slotStateOf(SlotIndex.morning), SlotState.done);
      // 他の枠は影響なし
      expect(s.slotStateOf(SlotIndex.midday), SlotState.pending);
      expect(s.slotStateOf(SlotIndex.evening), SlotState.pending);
      expect(s.slotStateOf(SlotIndex.night), SlotState.pending);
      // 日付は変わらない
      expect(s.currentDate, DateTime(2026, 4, 1));
    });

    test('同じ枠への二重適用は無視される', () {
      final s = GameState();
      s.applyAction(SlotIndex.morning, ActionKind.read);
      final intellect1 = s.allStats[StatKind.intellect]!;

      final ok = s.applyAction(SlotIndex.morning, ActionKind.read);

      expect(ok, isFalse);
      expect(s.allStats[StatKind.intellect], intellect1);
    });
  });

  group('applyAction: 運動', () {
    test('体力+5 / ストレス-3', () {
      final s = GameState(stress: 50);
      final beforeVit = s.vitality;
      s.applyAction(SlotIndex.morning, ActionKind.exercise);
      expect(s.vitality, beforeVit + 5);
      expect(s.stress, 50 - 3);
    });

    test('体力は上限を超えない', () {
      final s = GameState(vitality: 99, vitalityMax: 100);
      s.applyAction(SlotIndex.morning, ActionKind.exercise);
      expect(s.vitality, 100);
    });

    test('ストレスは 0 未満にならない', () {
      final s = GameState(stress: 1);
      s.applyAction(SlotIndex.morning, ActionKind.exercise);
      expect(s.stress, 0);
    });
  });

  group('applyAction: 就寝（残り枠スキップ）', () {
    test('朝に就寝すると残り 3 枠が skipped になり翌日へ進む', () {
      final s = GameState();
      final ok = s.applyAction(SlotIndex.morning, ActionKind.sleep);

      expect(ok, isTrue);
      // _advanceDay 後は全枠 pending に戻る
      for (final slot in SlotIndex.values) {
        expect(s.slotStateOf(slot), SlotState.pending);
      }
      expect(s.currentDate, DateTime(2026, 4, 2));
    });

    test('夕方に就寝すると夜だけ skipped → 翌日へ', () {
      final s = GameState();
      // 朝・日中を埋めておく
      s.applyAction(SlotIndex.morning, ActionKind.read);
      s.applyAction(SlotIndex.midday, ActionKind.exercise);
      s.applyAction(SlotIndex.evening, ActionKind.sleep);

      // 全枠解消 → 翌日へ
      expect(s.currentDate, DateTime(2026, 4, 2));
      for (final slot in SlotIndex.values) {
        expect(s.slotStateOf(slot), SlotState.pending);
      }
    });
  });

  group('日付進行: 4枠すべて pending 以外で翌日へ', () {
    test('4枠を読書で埋めると 4月2日になり、知性が +12 されている', () {
      final s = GameState();
      final intellectBefore = s.allStats[StatKind.intellect]!;
      for (final slot in SlotIndex.values) {
        s.applyAction(slot, ActionKind.read);
      }
      expect(s.currentDate, DateTime(2026, 4, 2));
      // 知性 +3 × 4 = +12
      expect(s.allStats[StatKind.intellect], intellectBefore + 12);
      // 翌日は再び全枠 pending
      for (final slot in SlotIndex.values) {
        expect(s.slotStateOf(slot), SlotState.pending);
      }
    });
  });

  group('sleepSkipRemaining: 明示 API', () {
    test('日中から呼ぶと日中以降がスキップされ翌日へ進む', () {
      final s = GameState();
      s.applyAction(SlotIndex.morning, ActionKind.read);
      s.sleepSkipRemaining(SlotIndex.midday);
      expect(s.currentDate, DateTime(2026, 4, 2));
    });

    test('既に解消済みの枠から呼ぶと何もしない', () {
      final s = GameState();
      s.applyAction(SlotIndex.morning, ActionKind.read);
      // morning は done。ここから呼ぶ → no-op
      final dateBefore = s.currentDate;
      s.sleepSkipRemaining(SlotIndex.morning);
      expect(s.currentDate, dateBefore);
    });
  });

  group('advanceDayIfAllSlotsDone', () {
    test('未解消枠があれば何もしない', () {
      final s = GameState();
      s.applyAction(SlotIndex.morning, ActionKind.read);
      final dateBefore = s.currentDate;
      s.advanceDayIfAllSlotsDone();
      expect(s.currentDate, dateBefore);
    });
  });

  group('3日ループの累積', () {
    test('3日連続で 4 枠ずつ読書しても落ちず、知性が +36 されている', () {
      final s = GameState(stress: 50, vitality: 100, vitalityMax: 100);
      final intellectBefore = s.allStats[StatKind.intellect]!;
      for (int d = 0; d < 3; d++) {
        for (final slot in SlotIndex.values) {
          s.applyAction(slot, ActionKind.read);
        }
      }
      expect(s.currentDate, DateTime(2026, 4, 4));
      expect(s.allStats[StatKind.intellect], intellectBefore + 36);
    });
  });
}
