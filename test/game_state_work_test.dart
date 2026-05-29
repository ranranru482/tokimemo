import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/stats.dart';
import 'package:tokimemo/models/work.dart';

void main() {
  group('applyWorkOutcome: 仕事ミニ判定結果の反映', () {
    test('success → 仕事評価が +5、日中枠が done', () {
      final s = GameState();
      final careerBefore = s.allStats[StatKind.career]!;
      final ok = s.applyWorkOutcome(WorkOutcome.success);
      expect(ok, isTrue);
      expect(s.allStats[StatKind.career], careerBefore + 5);
      expect(s.slotStateOf(SlotIndex.midday), SlotState.done);
      // 他の枠は影響なし
      expect(s.slotStateOf(SlotIndex.morning), SlotState.pending);
    });

    test('failure → ストレスが +5、日中枠が done、仕事評価は変わらない', () {
      final s = GameState(stress: 10);
      final careerBefore = s.allStats[StatKind.career]!;
      final ok = s.applyWorkOutcome(WorkOutcome.failure);
      expect(ok, isTrue);
      expect(s.stress, 10 + 5);
      expect(s.allStats[StatKind.career], careerBefore);
      expect(s.slotStateOf(SlotIndex.midday), SlotState.done);
    });

    test('既に日中枠が done なら何もしない（false 返却）', () {
      final s = GameState();
      s.applyWorkOutcome(WorkOutcome.success);
      final careerBefore = s.allStats[StatKind.career]!;
      final ok = s.applyWorkOutcome(WorkOutcome.success);
      expect(ok, isFalse);
      expect(s.allStats[StatKind.career], careerBefore);
    });

    test('成功 → 失敗を全枠で組み合わせると日付が進む', () {
      final s = GameState();
      s.applyAction(SlotIndex.morning, ActionKind.read);
      s.applyWorkOutcome(WorkOutcome.success); // midday
      s.applyAction(SlotIndex.evening, ActionKind.read);
      s.applyAction(SlotIndex.night, ActionKind.read);
      expect(s.currentDate, DateTime(2026, 4, 2));
    });
  });

  group('週初スナップショットと weeklyDeltas', () {
    test('初期化時点では全項目の delta が 0', () {
      final s = GameState();
      for (final v in s.weeklyDeltas.values) {
        expect(v, 0);
      }
    });

    test('能力値が変動すると weeklyDeltas に反映される', () {
      final s = GameState();
      final intellectBefore = s.allStats[StatKind.intellect]!;
      s.applyAction(SlotIndex.morning, ActionKind.read); // intellect +3
      expect(
        s.weeklyDeltas[StatKind.intellect],
        s.allStats[StatKind.intellect]! - intellectBefore,
      );
      expect(s.weeklyDeltas[StatKind.intellect], 3);
    });

    test('resetWeekSnapshot 後は delta が 0 に戻る', () {
      final s = GameState();
      s.applyAction(SlotIndex.morning, ActionKind.read);
      s.resetWeekSnapshot();
      expect(s.weeklyDeltas[StatKind.intellect], 0);
    });
  });

  group('月初給料イベント', () {
    test('4月30日終了で 5月1日に進むと給料を受け取り、所持金が増える', () {
      // 4月30日 = 木曜（平日）。4枠全部 read で進めて 5月1日にする。
      final s = GameState(
        currentDate: DateTime(2026, 4, 30),
        stress: 50,
        vitality: 100,
      );
      final moneyBefore = s.money;
      // 4枠すべて applyAction で埋める
      for (final slot in SlotIndex.values) {
        s.applyAction(slot, ActionKind.read);
      }
      expect(s.currentDate, DateTime(2026, 5, 1));
      // 給料が加算されている
      final expectedSalary = computeSalary(s.allStats[StatKind.career] ?? 0);
      expect(s.lastSalaryAmount, expectedSalary);
      expect(s.money, moneyBefore + expectedSalary);
    });

    test('月初イベント発火時に DayAdvanceListener が salary を受け取る', () {
      final s = GameState(currentDate: DateTime(2026, 4, 30));
      final events = <DayAdvanceEvent>[];
      s.addDayAdvanceListener(events.add);
      for (final slot in SlotIndex.values) {
        s.applyAction(slot, ActionKind.read);
      }
      expect(events, contains(DayAdvanceEvent.salary));
    });
  });

  group('日曜終了で weeklyReview イベント発火', () {
    test('4月5日（日）4枠完了 → weeklyReview が listener に届く', () {
      // 2026/4/5 は日曜
      expect(DateTime(2026, 4, 5).weekday, DateTime.sunday);
      final s = GameState(currentDate: DateTime(2026, 4, 5));
      final events = <DayAdvanceEvent>[];
      s.addDayAdvanceListener(events.add);
      for (final slot in SlotIndex.values) {
        s.applyAction(slot, ActionKind.read);
      }
      expect(events, contains(DayAdvanceEvent.weeklyReview));
    });

    test('平日の終了では weeklyReview は発火しない', () {
      final s = GameState(currentDate: DateTime(2026, 4, 6)); // 月曜
      final events = <DayAdvanceEvent>[];
      s.addDayAdvanceListener(events.add);
      for (final slot in SlotIndex.values) {
        s.applyAction(slot, ActionKind.read);
      }
      expect(events.contains(DayAdvanceEvent.weeklyReview), isFalse);
    });
  });

  group('残業: ActionKind.overtime', () {
    test('overtime で仕事評価 +3 かつストレス +5', () {
      final s = GameState(stress: 10);
      final careerBefore = s.allStats[StatKind.career]!;
      final ok = s.applyAction(SlotIndex.evening, ActionKind.overtime);
      expect(ok, isTrue);
      expect(s.allStats[StatKind.career], careerBefore + 3);
      expect(s.stress, 15);
      expect(s.slotStateOf(SlotIndex.evening), SlotState.done);
    });
  });
}
