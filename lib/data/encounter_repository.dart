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
    // 七瀬 灯（4/10 金）— よく通うカフェのカフェ研究員
    EncounterEvent(
      targetId: CharacterId.akari,
      fireDate: CharacterRepository.byId(CharacterId.akari).firstMeetDate,
      locationLabel: 'よく通うカフェのカウンター',
      lines: const [
        DialogueLine(
          Expression.normal,
          '——あ。よく来てくれる方ですよね。いつも同じ時間に、同じ席で。',
        ),
        DialogueLine(
          Expression.smile,
          '私は七瀬。ここで商品開発をしてる研究員です。よかったら、新作の感想、いつか聞かせて。',
        ),
        DialogueLine(
          Expression.normal,
          '——あ、抽出のタイマーだ。じゃ、また。試作ができたら出すね。',
        ),
      ],
    ),
    // 久遠 詩（4/15 水）— 通勤路の書店併設カフェにいる編集者
    EncounterEvent(
      targetId: CharacterId.uta,
      fireDate: CharacterRepository.byId(CharacterId.uta).firstMeetDate,
      locationLabel: '通勤路の書店併設カフェ',
      lines: const [
        DialogueLine(
          Expression.smile,
          'あ、すみません、席ふさいでましたよね。朝はここでゲラを読むのが日課で。',
        ),
        DialogueLine(
          Expression.normal,
          '出版社で編集をしてるんです。本になる前の文章を、こうやって朝のうちに直してて。',
        ),
        DialogueLine(
          Expression.smile,
          '——私は久遠。詩、って呼ばれることが多いです。また朝に、どうぞ。',
        ),
      ],
    ),
    // 鴻巣 透（4/20 月）— 取引先のスポーツメーカー営業
    EncounterEvent(
      targetId: CharacterId.toru,
      fireDate: CharacterRepository.byId(CharacterId.toru).firstMeetDate,
      locationLabel: '取引先との合同打ち合わせ',
      lines: const [
        DialogueLine(
          Expression.normal,
          '初めまして。メーカー営業の鴻巣です。提案書、メールで先に送っておいたほうの方ですか。',
        ),
        DialogueLine(
          Expression.troubled,
          '——あの、念のため確認なんですが、その納期、わりとシビアです。'
              '正直に言ってもらえたほうが後で困らないので。',
        ),
        DialogueLine(
          Expression.normal,
          '理解いただけて助かります。連絡はチャットでも構いません。返信は早いほうだと思います。',
        ),
      ],
    ),
    // 蓮見 紗夜（5/5 火・祝相当）— 深夜のコワーキングで会うデザイナー
    EncounterEvent(
      targetId: CharacterId.sayo,
      fireDate: CharacterRepository.byId(CharacterId.sayo).firstMeetDate,
      locationLabel: '深夜のコワーキングスペース',
      lines: const [
        DialogueLine(
          Expression.troubled,
          '——あ、ごめんなさい。色見本、散らかしちゃって。'
              '締切前で、つい広げすぎて。',
        ),
        DialogueLine(
          Expression.normal,
          '蓮見です。デザインの仕事してて、夜型なの。'
              'こんな時間に居るの、たいてい私くらいだから。',
        ),
        DialogueLine(
          Expression.smile,
          '——あ、拾ってくれた。ありがとう。助かりました。本当に。',
        ),
      ],
    ),
    // 槙原 結衣（5/10 日）— 駅前の楽器店スタッフ
    EncounterEvent(
      targetId: CharacterId.yui,
      fireDate: CharacterRepository.byId(CharacterId.yui).firstMeetDate,
      locationLabel: '駅前の楽器店',
      lines: const [
        DialogueLine(
          Expression.smile,
          'いらっしゃいませ！ 今日担当する槙原です。'
              '試奏、気になるのあれば気軽に声かけてくださいね。',
        ),
        DialogueLine(
          Expression.normal,
          '初めてだと迷いますよね。まずは持ったときに「軽いな」と思うやつから。'
              '無理に高いの選ばなくていいです、続けられるのが一番なので。',
        ),
        DialogueLine(
          Expression.smile,
          '——お疲れさまでした！ いい音、出てましたよ。気が向いたら、'
              'いつでも店頭で結衣を呼んでください。',
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
