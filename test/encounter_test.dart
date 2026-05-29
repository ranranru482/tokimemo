import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/data/encounter_repository.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/game_state.dart';

void main() {
  group('EncounterRepository', () {
    test('5 名分の出会いイベントが定義されている', () {
      expect(EncounterRepository.all.length, 5);
      final targets =
          EncounterRepository.all.map((e) => e.targetId).toSet();
      expect(targets, {
        CharacterId.akari,
        CharacterId.uta,
        CharacterId.toru,
        CharacterId.sayo,
        CharacterId.yui,
      });
    });

    test('eventOn は指定日付に発火するイベントを返す', () {
      final ev = EncounterRepository.eventOn(DateTime(2026, 4, 10));
      expect(ev, isNotNull);
      expect(ev!.targetId, CharacterId.akari);
      expect(EncounterRepository.eventOn(DateTime(2026, 4, 11)), isNull);
    });

    test('各イベントが 3 文以上の発話を持つ（表情差分の検証用）', () {
      for (final ev in EncounterRepository.all) {
        expect(ev.lines.length, greaterThanOrEqualTo(3),
            reason: '${ev.targetId} の発話が3文未満');
      }
    });

    test('全イベントの中で normal/smile/troubled が一度以上は登場する',
        () {
      // 表情差分の整備状況をリポジトリ全体で監査する。
      final expressions = <Expression>{};
      for (final ev in EncounterRepository.all) {
        for (final l in ev.lines) {
          expressions.add(l.expression);
        }
      }
      expect(expressions, containsAll(Expression.values));
    });
  });

  group('GameState.advanceDay: 出会いイベント発火', () {
    test('4/9 で全枠埋めて翌日に進むと akari の出会いイベントが発火予約される', () {
      final s = GameState(currentDate: DateTime(2026, 4, 9));
      // 4/9 は木曜（平日）。midday は仕事固定だが GameState 側の applyAction
      // は ActionKind 関係なく動くので read で 4 枠埋めて翌日に進める。
      DayAdvanceEvent? captured;
      s.addDayAdvanceListener((ev) {
        // encounter のみ捕捉（weeklyReview/salary は今回 4/9→4/10 では出ない）。
        if (ev == DayAdvanceEvent.encounter) captured = ev;
      });
      for (final slot in SlotIndex.values) {
        s.applyAction(slot, ActionKind.read);
      }
      expect(s.currentDate, DateTime(2026, 4, 10));
      expect(captured, DayAdvanceEvent.encounter);
      expect(s.pendingEncounter, isNotNull);
      expect(s.pendingEncounter!.targetId, CharacterId.akari);
    });

    test('consumePendingEncounter で対象が isMet=true になる', () {
      final s = GameState(currentDate: DateTime(2026, 4, 9));
      for (final slot in SlotIndex.values) {
        s.applyAction(slot, ActionKind.read);
      }
      expect(s.hasMet(CharacterId.akari), isFalse);
      s.consumePendingEncounter();
      expect(s.hasMet(CharacterId.akari), isTrue);
      expect(s.pendingEncounter, isNull);
    });

    test('既に出会い済のキャラに対しては再発火しない', () {
      final s = GameState(currentDate: DateTime(2026, 4, 9));
      // 先に akari を「出会い済」にしておく
      s.recordEncounter(CharacterId.akari);
      var encounterCount = 0;
      s.addDayAdvanceListener((ev) {
        if (ev == DayAdvanceEvent.encounter) encounterCount++;
      });
      for (final slot in SlotIndex.values) {
        s.applyAction(slot, ActionKind.read);
      }
      expect(encounterCount, 0);
      expect(s.pendingEncounter, isNull);
    });

    test('別キャラの発火日（4/14→4/15 uta）も正しく動く', () {
      final s = GameState(currentDate: DateTime(2026, 4, 14));
      for (final slot in SlotIndex.values) {
        s.applyAction(slot, ActionKind.read);
      }
      expect(s.currentDate, DateTime(2026, 4, 15));
      expect(s.pendingEncounter, isNotNull);
      expect(s.pendingEncounter!.targetId, CharacterId.uta);
    });
  });
}
