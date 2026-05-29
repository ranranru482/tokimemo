/// Sprint 09: セーブスロット 1 件分のメタデータ + 本体スナップショット。
///
/// `SaveRepository` が JSON 化/復元する単位。
/// メタとペイロードを分けることで、スロット一覧画面が「重い本体を読まずに
/// メタだけ取得」できるよう設計してある（実装上は同じ JSON 内に同居しているが、
/// 取り出し時の型を分けている）。
library;

/// セーブの種別。スロット番号・キー命名と組み合わせて SharedPreferences の
/// キー解決に使う。
///
/// 命名規約:
/// - manual:   `save.slot.0` 〜 `save.slot.9`
/// - quick:    `save.quick`
/// - auto:     `save.auto.0` 〜 `save.auto.2`（リングバッファ）
enum SaveSlotKind {
  manual,
  quick,
  auto,
}

/// セーブスロットの「どの種類・どの番号か」を一意に表す。
class SaveSlotKey {
  const SaveSlotKey({required this.kind, this.index = 0});

  factory SaveSlotKey.manual(int index) =>
      SaveSlotKey(kind: SaveSlotKind.manual, index: index);
  factory SaveSlotKey.quick() => const SaveSlotKey(kind: SaveSlotKind.quick);
  factory SaveSlotKey.auto(int index) =>
      SaveSlotKey(kind: SaveSlotKind.auto, index: index);

  final SaveSlotKind kind;
  final int index;

  /// SharedPreferences の文字列キー。
  String get prefsKey {
    switch (kind) {
      case SaveSlotKind.manual:
        return 'save.slot.$index';
      case SaveSlotKind.quick:
        return 'save.quick';
      case SaveSlotKind.auto:
        return 'save.auto.$index';
    }
  }

  /// 画面表示用のラベル（例: 「スロット1」「クイックセーブ」「オート3」）。
  String get displayLabel {
    switch (kind) {
      case SaveSlotKind.manual:
        return 'スロット${index + 1}';
      case SaveSlotKind.quick:
        return 'クイックセーブ';
      case SaveSlotKind.auto:
        return 'オートセーブ${index + 1}';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SaveSlotKey && other.kind == kind && other.index == index;

  @override
  int get hashCode => Object.hash(kind, index);
}

/// 1 件分のセーブデータ（メタ + ペイロード本体）。
class SaveSnapshot {
  const SaveSnapshot({
    required this.slot,
    required this.heroName,
    required this.savedAt,
    required this.inGameDate,
    required this.summary,
    required this.payload,
  });

  /// このスナップショットが属するスロット。
  final SaveSlotKey slot;

  /// 主人公名（スロット一覧の主表示）。
  final String heroName;

  /// 実時間のセーブ日時。
  final DateTime savedAt;

  /// ゲーム内日付。
  final DateTime inGameDate;

  /// 1 行サマリー（例: 「7月12日 / 体力80 / 出会い済3名」）。
  final String summary;

  /// GameState の `toMap` の中身。スロット復元時に直接 `restoreFromMap` に流す。
  final Map<String, dynamic> payload;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'version': 1,
        'heroName': heroName,
        'savedAt': savedAt.toIso8601String(),
        'inGameDate': inGameDate.toIso8601String(),
        'summary': summary,
        'payload': payload,
      };

  /// JSON Map → SaveSnapshot。`slot` は呼び出し側で渡す（キー由来のため）。
  static SaveSnapshot? fromMap(
      SaveSlotKey slot, Map<String, dynamic> map) {
    final savedAtStr = map['savedAt'] as String?;
    final inGameDateStr = map['inGameDate'] as String?;
    final summary = map['summary'] as String?;
    final heroName = map['heroName'] as String?;
    final payloadDyn = map['payload'];
    if (savedAtStr == null ||
        inGameDateStr == null ||
        summary == null ||
        heroName == null ||
        payloadDyn is! Map) {
      return null;
    }
    final savedAt = DateTime.tryParse(savedAtStr);
    final inGameDate = DateTime.tryParse(inGameDateStr);
    if (savedAt == null || inGameDate == null) return null;
    return SaveSnapshot(
      slot: slot,
      heroName: heroName,
      savedAt: savedAt,
      inGameDate: inGameDate,
      summary: summary,
      payload: payloadDyn.cast<String, dynamic>(),
    );
  }
}
