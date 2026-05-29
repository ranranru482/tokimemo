/// Sprint 08: イベントシステムの共通データ型。
///
/// 仕様書 §7 で定義された 4 種類のイベントカテゴリ
/// （共通 / 個別 / 季節（節目）/ ランダム）を 1 つのデータ型 [GameEvent] で
/// 表現する。発火条件は呼び出し側（リゾルバ）が個別に評価し、本ファイルでは
/// 「データ宣言」と「進行に関するメタ情報」のみを定義する。
///
/// 既存の `DialogueLine`（lib/models/encounter.dart）は `[Expression, String]` の
/// 2 値ペアで設計されていたが、Sprint 08 では「話者は誰か」「主人公のモノローグか」
/// を扱いたいため、本ファイルで [EventLine] を新設する。`DialogueModal` 側との
/// 互換性は `event_player.dart` のアダプタで吸収する。
///
/// 既存IP（ときめきメモリアル等）の固有名詞・台詞は使用していない。
/// すべての発話文はオリジナル。
library;

import '../models/character.dart';
import '../models/dialogue.dart';

/// イベントのカテゴリ区分。
///
/// - [common]    : 全プレイヤー共通の季節イベント（例: 健康診断・夏祭り・年度末）。
///                 日付ベースで自動発火する。キャラ別の差分はあるが、誰でも遭遇する。
/// - [individual]: キャラ別の個別イベント。
///                 affinityStage や特定の月日・能力値などの AND 条件で発火。
/// - [milestone] : 季節の節目イベント（例: クリスマス・バレンタイン）。
///                 「誰と過ごすか」の選択画面を挟む。
/// - [random]    : ランダム遭遇イベント。出勤枠タップ時に低確率で発火する短い小話。
enum EventCategory {
  common,
  individual,
  milestone,
  random,
}

/// 1 イベント内の 1 発話。
///
/// `speaker == null` の場合は地の文（主人公のモノローグ / ナレーション）扱い。
/// それ以外はキャラの台詞として表情とともに表示する。
///
/// Sprint 11: 将来のボイス追加に備えて [voiceKey] フィールドを追加（オプショナル）。
/// 既存の `EventLine(...)` 呼び出しは voiceKey 未指定で動くため後方互換。
class EventLine {
  const EventLine({
    this.speaker,
    this.expression = Expression.normal,
    required this.text,
    this.voiceKey,
  });

  /// 話者キャラ。null なら地の文 / モノローグ。
  final CharacterId? speaker;

  /// 立ち絵の表情差分（[speaker] が null のときは無視される）。
  final Expression expression;

  /// 1 発話の本文。
  final String text;

  /// 将来差し込むボイスアセットのキー。`voice.<character>.<id>` 形式を想定。
  /// null ならボイス無し（現状はすべて null）。仕様書 §13「ボイス追加」に対応する
  /// 空フィールド。AudioService に再生要求のみログとして残る形でも動作する。
  final String? voiceKey;
}

/// 1 イベント内の 1 つの選択肢。
///
/// 選んだときに走る能力値・好感度の変化は [outcome] が持つ。
/// 続きのシーン ID（[nextSceneId]）はまだ Sprint 08 では使わないが、
/// 将来「分岐 → 別スクリプトへジャンプ」を実現するために予備フィールドを置く。
class EventChoice {
  const EventChoice({
    required this.label,
    required this.outcome,
    this.nextSceneId,
  });

  final String label;
  final ChoiceOutcome outcome;
  final String? nextSceneId;
}

/// 選択肢を 1 つに集約したシーン定義。
///
/// 通常はスクリプト中の特定の位置に「選択肢シーン」が 1〜2 か所挟まる。
/// Sprint 08 ではシンプルに「スクリプトを順に表示 → 末尾で 1 度だけ選択肢」
/// の形を許容する（[GameEvent.choice] が null なら選択肢なし）。
class EventChoiceScene {
  const EventChoiceScene({
    this.prompt,
    this.promptSpeaker,
    this.promptExpression = Expression.normal,
    required this.choices,
  });

  /// 選択肢の前に表示する 1 行（任意）。
  final String? prompt;

  /// プロンプトの話者（null なら地の文）。
  final CharacterId? promptSpeaker;

  /// プロンプト時の表情。
  final Expression promptExpression;

  /// 通常 2〜4 件の選択肢。
  final List<EventChoice> choices;
}

/// 1 本のイベントを表す不変データ。
///
/// 発火条件（[fireDate] / [requiredAffinityStage] / [preferredSlot] 等）は
/// すべて任意フィールドで持ち、カテゴリごとにリゾルバ側で必要な条件のみを
/// 評価する。
///
/// 例:
/// - 共通イベント: [fireDate] のみで判定。
/// - 個別イベント: [target] + [requiredAffinityStage] (+ 任意で [preferredSlot] や
///                  [requiredMonth]) で判定。
/// - 節目イベント: [fireDate] + 「誰と過ごすか」を別 UI で選ぶ。
/// - ランダム: 確率判定のみ（リゾルバが日付・枠を見て選ぶ）。
class GameEvent {
  const GameEvent({
    required this.id,
    required this.category,
    required this.title,
    required this.locationLabel,
    required this.script,
    this.target,
    this.fireDate,
    this.requiredMonth,
    this.requiredAffinityStage,
    this.preferredSlot,
    this.choice,
    this.cgKey,
    this.cgTitle,
    this.cgCaption,
    this.unlockMessage,
  });

  /// 一意 ID。`unlockedEventIds` の重複防止キーや CG キーのプレフィックスに使う。
  final String id;

  /// 本イベントのカテゴリ。リゾルバ側のフィルタに使う。
  final EventCategory category;

  /// 画面上部に出す短いタイトル（例: 「健康診断」「写真展のおとずれ」）。
  final String title;

  /// 場所表記（例: 「会議室の隣の医務室」「商店街の小さな個展会場」）。
  final String locationLabel;

  /// 発話列。`speaker == null` で地の文を混ぜられる。
  final List<EventLine> script;

  /// 個別イベント・節目イベントで対象となるキャラ。共通/ランダムでは null。
  final CharacterId? target;

  /// 共通・節目イベントの発火日（年は使わず month/day のみで判定する）。
  final DateTime? fireDate;

  /// 個別イベントで「この月以降のみ発火可」とするための予備フィールド。
  /// null なら月縛りなし。
  final int? requiredMonth;

  /// 個別イベントの解放しきい値（表面好感度の段階：2 以上で開放など）。
  final int? requiredAffinityStage;

  /// 個別イベントで「この枠のときだけ優先発火する」場合に指定。
  /// null ならどの枠でも発火可。
  final int? preferredSlot;

  /// 末尾に挟む選択肢シーン（任意）。
  final EventChoiceScene? choice;

  /// 解放する CG のキー。null なら CG なし。
  /// 命名規約: `cg.<category>.<id>` 推奨（例: `cg.common.health_check_jun`）。
  final String? cgKey;

  /// メモリーアルバムでサムネに重ねる短いタイトル（CG の見出し）。
  final String? cgTitle;

  /// メモリーアルバムの全画面表示で下に出すキャプション（このイベントの一言説明）。
  final String? cgCaption;

  /// イベント完了直後に SnackBar 等で表示する短文（任意）。
  final String? unlockMessage;
}
