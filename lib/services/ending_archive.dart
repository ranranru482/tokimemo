import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ending.dart';

/// Sprint 09: エンディング達成履歴の永続化リポジトリ。
///
/// SharedPreferences のキー `ending.archive` に JSON 文字列で保存する。
/// データ形式（バージョニング前提）:
/// ```
/// {
///   "version": 1,
///   "entries": [
///     { "kind": "ending.akari", "achievedAt": "2027-03-31T20:00:00.000" },
///     ...
///   ]
/// }
/// ```
///
/// 1 種類の ED に複数回到達した場合は「最も古い達成日時」を保持する（初回達成）。
/// `EndingArchive` 自体は ChangeNotifier として再描画通知を発火する。
class EndingArchive extends ChangeNotifier {
  EndingArchive._(this._prefs, Map<EndingKind, EndingArchiveEntry> initial)
      : _entries = Map<EndingKind, EndingArchiveEntry>.from(initial);

  /// テスト・実装用に注入可能な SharedPreferences。
  final SharedPreferences _prefs;

  /// 達成済 ED の Map。キーは [EndingKind]。
  final Map<EndingKind, EndingArchiveEntry> _entries;

  static const String _prefsKey = 'ending.archive';
  static const int _schemaVersion = 1;

  /// SharedPreferences からロードして [EndingArchive] を生成する。
  static Future<EndingArchive> load([SharedPreferences? prefsOverride]) async {
    final prefs = prefsOverride ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final initial = <EndingKind, EndingArchiveEntry>{};
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final list = decoded['entries'];
          if (list is List) {
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final entry = EndingArchiveEntry.fromMap(item);
                if (entry != null) {
                  initial.putIfAbsent(entry.kind, () => entry);
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[EndingArchive] decode failed, dropping data: $e');
        // 壊れたデータは破棄して空アーカイブで起動。
      }
    }
    return EndingArchive._(prefs, initial);
  }

  /// 達成済 ED の一覧（読み取り専用）。
  Map<EndingKind, EndingArchiveEntry> get entries =>
      Map<EndingKind, EndingArchiveEntry>.unmodifiable(_entries);

  /// 指定 ED が達成済みかどうか。
  bool isAchieved(EndingKind kind) => _entries.containsKey(kind);

  /// 達成済 ED 数。
  int get achievedCount => _entries.length;

  /// ED を達成記録に追加する。既に達成済みなら何もしない（初回達成のみ保持）。
  Future<void> recordAchievement(EndingKind kind, DateTime achievedAt) async {
    if (_entries.containsKey(kind)) return;
    _entries[kind] = EndingArchiveEntry(kind: kind, achievedAt: achievedAt);
    await _persist();
    notifyListeners();
  }

  /// 達成履歴を全消去する（タイトル「データ初期化」用）。
  Future<void> clear() async {
    if (_entries.isEmpty) return;
    _entries.clear();
    await _prefs.remove(_prefsKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    final payload = <String, dynamic>{
      'version': _schemaVersion,
      'entries': [for (final e in _entries.values) e.toMap()],
    };
    await _prefs.setString(_prefsKey, jsonEncode(payload));
  }
}
