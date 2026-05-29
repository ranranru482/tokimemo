import 'package:flutter/material.dart';

import '../models/stats.dart';

/// 週次ふりかえり画面（仕様書 §10 画面09）。
///
/// Sprint 04 暫定実装：
/// - 今週の日付範囲（週初〜日曜）
/// - 7能力値（4能力値 + 体力 + 所持金 + ストレス）の前週比 +N / -N
/// - 「閉じる」ボタンで Navigator.pop
///
/// 好感度サマリーと特筆イベントは Sprint 06 以降。
class WeeklyReviewScreen extends StatelessWidget {
  const WeeklyReviewScreen({
    super.key,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.deltas,
    required this.currentStats,
  });

  /// 今週の開始日（通常は前回の月曜またはゲーム開始日）。
  final DateTime weekStartDate;

  /// 今週の終了日（日曜）。
  final DateTime weekEndDate;

  /// 各能力値の今週の変動（現在値 - 週初値）。
  final Map<StatKind, int> deltas;

  /// 各能力値の現在値（参考表示用）。
  final Map<StatKind, int> currentStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: const ValueKey('weeklyReview.scaffold'),
      appBar: AppBar(title: const Text('週次ふりかえり')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              key: const ValueKey('weeklyReview.range'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_formatMD(weekStartDate)}〜${_formatMD(weekEndDate)}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('能力値の週間変動', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final kind in StatKind.values)
              _DeltaRow(
                kind: kind,
                delta: deltas[kind] ?? 0,
                current: currentStats[kind] ?? 0,
              ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('weeklyReview.close'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatMD(DateTime d) => '${d.month}月${d.day}日';
}

class _DeltaRow extends StatelessWidget {
  const _DeltaRow({
    required this.kind,
    required this.delta,
    required this.current,
  });

  final StatKind kind;
  final int delta;
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = delta > 0;
    final isNegative = delta < 0;
    Color color;
    if (isPositive) {
      color = Colors.green;
    } else if (isNegative) {
      color = theme.colorScheme.error;
    } else {
      color = theme.colorScheme.onSurfaceVariant;
    }
    final sign = isPositive ? '+' : '';
    final deltaText = '$sign$delta';
    return Container(
      key: ValueKey('weeklyReview.row.${kind.name}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(kind.label, style: theme.textTheme.bodyLarge),
          ),
          Expanded(
            flex: 2,
            child: Text(
              kind == StatKind.wallet
                  ? '${_formatYen(current)}円'
                  : '$current',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            deltaText,
            key: ValueKey('weeklyReview.delta.${kind.name}'),
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  static String _formatYen(int yen) {
    final s = yen.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write(',');
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
