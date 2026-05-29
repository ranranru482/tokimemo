import 'package:flutter/material.dart';

import '../data/work_events.dart';

/// Sprint C: 仕事中イベントを 1 件分提示するダイアログ。
///
/// 流れ:
/// 1. 状況テキストと 2 つの選択肢ボタンを表示。
/// 2. 選択後は同じダイアログ内で結果テキストに切り替える。
/// 3. 「閉じる」で pop。pop 前に選択された [WorkChoice] を返す（null は中断）。
///
/// 効果の適用は呼び出し側（HomeScreen）で `GameState.applyWorkChoice` に委譲する。
Future<WorkChoice?> showWorkEventDialog(
  BuildContext context, {
  required WorkEvent event,
}) {
  return showDialog<WorkChoice>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _WorkEventDialog(event: event);
    },
  );
}

class _WorkEventDialog extends StatefulWidget {
  const _WorkEventDialog({required this.event});

  final WorkEvent event;

  @override
  State<_WorkEventDialog> createState() => _WorkEventDialogState();
}

class _WorkEventDialogState extends State<_WorkEventDialog> {
  WorkChoice? _picked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picked = _picked;
    return AlertDialog(
      key: ValueKey('workEvent.${widget.event.id}'),
      title: Text(widget.event.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _categoryLabel(widget.event.category),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              picked == null ? widget.event.situation : picked.resultText,
              key: ValueKey(
                picked == null
                    ? 'workEvent.${widget.event.id}.situation'
                    : 'workEvent.${widget.event.id}.result',
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      actions: picked == null
          ? [
              for (int i = 0; i < widget.event.choices.length; i++)
                TextButton(
                  key: ValueKey('workEvent.${widget.event.id}.choice.$i'),
                  onPressed: () =>
                      setState(() => _picked = widget.event.choices[i]),
                  child: Text(widget.event.choices[i].label),
                ),
            ]
          : [
              FilledButton(
                key: ValueKey('workEvent.${widget.event.id}.close'),
                onPressed: () => Navigator.of(context).pop(picked),
                child: const Text('閉じる'),
              ),
            ],
    );
  }

  static String _categoryLabel(WorkEventCategory c) {
    switch (c) {
      case WorkEventCategory.boss:
        return '上司';
      case WorkEventCategory.colleague:
        return '同僚';
      case WorkEventCategory.project:
        return 'プロジェクト';
      case WorkEventCategory.mistake:
        return 'ミス';
      case WorkEventCategory.chance:
        return 'チャンス';
    }
  }
}
