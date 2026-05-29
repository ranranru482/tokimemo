import 'package:flutter/foundation.dart';

import '../data/gift_catalog.dart';
import 'gift_item.dart';

/// Sprint 12: 主人公の所持アイテム（プレゼント）の在庫管理。
///
/// 仕様書 Sprint 12「ショップ画面で購入したプレゼントが所持アイテム一覧に
/// 追加される」を支えるデータ。
///
/// 構造:
/// - `Map<String, int>` (item id → 個数)。0 個になったらキーを削除。
/// - ChangeNotifier を継承し、購入・消費で AnimatedBuilder に再描画させる。
/// - JSON シリアライズで SaveSnapshot に同梱（SaveRepository が JSON 化）。
class Inventory extends ChangeNotifier {
  Inventory({Map<String, int>? initial}) {
    if (initial != null) {
      initial.forEach((id, qty) {
        if (qty > 0) _items[id] = qty;
      });
    }
  }

  final Map<String, int> _items = <String, int>{};

  /// 全アイテムの所持マップ（読み取り専用ビュー）。
  Map<String, int> get items => Map<String, int>.unmodifiable(_items);

  /// 全アイテムの合計所持数。
  int get totalCount {
    int sum = 0;
    for (final qty in _items.values) {
      sum += qty;
    }
    return sum;
  }

  /// 1 アイテムの所持数（未所持は 0）。
  int countOf(String itemId) => _items[itemId] ?? 0;

  /// 所持しているかどうか（個数 > 0）。
  bool has(String itemId) => countOf(itemId) > 0;

  /// アイテムを 1 つ追加する（[delta] が正なら加算、負なら減算）。
  /// 在庫数が 0 以下になればキーを削除する。
  void bump(String itemId, int delta) {
    if (delta == 0) return;
    final next = (_items[itemId] ?? 0) + delta;
    if (next <= 0) {
      _items.remove(itemId);
    } else {
      _items[itemId] = next;
    }
    notifyListeners();
  }

  /// 1 アイテムを 1 つ追加（ショップ購入で 1 回呼ぶ）。
  void add(String itemId) => bump(itemId, 1);

  /// 1 アイテムを 1 つ消費（将来「渡す」UI 実装時に使う想定）。
  /// 在庫不足なら false を返し、状態は変えない。
  bool consume(String itemId) {
    final cur = _items[itemId] ?? 0;
    if (cur <= 0) return false;
    bump(itemId, -1);
    return true;
  }

  /// セーブデータの初期化等で全消去する。
  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  /// 所持アイテムを GiftItem 解決済みのリストとして返す（順序は GiftCatalog 宣言順）。
  /// カタログに無い ID（古いセーブデータ等）は除外する。
  List<InventoryEntry> resolvedEntries() {
    final result = <InventoryEntry>[];
    for (final gift in GiftCatalog.all) {
      final qty = countOf(gift.id);
      if (qty > 0) {
        result.add(InventoryEntry(gift: gift, quantity: qty));
      }
    }
    return result;
  }

  // ---- シリアライズ ------------------------------------------------------

  /// SaveSnapshot 用の JSON 化（純粋な Map）。
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      for (final entry in _items.entries) entry.key: entry.value,
    };
  }

  /// SaveSnapshot からの復元。既存内容は破棄して上書きする。
  void restoreFromMap(Map<String, dynamic> map) {
    _items.clear();
    map.forEach((key, value) {
      if (value is int && value > 0) {
        _items[key] = value;
      }
    });
    notifyListeners();
  }
}

/// `Inventory.resolvedEntries` の戻り値。
@immutable
class InventoryEntry {
  const InventoryEntry({required this.gift, required this.quantity});
  final GiftItem gift;
  final int quantity;
}
