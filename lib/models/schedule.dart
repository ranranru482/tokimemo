import 'actions.dart';

/// スケジュール画面で扱う「特定日のキー」。
///
/// `DateTime` は時刻まで持つため、Map のキーに直接使うと「同じ日付」でも
/// インスタンスが異なれば一致しないことがある。これを避けるため、
/// year/month/day の 3 要素のみに正規化したクラスを用意する。
///
/// `==` / `hashCode` は3要素の組で安定する。
class DateKey {
  const DateKey(this.year, this.month, this.day);

  factory DateKey.fromDateTime(DateTime date) =>
      DateKey(date.year, date.month, date.day);

  final int year;
  final int month;
  final int day;

  DateTime toDateTime() => DateTime(year, month, day);

  @override
  bool operator ==(Object other) {
    return other is DateKey &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$year-$month-$day';
}

/// 予約データを保持するインメモリストア。
///
/// Sprint 05 では永続化なし（アプリ再起動で消える）。
/// 永続化は Sprint 09 のセーブ/ロードで対応する（progress.md の負債参照）。
///
/// 構造: `DateKey` → `SlotIndex` → `ActionKind` のネスト Map。
/// 1日のうち4枠それぞれに最大1つの予約を保持する。
///
/// 「予約の追加」「キャンセル」「取り出し」「枠ごとのクリア」のみを提供する。
/// 能力値変動・所持金チェックなどのゲームロジックは [GameState] 側で行う。
class ScheduleStore {
  ScheduleStore({Map<DateKey, Map<SlotIndex, ActionKind>>? initial})
      : _data = <DateKey, Map<SlotIndex, ActionKind>>{
          if (initial != null)
            for (final entry in initial.entries)
              entry.key: Map<SlotIndex, ActionKind>.from(entry.value),
        };

  final Map<DateKey, Map<SlotIndex, ActionKind>> _data;

  /// 指定日付・枠の予約を取り出す。未予約なら null。
  ActionKind? reservationOf(DateTime date, SlotIndex slot) {
    final key = DateKey.fromDateTime(date);
    return _data[key]?[slot];
  }

  /// 指定日付の全予約を `Map<SlotIndex, ActionKind>` として返す（コピー）。
  Map<SlotIndex, ActionKind> reservationsOn(DateTime date) {
    final key = DateKey.fromDateTime(date);
    final m = _data[key];
    if (m == null) return <SlotIndex, ActionKind>{};
    return Map<SlotIndex, ActionKind>.unmodifiable(m);
  }

  /// 指定日付・枠に予約を追加する。同じ枠に既に予約があれば上書きされる。
  void reserve(DateTime date, SlotIndex slot, ActionKind action) {
    final key = DateKey.fromDateTime(date);
    _data.putIfAbsent(key, () => <SlotIndex, ActionKind>{})[slot] = action;
  }

  /// 指定日付・枠の予約をキャンセルする。元々予約がなければ何もしない。
  void cancel(DateTime date, SlotIndex slot) {
    final key = DateKey.fromDateTime(date);
    final m = _data[key];
    if (m == null) return;
    m.remove(slot);
    if (m.isEmpty) {
      _data.remove(key);
    }
  }

  /// 指定日付の予約をすべて削除する。
  void clearDay(DateTime date) {
    final key = DateKey.fromDateTime(date);
    _data.remove(key);
  }

  /// 予約が 1 件以上ある日付の一覧。テストや表示用。
  Iterable<DateKey> get reservedDates => _data.keys;

  /// 全予約をリセットする（resetToStart 用）。
  void clear() {
    _data.clear();
  }

  /// Sprint 09: セーブ用スナップショット。
  ///
  /// 形式: `[ { "date": "2026-04-12", "slot": "morning", "action": "movie" }, ... ]`
  /// JSON 化されることを前提に、Map ではなくリストの並びで保存する。
  List<Map<String, dynamic>> snapshot() {
    final list = <Map<String, dynamic>>[];
    for (final entry in _data.entries) {
      final dk = entry.key;
      for (final slotEntry in entry.value.entries) {
        list.add(<String, dynamic>{
          'date': '${dk.year.toString().padLeft(4, '0')}-'
              '${dk.month.toString().padLeft(2, '0')}-'
              '${dk.day.toString().padLeft(2, '0')}',
          'slot': slotEntry.key.name,
          'action': slotEntry.value.name,
        });
      }
    }
    return list;
  }

  /// Sprint 09: ロード用復元。既存内容はクリアしてから注入する。
  ///
  /// 不正な日付・列挙値は黙ってスキップする（前方互換のため）。
  void restoreFrom(List<dynamic> raw) {
    _data.clear();
    for (final item in raw) {
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();
      final dateStr = map['date'] as String?;
      final slotName = map['slot'] as String?;
      final actionName = map['action'] as String?;
      if (dateStr == null || slotName == null || actionName == null) continue;
      final parts = dateStr.split('-');
      if (parts.length != 3) continue;
      final y = int.tryParse(parts[0]);
      final mo = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y == null || mo == null || d == null) continue;
      SlotIndex? slot;
      for (final s in SlotIndex.values) {
        if (s.name == slotName) {
          slot = s;
          break;
        }
      }
      ActionKind? action;
      for (final a in ActionKind.values) {
        if (a.name == actionName) {
          action = a;
          break;
        }
      }
      if (slot == null || action == null) continue;
      reserve(DateTime(y, mo, d), slot, action);
    }
  }
}
