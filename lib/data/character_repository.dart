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
      age: 30,
      roleLabel: '同社・別部署の先輩 / マーケティング職',
      bioShort: '仕事中はクール、休日は柔らかい笑顔。フィルムカメラを大切にしている。',
      bioLong:
          '地方出身、上京して8年目。仕事はできるが家庭の事情で結婚を急かされており、'
          '転職と恋愛の狭間で揺れている。学生時代は写真部で、'
          '今もフィルムカメラを大切にしている。',
      appealText:
          '仕事中はクールで隙がないが、休日に偶然会うと別人のように柔らかい笑顔を見せるギャップ。',
      firstMeetDate: DateTime(2026, 4, 10),
      themeColor: Color(0xFFB66E5C), // テラコッタ
    ),
    Character(
      id: CharacterId.uta,
      displayName: '久遠 詩',
      age: 28,
      roleLabel: '通勤路の個人経営カフェ店長',
      bioShort: '元音楽出版社勤務。閉店後は自作曲を書いている。',
      bioLong:
          '元音楽出版社勤務で、3年前に独立して開業。閉店後は自作曲を書いており、'
          'いつか自分の名前で配信したいと考えている。表向きは明るいが、'
          '開業資金の借入返済に追われている。',
      appealText: '朝の珈琲を覚えてくれる気遣いと、夜に弾き語る素の彼女との温度差。',
      firstMeetDate: DateTime(2026, 4, 15),
      themeColor: Color(0xFF5E8D7A), // モスグリーン
    ),
    Character(
      id: CharacterId.toru,
      displayName: '鴻巣 透',
      age: 26,
      roleLabel: '取引先のシステム会社エンジニア',
      bioShort: '表面はぶっきらぼう、論理的で誠実。週末はソロキャンプ派。',
      bioLong:
          '表面上はぶっきらぼうだが論理的で誠実。前職でメンタルを崩した経験があり、'
          '仕事と私生活の線引きに敏感。週末はソロキャンプとガジェット弄りが趣味。',
      appealText: '距離が縮まると見せる、不器用だが本気の優しさ。LINEの返信が異常に速い。',
      firstMeetDate: DateTime(2026, 4, 20),
      themeColor: Color(0xFF4C6B9A), // インディゴブルー
    ),
    Character(
      id: CharacterId.sayo,
      displayName: '蓮見 紗夜',
      age: 34,
      roleLabel: 'マンションの隣人 / フリーランス翻訳家',
      bioShort: '一度結婚して離婚した経験あり。猫を3匹飼っており夜型。',
      bioLong:
          '一度結婚して離婚した経験あり。猫を3匹飼っており、生活は質素だが'
          '本棚と紅茶への投資は惜しまない。夜型で深夜の廊下で偶然会うことから'
          '関係が始まる。',
      appealText: '大人の余裕と、それでも踏み込めない過去への影。',
      firstMeetDate: DateTime(2026, 5, 5),
      themeColor: Color(0xFF6F4F8C), // モーブ
    ),
    Character(
      id: CharacterId.yui,
      displayName: '槙原 結衣',
      age: 24,
      roleLabel: 'ジムのパーソナルトレーナー',
      bioShort: '元アスリート、SNSのフォロワーが多い。明るく前向き。',
      bioLong:
          '元アスリート、競技引退後に転身。明るく前向きだが、'
          '過去の挫折からくる「もう一度何かを成し遂げたい」という野心を秘めている。'
          'SNSのフォロワーが多い。',
      appealText: 'ストレートな言葉と、トレーニング後の達成感を共有できる時間。',
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
