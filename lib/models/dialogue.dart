/// Sprint 07: 会話の選択肢とその効果を表すデータ型。
///
/// 仕様書 §6 で述べられている「2層好感度」を支える根幹型。
/// 選択肢ごとに表面好感度・真の好感度の増減を別フィールドで持つことで、
/// 「表面が上がっても真の好感度が下がる『上辺だけの会話』」を表現する。
///
/// Sprint 07 ではまず「誘う成功後の汎用ミニ会話」で使う。
/// Sprint 08 で本格的なイベントスクリプトに展開していく。
library;

import 'character.dart';

/// 1 つの選択肢ボタンに対応する結果データ。
class ChoiceOutcome {
  const ChoiceOutcome({
    required this.label,
    this.affinityDelta = 0,
    this.trueAffinityDelta = 0,
    this.stressDelta = 0,
    this.reply,
    this.replyExpression = Expression.normal,
  });

  /// ボタンに表示する文字列（例: 「（無難な相づち）」「（本音を話す）」）。
  final String label;

  /// 対象キャラの表面好感度の差分。
  final int affinityDelta;

  /// 対象キャラの真の好感度の差分（非表示）。
  final int trueAffinityDelta;

  /// 主人公のストレス差分（任意）。
  final int stressDelta;

  /// 選択後に対象キャラが返す短い返答（任意）。null なら返答演出をスキップ。
  final String? reply;

  /// 返答時の表情。
  final Expression replyExpression;
}

/// 1 件の選択肢シーン。
///
/// [prompt] が選択肢の前に表示される問いかけ。`null` なら直接ボタンのみ表示。
/// [choices] は通常 2〜4 件。
class DialogueChoiceScene {
  const DialogueChoiceScene({
    this.prompt,
    this.promptExpression = Expression.normal,
    required this.choices,
  });

  final String? prompt;
  final Expression promptExpression;
  final List<ChoiceOutcome> choices;
}
