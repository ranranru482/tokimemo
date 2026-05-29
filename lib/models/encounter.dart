import 'character.dart';

/// 会話シーンの1発話を表すデータ。
///
/// [text] が画面下部のテキストウィンドウに表示され、
/// [expression] に応じて立ち絵が `normal / smile / troubled` の3差分で
/// 切り替わる。Sprint 06 では台詞は短文。Sprint 08 で本格的なシナリオに置換予定。
///
/// Sprint 11: 将来のボイス追加に備えて [voiceKey] フィールドを追加。
/// デフォルト null（ボイス無し）。値が入っていれば DialogueModal / EventPlayer
/// 側で AudioService 経由で再生要求される（実音は無く、ログのみ）。
/// 仕様書 §14 Sprint 11 受入基準5「各キャラの会話データに空のボイスフィールドが
/// 存在し、将来差し込めることがコードレビューで確認される」に対応。
class DialogueLine {
  const DialogueLine(this.expression, this.text, {this.voiceKey});

  final Expression expression;
  final String text;

  /// 将来差し込むボイスアセットのキー。`voice.<character>.<id>` 形式を想定。
  /// null ならボイス無し（現状はすべて null）。
  final String? voiceKey;
}

/// 出会いイベント 1 本分のデータ。
///
/// 各キャラに 1 本ずつ用意し、`fireDate` と当日日付が一致すると
/// `HomeScreen` 側で `DialogueModal` が自動的に開く。
///
/// 紹介テキスト [lines] は spec の各キャラの背景に基づくオリジナル短文。
/// 既存IPっぽい言い回し（「キミと…」「想い出が…」等）は意図的に避けている。
class EncounterEvent {
  const EncounterEvent({
    required this.targetId,
    required this.fireDate,
    required this.locationLabel,
    required this.lines,
  });

  /// 出会う相手のキャラ ID。
  final CharacterId targetId;

  /// 発火日。`GameState.currentDate` と (year, month, day) で一致したら発火。
  final DateTime fireDate;

  /// 「会社のエレベーター前」「商店街のカフェ」等、出会いの状況を示す短い場所表記。
  /// `DialogueModal` のヘッダに使う。
  final String locationLabel;

  /// 会話の発話列。複数の表情を切り替えながら順に表示する。
  final List<DialogueLine> lines;
}
