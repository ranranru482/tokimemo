import 'package:flutter/material.dart';

/// 月初の給料受領演出。所持金は `GameState._advanceDay` 内で既に加算済み。
/// このダイアログは演出のみを担当する。
Future<void> showSalaryDialog(
  BuildContext context, {
  required int amount,
  required DateTime date,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        key: const ValueKey('salary.dialog'),
        title: Text('${date.month}月 給料日'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.payments, size: 48),
            const SizedBox(height: 12),
            Text(
              '給料 ${_formatYen(amount)}円 を受け取りました',
              key: const ValueKey('salary.dialog.amount'),
            ),
          ],
        ),
        actions: [
          FilledButton(
            key: const ValueKey('salary.dialog.close'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      );
    },
  );
}

String _formatYen(int yen) {
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
