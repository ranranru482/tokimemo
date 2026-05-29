import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/data/gift_catalog.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/gift_item.dart';
import 'package:tokimemo/models/inventory.dart';

/// Sprint 12: Inventory モデルの単体テスト。
///
/// 受け入れ基準4 の補強: 「所持アイテム一覧」の根幹データが
/// 追加・減少・保存復元すべてに対応していることを確認する。
void main() {
  group('Inventory: 基本操作', () {
    test('初期状態は空（countOf=0 / totalCount=0 / has=false）', () {
      final inv = Inventory();
      expect(inv.countOf('gift.bouquet'), 0);
      expect(inv.totalCount, 0);
      expect(inv.has('gift.bouquet'), isFalse);
    });

    test('add で +1 され、countOf / totalCount に反映される', () {
      final inv = Inventory();
      inv.add('gift.bouquet');
      expect(inv.countOf('gift.bouquet'), 1);
      expect(inv.totalCount, 1);
      expect(inv.has('gift.bouquet'), isTrue);
    });

    test('同じ ID を複数回 add すれば加算される', () {
      final inv = Inventory();
      inv.add('gift.bouquet');
      inv.add('gift.bouquet');
      inv.add('gift.bouquet');
      expect(inv.countOf('gift.bouquet'), 3);
      expect(inv.totalCount, 3);
    });

    test('複数 ID を扱える', () {
      final inv = Inventory();
      inv.add('gift.bouquet');
      inv.add('gift.book');
      inv.add('gift.book');
      expect(inv.totalCount, 3);
      expect(inv.countOf('gift.bouquet'), 1);
      expect(inv.countOf('gift.book'), 2);
    });

    test('consume で -1 され、在庫不足は false を返す', () {
      final inv = Inventory();
      inv.add('gift.bouquet');
      expect(inv.consume('gift.bouquet'), isTrue);
      expect(inv.countOf('gift.bouquet'), 0);
      expect(inv.consume('gift.bouquet'), isFalse);
    });

    test('bump で負値を渡すと減算、0 以下になればキー削除', () {
      final inv = Inventory();
      inv.bump('gift.sweets', 3);
      expect(inv.items.containsKey('gift.sweets'), isTrue);
      inv.bump('gift.sweets', -5);
      expect(inv.items.containsKey('gift.sweets'), isFalse);
      expect(inv.totalCount, 0);
    });

    test('clear で全消去 + notifyListeners 発火', () {
      final inv = Inventory();
      inv.add('gift.bouquet');
      inv.add('gift.book');
      int notified = 0;
      inv.addListener(() => notified++);
      inv.clear();
      expect(inv.totalCount, 0);
      expect(notified, 1);
    });
  });

  group('Inventory: resolvedEntries', () {
    test('GiftCatalog 宣言順で並ぶ', () {
      final inv = Inventory();
      // 宣言順の後ろの方から先に add する
      inv.add('gift.protein');
      inv.add('gift.bouquet');
      final entries = inv.resolvedEntries();
      // GiftCatalog.all は sweets/hand_cream/fragrance_pouch/bouquet/book/.../protein の順
      // 取得したエントリは bouquet が protein より先に来るはず。
      final ids = entries.map((e) => e.gift.id).toList();
      expect(ids.indexOf('gift.bouquet'), lessThan(ids.indexOf('gift.protein')));
    });

    test('GiftCatalog に無い ID はスキップされる', () {
      final inv = Inventory(initial: {'gift.unknown_legacy_id': 5});
      expect(inv.resolvedEntries(), isEmpty);
      // ただし内部マップには残るので totalCount は 5。
      expect(inv.totalCount, 5);
    });

    test('quantity が正しく入っている', () {
      final inv = Inventory();
      inv.bump('gift.book', 4);
      final entries = inv.resolvedEntries();
      expect(entries, hasLength(1));
      expect(entries.first.quantity, 4);
      expect(entries.first.gift.id, 'gift.book');
    });
  });

  group('Inventory: シリアライズ往復', () {
    test('toMap → restoreFromMap で完全に復元される', () {
      final inv = Inventory();
      inv.add('gift.bouquet');
      inv.bump('gift.book', 3);
      final map = inv.toMap();

      final restored = Inventory();
      restored.restoreFromMap(map);
      expect(restored.countOf('gift.bouquet'), 1);
      expect(restored.countOf('gift.book'), 3);
      expect(restored.totalCount, 4);
    });

    test('restoreFromMap の前に保持していたデータは消える', () {
      final inv = Inventory();
      inv.add('gift.bouquet');
      inv.restoreFromMap({'gift.book': 2});
      expect(inv.countOf('gift.bouquet'), 0);
      expect(inv.countOf('gift.book'), 2);
    });

    test('restoreFromMap で 0 以下の値は無視される', () {
      final inv = Inventory();
      inv.restoreFromMap({'gift.book': 0, 'gift.bouquet': -2, 'gift.sweets': 4});
      expect(inv.countOf('gift.book'), 0);
      expect(inv.countOf('gift.bouquet'), 0);
      expect(inv.countOf('gift.sweets'), 4);
    });
  });

  group('GiftCatalog: メタ整合性', () {
    test('全商品 9 件、price は正の整数', () {
      expect(GiftCatalog.all, hasLength(9));
      for (final g in GiftCatalog.all) {
        expect(g.price, greaterThan(0), reason: '${g.id} price=${g.price}');
        expect(g.displayName, isNotEmpty);
        expect(g.description, isNotEmpty);
      }
    });

    test('byId で取得できる', () {
      final g = GiftCatalog.byId('gift.bouquet');
      expect(g, isNotNull);
      expect(g!.displayName, '小ぶりの花束');
    });

    test('byId で未定義は null', () {
      expect(GiftCatalog.byId('gift.nonexistent'), isNull);
    });

    test('キャラ別商品が 5 キャラ分揃っている', () {
      final targetCounts = <CharacterId, int>{};
      for (final g in GiftCatalog.all) {
        final t = g.targetCharacterId;
        if (t != null) {
          targetCounts[t] = (targetCounts[t] ?? 0) + 1;
        }
      }
      for (final c in CharacterId.values) {
        expect(targetCounts[c] ?? 0, greaterThanOrEqualTo(1),
            reason: '$c 向け商品が見つからない');
      }
    });

    test('GiftItem は @immutable コンパイル時アノテーション持ち', () {
      const g = GiftItem(
        id: 'x',
        displayName: 'x',
        price: 1,
        description: 'x',
      );
      expect(g.targetCharacterId, isNull);
      expect(g.affinityBonus, isNull);
    });
  });
}
