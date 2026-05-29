import 'package:flutter/material.dart';

/// 攻略対象キャラの識別子。spec.md §5 に定義された 5 名に対応する。
///
/// ID は spec のローマ字名に由来：
/// - akari → 七瀬 灯 (Nanase Akari)
/// - uta   → 久遠 詩 (Kuon Uta)
/// - toru  → 鴻巣 透 (Kounosu Toru)
/// - sayo  → 蓮見 紗夜 (Hasumi Sayo)
/// - yui   → 槙原 結衣 (Makihara Yui)
///
/// 各 enum 値の宣言順は「キャラ一覧画面のグリッド表示順」も兼ねる。
enum CharacterId {
  akari,
  uta,
  toru,
  sayo,
  yui,
}

/// キャラの立ち絵に持たせる表情差分。
///
/// 仕様書 Sprint 06 の受け入れ基準5「立ち絵の表情差分（通常/笑顔/困惑）」に対応。
/// 後で実イラスト（`assets/characters/[id]_[expression].png` 等）に差し替えやすい
/// よう、enum 値の name はファイル名候補としてそのまま使える形にしてある。
enum Expression {
  normal,
  smile,
  troubled,
}

/// 攻略対象キャラ 1 名分の静的データ。
///
/// 「静的」とはゲーム進行で変化しないプロフィール情報を指す。
/// 出会い済みフラグや好感度などの「実行時に変化する状態」は
/// [CharacterState] 側で管理する（責務分割）。
///
/// 立ち絵については現時点で実画像が無いため、`CharacterPortrait` ウィジェットが
/// `themeColor` + イニシャル + 表情アイコンで擬似描画する。実イラスト導入時は
/// `assetPath` フィールドの将来追加で対応する（コメントで明記）。
@immutable
class Character {
  const Character({
    required this.id,
    required this.displayName,
    required this.age,
    required this.roleLabel,
    required this.bioShort,
    required this.bioLong,
    required this.appealText,
    required this.firstMeetDate,
    required this.themeColor,
  });

  /// キャラの一意 ID。`CharacterState` のキーや出会いイベントの参照にも使う。
  final CharacterId id;

  /// 画面に表示される正式名（例: 「七瀬 灯」）。spec.md §5 に準拠。
  final String displayName;

  /// 年齢。spec.md §5 の各キャラ定義に準拠。
  final int age;

  /// 役職/関係を示す短い 1 行（例: 「同社・別部署の先輩 / 30歳・マーケティング職」）。
  /// キャラ一覧カードの 2 行目に表示する。
  final String roleLabel;

  /// 短いバイオ（1 行）。キャラ一覧カードのサブテキストに使う。
  final String bioShort;

  /// 長いバイオ（spec の背景5行ぶん）。詳細画面のプロフィール本文に使う。
  final String bioLong;

  /// 魅力テキスト。spec の「魅力」項目に対応。詳細画面で表示。
  final String appealText;

  /// 出会いイベントの発火日。日付が一致したら自動的に出会いイベントが起動する。
  /// 年は 2026 で固定（GameState の `_defaultStartDate` と整合）。
  final DateTime firstMeetDate;

  /// キャラ固有のカラー（立ち絵プレースホルダの背景・カードのアクセント）。
  ///
  /// 実イラスト導入時はあくまで「テーマ色」として残し、ハートの色や
  /// イベントポップアップのアクセントなどに使い回せる。
  final Color themeColor;

  /// 立ち絵の表示に使う 1 文字（displayName 先頭の漢字）。
  ///
  /// プレースホルダ Widget 専用。実イラスト導入後は不要になるが、フォールバック
  /// 表示のために残しておく予定。
  String get initial {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first;
  }
}
