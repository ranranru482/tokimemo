import 'dart:math';

import 'package:flutter/material.dart';

import '../app.dart';
import '../data/character_repository.dart';
import '../models/actions.dart';
import '../models/character.dart';
import '../models/dialogue.dart';
import '../models/invite_balance.dart';
import 'character_portrait.dart';

/// 「誘う」行動を選んだ際に表示するシート群。
///
/// フロー（Sprint 07 更新版）:
/// 1. キャラ選択シート: 出会い済みキャラのみリストアップ。
/// 2. 確認ダイアログ: 「○○をカフェに誘う」「コスト ¥800」を表示。
/// 3. 判定:
///    a. ストレス >= 80 のとき [stressRejectionPercent] の確率で「拒否シーン」発生。
///       → 拒否ダイアログ表示、affinity / trueAffinity 大幅減、ストレス+5。
///    b. それ以外は [inviteSuccessPercent](affinity) の確率で成否判定。
///       成功時は表面+2 / 真+1、失敗時は真-1（表面は変動なし）。
/// 4. 成功時のみ「ミニ会話」を 1 問だけ表示し、選択肢で真の好感度が動く。
///
/// 戻り値:
/// - true: 誘い行動を実行して枠を消費した（成功・失敗・拒否どれでも true）。
/// - false: ユーザが途中で閉じた、または対象キャラ不在で中止。
Future<bool> runInviteFlow(
  BuildContext context, {
  required SlotIndex slot,
  Random? rng,
}) async {
  final gameState = AppScope.of(context).gameState;
  // 出会い済キャラのみ抽出
  final available = <Character>[
    for (final c in CharacterRepository.all)
      if (gameState.hasMet(c.id)) c,
  ];

  if (available.isEmpty) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('まだ誰とも出会っていないため、誘えません。')),
    );
    return false;
  }

  // ステップ1: キャラ選択
  final picked = await showModalBottomSheet<Character>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _InvitePickerSheet(candidates: available),
  );
  if (picked == null || !context.mounted) return false;

  // ステップ2: 確認ダイアログ
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _InviteConfirmDialog(target: picked),
  );
  if (confirmed != true || !context.mounted) return false;

  // ステップ3: ストレス連動の拒否シーン判定（Sprint 07）
  final r = rng ?? Random();
  final rejectionPercent = stressRejectionPercent(gameState.stress);
  if (rejectionPercent > 0 && r.nextInt(100) < rejectionPercent) {
    final applied = gameState.applyInviteRejection(
      slot: slot,
      target: picked.id,
    );
    if (!applied) return false;
    if (!context.mounted) return true;
    await showDialog<void>(
      context: context,
      builder: (_) => _InviteRejectionDialog(target: picked),
    );
    return true;
  }

  // ステップ4: 通常の成否判定（成功率は表面好感度に依存）
  final targetState = gameState.characterStateOf(picked.id);
  final percent = inviteSuccessPercent(targetState.affinity);
  final success = r.nextInt(100) < percent;

  gameState.applyInviteOutcome(
    slot: slot,
    target: picked.id,
    success: success,
  );

  if (!context.mounted) return true;
  await showDialog<void>(
    context: context,
    builder: (_) => _InviteResultDialog(target: picked, success: success),
  );

  // ステップ5: 成功時のみ、ミニ会話の選択肢で真の好感度を動かす（Sprint 07）
  if (success && context.mounted) {
    final scene = _buildPostSuccessChoiceScene();
    final picked2 = await showDialog<ChoiceOutcome>(
      context: context,
      builder: (_) => _ChoiceDialog(target: picked, scene: scene),
    );
    if (picked2 != null) {
      gameState.applyChoiceOutcome(target: picked.id, outcome: picked2);
      if (context.mounted && picked2.reply != null) {
        await showDialog<void>(
          context: context,
          builder: (_) => _ChoiceReplyDialog(
            target: picked,
            reply: picked2.reply!,
            expression: picked2.replyExpression,
          ),
        );
      }
    }
  }

  return true;
}

/// 誘い成功後の汎用ミニ会話。Sprint 08 で本格的なイベントスクリプトに
/// 置換される予定。ここでは「無難 / 本音」の 2 択のみ。
DialogueChoiceScene _buildPostSuccessChoiceScene() {
  return const DialogueChoiceScene(
    prompt: '相手はカップを置いて、こちらをまっすぐ見た。'
        '何気ない話のはずが、ふっと核心に触れる流れになる。',
    choices: [
      ChoiceOutcome(
        label: '（無難な相づち）',
        affinityDelta: kSafeChoiceAffinityDelta,
        trueAffinityDelta: kSafeChoiceTrueAffinityDelta,
        reply: 'うん、そうかも。'
            '——なんでもないようなことが、案外気が楽でいいね。',
        replyExpression: Expression.smile,
      ),
      ChoiceOutcome(
        label: '（本音を話す）',
        affinityDelta: kHonestChoiceAffinityDelta,
        trueAffinityDelta: kHonestChoiceTrueAffinityDelta,
        reply: '——そっか。'
            '言ってくれて、助かる。少しだけ、距離が縮んだ気がする。',
        replyExpression: Expression.normal,
      ),
    ],
  );
}

/// テスト容易化のために独立した Widget として公開。
class _InvitePickerSheet extends StatelessWidget {
  const _InvitePickerSheet({required this.candidates});

  final List<Character> candidates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('inviteSheet.root'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '誰を誘いますか？',
              key: const ValueKey('inviteSheet.title'),
              style: theme.textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final c in candidates)
                    ListTile(
                      key: ValueKey('inviteSheet.candidate.${c.id.name}'),
                      leading: CharacterPortrait(
                        character: c,
                        size: 40,
                      ),
                      title: Text(c.displayName),
                      subtitle: Text(c.roleLabel),
                      onTap: () => Navigator.of(context).pop(c),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteConfirmDialog extends StatelessWidget {
  const _InviteConfirmDialog({required this.target});

  final Character target;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('inviteSheet.confirmDialog'),
      title: const Text('カフェに誘う'),
      content: Text(
        '${target.displayName} を近所のカフェに誘いますか？\n'
        '（コスト: $kInviteCostMoney円）',
      ),
      actions: [
        TextButton(
          key: const ValueKey('inviteSheet.confirm.cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('やめる'),
        ),
        FilledButton(
          key: const ValueKey('inviteSheet.confirm.ok'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('誘う'),
        ),
      ],
    );
  }
}

class _InviteResultDialog extends StatelessWidget {
  const _InviteResultDialog({required this.target, required this.success});

  final Character target;
  final bool success;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: ValueKey('inviteSheet.resultDialog.${success ? 'success' : 'failure'}'),
      title: Text(success ? '誘い成功' : '誘い失敗'),
      content: Text(
        success
            ? '${target.displayName} とカフェで穏やかな時間を過ごせた。'
                'もっと仲良くなれた気がする。'
            : '${target.displayName} は今日は予定があったみたい。'
                'また機会を見て誘ってみよう。',
      ),
      actions: [
        TextButton(
          key: const ValueKey('inviteSheet.result.close'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

/// Sprint 07: ストレス連動の拒否シーン。
class _InviteRejectionDialog extends StatelessWidget {
  const _InviteRejectionDialog({required this.target});

  final Character target;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('inviteSheet.rejectionDialog'),
      title: const Text('断られてしまった'),
      content: Text(
        '${target.displayName} は少し驚いた表情を浮かべて、'
        '「——ごめん、今日は予定があって。それと、'
        'なんだか今日のあなた、いつもより少し急いでる感じがする」と'
        '静かに断った。\n\n'
        '無理に押せば押すほど、相手は遠ざかっていくのが分かった。',
      ),
      actions: [
        TextButton(
          key: const ValueKey('inviteSheet.rejection.close'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

/// Sprint 07: 成功直後のミニ会話で 2 択を出すダイアログ。
class _ChoiceDialog extends StatelessWidget {
  const _ChoiceDialog({required this.target, required this.scene});

  final Character target;
  final DialogueChoiceScene scene;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      key: const ValueKey('inviteSheet.choiceDialog'),
      title: Text('${target.displayName} との会話'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (scene.prompt != null)
            Text(
              scene.prompt!,
              key: const ValueKey('inviteSheet.choiceDialog.prompt'),
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
      actions: [
        for (int i = 0; i < scene.choices.length; i++)
          TextButton(
            key: ValueKey('inviteSheet.choiceDialog.choice.$i'),
            onPressed: () => Navigator.of(context).pop(scene.choices[i]),
            child: Text(scene.choices[i].label),
          ),
      ],
    );
  }
}

/// Sprint 07: 選択肢を選んだ後に出る、対象キャラの短い返答ダイアログ。
class _ChoiceReplyDialog extends StatelessWidget {
  const _ChoiceReplyDialog({
    required this.target,
    required this.reply,
    required this.expression,
  });

  final Character target;
  final String reply;
  final Expression expression;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('inviteSheet.choiceReplyDialog'),
      title: Text(target.displayName),
      content: Row(
        children: [
          CharacterPortrait(
            character: target,
            expression: expression,
            size: 56,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(reply)),
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('inviteSheet.choiceReply.close'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
