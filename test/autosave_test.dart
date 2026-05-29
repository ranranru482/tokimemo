import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/game_state.dart';

/// Sprint 09: オートセーブのトリガが正しく発火するか unit で検証。
///
/// HomeScreen のリスナとは独立に、GameState._advanceDay 内で
/// `pendingAutosaveTrigger` がセットされることを確認する。
void main() {
  group('AutosaveTrigger: 月初', () {
    test('4/30 → 5/1 で monthStart がセットされる', () {
      final s = GameState(currentDate: DateTime(2026, 4, 30));
      AutosaveTrigger? captured;
      s.addDayAdvanceListener((event) {
        if (event == DayAdvanceEvent.autosave) {
          captured = s.pendingAutosaveTrigger;
        }
      });
      for (final slot in SlotIndex.values) {
        if (s.slotStateOf(slot) == SlotState.pending) {
          s.applyAction(slot, ActionKind.read);
        }
      }
      expect(s.currentDate, DateTime(2026, 5, 1));
      expect(captured, AutosaveTrigger.monthStart);
    });
  });

  group('AutosaveTrigger: 週末（日曜 → 月曜）', () {
    test('4/5（日）→ 4/6（月）で weekEnd がセットされる', () {
      final s = GameState(currentDate: DateTime(2026, 4, 5)); // 日曜
      AutosaveTrigger? captured;
      s.addDayAdvanceListener((event) {
        if (event == DayAdvanceEvent.autosave) {
          captured = s.pendingAutosaveTrigger;
        }
      });
      for (final slot in SlotIndex.values) {
        if (s.slotStateOf(slot) == SlotState.pending) {
          s.applyAction(slot, ActionKind.read);
        }
      }
      expect(s.currentDate, DateTime(2026, 4, 6));
      expect(captured, AutosaveTrigger.weekEnd);
    });
  });

  group('AutosaveTrigger: イベント前', () {
    test('6/14 → 6/15（健康診断）で beforeEvent がセットされる', () {
      final s = GameState(currentDate: DateTime(2026, 6, 14));
      AutosaveTrigger? captured;
      s.addDayAdvanceListener((event) {
        if (event == DayAdvanceEvent.autosave) {
          captured = s.pendingAutosaveTrigger;
        }
      });
      for (final slot in SlotIndex.values) {
        if (s.slotStateOf(slot) == SlotState.pending) {
          s.applyAction(slot, ActionKind.read);
        }
      }
      expect(s.currentDate, DateTime(2026, 6, 15));
      expect(captured, AutosaveTrigger.beforeEvent);
    });
  });

  group('AutosaveTrigger: 通常の平日進行', () {
    test('4/1 → 4/2 のような通常日では autosave しない', () {
      // 4/1（水）は月初。そこから 1 日進めると 4/2 になる。
      // 4/2 は平日（木）でも、週初でもないので autosave は発火しない。
      final s = GameState(currentDate: DateTime(2026, 4, 1));
      // まず 4/1 → 4/2 へ進める。4/1 から月初は外れるので monthStart は出ない。
      for (final slot in SlotIndex.values) {
        if (s.slotStateOf(slot) == SlotState.pending) {
          s.applyAction(slot, ActionKind.read);
        }
      }
      // 進行後の currentDate は 4/2 で pendingAutosaveTrigger は null である。
      expect(s.currentDate, DateTime(2026, 4, 2));
      expect(s.pendingAutosaveTrigger, isNull);
    });
  });

  group('consumePendingAutosaveTrigger', () {
    test('consume すると null に戻る', () {
      final s = GameState(currentDate: DateTime(2026, 4, 30));
      for (final slot in SlotIndex.values) {
        if (s.slotStateOf(slot) == SlotState.pending) {
          s.applyAction(slot, ActionKind.read);
        }
      }
      expect(s.pendingAutosaveTrigger, isNotNull);
      s.consumePendingAutosaveTrigger();
      expect(s.pendingAutosaveTrigger, isNull);
    });
  });
}
