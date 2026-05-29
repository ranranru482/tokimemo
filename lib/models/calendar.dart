/// 平日・休日判定。
///
/// Sprint 04 では祝日は対象外。土曜・日曜のみ「休日」扱いとする。
/// 月曜〜金曜が「平日」となり、平日の日中枠は「仕事」固定で表示される。
///
/// 将来的に祝日カレンダーを差し込めるよう、純粋関数として
/// `DateTime` を受け取り bool を返す形に統一しておく。
library;


/// 平日（月〜金）かどうか。
bool isWeekday(DateTime date) {
  return date.weekday >= DateTime.monday && date.weekday <= DateTime.friday;
}

/// 休日（土・日）かどうか。
///
/// Sprint 04 時点では祝日は判定しない。`!isWeekday(date)` と等価。
bool isHoliday(DateTime date) {
  return date.weekday == DateTime.saturday ||
      date.weekday == DateTime.sunday;
}

/// 指定日が週の最終日（日曜日）かどうか。
///
/// 「日曜終了 → 週次ふりかえり画面起動」のトリガに使う。
bool isWeekEnd(DateTime date) => date.weekday == DateTime.sunday;

/// 月初（毎月1日）かどうか。
///
/// 「翌日が月の1日に進んだ瞬間 → 給料イベント発火」のトリガに使う。
bool isMonthStart(DateTime date) => date.day == 1;
