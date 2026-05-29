import 'dart:math';

import 'package:flutter/material.dart';

import '../models/work.dart';

/// 平日日中の「仕事ミニ判定」を進めるダイアログ群。
///
/// 流れ:
/// 1. [showWorkConfirmDialog] で「出社する／やめる」確認。
/// 2. 確認が取れたら呼び出し側で [WorkResolver.resolve] により結果を確定。
///    その結果を `GameState.applyWorkOutcome` に渡し、能力値変動を反映する。
/// 3. 直後に [showWorkResultDialog] で成功/失敗の演出を表示。
///
/// テストを書きやすくするため、ダイアログ表示と結果判定は分離している。

/// 「出社する／やめる」確認ダイアログ。`true` を返したら判定へ進む。
Future<bool> showWorkConfirmDialog(
  BuildContext context, {
  required int careerValue,
}) async {
  final p = const WorkResolver().successPercent(careerValue);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        key: const ValueKey('work.confirmDialog'),
        title: const Text('仕事'),
        content: Text('今日も会社に向かう。\n（今日の成功率の目安: $p%）'),
        actions: [
          TextButton(
            key: const ValueKey('work.confirmDialog.cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('work.confirmDialog.ok'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('出社する'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// 結果ダイアログ。閉じると次の操作に戻る。
Future<void> showWorkResultDialog(
  BuildContext context, {
  required WorkOutcome outcome,
}) async {
  final isSuccess = outcome == WorkOutcome.success;
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        key: ValueKey(
          isSuccess ? 'work.resultDialog.success' : 'work.resultDialog.failure',
        ),
        title: Text(isSuccess ? '今日は手応えがあった' : '今日はうまくいかなかった'),
        content: Text(
          isSuccess
              ? '仕事評価が $kWorkSuccessCareerDelta 上がった。'
              : 'ストレスが $kWorkFailureStressDelta 増えた。',
        ),
        actions: [
          FilledButton(
            key: const ValueKey('work.resultDialog.close'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      );
    },
  );
}

/// テストで決定論的に動作させるための、Random 注入版ヘルパ。
///
/// `WorkResolver.resolve` を内部で呼ぶ。実プレイ時は `Random()` を渡す。
WorkOutcome rollWorkOutcome({
  required int careerValue,
  Random? rng,
}) {
  return const WorkResolver().resolve(rng ?? Random(), careerValue);
}
