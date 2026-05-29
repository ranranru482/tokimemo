import 'package:flutter/foundation.dart';

import 'character.dart';

/// Sprint 12: ショップで購入できるプレゼント（贈答品）1 種類。
///
/// 仕様書 Sprint 12 「ショップ画面（基礎枠のみ・ゲーム内通貨でプレゼント購入）」
/// の最小単位データ。
///
/// 設計指針:
/// - 商品名・説明は **完全オリジナル**。既存 IP（ときめきメモリアル等）の
///   贈答品名・台詞・キャラ固有名詞には依存しない。社会人向けに違和感のない
///   無難な汎用商品（花束 / 本 / 紅茶 / コーヒー豆 / プロテイン 等）を採用。
/// - `targetCharacterId` が null なら **全員に有効** な汎用品。
///   非 null の場合「このキャラに渡すと追加好感度ボーナス」が乗る贈り物。
/// - `affinityBonus` は将来「キャラに渡す」UI を実装した際に
///   `applyChoiceOutcome` 等に流す値（Sprint 12 範囲では「購入と所持」までを
///   実装し、「渡す」UI は未実装）。
/// - 価格は所持金（円単位）に対する自然なバランス感（800〜2500円）。
///
/// 「渡す」UI は Sprint 12 受け入れ基準 4 の範囲外（仕様メモ「基礎枠のみ」）。
/// 本クラスは即時の購入と所持アイテム一覧のみを支える。
@immutable
class GiftItem {
  const GiftItem({
    required this.id,
    required this.displayName,
    required this.price,
    required this.description,
    this.targetCharacterId,
    this.affinityBonus,
  });

  /// 一意 ID（セーブデータ・所持数マップのキー用）。
  final String id;

  /// 画面表示用の商品名（オリジナル）。
  final String displayName;

  /// 円単位の価格。
  final int price;

  /// 商品カードの説明文（1〜2 行）。
  final String description;

  /// この商品のターゲットキャラ（任意）。null なら汎用品。
  final CharacterId? targetCharacterId;

  /// 「ターゲットキャラに渡したとき」のボーナス好感度。
  /// Sprint 12 範囲では「渡す」UI 未実装のため購入と所持のみが利用する。
  /// 将来 `applyChoiceOutcome` 等に渡す値として保持する。
  final int? affinityBonus;
}
