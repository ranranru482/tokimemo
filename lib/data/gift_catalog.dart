/// Sprint 12: ショップで購入できるプレゼント一覧。
///
/// 仕様書 Sprint 12 設計指針に従い、汎用品 + キャラ別の好み品を取り混ぜた
/// 9 種類を定義する。すべて **完全オリジナル** の商品名・説明文：
/// 既存 IP の固有商品名（クマのぬいぐるみ / お守り / etc）は使用しない。
///
/// 命名規約: `gift.<short_id>`（保存データ・所持マップキーで使う）。
library;

import '../models/character.dart';
import '../models/gift_item.dart';

class GiftCatalog {
  GiftCatalog._();

  /// 商品一覧。順序はショップ画面のグリッド表示順を兼ねる。
  static const List<GiftItem> all = <GiftItem>[
    // --- 汎用品（全員有効） ---
    GiftItem(
      id: 'gift.sweets',
      displayName: '焼き菓子の詰め合わせ',
      price: 800,
      description: '街の洋菓子店のごく普通の詰め合わせ。誰に渡しても無難。',
    ),
    GiftItem(
      id: 'gift.hand_cream',
      displayName: 'ハンドクリーム',
      price: 1200,
      description: '無香料の保湿クリーム。冬場の小さな気遣いに。',
    ),
    GiftItem(
      id: 'gift.fragrance_pouch',
      displayName: '香り袋',
      price: 1500,
      description: 'ほのかに香る巾着型のサシェ。机の引き出しに忍ばせる用。',
    ),
    GiftItem(
      id: 'gift.bouquet',
      displayName: '小ぶりの花束',
      price: 1500,
      description: '駅前の花屋で見繕った季節の花束。気軽に渡せる量。',
      affinityBonus: 1,
    ),

    // --- キャラ別の好み品 ---
    GiftItem(
      id: 'gift.book',
      displayName: '文芸文庫',
      price: 2000,
      description: '昨年の文学賞候補に上がった作品の文庫版。',
      targetCharacterId: CharacterId.uta, // 久遠：出版社編集者
      affinityBonus: 2,
    ),
    GiftItem(
      id: 'gift.coffee_beans',
      displayName: 'スペシャルティ珈琲豆',
      price: 1800,
      description: '産地違いの小袋セット。試作の合間に味わいたくなる配合。',
      targetCharacterId: CharacterId.akari, // 七瀬：カフェ研究員
      affinityBonus: 2,
    ),
    GiftItem(
      id: 'gift.tech_magazine',
      displayName: 'スポーツ専門誌',
      price: 2500,
      description: '今月号は最新ランニングギア特集。仕事帰りの読み物に。',
      targetCharacterId: CharacterId.toru, // 鴻巣：スポーツメーカー営業
      affinityBonus: 2,
    ),
    GiftItem(
      id: 'gift.tea_set',
      displayName: '紅茶セット',
      price: 2200,
      description: '茶葉 3 種とリーフディフューザの組み合わせ。深夜の作業の一杯に。',
      targetCharacterId: CharacterId.sayo, // 蓮見：デザイナー（紅茶派）
      affinityBonus: 2,
    ),
    GiftItem(
      id: 'gift.protein',
      displayName: 'ギター弦セット',
      price: 1500,
      description: '定番ゲージの替え弦 3 セット。試奏や練習の消耗品に。',
      targetCharacterId: CharacterId.yui, // 槙原：楽器店スタッフ
      affinityBonus: 2,
    ),
  ];

  /// ID から取得（未定義は null）。
  static GiftItem? byId(String id) {
    for (final g in all) {
      if (g.id == id) return g;
    }
    return null;
  }
}
