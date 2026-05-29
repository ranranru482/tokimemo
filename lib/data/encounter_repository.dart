import '../models/character.dart';
import '../models/encounter.dart';
import 'character_repository.dart';

/// 5 名分の最初の出会いイベント定義。
///
/// 発火日は [CharacterRepository] の各 `firstMeetDate` と 1:1 で対応する。
/// 紹介テキストは spec.md §5 の各キャラ背景に基づくオリジナル短文。
/// 既存IP（ときめきメモリアル等）の台詞・固有名詞は使用していない。
class EncounterRepository {
  EncounterRepository._();

  /// 5 本の出会いイベント。順序は CharacterId の宣言順。
  static final List<EncounterEvent> all =
      List<EncounterEvent>.unmodifiable(<EncounterEvent>[
    // 七瀬 灯（4/10 金）— 同社・別部署の先輩
    EncounterEvent(
      targetId: CharacterId.akari,
      fireDate: CharacterRepository.byId(CharacterId.akari).firstMeetDate,
      locationLabel: '会社のエレベーターホール',
      lines: const [
        DialogueLine(
          Expression.normal,
          '——あ。新しく入った人？ 別部署だけど、勉強会で見かけたことがある気がする。',
        ),
        DialogueLine(
          Expression.smile,
          '私はマーケの七瀬。よろしくね。困ったら声かけて、答えられる範囲で答えるから。',
        ),
        DialogueLine(
          Expression.normal,
          '——あ、エレベーター来た。じゃ、また勉強会で。',
        ),
      ],
    ),
    // 久遠 詩（4/15 水）— 通勤路のカフェ店長
    EncounterEvent(
      targetId: CharacterId.uta,
      fireDate: CharacterRepository.byId(CharacterId.uta).firstMeetDate,
      locationLabel: '通勤路の小さなカフェ',
      lines: const [
        DialogueLine(
          Expression.smile,
          'いらっしゃい。あ、駅の向こうから歩いてきた方ですよね。最近よく前を通る人だ。',
        ),
        DialogueLine(
          Expression.normal,
          'うちは個人でやってるカフェなので、豆は浅煎り中心です。よかったらおすすめ淹れますね。',
        ),
        DialogueLine(
          Expression.smile,
          '——私は久遠。詩、って呼ばれることが多いです。また気が向いたらどうぞ。',
        ),
      ],
    ),
    // 鴻巣 透（4/20 月）— 取引先のエンジニア
    EncounterEvent(
      targetId: CharacterId.toru,
      fireDate: CharacterRepository.byId(CharacterId.toru).firstMeetDate,
      locationLabel: '取引先との合同打ち合わせ',
      lines: const [
        DialogueLine(
          Expression.normal,
          '初めまして。システム側担当の鴻巣です。要件、メールで先に送っておいたほうの方ですか。',
        ),
        DialogueLine(
          Expression.troubled,
          '——あの、念のため確認なんですが、そこ、納期わりとシビアです。'
              '正直に言ってもらえたほうが後で困らないので。',
        ),
        DialogueLine(
          Expression.normal,
          '理解いただけて助かります。連絡はチャットでも構いません。返信は早いほうだと思います。',
        ),
      ],
    ),
    // 蓮見 紗夜（5/5 火・祝相当）— マンションの隣人
    EncounterEvent(
      targetId: CharacterId.sayo,
      fireDate: CharacterRepository.byId(CharacterId.sayo).firstMeetDate,
      locationLabel: 'マンションの深夜の廊下',
      lines: const [
        DialogueLine(
          Expression.troubled,
          '——あ、ごめんなさい。猫が逃げちゃって。'
              '玄関ドア開けたら走っていって。',
        ),
        DialogueLine(
          Expression.normal,
          '隣の蓮見です。翻訳の仕事してて、夜遅くまで起きてるの。'
              '物音うるさかったらすみません。',
        ),
        DialogueLine(
          Expression.smile,
          '——あ、捕まえてくれた。ありがとう。助かりました。本当に。',
        ),
      ],
    ),
    // 槙原 結衣（5/10 日）— ジムのトレーナー
    EncounterEvent(
      targetId: CharacterId.yui,
      fireDate: CharacterRepository.byId(CharacterId.yui).firstMeetDate,
      locationLabel: '週末通うジムの受付',
      lines: const [
        DialogueLine(
          Expression.smile,
          'はじめまして！ 今日担当する槙原です。'
              '体験プログラム来てくれてありがとうございます。',
        ),
        DialogueLine(
          Expression.normal,
          'デスクワーク中心みたいなので、まずは肩甲骨まわりからほぐしましょう。'
              '無理しないでいいです、できる範囲で。',
        ),
        DialogueLine(
          Expression.smile,
          '——お疲れさまでした！ 良い汗かきましたね。続けたくなったら、'
              'いつでも受付で結衣を呼んでください。',
        ),
      ],
    ),
  ]);

  /// 指定日付に発火すべき出会いイベントを返す。なければ null。
  /// 比較は (year, month, day) のみ。
  static EncounterEvent? eventOn(DateTime date) {
    for (final e in all) {
      if (e.fireDate.year == date.year &&
          e.fireDate.month == date.month &&
          e.fireDate.day == date.day) {
        return e;
      }
    }
    return null;
  }
}
