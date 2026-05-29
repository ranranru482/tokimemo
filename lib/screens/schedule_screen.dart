import 'package:flutter/material.dart';

import '../app.dart';
import '../models/actions.dart';
import '../models/calendar.dart';
import '../models/game_state.dart';

/// スケジュール画面（仕様書 §10 画面03）。
///
/// Sprint 05 で実装。月カレンダーで「現在月」を表示し、日付をタップすると
/// 下部に 4 枠（朝・日中・夕方・夜）の予約状況を表示するシートが開く。
/// プレイヤーは翌日以降の枠に行動を予約／キャンセルできる。
///
/// 表示範囲: 仕様書 §10 で「先1ヶ月分」の要件があるため、月ヘッダで前後の
/// 月をめくれる UI も提供する（直近の現在月から ±1ヶ月の範囲のみ）。
///
/// カレンダー部分は自前実装（dependencies を増やさないため）。
/// 月の初日の曜日オフセット計算と 7列×6行のグリッドで描画する。
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  /// 現在カレンダーに表示している月の「1日」。
  /// 初期値は GameState.currentDate の月初。
  DateTime? _visibleMonth;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: scope.gameState,
      builder: (context, _) {
        final state = scope.gameState;
        final visibleMonth = _visibleMonth ??
            DateTime(state.currentDate.year, state.currentDate.month, 1);
        return Scaffold(
          key: const ValueKey('scaffold.schedule'),
          appBar: AppBar(title: const Text('スケジュール')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MonthHeader(
                    month: visibleMonth,
                    onPrev: _canGoPrev(visibleMonth, state.currentDate)
                        ? () => setState(() {
                              _visibleMonth =
                                  DateTime(visibleMonth.year, visibleMonth.month - 1, 1);
                            })
                        : null,
                    onNext: _canGoNext(visibleMonth, state.currentDate)
                        ? () => setState(() {
                              _visibleMonth =
                                  DateTime(visibleMonth.year, visibleMonth.month + 1, 1);
                            })
                        : null,
                  ),
                  const SizedBox(height: 8),
                  const _WeekdayRow(),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _MonthGrid(
                      visibleMonth: visibleMonth,
                      today: state.currentDate,
                      gameState: state,
                      onTapDay: (date) =>
                          _showDaySheet(context, date: date, gameState: state),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 「現在月の前月」までめくれる。それ以上前は不可。
  bool _canGoPrev(DateTime visibleMonth, DateTime today) {
    final minMonth = DateTime(today.year, today.month - 1, 1);
    return !_isSameMonth(visibleMonth, minMonth) && visibleMonth.isAfter(minMonth);
  }

  /// 「現在月の翌月」までめくれる。それ以上先は不可（仕様: 先1ヶ月分）。
  bool _canGoNext(DateTime visibleMonth, DateTime today) {
    final maxMonth = DateTime(today.year, today.month + 1, 1);
    return !_isSameMonth(visibleMonth, maxMonth) && visibleMonth.isBefore(maxMonth);
  }

  static bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  Future<void> _showDaySheet(
    BuildContext context, {
    required DateTime date,
    required GameState gameState,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ScheduleDaySheet(date: date),
    );
  }
}

/// 月送りヘッダ。「< 2026年4月 >」のような表示。
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          key: const ValueKey('schedule.monthPrev'),
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
        ),
        Text(
          '${month.year}年${month.month}月',
          key: const ValueKey('schedule.monthLabel'),
          style: theme.textTheme.titleLarge,
        ),
        IconButton(
          key: const ValueKey('schedule.monthNext'),
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// 曜日行（月〜日）。日本のカレンダー慣例に合わせて月始まり。
class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  static const List<String> _names = <String>['月', '火', '水', '木', '金', '土', '日'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final n in _names)
          Expanded(
            child: Center(
              child: Text(
                n,
                style: theme.textTheme.labelMedium,
              ),
            ),
          ),
      ],
    );
  }
}

/// 月のカレンダー本体。7列×6行のグリッドを自前で描画する。
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visibleMonth,
    required this.today,
    required this.gameState,
    required this.onTapDay,
  });

  final DateTime visibleMonth;
  final DateTime today;
  final GameState gameState;
  final void Function(DateTime date) onTapDay;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;

    // 月曜始まり: weekday 月=1, ..., 日=7 を 0..6 に。
    final leadingBlanks = firstOfMonth.weekday - DateTime.monday;
    // 全42セル（6行×7列）を埋める。
    final cells = <Widget>[];
    for (int i = 0; i < leadingBlanks; i++) {
      cells.add(const _EmptyCell());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(visibleMonth.year, visibleMonth.month, day);
      final reservations = gameState.schedule.reservationsOn(date);
      final isToday = _isSameDay(date, today);
      final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
      cells.add(_DayCell(
        date: date,
        reservationCount: reservations.length,
        isToday: isToday,
        isPast: isPast,
        onTap: () => onTapDay(date),
      ));
    }
    // 末尾の空セル（行を揃える）
    while (cells.length % 7 != 0) {
      cells.add(const _EmptyCell());
    }

    return GridView.count(
      key: const ValueKey('schedule.monthGrid'),
      crossAxisCount: 7,
      childAspectRatio: 1,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.reservationCount,
    required this.isToday,
    required this.isPast,
    required this.onTap,
  });

  final DateTime date;
  final int reservationCount;
  final bool isToday;
  final bool isPast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isToday
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surface;
    final fg = isPast
        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
        : isToday
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          key: ValueKey(
            'schedule.day.${date.year}-${date.month}-${date.day}',
          ),
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: theme.textTheme.bodyLarge?.copyWith(color: fg),
                ),
                const SizedBox(height: 2),
                if (reservationCount > 0)
                  Container(
                    key: ValueKey(
                      'schedule.day.${date.year}-${date.month}-${date.day}.badge',
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$reservationCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 日付をタップしたときに開く 4 枠の予約状況シート。
///
/// 各枠について：
/// - 未予約: 「+ 予約」ボタン → 行動選択リスト（休日/平日で出る行動が変わる）。
/// - 予約済: 行動名表示、ゴミ箱アイコンでキャンセル。
///
/// 平日日中は仕事固定のため予約不可。
/// 過去日（今日を含む？）は新規予約不可だが、シートは閲覧可。
class ScheduleDaySheet extends StatefulWidget {
  const ScheduleDaySheet({super.key, required this.date});

  final DateTime date;

  @override
  State<ScheduleDaySheet> createState() => _ScheduleDaySheetState();
}

class _ScheduleDaySheetState extends State<ScheduleDaySheet> {
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: scope.gameState,
      builder: (context, _) {
        final state = scope.gameState;
        final today = state.currentDate;
        final isTodayOrPast = !widget.date
            .isAfter(DateTime(today.year, today.month, today.day));
        final isHolidayDate = isHoliday(widget.date);
        final reservations = state.schedule.reservationsOn(widget.date);
        return Padding(
          key: const ValueKey('schedule.daySheet.root'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${widget.date.month}月${widget.date.day}日（${_weekdayLabel(widget.date)}）の予約',
                  key: const ValueKey('schedule.daySheet.title'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              for (final slot in SlotIndex.values)
                _SlotRow(
                  date: widget.date,
                  slot: slot,
                  reserved: reservations[slot],
                  isHolidayDate: isHolidayDate,
                  isTodayOrPast: isTodayOrPast,
                  onReserve: (action) {
                    state.reserveAction(widget.date, slot, action);
                  },
                  onCancel: () {
                    state.cancelReservation(widget.date, slot);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  static String _weekdayLabel(DateTime d) {
    const names = ['月', '火', '水', '木', '金', '土', '日'];
    return names[d.weekday - 1];
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.date,
    required this.slot,
    required this.reserved,
    required this.isHolidayDate,
    required this.isTodayOrPast,
    required this.onReserve,
    required this.onCancel,
  });

  final DateTime date;
  final SlotIndex slot;
  final ActionKind? reserved;
  final bool isHolidayDate;
  final bool isTodayOrPast;
  final ValueChanged<ActionKind> onReserve;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 平日日中は仕事固定で予約不可
    final isWeekdayMidday =
        !isHolidayDate && slot == SlotIndex.midday;

    if (isWeekdayMidday) {
      return ListTile(
        key: ValueKey('schedule.daySheet.slot.${slot.label}'),
        leading: SizedBox(
          width: 40,
          child: Text(slot.label, style: theme.textTheme.titleMedium),
        ),
        title: Text(
          '仕事（予約不可）',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (reserved != null) {
      final effect = kActionCatalog[reserved]!;
      return ListTile(
        key: ValueKey('schedule.daySheet.slot.${slot.label}'),
        leading: SizedBox(
          width: 40,
          child: Text(slot.label, style: theme.textTheme.titleMedium),
        ),
        title: Text(effect.label),
        subtitle: Text(effect.description),
        trailing: isTodayOrPast
            ? null
            : IconButton(
                key: ValueKey('schedule.daySheet.slot.${slot.label}.cancel'),
                icon: const Icon(Icons.delete_outline),
                tooltip: '予約を取り消す',
                onPressed: onCancel,
              ),
      );
    }

    // 未予約: 翌日以降のみ「+ 予約」ボタンを表示
    return ListTile(
      key: ValueKey('schedule.daySheet.slot.${slot.label}'),
      leading: SizedBox(
        width: 40,
        child: Text(slot.label, style: theme.textTheme.titleMedium),
      ),
      title: Text(
        isTodayOrPast ? '未予約（過去日・当日は予約不可）' : '未予約',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isTodayOrPast
          ? null
          : FilledButton.tonalIcon(
              key: ValueKey('schedule.daySheet.slot.${slot.label}.reserve'),
              onPressed: () async {
                final picked = await _pickAction(context);
                if (picked != null) {
                  onReserve(picked);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('予約'),
            ),
    );
  }

  /// 予約対象の行動を選ぶサブシート。
  Future<ActionKind?> _pickAction(BuildContext context) {
    // 平日朝/夜: 自宅3行動のみ
    // 平日夕方: 自宅3 + 残業（残業は当日その場で決める性質だが、予約も許可する）
    // 休日: 自宅3 + 外出4 = 7行動
    // 「誘う」は当日その場で対象キャラを選ぶ動的な行動のため予約対象外。
    final List<ActionEffect> actions;
    if (isHolidayDate) {
      actions = kHolidayActionList
          .where((e) => e.kind != ActionKind.invite)
          .toList();
    } else if (slot == SlotIndex.evening) {
      actions = kWeekdayEveningActionList;
    } else {
      actions = kHomeActionList;
    }

    return showModalBottomSheet<ActionKind>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          key: const ValueKey('schedule.reservePicker.root'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${slot.label}の予約',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final e in actions)
                        ListTile(
                          key: ValueKey(
                              'schedule.reservePicker.action.${e.kind.name}'),
                          title: Text(e.label),
                          subtitle: Text(e.description),
                          onTap: () => Navigator.of(context).pop(e.kind),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
