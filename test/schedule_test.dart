import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/schedule.dart';
import 'package:tokimemo/models/stats.dart';

/// Sprint 05 受け入れ基準のうち、予約データ周りの単体テスト。
/// - ScheduleStore: 予約の追加/取り出し/キャンセル
/// - GameState.applyScheduledActionFor: 予約自動実行のルール
/// - GameState.canAfford: 所持金チェック
void main() {
  group('ScheduleStore: 予約の追加/取り出し/キャンセル', () {
    test('追加した予約を取り出せる', () {
      final store = ScheduleStore();
      final date = DateTime(2026, 4, 11); // 土曜
      store.reserve(date, SlotIndex.morning, ActionKind.museum);
      expect(store.reservationOf(date, SlotIndex.morning), ActionKind.museum);
    });

    test('別の枠に予約しても干渉しない', () {
      final store = ScheduleStore();
      final date = DateTime(2026, 4, 11);
      store.reserve(date, SlotIndex.morning, ActionKind.museum);
      store.reserve(date, SlotIndex.evening, ActionKind.movie);
      expect(store.reservationOf(date, SlotIndex.morning), ActionKind.museum);
      expect(store.reservationOf(date, SlotIndex.evening), ActionKind.movie);
    });

    test('同じ枠に再予約すると上書きされる', () {
      final store = ScheduleStore();
      final date = DateTime(2026, 4, 11);
      store.reserve(date, SlotIndex.morning, ActionKind.museum);
      store.reserve(date, SlotIndex.morning, ActionKind.cafe);
      expect(store.reservationOf(date, SlotIndex.morning), ActionKind.cafe);
    });

    test('キャンセルすると null に戻る', () {
      final store = ScheduleStore();
      final date = DateTime(2026, 4, 11);
      store.reserve(date, SlotIndex.morning, ActionKind.museum);
      store.cancel(date, SlotIndex.morning);
      expect(store.reservationOf(date, SlotIndex.morning), isNull);
    });

    test('DateKey は同じ年月日なら一致する（時刻違いでも）', () {
      final a = DateKey.fromDateTime(DateTime(2026, 4, 11, 13, 30));
      final b = DateKey.fromDateTime(DateTime(2026, 4, 11, 0, 0));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('reservationsOn は当該日の全予約を返す', () {
      final store = ScheduleStore();
      final date = DateTime(2026, 4, 11);
      store.reserve(date, SlotIndex.morning, ActionKind.museum);
      store.reserve(date, SlotIndex.night, ActionKind.read);
      final map = store.reservationsOn(date);
      expect(map.length, 2);
      expect(map[SlotIndex.morning], ActionKind.museum);
      expect(map[SlotIndex.night], ActionKind.read);
    });
  });

  group('GameState.canAfford', () {
    test('所持金が要件以上なら true', () {
      final s = GameState(money: 5000);
      expect(s.canAfford(ActionKind.movie), isTrue); // 必要 2000円
      expect(s.canAfford(ActionKind.cafe), isTrue); // 必要 800円
    });

    test('所持金不足なら false', () {
      final s = GameState(money: 500);
      expect(s.canAfford(ActionKind.movie), isFalse);
      expect(s.canAfford(ActionKind.museum), isFalse);
      // 自宅行動はコスト 0 なので always true
      expect(s.canAfford(ActionKind.read), isTrue);
      expect(s.canAfford(ActionKind.sleep), isTrue);
    });
  });

  group('GameState.applyScheduledActionFor', () {
    test('予約がある枠で呼ぶと適用されて applied が返る + 能力値変動 + 予約クリア',
        () {
      // 4/4（土）は休日。今日も 4/4 で「予約済の枠を開く」シナリオ。
      final s = GameState(
        currentDate: DateTime(2026, 4, 4),
        money: 50000,
      );
      s.schedule.reserve(DateTime(2026, 4, 4), SlotIndex.morning, ActionKind.museum);

      final sensBefore = s.allStats[StatKind.sensibility]!;
      final intBefore = s.allStats[StatKind.intellect]!;
      final moneyBefore = s.money;

      final result = s.applyScheduledActionFor(SlotIndex.morning);

      expect(result, ScheduledActionResult.applied);
      expect(s.allStats[StatKind.sensibility], sensBefore + 5);
      expect(s.allStats[StatKind.intellect], intBefore + 2);
      expect(s.money, moneyBefore - 1800);
      expect(s.slotStateOf(SlotIndex.morning), SlotState.done);
      // 予約はクリアされている
      expect(
        s.schedule.reservationOf(DateTime(2026, 4, 4), SlotIndex.morning),
        isNull,
      );
    });

    test('予約がない枠で呼ぶと noReservation', () {
      final s = GameState(currentDate: DateTime(2026, 4, 4));
      final result = s.applyScheduledActionFor(SlotIndex.morning);
      expect(result, ScheduledActionResult.noReservation);
    });

    test('所持金不足の場合 skippedInsufficientMoney + 予約クリア（能力値は変動しない）', () {
      final s = GameState(
        currentDate: DateTime(2026, 4, 4),
        money: 500, // 映画 2000 円に届かない
      );
      s.schedule.reserve(DateTime(2026, 4, 4), SlotIndex.morning, ActionKind.movie);
      final sensBefore = s.allStats[StatKind.sensibility]!;

      final result = s.applyScheduledActionFor(SlotIndex.morning);

      expect(result, ScheduledActionResult.skippedInsufficientMoney);
      expect(s.allStats[StatKind.sensibility], sensBefore);
      expect(s.slotStateOf(SlotIndex.morning), SlotState.pending);
      // コスト不足の予約はクリアされる
      expect(
        s.schedule.reservationOf(DateTime(2026, 4, 4), SlotIndex.morning),
        isNull,
      );
    });

    test('枠が既に done なら skippedSlotResolved', () {
      final s = GameState(
        currentDate: DateTime(2026, 4, 4),
        money: 50000,
      );
      s.applyAction(SlotIndex.morning, ActionKind.read); // done にしておく
      s.schedule.reserve(DateTime(2026, 4, 4), SlotIndex.morning, ActionKind.movie);
      final result = s.applyScheduledActionFor(SlotIndex.morning);
      expect(result, ScheduledActionResult.skippedSlotResolved);
    });
  });

  group('GameState.reserveAction / cancelReservation', () {
    test('reserveAction → notifyListeners が呼ばれる', () {
      final s = GameState();
      var notified = 0;
      s.addListener(() => notified++);
      s.reserveAction(DateTime(2026, 4, 11), SlotIndex.morning, ActionKind.museum);
      expect(notified, 1);
      expect(
        s.schedule.reservationOf(DateTime(2026, 4, 11), SlotIndex.morning),
        ActionKind.museum,
      );
    });

    test('cancelReservation → 予約が消える + notifyListeners', () {
      final s = GameState();
      s.reserveAction(DateTime(2026, 4, 11), SlotIndex.morning, ActionKind.museum);
      var notified = 0;
      s.addListener(() => notified++);
      s.cancelReservation(DateTime(2026, 4, 11), SlotIndex.morning);
      expect(notified, 1);
      expect(
        s.schedule.reservationOf(DateTime(2026, 4, 11), SlotIndex.morning),
        isNull,
      );
    });
  });
}
