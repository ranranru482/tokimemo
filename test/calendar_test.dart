import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/calendar.dart';

void main() {
  group('isWeekday / isHoliday', () {
    test('月〜金は平日、土日は休日', () {
      // 2026/4/6 (月) 〜 2026/4/12 (日) を網羅
      expect(isWeekday(DateTime(2026, 4, 6)), isTrue, reason: '月曜');
      expect(isWeekday(DateTime(2026, 4, 7)), isTrue, reason: '火曜');
      expect(isWeekday(DateTime(2026, 4, 8)), isTrue, reason: '水曜');
      expect(isWeekday(DateTime(2026, 4, 9)), isTrue, reason: '木曜');
      expect(isWeekday(DateTime(2026, 4, 10)), isTrue, reason: '金曜');
      expect(isWeekday(DateTime(2026, 4, 11)), isFalse, reason: '土曜');
      expect(isWeekday(DateTime(2026, 4, 12)), isFalse, reason: '日曜');

      expect(isHoliday(DateTime(2026, 4, 6)), isFalse);
      expect(isHoliday(DateTime(2026, 4, 11)), isTrue);
      expect(isHoliday(DateTime(2026, 4, 12)), isTrue);
    });

    test('isWeekday と isHoliday は相互排他', () {
      for (int i = 0; i < 14; i++) {
        final d = DateTime(2026, 4, 1).add(Duration(days: i));
        expect(isWeekday(d) ^ isHoliday(d), isTrue,
            reason: '$d で重複/欠落あり');
      }
    });
  });

  group('isWeekEnd / isMonthStart', () {
    test('isWeekEnd は日曜のみ true', () {
      expect(isWeekEnd(DateTime(2026, 4, 11)), isFalse, reason: '土曜');
      expect(isWeekEnd(DateTime(2026, 4, 12)), isTrue, reason: '日曜');
      expect(isWeekEnd(DateTime(2026, 4, 13)), isFalse, reason: '月曜');
    });

    test('isMonthStart は毎月1日のみ true', () {
      expect(isMonthStart(DateTime(2026, 5, 1)), isTrue);
      expect(isMonthStart(DateTime(2026, 5, 2)), isFalse);
      expect(isMonthStart(DateTime(2026, 4, 30)), isFalse);
      expect(isMonthStart(DateTime(2027, 1, 1)), isTrue);
    });
  });

  test('開始日 2026/4/1 は水曜（平日）', () {
    final d = DateTime(2026, 4, 1);
    expect(d.weekday, DateTime.wednesday);
    expect(isWeekday(d), isTrue);
  });
}
