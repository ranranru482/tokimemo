import 'package:flutter/material.dart';

import '../models/character.dart';

/// spec.md §5 に定義された 5 名のキャラデータ。
///
/// 値の出所はすべて spec.md §5（役割/関係・背景・魅力）に基づく。
/// プレースホルダ立ち絵で使う `themeColor` のみオリジナル割当。
///
/// `firstMeetDate` は Sprint 06 仕様の指示に従って 4/10、4/15、4/20、5/5、5/10
/// の 5 日程に散らしてある（特定日 AND 条件のテスト容易化のためすべて散らす）。
/// 年は GameState の `_defaultStartDate` と整合させて 2026 固定。
class CharacterRepository {
  CharacterRepository._();

  /// 5 名のキャラを宣言順に並べた不変リスト。
  ///
  /// 並び順 = キャラ一覧画面のグリッド表示順。
  static final List<Character> all = List<Character>.unmodifiable(<Character>[
    Character(
      id: CharacterId.akari,
      displayName: '七瀬 灯',
      age: 25,
      roleLabel: 'よく通うカフェの商品開発担当 / カフェ研究員',
      bioShort: '珈琲と新メニュー開発に情熱を注ぐ研究肌。試作に没頭すると周りが見えなくなる。',
      bioLong:
          'カフェの商品開発を担うカフェ研究員。豆の産地や抽出の探求に真摯で、'
          '新作の試作に没頭すると時間を忘れる。仕事には妥協しないが、'
          'ふと見せる無防備な笑顔とのギャップがある。',
      appealText:
          '真剣に珈琲を語るときの熱量と、ふと見せる無防備な笑顔のギャップ。',
      firstMeetDate: DateTime(2026, 4, 10),
      themeColor: Color(0xFFB66E5C), // テラコッタ
    ),
    Character(
      id: CharacterId.uta,
      displayName: '久遠 詩',
      age: 27,
      roleLabel: '本づくりに携わる出版社編集者',
      bioShort: '言葉を扱う編集者。締切に追われつつ、作り手に寄り添う。',
      bioLong:
          '出版社の編集者として作り手に寄り添う日々。締切に追われながらも、'
          '人の言葉を丁寧にすくい上げる。表向きは穏やかだが芯は強く、'
          '自分の本音はなかなか出さない不器用さがある。',
      appealText: '人の言葉を丁寧にすくい上げる聞き上手さと、自分の本音は出さない不器用さ。',
      firstMeetDate: DateTime(2026, 4, 15),
      themeColor: Color(0xFF5E8D7A), // モスグリーン
    ),
    Character(
      id: CharacterId.toru,
      displayName: '鴻巣 透',
      age: 26,
      roleLabel: 'スポーツメーカーの営業',
      bioShort: 'フットワークの軽い体育会系営業。ぶっきらぼうだが面倒見が良い。',
      bioLong:
          'スポーツメーカーの営業として各地を飛び回る。体育会系でフットワークが軽く誠実。'
          'ぶっきらぼうに見えて面倒見が良く、距離が縮まると不器用な優しさを見せる。',
      appealText: '距離が縮まると見せる、不器用だが本気の優しさ。連絡のレスポンスが速い。',
      firstMeetDate: DateTime(2026, 4, 20),
      themeColor: Color(0xFF4C6B9A), // インディゴブルー
    ),
    Character(
      id: CharacterId.sayo,
      displayName: '蓮見 紗夜',
      age: 28,
      roleLabel: '視覚表現を手がけるデザイナー',
      bioShort: 'クールで美意識の高いデザイナー。夜型で大人の余裕を纏う。',
      bioLong:
          '視覚表現を手がけるデザイナー。美意識が高くクールで、夜型の生活リズム。'
          '仕事には完璧主義だが、ふいに繊細さと、過去への踏み込めない距離感を'
          '覗かせる。',
      appealText: '大人の余裕と、それでも踏み込めない過去への影。',
      firstMeetDate: DateTime(2026, 5, 5),
      themeColor: Color(0xFF6F4F8C), // モーブ
    ),
    Character(
      id: CharacterId.yui,
      displayName: '槙原 結衣',
      age: 24,
      roleLabel: '楽器店スタッフ / 最年少',
      bioShort: '音楽好きで明るい楽器店スタッフ。接客上手でまっすぐ。',
      bioLong:
          '楽器店で働く最年少スタッフ。音楽が好きで明るく前向き、接客も上手い。'
          'ストレートな物言いで、好きな音楽の話になると止まらなくなる。'
          '何かを成し遂げたいという前向きな野心を秘めている。',
      appealText: 'ストレートな言葉と、好きな音楽を共有する時間の心地よさ。',
      firstMeetDate: DateTime(2026, 5, 10),
      themeColor: Color(0xFFC97A3F), // オレンジゴールド
    ),
  ]);

  /// ID 引きでキャラを取得する。存在しなければ例外。
  static Character byId(CharacterId id) {
    return all.firstWhere(
      (c) => c.id == id,
      orElse: () => throw ArgumentError('Unknown CharacterId: $id'),
    );
  }
}
