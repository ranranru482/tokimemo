import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/character_repository.dart';
import '../models/game_state.dart';
import '../models/save_snapshot.dart';

/// Sprint 09: セーブデータの永続化リポジトリ。
///
/// 設計:
/// - 手動 10 スロット (`save.slot.0` 〜 `save.slot.9`)
/// - クイック 1 スロット (`save.quick`)
/// - オート 3 スロット (`save.auto.0` 〜 `save.auto.2`) — リングバッファで上書き
/// - SharedPreferences に JSON 文字列で保存
///
/// `ChangeNotifier` を継承することで、スロット一覧画面が
/// `AnimatedBuilder(animation: repository)` で再描画できる。
///
/// 1 セーブ ≒ 5〜10 KB 想定。SharedPreferences の上限内に収まる
/// （Android: 1MB, iOS: 数 MB）。
class SaveRepository extends ChangeNotifier {
  SaveRepository._(this._prefs);

  final SharedPreferences _prefs;

  static const int manualSlotCount = 10;
  static const int autoSlotCount = 3;

  /// オートセーブの「次に書き込むべきスロット」のインデックスを保持するキー。
  static const String _autoCursorKey = 'save.auto.cursor';

  /// SharedPreferences をロードして [SaveRepository] を生成する。
  static Future<SaveRepository> load([SharedPreferences? prefsOverride]) async {
    final prefs = prefsOverride ?? await SharedPreferences.getInstance();
    return SaveRepository._(prefs);
  }

  /// テスト用: 既存の SharedPreferences モックを同期取得して構築する。
  ///
  /// `SharedPreferences.setMockInitialValues({})` 等を呼んだ後、Future を待たずに
  /// 同期的にスタブが必要なときに使う。
  /// Future ベースの SharedPreferences.getInstance を呼べないシーンで便利。
  static SaveRepository forTesting(SharedPreferences prefs) =>
      SaveRepository._(prefs);

  // ---- 単一スロットの読み書き --------------------------------------------

  /// スロットからスナップショットを読み出す。空なら null。
  SaveSnapshot? read(SaveSlotKey slot) {
    final raw = _prefs.getString(slot.prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return SaveSnapshot.fromMap(slot, decoded);
    } catch (e) {
      debugPrint('[SaveRepository] read failed for ${slot.prefsKey}: $e');
      return null;
    }
  }

  /// 現在のゲーム状態を指定スロットに書き出す。
  ///
  /// `summary` は呼び出し側で組み立てて渡してもいいが、省略時は
  /// `buildSummary(GameState)` で自動生成する。
  Future<SaveSnapshot> write(SaveSlotKey slot, GameState state,
      {DateTime? now, String? summary}) async {
    final savedAt = now ?? DateTime.now();
    final snap = SaveSnapshot(
      slot: slot,
      heroName: state.heroName,
      savedAt: savedAt,
      inGameDate: state.currentDate,
      summary: summary ?? buildSummary(state),
      payload: state.toMap(),
    );
    final encoded = jsonEncode(snap.toMap());
    await _prefs.setString(slot.prefsKey, encoded);
    notifyListeners();
    return snap;
  }

  /// 指定スロットを削除する。空スロットでも例外にはしない。
  Future<void> delete(SaveSlotKey slot) async {
    if (_prefs.containsKey(slot.prefsKey)) {
      await _prefs.remove(slot.prefsKey);
      notifyListeners();
    }
  }

  // ---- 集合アクセサ ------------------------------------------------------

  /// 手動スロット 10 件のスナップショット（空は null）。
  List<SaveSnapshot?> readAllManual() => <SaveSnapshot?>[
        for (int i = 0; i < manualSlotCount; i++) read(SaveSlotKey.manual(i)),
      ];

  /// オートスロット 3 件のスナップショット。
  List<SaveSnapshot?> readAllAuto() => <SaveSnapshot?>[
        for (int i = 0; i < autoSlotCount; i++) read(SaveSlotKey.auto(i)),
      ];

  /// クイックスロットのスナップショット。
  SaveSnapshot? readQuick() => read(SaveSlotKey.quick());

  /// 全スロットを横断して「最も新しい savedAt」のスナップショットを返す。
  /// タイトル画面の「つづきから」で開始位置を示すために使う。
  SaveSnapshot? readLatest() {
    SaveSnapshot? best;
    for (final s in [
      readQuick(),
      ...readAllManual(),
      ...readAllAuto(),
    ]) {
      if (s == null) continue;
      if (best == null || s.savedAt.isAfter(best.savedAt)) {
        best = s;
      }
    }
    return best;
  }

  /// 全スロットを消去する（タイトル「データ初期化」用）。
  Future<void> clearAll() async {
    for (int i = 0; i < manualSlotCount; i++) {
      await _prefs.remove(SaveSlotKey.manual(i).prefsKey);
    }
    await _prefs.remove(SaveSlotKey.quick().prefsKey);
    for (int i = 0; i < autoSlotCount; i++) {
      await _prefs.remove(SaveSlotKey.auto(i).prefsKey);
    }
    await _prefs.remove(_autoCursorKey);
    notifyListeners();
  }

  // ---- オートセーブ（リングバッファ） ----------------------------------

  /// 次に書き込むオートスロット番号を返す（0..autoSlotCount-1）。
  int peekAutoCursor() =>
      (_prefs.getInt(_autoCursorKey) ?? 0) % autoSlotCount;

  /// オートセーブを 1 件書き込む。
  ///
  /// リングバッファとして 0 → 1 → 2 → 0 → ... と巡回する。
  /// 戻り値は書き込んだスナップショット。
  Future<SaveSnapshot> writeAuto(GameState state,
      {DateTime? now, String? summary}) async {
    final idx = peekAutoCursor();
    final slot = SaveSlotKey.auto(idx);
    final snap =
        await write(slot, state, now: now, summary: summary);
    await _prefs.setInt(_autoCursorKey, (idx + 1) % autoSlotCount);
    return snap;
  }

  // ---- サマリー文字列 ---------------------------------------------------

  /// 「7月12日 / 体力80 / 出会い済3名」のような 1 行を生成する。
  static String buildSummary(GameState state) {
    final d = state.currentDate;
    final metCount = <int>[
      for (final c in CharacterRepository.all)
        if (state.hasMet(c.id)) 1,
    ].length;
    return '${d.month}月${d.day}日 / 体力${state.vitality} / 出会い済$metCount名';
  }
}
