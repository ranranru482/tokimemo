import '../models/dialogue.dart';
import '../models/event.dart';

/// Sprint 08: 共通イベント・節目イベントの定義。
///
/// 仕様書 §7「共通イベント / 季節・節目イベント」を 7 本以上揃える。
/// 発火日は month/day のみで判定するため、`fireDate` の年は便宜上 2026 固定。
///
/// すべての台詞・登場人物名はオリジナル（spec.md §5 に登場するキャラ名と
/// 「主人公」のみを使用、ときめきメモリアル等の既存IPは使わない）。
///
/// 共通イベント本数: 9 本（うち 1 本が節目=クリスマス）
/// - 4/1  入社式
/// - 5/3  ゴールデンウィークの読書日
/// - 6/15 健康診断
/// - 7/24 夏季賞与
/// - 8/13 夏祭り
/// - 10/31 ハロウィン残業
/// - 11/20 期末評価面談
/// - 12/24 クリスマス（節目）
/// - 2/14 バレンタイン
/// - 3/31 年度末
class CommonEventCatalog {
  CommonEventCatalog._();

  static final List<GameEvent> all = List<GameEvent>.unmodifiable(<GameEvent>[
    _entranceCeremony,
    _goldenWeek,
    _healthCheck,
    _summerBonus,
    _summerFestival,
    _halloweenOvertime,
    _midYearReview,
    _christmas, // 節目（milestone）扱いだが all にも含めて一覧性を保つ
    _valentine,
    _yearEnd,
  ]);

  /// 節目イベントのみ抽出（「誰と過ごすか」の選択画面を起動するもの）。
  static final List<GameEvent> milestones = List<GameEvent>.unmodifiable(
    all.where((e) => e.category == EventCategory.milestone).toList(),
  );

  // -------------------------------------------------------------------------
  // 各イベント本体
  // -------------------------------------------------------------------------

  static final GameEvent _entranceCeremony = GameEvent(
    id: 'common.entrance.apr',
    category: EventCategory.common,
    title: '新年度の朝',
    locationLabel: '会社のロビー',
    fireDate: _apr1,
    script: [
      EventLine(text: '4月1日。新しい年度が始まる朝。机の上にはまだ前年度の付箋が残っている。'),
      EventLine(text: '入社して4年目、もう「新人です」と名乗ることもなくなった。'),
      EventLine(text: '今年は——どんな1年にしようか。'),
    ],
    choice: EventChoiceScene(
      prompt: '通勤電車の中で、ふと心の中で抱負をつぶやく。',
      choices: [
        EventChoice(
          label: '（仕事で結果を出す年にする）',
          outcome: ChoiceOutcome(label: '仕事優先', stressDelta: 2),
        ),
        EventChoice(
          label: '（誰かと、ちゃんと向き合う年にする）',
          outcome: ChoiceOutcome(label: '人優先'),
        ),
        EventChoice(
          label: '（自分のための時間を増やす年にする）',
          outcome: ChoiceOutcome(label: '自分優先', stressDelta: -3),
        ),
      ],
    ),
    cgKey: 'cg.common.entrance_apr',
    cgTitle: '新年度の朝',
    cgCaption: '4月1日、新しい年度のはじまり。机の上の付箋を、そっとめくる。',
  );

  static final GameEvent _goldenWeek = GameEvent(
    id: 'common.golden_week.may',
    category: EventCategory.common,
    title: 'ゴールデンウィークの読書日',
    locationLabel: '自宅のソファ',
    fireDate: _may3,
    script: [
      EventLine(text: '長い連休のなかば。何も予定を入れない日を1日だけ作った。'),
      EventLine(text: 'ソファに沈み込んで、買ったまま積んでいた小説を開く。'),
      EventLine(text: '誰にも会わない時間が、こんなに必要だったとは。'),
      EventLine(text: '——少しだけ、肩の力が抜けた気がする。'),
    ],
    cgKey: 'cg.common.golden_week_may',
    cgTitle: '何もしない休日',
    cgCaption: '連休のなかば、ソファに沈んで小説を一冊読み切った日。',
    unlockMessage: 'ゆっくり休めた。ストレスが少し和らいだ。',
  );

  /// 受け入れ基準1: 6月の健康診断イベントが自動発火し、共通イベントとして
  /// 全プレイヤーに表示される。
  static final GameEvent _healthCheck = GameEvent(
    id: 'common.health_check.jun',
    category: EventCategory.common,
    title: '健康診断',
    locationLabel: '会議室の隣の医務室',
    fireDate: _jun15,
    script: [
      EventLine(text: '6月の健康診断の日。朝食を抜いて出社する。'),
      EventLine(text: '受付で番号札を渡され、しばらく廊下のベンチで待たされる。'),
      EventLine(text: '同じ部署の人とすれ違うと、お互い少し気まずい挨拶を交わす。'),
      EventLine(text: '——身長、体重、血圧、視力。淡々と項目が進んでいく。'),
      EventLine(text: '医師から「数値は概ね問題ないですが、もう少し休んでくださいね」と言われた。'),
      EventLine(text: 'ちゃんと食べて、ちゃんと寝る。当たり前のことを当たり前に。'),
    ],
    cgKey: 'cg.common.health_check_jun',
    cgTitle: '6月の医務室',
    cgCaption: '健康診断の帰り道、コンビニで買ったゼリー飲料が妙に沁みた。',
    unlockMessage: '健康診断を受けた。生活を少し見直そう。',
  );

  static final GameEvent _summerBonus = GameEvent(
    id: 'common.summer_bonus.jul',
    category: EventCategory.common,
    title: '夏季賞与の通知',
    locationLabel: 'デスクのPC画面',
    fireDate: _jul10,
    script: [
      EventLine(text: '昼休み直前、社内メールに賞与明細の通知が届いた。'),
      EventLine(text: '人事システムにログインして、金額を確認する。'),
      EventLine(text: '想像していたよりは多く、想像していたよりは少ない、いつもの数字。'),
      EventLine(text: '——何に使うかは、また家で考えよう。'),
    ],
    cgKey: 'cg.common.summer_bonus_jul',
    cgTitle: '夏季賞与の通知',
    cgCaption: '画面の数字を見ながら、ぼんやりと夏の予定を思い描く。',
  );

  static final GameEvent _summerFestival = GameEvent(
    id: 'common.summer_festival.aug',
    category: EventCategory.common,
    title: '夏祭りの夜',
    locationLabel: '駅前の通り',
    fireDate: _aug13,
    script: [
      EventLine(text: '駅から家までの道に、屋台の灯りが並んでいる。'),
      EventLine(text: '焼きとうもろこしの匂い、子どもの笑い声、遠くで鳴っている太鼓の音。'),
      EventLine(text: '誰かと来るのも、一人で歩くのも、それぞれ違う良さがある気がする。'),
      EventLine(text: 'りんご飴を1本だけ買って、ゆっくり家路をたどる。'),
    ],
    cgKey: 'cg.common.summer_festival_aug',
    cgTitle: '駅前の夏祭り',
    cgCaption: 'りんご飴を片手に、屋台の灯りの間をゆっくり歩いた夜。',
  );

  static final GameEvent _halloweenOvertime = GameEvent(
    id: 'common.halloween.oct',
    category: EventCategory.common,
    title: 'ハロウィンの夜の残業',
    locationLabel: '無人のオフィス',
    fireDate: _oct31,
    script: [
      EventLine(text: '渋谷の方向から、にぎやかな声がうっすら聞こえてくる。'),
      EventLine(text: 'オフィスに残っているのは自分を含めて数名。'),
      EventLine(text: '誰かが買ってきた小さなチョコ菓子が、ホワイトボードの下に置いてあった。'),
      EventLine(text: '一つだけもらって、また画面に視線を戻す。'),
    ],
    cgKey: 'cg.common.halloween_oct',
    cgTitle: '無人のオフィスのチョコ菓子',
    cgCaption: 'ハロウィンの夜、誰かが置いてくれた小さな包みに少しだけ救われた。',
  );

  static final GameEvent _midYearReview = GameEvent(
    id: 'common.mid_year_review.nov',
    category: EventCategory.common,
    title: '期末評価面談',
    locationLabel: '小会議室',
    fireDate: _nov20,
    script: [
      EventLine(text: '半期に一度の評価面談。上司と1対1で30分。'),
      EventLine(text: '事前に書いた自己評価シートを見ながら、淡々と振り返りが進む。'),
      EventLine(text: '「成果は出ています。あとは、もう少し自分から動いてもいいかもしれません」'),
      EventLine(text: '——そう言われて、少し背筋が伸びる。'),
    ],
    choice: EventChoiceScene(
      prompt: '帰り際、上司にどう返事をするか。',
      choices: [
        EventChoice(
          label: '「精一杯やってみます」',
          outcome: ChoiceOutcome(label: '前向き'),
        ),
        EventChoice(
          label: '「少し時間をください」',
          outcome: ChoiceOutcome(label: '慎重', stressDelta: -2),
        ),
      ],
    ),
    cgKey: 'cg.common.mid_year_review_nov',
    cgTitle: '小会議室の午後',
    cgCaption: '評価シートの余白に、上司が手書きでメモを残してくれた。',
  );

  /// 受け入れ基準3: 12月のクリスマスで「誰と過ごすか」選択画面が出る。
  /// 本イベントは [EventCategory.milestone]。
  /// HomeScreen 側でこのイベントを検出したら通常の `EventPlayer` ではなく
  /// `ChristmasChoiceScreen` を push する。
  static final GameEvent _christmas = GameEvent(
    id: 'common.christmas.dec',
    category: EventCategory.milestone,
    title: 'クリスマスイブの夜',
    locationLabel: '夜の街',
    fireDate: _dec24,
    script: [
      EventLine(text: '12月24日。仕事は早めに切り上げて、駅前のイルミネーションを横目に家へ向かう。'),
      EventLine(text: '——今夜、誰と過ごそうか。'),
    ],
    cgKey: 'cg.common.christmas_dec',
    cgTitle: 'イブの夜',
    cgCaption: 'イルミネーションの下、選んだ人と歩いた小さな夜の記録。',
  );

  static final GameEvent _valentine = GameEvent(
    id: 'common.valentine.feb',
    category: EventCategory.common,
    title: 'バレンタインの社内',
    locationLabel: '給湯室',
    fireDate: _feb14,
    script: [
      EventLine(text: '2月14日。給湯室に、共同購入の義理チョコの箱が置いてある。'),
      EventLine(text: '小さな付箋に「いつもありがとうございます」と書かれていた。'),
      EventLine(text: '——書いた人の顔を想像して、少しだけ口角が上がる。'),
    ],
    cgKey: 'cg.common.valentine_feb',
    cgTitle: '給湯室の付箋',
    cgCaption: '誰の字かは分からないが、その一言で1日が少しだけ良くなった。',
  );

  static final GameEvent _yearEnd = GameEvent(
    id: 'common.year_end.mar',
    category: EventCategory.common,
    title: '年度末の夜',
    locationLabel: '帰り道の桜並木',
    fireDate: _mar31,
    script: [
      EventLine(text: '3月31日。1年が終わる夜。'),
      EventLine(text: '帰り道、まだ五分咲きの桜並木の下を歩く。'),
      EventLine(text: 'いろいろなことがあった。覚えていられないほどの、些細なやり取りも含めて。'),
      EventLine(text: '——明日からも、たぶん、生きていける。'),
    ],
    cgKey: 'cg.common.year_end_mar',
    cgTitle: '五分咲きの桜並木',
    cgCaption: '1年の終わりの夜、ひとつだけ深呼吸をして帰った。',
  );
}

// DateTime には const コンストラクタが無いため final で宣言する。
// 共通イベントの判定では month/day のみを比較するため、年は便宜上の値。
final DateTime _apr1 = DateTime(2026, 4, 1);
final DateTime _may3 = DateTime(2026, 5, 3);
final DateTime _jun15 = DateTime(2026, 6, 15);
final DateTime _jul10 = DateTime(2026, 7, 10);
final DateTime _aug13 = DateTime(2026, 8, 13);
final DateTime _oct31 = DateTime(2026, 10, 31);
final DateTime _nov20 = DateTime(2026, 11, 20);
final DateTime _dec24 = DateTime(2026, 12, 24);
final DateTime _feb14 = DateTime(2027, 2, 14);
final DateTime _mar31 = DateTime(2027, 3, 31);
