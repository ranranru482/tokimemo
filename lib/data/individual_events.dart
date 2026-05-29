import '../models/character.dart';
import '../models/dialogue.dart';
import '../models/event.dart';

/// Sprint 08: 各キャラ 5 本ずつ（合計 25 本）の個別イベント。
///
/// spec.md §5「攻略の鍵」を参考にモチーフを設計：
/// - 七瀬 灯: 写真展 / 社内勉強会
/// - 久遠 詩: カフェ夜ライブ / 朝の珈琲
/// - 鴻巣 透: 論理的選択 / ソロキャンプ
/// - 蓮見 紗夜: 雨の日の廊下 / 紅茶と猫
/// - 槙原 結衣: 草大会の応援 / ジム朝練
///
/// 解放条件は基本的に [requiredAffinityStage]（誘い反復で 2 段階目=20以上に
/// 到達したら Event 1 解放）。Event 3 以降は requiredMonth とのANDで揃える。
/// すべての台詞はオリジナル。
///
/// 各イベントの末尾には選択肢を 1 件挟み、結果は ChoiceOutcome で
/// 表面/真の好感度・ストレスに反映する。
class IndividualEventCatalog {
  IndividualEventCatalog._();

  static final List<GameEvent> all = List<GameEvent>.unmodifiable(<GameEvent>[
    ..._akari,
    ..._uta,
    ..._toru,
    ..._sayo,
    ..._yui,
  ]);

  /// 指定キャラの個別イベント一覧（順序保持）。
  static List<GameEvent> forCharacter(CharacterId id) {
    return all.where((e) => e.target == id).toList(growable: false);
  }

  // ===========================================================================
  // 七瀬 灯（akari）— 写真展 / 勉強会 / フィルムカメラ
  // ===========================================================================
  static const List<GameEvent> _akari = [
    GameEvent(
      id: 'ind.akari.1',
      category: EventCategory.individual,
      target: CharacterId.akari,
      requiredAffinityStage: 2,
      title: '勉強会のあとで',
      locationLabel: '会社の階段の踊り場',
      script: [
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.normal,
          text: '——お疲れさま。さっきの質問、ちゃんと聞こえてたよ。よく調べてる。',
        ),
        EventLine(text: '勉強会のあと、階段の踊り場で偶然会った七瀬さんが、缶コーヒーをひとつ差し出してきた。'),
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.smile,
          text: '私もね、最初の3年は同じことばっかり聞いてた。だから恥ずかしがらなくていい。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '七瀬さんに何と返そうか。',
        choices: [
          EventChoice(
            label: '「ありがとうございます。助かります」',
            outcome: ChoiceOutcome(
              label: '無難',
              affinityDelta: 2,
              trueAffinityDelta: 1,
            ),
          ),
          EventChoice(
            label: '「七瀬さんの3年目、どんな感じだったんですか？」',
            outcome: ChoiceOutcome(
              label: '踏み込む',
              affinityDelta: 1,
              trueAffinityDelta: 4,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.akari.1',
      cgTitle: '踊り場の缶コーヒー',
      cgCaption: '勉強会の帰り、缶コーヒーを片手に立っていた先輩の横顔。',
    ),
    GameEvent(
      id: 'ind.akari.2',
      category: EventCategory.individual,
      target: CharacterId.akari,
      requiredAffinityStage: 3,
      title: 'フィルムカメラの話',
      locationLabel: '会社近くの公園のベンチ',
      script: [
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.smile,
          text: '——お昼、ここで食べていい？ あ、ごめん、聞いてから座ればよかった。',
        ),
        EventLine(text: '七瀬さんのカバンから、見慣れない小さなカメラが顔をのぞかせている。'),
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.normal,
          text: '昔の機械式。デジタルと違って、撮ったあとすぐ見られないのがいいの。'
              '忘れたころに現像してもらって、ようやく思い出す。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'カメラについて何か聞いてみる。',
        choices: [
          EventChoice(
            label: '「いつか撮ってもらえます？」',
            outcome: ChoiceOutcome(
              label: '距離を縮める',
              affinityDelta: 2,
              trueAffinityDelta: 2,
            ),
          ),
          EventChoice(
            label: '「写真、見せてもらってもいいですか？」',
            outcome: ChoiceOutcome(
              label: '丁寧',
              affinityDelta: 1,
              trueAffinityDelta: 3,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.akari.2',
      cgTitle: '公園のフィルムカメラ',
      cgCaption: '昼下がりの公園、銀色の小さなカメラを抱えた人の話を聞いた。',
    ),
    GameEvent(
      id: 'ind.akari.3',
      category: EventCategory.individual,
      target: CharacterId.akari,
      requiredAffinityStage: 3,
      requiredMonth: 9,
      title: '写真展の招待',
      locationLabel: '商店街の小さな個展会場',
      script: [
        EventLine(text: '休日の昼、商店街の二階にある小さなギャラリー。'),
        EventLine(text: '会場の中ほどで、白いシャツの七瀬さんが、こちらに小さく手を振った。'),
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.smile,
          text: '来てくれたんだ。——あの、緊張するから、感想は帰り際でいいから。',
        ),
        EventLine(text: '壁に並ぶのは、夕方の街角を撮った数十枚の写真。どれも誰かを待っているような色をしている。'),
      ],
      choice: EventChoiceScene(
        prompt: '帰り際、何を伝えるか。',
        choices: [
          EventChoice(
            label: '「全部、知らない街なのに、知ってる気がしました」',
            outcome: ChoiceOutcome(
              label: '本音',
              affinityDelta: 2,
              trueAffinityDelta: 5,
            ),
          ),
          EventChoice(
            label: '「次の個展も、絶対来ます」',
            outcome: ChoiceOutcome(
              label: '前向き',
              affinityDelta: 3,
              trueAffinityDelta: 2,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.akari.3',
      cgTitle: '商店街の個展会場',
      cgCaption: '夕方の街角の写真の前で、ぽつりと話した時間。',
    ),
    GameEvent(
      id: 'ind.akari.4',
      category: EventCategory.individual,
      target: CharacterId.akari,
      requiredAffinityStage: 4,
      title: '結婚を急かされる話',
      locationLabel: '会社近くの居酒屋',
      script: [
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.troubled,
          text: '——ごめん、こんな話するつもりじゃなかったんだけど。実家がね、ちょっとうるさくて。',
        ),
        EventLine(text: '隅の席で、七瀬さんはグラスを両手で包むようにしていた。'),
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.normal,
          text: '転職するか、結婚するか、どっちかにしろって。'
              '——自分の時間軸で決めたいだけなんだけどな。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'どう応えるか。',
        choices: [
          EventChoice(
            label: '「七瀬さんのペースが、一番正しいと思います」',
            outcome: ChoiceOutcome(
              label: '味方になる',
              affinityDelta: 2,
              trueAffinityDelta: 6,
            ),
          ),
          EventChoice(
            label: '「——その話、もう少し聞いてもいいですか」',
            outcome: ChoiceOutcome(
              label: '寄り添う',
              affinityDelta: 1,
              trueAffinityDelta: 4,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.akari.4',
      cgTitle: '居酒屋の片隅',
      cgCaption: 'グラスを両手で包んで、ぽつぽつと家族の話をしていた夜。',
    ),
    GameEvent(
      id: 'ind.akari.5',
      category: EventCategory.individual,
      target: CharacterId.akari,
      requiredAffinityStage: 4,
      requiredMonth: 11,
      title: '冬の朝、決めたこと',
      locationLabel: '会社近くのカフェ',
      script: [
        EventLine(text: '冷たい朝、開店直後のカフェで、七瀬さんが手を上げた。'),
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.normal,
          text: '——転職、しないことにした。今の場所で、もう少しやってみる。'
              'それと、結婚も、急がない。',
        ),
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.smile,
          text: '聞いてくれてたから、決められた気がする。本当に。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '何と返すか。',
        choices: [
          EventChoice(
            label: '「七瀬さんが決めたなら、それが正解です」',
            outcome: ChoiceOutcome(
              label: '受け止める',
              affinityDelta: 3,
              trueAffinityDelta: 6,
            ),
          ),
          EventChoice(
            label: '「これからも、話、聞かせてください」',
            outcome: ChoiceOutcome(
              label: '関係を選ぶ',
              affinityDelta: 2,
              trueAffinityDelta: 8,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.akari.5',
      cgTitle: '冬の朝のカフェ',
      cgCaption: '湯気の向こうで「決めた」と言った人の、小さな笑顔。',
    ),
    GameEvent(
      id: 'ind.akari.6',
      category: EventCategory.individual,
      target: CharacterId.akari,
      requiredAffinityStage: 3,
      requiredMonth: 5,
      title: '五月の社内勉強会',
      locationLabel: '会社の小会議室',
      script: [
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.smile,
          text: '——五月病の時期にやる勉強会、効くと思って始めたの。'
              '今日のテーマ、よかったら聞いてって。',
        ),
        EventLine(text: 'ホワイトボードの脇には、彼女の手書きのレジュメ。'),
      ],
      choice: EventChoiceScene(
        prompt: '勉強会のあと、どう声をかけるか。',
        choices: [
          EventChoice(
            label: '「レジュメ、社内ブログに転載していいですか？」',
            outcome: ChoiceOutcome(
              label: '広める',
              affinityDelta: 2,
              trueAffinityDelta: 3,
            ),
          ),
          EventChoice(
            label: '「今日の話、自分の案件で試してみます」',
            outcome: ChoiceOutcome(
              label: '実践',
              affinityDelta: 1,
              trueAffinityDelta: 4,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.akari.6',
      cgTitle: '五月の小会議室',
      cgCaption: '手書きのレジュメと、誰かを待つホワイトボード。',
    ),
    GameEvent(
      id: 'ind.akari.7',
      category: EventCategory.individual,
      target: CharacterId.akari,
      requiredAffinityStage: 4,
      preferredSlot: 3, // night
      title: '退社後の長電話',
      locationLabel: '自宅の机',
      script: [
        EventLine(text: '深夜、自宅でぼんやりしていると、七瀬さんから着信があった。'),
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.normal,
          text: '——遅くにごめんね。'
              '昼間、言いそびれた話があって、いまなら言える気がして。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '受話器越し、どう返すか。',
        choices: [
          EventChoice(
            label: '「ゆっくりでいいです。聞きます」',
            outcome: ChoiceOutcome(
              label: '受け止める',
              affinityDelta: 2,
              trueAffinityDelta: 5,
            ),
          ),
          EventChoice(
            label: '「明日、もう一度、対面で聞かせてください」',
            outcome: ChoiceOutcome(
              label: '対面を選ぶ',
              affinityDelta: 3,
              trueAffinityDelta: 3,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.akari.7',
      cgTitle: '深夜の長電話',
      cgCaption: '机に置かれたカップと、灯りの落ちた部屋の通話。',
    ),
  ];

  // ===========================================================================
  // 久遠 詩（uta）— カフェ夜ライブ / 朝の珈琲
  // ===========================================================================
  static const List<GameEvent> _uta = [
    GameEvent(
      id: 'ind.uta.1',
      category: EventCategory.individual,
      target: CharacterId.uta,
      requiredAffinityStage: 2,
      preferredSlot: 0, // morning
      title: '朝の常連扱い',
      locationLabel: '通勤路のカフェ',
      script: [
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.smile,
          text: 'おはようございます。今日もブレンド、深めの方でいいですか？',
        ),
        EventLine(text: '注文を覚えてくれている。それだけで朝の始まりが少し違って感じる。'),
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.normal,
          text: '今朝はね、外に小鳥が来てたんですよ。'
              'お客さんが来る前って、わりとそういう時間で。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'どう返すか。',
        choices: [
          EventChoice(
            label: '「いつも覚えてくれて、ありがとうございます」',
            outcome: ChoiceOutcome(
              label: '感謝',
              affinityDelta: 2,
              trueAffinityDelta: 2,
            ),
          ),
          EventChoice(
            label: '「今度、朝の時間も少し早く来ますね」',
            outcome: ChoiceOutcome(
              label: '関心',
              affinityDelta: 1,
              trueAffinityDelta: 3,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.uta.1',
      cgTitle: '常連用のブレンド',
      cgCaption: '湯気の向こうで「いつもの方で」と微笑む顔。',
    ),
    GameEvent(
      id: 'ind.uta.2',
      category: EventCategory.individual,
      target: CharacterId.uta,
      requiredAffinityStage: 3,
      title: 'カウンター越しの相談',
      locationLabel: 'カフェの夕方',
      script: [
        EventLine(text: '夕方、客のいないカウンターで、店長は珍しくぼんやりしていた。'),
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.troubled,
          text: '——実はね、今月、ちょっと厳しくて。'
              'お店、続けるのに、いろいろ考えなきゃいけないことがある。',
        ),
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.normal,
          text: 'ごめんなさい、お客さんに話すことじゃないですよね。'
              '——でも、なんか、あなたには言いたかった。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '何と返すか。',
        choices: [
          EventChoice(
            label: '「お店、続けてほしいです。常連として」',
            outcome: ChoiceOutcome(
              label: '率直',
              affinityDelta: 2,
              trueAffinityDelta: 4,
            ),
          ),
          EventChoice(
            label: '「話してくれて、ありがとうございます」',
            outcome: ChoiceOutcome(
              label: '受け止める',
              affinityDelta: 1,
              trueAffinityDelta: 5,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.uta.2',
      cgTitle: '夕方のカウンター',
      cgCaption: 'カウンターの内側で、ふと素顔を見せてくれた時間。',
    ),
    GameEvent(
      id: 'ind.uta.3',
      category: EventCategory.individual,
      target: CharacterId.uta,
      requiredAffinityStage: 3,
      requiredMonth: 8,
      title: '閉店後の弾き語り',
      locationLabel: '閉店後のカフェ',
      script: [
        EventLine(text: '閉店の札が下げられたあとのカフェで、小さなライブが開かれた。'),
        EventLine(text: '集まったのは10人ほど。詩さんはギターを抱えて、低い声で歌い始める。'),
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.smile,
          text: '——招いてよかった。来てくれて、ありがとう。',
        ),
        EventLine(text: '1曲目は、自分で作ったという珈琲の歌だった。'),
      ],
      choice: EventChoiceScene(
        prompt: 'ライブ後、声をかける。',
        choices: [
          EventChoice(
            label: '「曲、レコードで欲しいくらいでした」',
            outcome: ChoiceOutcome(
              label: '素直',
              affinityDelta: 2,
              trueAffinityDelta: 5,
            ),
          ),
          EventChoice(
            label: '「あの曲、もう一度聴かせてください」',
            outcome: ChoiceOutcome(
              label: '深く',
              affinityDelta: 1,
              trueAffinityDelta: 6,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.uta.3',
      cgTitle: '閉店後のライブ',
      cgCaption: '10席だけのライブ、珈琲の歌を低い声で聴いた夜。',
    ),
    GameEvent(
      id: 'ind.uta.4',
      category: EventCategory.individual,
      target: CharacterId.uta,
      requiredAffinityStage: 4,
      title: '配信、はじめます',
      locationLabel: 'カフェの定休日',
      script: [
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.normal,
          text: '定休日にごめんなさい。——あの、自分の曲、配信に出すことにしたんです。',
        ),
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.smile,
          text: '誰にも言わずに出そうとしたんだけど、結局、誰かに言いたくなって。'
              'あなたが浮かんだ。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'どう応えるか。',
        choices: [
          EventChoice(
            label: '「最初の1人になります。聴かせてください」',
            outcome: ChoiceOutcome(
              label: '伴走',
              affinityDelta: 2,
              trueAffinityDelta: 6,
            ),
          ),
          EventChoice(
            label: '「いい曲だから、ちゃんと届くと思います」',
            outcome: ChoiceOutcome(
              label: '応援',
              affinityDelta: 3,
              trueAffinityDelta: 4,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.uta.4',
      cgTitle: '定休日のカウンター',
      cgCaption: '誰もいない店内、ノートPCの上に置かれた「配信開始」の文字。',
    ),
    GameEvent(
      id: 'ind.uta.5',
      category: EventCategory.individual,
      target: CharacterId.uta,
      requiredAffinityStage: 4,
      requiredMonth: 12,
      title: '冬の朝、いつもの一杯',
      locationLabel: 'カフェの開店直前',
      script: [
        EventLine(text: '凍えるような朝、開店前のカフェにあたたかい湯気が漂っていた。'),
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.smile,
          text: '寒いですよね。よかったら、開店前に1杯どうぞ。'
              '——今日はちょっと、特別な豆で淹れました。',
        ),
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.normal,
          text: '配信のこと、応援してくれて、ありがとうございました。'
              'お礼って言うほどじゃないですけど、これは私からの一杯です。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'カップを受け取りながら、何と返すか。',
        choices: [
          EventChoice(
            label: '「ここの朝の一杯、当分やめられないですね」',
            outcome: ChoiceOutcome(
              label: '受け取る',
              affinityDelta: 3,
              trueAffinityDelta: 5,
            ),
          ),
          EventChoice(
            label: '「次は——お礼じゃなくて、ふつうに飲みに来ます」',
            outcome: ChoiceOutcome(
              label: '関係を選ぶ',
              affinityDelta: 2,
              trueAffinityDelta: 8,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.uta.5',
      cgTitle: '冬の朝の特別な一杯',
      cgCaption: '開店前の店内、湯気の向こうで差し出された一杯。',
    ),
    GameEvent(
      id: 'ind.uta.6',
      category: EventCategory.individual,
      target: CharacterId.uta,
      requiredAffinityStage: 2,
      preferredSlot: 2, // evening
      title: '夕方の試作豆',
      locationLabel: '夕方のカフェ',
      script: [
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.smile,
          text: '今日、試作の豆が届いたんです。'
              '——感想、聞かせてもらえますか？',
        ),
        EventLine(text: '小さなテイスティング用カップが2つ、カウンターに並んだ。'),
      ],
      choice: EventChoiceScene(
        prompt: '一口飲んでから、何と返すか。',
        choices: [
          EventChoice(
            label: '「香り、いつもより少し青いですね」',
            outcome: ChoiceOutcome(
              label: '言語化',
              affinityDelta: 2,
              trueAffinityDelta: 3,
            ),
          ),
          EventChoice(
            label: '「これ、レギュラーにしてほしいです」',
            outcome: ChoiceOutcome(
              label: '即決',
              affinityDelta: 3,
              trueAffinityDelta: 2,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.uta.6',
      cgTitle: '夕方の試作テイスティング',
      cgCaption: '小さなカップ2つと、夕方のカウンターに広がる豆の香り。',
    ),
    GameEvent(
      id: 'ind.uta.7',
      category: EventCategory.individual,
      target: CharacterId.uta,
      requiredAffinityStage: 3,
      requiredMonth: 7,
      title: '夏祭り前夜',
      locationLabel: '商店街の路地',
      script: [
        EventLine(text: '夏祭りの前夜、商店街の路地は提灯の試し点けで暖かい色だった。'),
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.smile,
          text: '——お店、明日は早じまいします。'
              'よかったら、ふつうのお客じゃなくて、一緒に歩きませんか。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'どう答えるか。',
        choices: [
          EventChoice(
            label: '「ぜひ、ふつうの夜として」',
            outcome: ChoiceOutcome(
              label: '関係を選ぶ',
              affinityDelta: 3,
              trueAffinityDelta: 4,
            ),
          ),
          EventChoice(
            label: '「店じまい、手伝います。それから」',
            outcome: ChoiceOutcome(
              label: '伴走',
              affinityDelta: 2,
              trueAffinityDelta: 5,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.uta.7',
      cgTitle: '夏祭り前夜の路地',
      cgCaption: '点り始めた提灯の下、ふつうの夜を歩く約束。',
    ),
  ];

  // ===========================================================================
  // 鴻巣 透（toru）— 論理的選択 / ソロキャンプ
  // ===========================================================================
  static const List<GameEvent> _toru = [
    GameEvent(
      id: 'ind.toru.1',
      category: EventCategory.individual,
      target: CharacterId.toru,
      requiredAffinityStage: 2,
      title: 'チャットの返信、早すぎる',
      locationLabel: '退社後のチャット画面',
      script: [
        EventLine(text: '退社して数分、業務チャットが鳴った。'),
        EventLine(
          speaker: CharacterId.toru,
          expression: Expression.normal,
          text: '昼間の件、整理し直しました。添付の構成図、見てもらえますか。'
              '今夜じゃなくていいです。',
        ),
        EventLine(text: '——たぶん、退社後すぐに自宅で書き直したんだろう。スピードと丁寧さが両立している。'),
      ],
      choice: EventChoiceScene(
        prompt: '返信に何を添えるか。',
        choices: [
          EventChoice(
            label: '「明日の朝、ちゃんと読んで返事します」',
            outcome: ChoiceOutcome(
              label: '誠実',
              affinityDelta: 2,
              trueAffinityDelta: 3,
            ),
          ),
          EventChoice(
            label: '「今読みました。ここの分岐だけ気になります」',
            outcome: ChoiceOutcome(
              label: '即応',
              affinityDelta: 3,
              trueAffinityDelta: 2,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.toru.1',
      cgTitle: '夜の構成図',
      cgCaption: '退社直後に送られてきた、丁寧に作り直された構成図。',
    ),
    GameEvent(
      id: 'ind.toru.2',
      category: EventCategory.individual,
      target: CharacterId.toru,
      requiredAffinityStage: 3,
      title: '線引きの話',
      locationLabel: '打ち合わせ後の休憩室',
      script: [
        EventLine(
          speaker: CharacterId.toru,
          expression: Expression.troubled,
          text: '——あの、ちょっと、前の話で。'
              '会議のあと、いつもより少し早めに帰らせてください。',
        ),
        EventLine(text: '声のトーンが、いつもより少し低い。'),
        EventLine(
          speaker: CharacterId.toru,
          expression: Expression.normal,
          text: '前の職場で、線引きを誤って、結構しんどい時期があったんです。'
              '今はそれを繰り返したくない。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'どう応えるか。',
        choices: [
          EventChoice(
            label: '「全然です。むしろ、教えてくれて助かります」',
            outcome: ChoiceOutcome(
              label: '線を尊重',
              affinityDelta: 2,
              trueAffinityDelta: 5,
            ),
          ),
          EventChoice(
            label: '「鴻巣さんが安全に働ける方を、最優先で」',
            outcome: ChoiceOutcome(
              label: '配慮',
              affinityDelta: 1,
              trueAffinityDelta: 6,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.toru.2',
      cgTitle: '休憩室の窓辺',
      cgCaption: '窓の外を見ながら、過去の話を少しだけ聞かせてくれた時間。',
    ),
    GameEvent(
      id: 'ind.toru.3',
      category: EventCategory.individual,
      target: CharacterId.toru,
      requiredAffinityStage: 3,
      requiredMonth: 9,
      title: '論理的な納期調整',
      locationLabel: 'オンライン会議',
      script: [
        EventLine(text: '画面の中、鴻巣さんは資料を共有しながら淡々と話している。'),
        EventLine(
          speaker: CharacterId.toru,
          expression: Expression.normal,
          text: '結論、納期を1週間ずらせば、品質・人員・コスト、どれも安全圏に入ります。'
              '判断はそちらに委ねますが、根拠は3点あります。',
        ),
        EventLine(text: '——感情ではなく、根拠で動く人。だからこそ、信頼できる。'),
      ],
      choice: EventChoiceScene(
        prompt: '会議の最後、何と返すか。',
        choices: [
          EventChoice(
            label: '「3点とも納得です。1週間ずらしましょう」',
            outcome: ChoiceOutcome(
              label: '論理に乗る',
              affinityDelta: 3,
              trueAffinityDelta: 4,
            ),
          ),
          EventChoice(
            label: '「持ち帰って、社内で擦り合わせます」',
            outcome: ChoiceOutcome(
              label: '慎重',
              affinityDelta: 1,
              trueAffinityDelta: 2,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.toru.3',
      cgTitle: '画面越しの3点根拠',
      cgCaption: '画面共有の資料の隅に、小さく「3点あります」と書かれていた。',
    ),
    GameEvent(
      id: 'ind.toru.4',
      category: EventCategory.individual,
      target: CharacterId.toru,
      requiredAffinityStage: 4,
      title: 'ソロキャンプの写真',
      locationLabel: 'チャットの画像',
      script: [
        EventLine(text: '週末、チャットに画像が1枚だけ送られてきた。'),
        EventLine(text: '焚き火、コーヒー、組み立て式のテーブル。背景は静かな湖。'),
        EventLine(
          speaker: CharacterId.toru,
          expression: Expression.normal,
          text: '休んでます、というだけの報告です。'
              '——次の打ち合わせ、月曜の朝でいいですか。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '返信に何を書くか。',
        choices: [
          EventChoice(
            label: '「写真、いいですね。月曜、朝で大丈夫です」',
            outcome: ChoiceOutcome(
              label: '受け取る',
              affinityDelta: 2,
              trueAffinityDelta: 4,
            ),
          ),
          EventChoice(
            label: '「いつか、そういう静かな場所、教えてください」',
            outcome: ChoiceOutcome(
              label: '関心',
              affinityDelta: 1,
              trueAffinityDelta: 6,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.toru.4',
      cgTitle: '湖と焚き火',
      cgCaption: 'チャットに1枚だけ届いた、静かな週末の景色。',
    ),
    GameEvent(
      id: 'ind.toru.5',
      category: EventCategory.individual,
      target: CharacterId.toru,
      requiredAffinityStage: 4,
      requiredMonth: 1,
      title: '冷えた夜のメッセージ',
      locationLabel: '深夜のチャット',
      script: [
        EventLine(text: '深夜0時を回ったころ、いつもの業務チャットではないチャネルに通知が来た。'),
        EventLine(
          speaker: CharacterId.toru,
          expression: Expression.normal,
          text: '仕事と関係ない話、すみません。'
              '——前に話した「線引き」の件、今のチームでは大丈夫みたいです。',
        ),
        EventLine(
          speaker: CharacterId.toru,
          expression: Expression.smile,
          text: 'あなたが普通に接してくれたのが、けっこう大きかったです。'
              '伝えとこうと思って。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '深夜の返信に、何と書くか。',
        choices: [
          EventChoice(
            label: '「教えてくれて、ありがとうございます」',
            outcome: ChoiceOutcome(
              label: '受け取る',
              affinityDelta: 3,
              trueAffinityDelta: 5,
            ),
          ),
          EventChoice(
            label: '「これからも、ふつうに話しましょう」',
            outcome: ChoiceOutcome(
              label: '関係を選ぶ',
              affinityDelta: 2,
              trueAffinityDelta: 8,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.toru.5',
      cgTitle: '深夜のチャット画面',
      cgCaption: '0時過ぎ、業務外のチャネルにだけ送られてきた短い文面。',
    ),
    GameEvent(
      id: 'ind.toru.6',
      category: EventCategory.individual,
      target: CharacterId.toru,
      requiredAffinityStage: 3,
      requiredMonth: 11,
      title: '秋の納品トラブル',
      locationLabel: 'オンライン緊急通話',
      script: [
        EventLine(text: '深夜の納品直前、画面の中で鴻巣さんが資料を共有している。'),
        EventLine(
          speaker: CharacterId.toru,
          expression: Expression.troubled,
          text: '——いま、こちらで止まってる箇所、3つ。'
              '1つだけ、判断、頼んでもいいですか。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '判断を下す。',
        choices: [
          EventChoice(
            label: '「Aで進めましょう。責任は持ちます」',
            outcome: ChoiceOutcome(
              label: '即断',
              affinityDelta: 2,
              trueAffinityDelta: 5,
            ),
          ),
          EventChoice(
            label: '「3点とも、根拠を一度整理しましょう」',
            outcome: ChoiceOutcome(
              label: '整理優先',
              affinityDelta: 1,
              trueAffinityDelta: 6,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.toru.6',
      cgTitle: '深夜の判断台',
      cgCaption: '共有画面の右上に「判断、頼みます」の一文。',
    ),
    GameEvent(
      id: 'ind.toru.7',
      category: EventCategory.individual,
      target: CharacterId.toru,
      requiredAffinityStage: 4,
      preferredSlot: 3, // night
      title: '夜のコーヒー談義',
      locationLabel: 'チャットのボイスチャンネル',
      script: [
        EventLine(text: 'チャットのボイスチャンネルに、鴻巣さんから招待が届いた。'),
        EventLine(
          speaker: CharacterId.toru,
          expression: Expression.normal,
          text: '今夜は仕事じゃない話、20分だけ。'
              '——いま、淹れたてのコーヒーを片手に。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '何を話題にする？',
        choices: [
          EventChoice(
            label: '「キャンプの装備、見せてくれません？」',
            outcome: ChoiceOutcome(
              label: '趣味',
              affinityDelta: 2,
              trueAffinityDelta: 4,
            ),
          ),
          EventChoice(
            label: '「鴻巣さんの3点ルール、自分の生活にも入れてみました」',
            outcome: ChoiceOutcome(
              label: '影響を伝える',
              affinityDelta: 1,
              trueAffinityDelta: 6,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.toru.7',
      cgTitle: '夜のボイスチャット',
      cgCaption: 'ヘッドセット越し、淹れたての湯気が聞こえそうな会話。',
    ),
  ];

  // ===========================================================================
  // 蓮見 紗夜（sayo）— 雨の日の廊下 / 紅茶と猫
  // ===========================================================================
  static const List<GameEvent> _sayo = [
    GameEvent(
      id: 'ind.sayo.1',
      category: EventCategory.individual,
      target: CharacterId.sayo,
      requiredAffinityStage: 2,
      preferredSlot: 3, // night
      title: '深夜のエレベーター',
      locationLabel: 'マンションの深夜の廊下',
      script: [
        EventLine(text: '日付が変わったころ、エレベーターを降りると、紗夜さんが郵便受けの前に立っていた。'),
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.normal,
          text: 'こんばんは。——お仕事、遅かったみたいですね。'
              '無理しないようにね。',
        ),
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.smile,
          text: '私は夜型だから、こういう時間に廊下で会うと、なんだか嬉しい。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'どう返すか。',
        choices: [
          EventChoice(
            label: '「お疲れさまです。蓮見さんも、無理しないでください」',
            outcome: ChoiceOutcome(
              label: 'ふつう',
              affinityDelta: 2,
              trueAffinityDelta: 2,
            ),
          ),
          EventChoice(
            label: '「今度、夜の時間、少しだけお茶でも」',
            outcome: ChoiceOutcome(
              label: '一歩',
              affinityDelta: 1,
              trueAffinityDelta: 4,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.sayo.1',
      cgTitle: '深夜の郵便受け',
      cgCaption: '日付が変わる頃、廊下の灯りの下で交わした静かな挨拶。',
    ),
    GameEvent(
      id: 'ind.sayo.2',
      category: EventCategory.individual,
      target: CharacterId.sayo,
      requiredAffinityStage: 3,
      title: '紅茶と猫',
      locationLabel: '隣室のリビング',
      script: [
        EventLine(text: '招かれて入った隣の部屋は、本棚と紅茶缶でいっぱいだった。'),
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.smile,
          text: '物はあんまり買わないんだけど、本と紅茶だけはね、つい。'
              '——あ、その子は人見知りだから、無理に撫でなくていいから。',
        ),
        EventLine(text: '足元で、三毛猫がゆっくりと尻尾を動かしている。'),
      ],
      choice: EventChoiceScene(
        prompt: '紅茶を一口飲んだあと、どう返すか。',
        choices: [
          EventChoice(
            label: '「この紅茶、家でも探してみます」',
            outcome: ChoiceOutcome(
              label: 'ふつう',
              affinityDelta: 2,
              trueAffinityDelta: 3,
            ),
          ),
          EventChoice(
            label: '「本棚、見ていてもいいですか？」',
            outcome: ChoiceOutcome(
              label: '深く知る',
              affinityDelta: 1,
              trueAffinityDelta: 5,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.sayo.2',
      cgTitle: '本棚と紅茶缶',
      cgCaption: '足元でゆっくり尻尾を振る三毛猫と、湯気の立つカップ。',
    ),
    GameEvent(
      id: 'ind.sayo.3',
      category: EventCategory.individual,
      target: CharacterId.sayo,
      requiredAffinityStage: 3,
      requiredMonth: 6,
      title: '雨の日の廊下',
      locationLabel: 'マンションの共用廊下',
      script: [
        EventLine(text: '梅雨の夕方、廊下の窓に雨が叩きつけている。'),
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.troubled,
          text: '——前の人と別れたのも、ちょうど梅雨の頃でね。'
              'こういう日になると、ふっと思い出す。',
        ),
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.normal,
          text: 'ごめんなさい、湿っぽい話して。'
              '——でも、誰かに少しだけ聞いてもらえると、'
              'ほんとに、それだけで助かる時がある。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'どう応えるか。',
        choices: [
          EventChoice(
            label: '「いつでも、聞きます。ちゃんと」',
            outcome: ChoiceOutcome(
              label: '受け止める',
              affinityDelta: 2,
              trueAffinityDelta: 6,
            ),
          ),
          EventChoice(
            label: '「——その話、もう少し、聞かせてください」',
            outcome: ChoiceOutcome(
              label: '寄り添う',
              affinityDelta: 1,
              trueAffinityDelta: 7,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.sayo.3',
      cgTitle: '雨の窓と廊下',
      cgCaption: '梅雨の夕方、雨の音と一緒に聞いた小さな打ち明け話。',
    ),
    GameEvent(
      id: 'ind.sayo.4',
      category: EventCategory.individual,
      target: CharacterId.sayo,
      requiredAffinityStage: 4,
      title: '締切前夜の手伝い',
      locationLabel: '隣室の仕事机',
      script: [
        EventLine(text: '翻訳の締切前夜。隣室から、紅茶を取りに来てとメッセージが来た。'),
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.troubled,
          text: '——ごめん、もう紅茶が淹れられない手の状態で。'
              'お湯だけ、お願いしていい？',
        ),
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.normal,
          text: 'こういう日に頼れる相手、最近まで自分にいるって思ってなかった。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'お湯を注ぎながら、どう返すか。',
        choices: [
          EventChoice(
            label: '「呼んでくれて、よかったです」',
            outcome: ChoiceOutcome(
              label: '受け取る',
              affinityDelta: 2,
              trueAffinityDelta: 5,
            ),
          ),
          EventChoice(
            label: '「次は、もっと早めに呼んでください」',
            outcome: ChoiceOutcome(
              label: '関係を更新',
              affinityDelta: 3,
              trueAffinityDelta: 6,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.sayo.4',
      cgTitle: '締切前夜の机',
      cgCaption: 'キーボードの隣、湯気の立つ紅茶と原稿用紙の山。',
    ),
    GameEvent(
      id: 'ind.sayo.5',
      category: EventCategory.individual,
      target: CharacterId.sayo,
      requiredAffinityStage: 4,
      requiredMonth: 6,
      title: '雨の上がった廊下',
      locationLabel: 'マンションの共用廊下',
      script: [
        EventLine(text: '長く降った雨が、夜中にようやく上がった。'),
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.smile,
          text: '——前に話したこと、覚えててくれて、ありがとう。'
              'なんか、ちゃんと聞いてもらえてた気がする。',
        ),
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.normal,
          text: '次の梅雨も、たぶん、私はちょっとへこむ。'
              'そのときは、また廊下で会いましょう。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '何と返すか。',
        choices: [
          EventChoice(
            label: '「廊下じゃなくて、家でもいいですよ」',
            outcome: ChoiceOutcome(
              label: '一歩進む',
              affinityDelta: 3,
              trueAffinityDelta: 7,
            ),
          ),
          EventChoice(
            label: '「来年の梅雨も、ちゃんと隣にいます」',
            outcome: ChoiceOutcome(
              label: '関係を選ぶ',
              affinityDelta: 2,
              trueAffinityDelta: 8,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.sayo.5',
      cgTitle: '雨上がりの廊下',
      cgCaption: '長雨が止んだ夜、窓の外で街灯の光が静かに揺れていた。',
    ),
    GameEvent(
      id: 'ind.sayo.6',
      category: EventCategory.individual,
      target: CharacterId.sayo,
      requiredAffinityStage: 2,
      preferredSlot: 3, // night
      title: '夜の本貸し',
      locationLabel: 'マンションの廊下',
      script: [
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.smile,
          text: '——夜遅くにごめんなさい。'
              'この本、読み終わったから、よかったら。返却はいつでも。',
        ),
        EventLine(text: '差し出されたのは、紙の手触りが優しい1冊の文庫本だった。'),
      ],
      choice: EventChoiceScene(
        prompt: '受け取りながら、何と返すか。',
        choices: [
          EventChoice(
            label: '「読み終わったら、感想、長めに書きます」',
            outcome: ChoiceOutcome(
              label: '丁寧',
              affinityDelta: 2,
              trueAffinityDelta: 4,
            ),
          ),
          EventChoice(
            label: '「読み終えたら、紅茶のお礼に伺います」',
            outcome: ChoiceOutcome(
              label: '関係を進める',
              affinityDelta: 3,
              trueAffinityDelta: 3,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.sayo.6',
      cgTitle: '夜の貸し本',
      cgCaption: '廊下の灯りの下で受け取った、ひっそりした1冊。',
    ),
    GameEvent(
      id: 'ind.sayo.7',
      category: EventCategory.individual,
      target: CharacterId.sayo,
      requiredAffinityStage: 3,
      requiredMonth: 2,
      title: '冬の紅茶配達',
      locationLabel: 'マンションのドア越し',
      script: [
        EventLine(text: '凍えるような夜、玄関のドアを軽くノックする音。'),
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.normal,
          text: '——余ったから、おすそ分け。'
              'お湯だけ沸かして、好きに淹れて。',
        ),
        EventLine(text: '手渡されたティーバッグ4つ。指先が、ほんの少しだけ冷たかった。'),
      ],
      choice: EventChoiceScene(
        prompt: 'どう返すか。',
        choices: [
          EventChoice(
            label: '「次は、こちらから何か持っていきます」',
            outcome: ChoiceOutcome(
              label: '対等にする',
              affinityDelta: 2,
              trueAffinityDelta: 5,
            ),
          ),
          EventChoice(
            label: '「中で、一緒に淹れません？」',
            outcome: ChoiceOutcome(
              label: '一歩進む',
              affinityDelta: 3,
              trueAffinityDelta: 4,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.sayo.7',
      cgTitle: '冬のおすそ分け',
      cgCaption: '玄関先のティーバッグと、冷たい指先の温度。',
    ),
  ];

  // ===========================================================================
  // 槙原 結衣（yui）— ジム朝練 / 草大会の応援
  // ===========================================================================
  static const List<GameEvent> _yui = [
    GameEvent(
      id: 'ind.yui.1',
      category: EventCategory.individual,
      target: CharacterId.yui,
      requiredAffinityStage: 2,
      title: '朝練のあとのプロテイン',
      locationLabel: '週末通うジムのラウンジ',
      script: [
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.smile,
          text: 'お疲れさまでした！ プロテイン、私からのおごりです。'
              '——いつも来てくれてるお礼。',
        ),
        EventLine(text: '汗を拭きながら、結衣さんはいつもより少し饒舌だった。'),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.normal,
          text: '続けてくれる人がいるとね、こっちもやる気が違うんですよ。'
              'ほんとに。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'プロテインを受け取りながら何と返すか。',
        choices: [
          EventChoice(
            label: '「結衣さんのプログラム、続けやすいから」',
            outcome: ChoiceOutcome(
              label: '率直',
              affinityDelta: 2,
              trueAffinityDelta: 3,
            ),
          ),
          EventChoice(
            label: '「これからも、よろしくお願いします」',
            outcome: ChoiceOutcome(
              label: '丁寧',
              affinityDelta: 3,
              trueAffinityDelta: 2,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.yui.1',
      cgTitle: 'ラウンジのプロテイン',
      cgCaption: 'トレーニング後のラウンジ、おごってくれた小さなコップ。',
    ),
    GameEvent(
      id: 'ind.yui.2',
      category: EventCategory.individual,
      target: CharacterId.yui,
      requiredAffinityStage: 3,
      title: '元アスリートの話',
      locationLabel: 'ジムの隅のベンチ',
      script: [
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.troubled,
          text: '——前にね、競技、やってたんです。'
              'そこそこいい線まで行って、だけど、最後の大会で、ぜんぜん勝てなくて。',
        ),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.normal,
          text: '今は、別の形で勝負したい。'
              'SNSでフォロワー集めてるのも、その延長線。だから、続けたい。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'どう返すか。',
        choices: [
          EventChoice(
            label: '「結衣さんのトレーニング、ちゃんと結果出てます」',
            outcome: ChoiceOutcome(
              label: '事実で返す',
              affinityDelta: 2,
              trueAffinityDelta: 4,
            ),
          ),
          EventChoice(
            label: '「——その話、もう少し聞かせてください」',
            outcome: ChoiceOutcome(
              label: '寄り添う',
              affinityDelta: 1,
              trueAffinityDelta: 6,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.yui.2',
      cgTitle: 'ジムの隅のベンチ',
      cgCaption: 'タオルを首にかけて、過去の話を少しだけ聞かせてくれた時間。',
    ),
    GameEvent(
      id: 'ind.yui.3',
      category: EventCategory.individual,
      target: CharacterId.yui,
      requiredAffinityStage: 3,
      requiredMonth: 10,
      title: '草大会の応援',
      locationLabel: '河川敷のグラウンド',
      script: [
        EventLine(text: '秋晴れの河川敷。トラックの脇で、結衣さんが軽くストレッチしている。'),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.smile,
          text: '見に来てくれて、ありがとう！ 草大会だけど、'
              '——けっこう、本気で走ります。',
        ),
        EventLine(text: 'スタートの号砲が鳴る。フォームが整っていて、見ていてまっすぐ気持ちが良い。'),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.normal,
          text: '——ありがとう。'
              '誰かが見てる、っていうだけで、こんなに走れるんだって、はじめて分かった。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'ゴール後、何と声をかけるか。',
        choices: [
          EventChoice(
            label: '「めちゃくちゃ速かったです」',
            outcome: ChoiceOutcome(
              label: '事実',
              affinityDelta: 3,
              trueAffinityDelta: 4,
            ),
          ),
          EventChoice(
            label: '「これからも、見に来ます」',
            outcome: ChoiceOutcome(
              label: '約束',
              affinityDelta: 2,
              trueAffinityDelta: 6,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.yui.3',
      cgTitle: '河川敷のスタートライン',
      cgCaption: '秋晴れの河川敷、ゴールで振り返って手を上げてくれた瞬間。',
    ),
    GameEvent(
      id: 'ind.yui.4',
      category: EventCategory.individual,
      target: CharacterId.yui,
      requiredAffinityStage: 4,
      title: 'SNSの裏側',
      locationLabel: 'ジム閉店後のロビー',
      script: [
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.troubled,
          text: 'SNSってね、数字が伸びると嬉しいんだけど、'
              'ときどき、心が削れるコメントも来るんです。',
        ),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.normal,
          text: 'こういう話、トレーナーは普通お客さんにしないんだけど。'
              '——あなたには、なんか、言える。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'どう返すか。',
        choices: [
          EventChoice(
            label: '「全部の数字に応える必要ないですよ」',
            outcome: ChoiceOutcome(
              label: '線を引く',
              affinityDelta: 2,
              trueAffinityDelta: 5,
            ),
          ),
          EventChoice(
            label: '「次のしんどい日、また話してください」',
            outcome: ChoiceOutcome(
              label: '関係を更新',
              affinityDelta: 1,
              trueAffinityDelta: 7,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.yui.4',
      cgTitle: '閉店後のロビー',
      cgCaption: '消灯前のロビー、スマホを見ながらぽつりとこぼした本音。',
    ),
    GameEvent(
      id: 'ind.yui.5',
      category: EventCategory.individual,
      target: CharacterId.yui,
      requiredAffinityStage: 4,
      requiredMonth: 3,
      title: '次の春の目標',
      locationLabel: '河川敷の朝',
      script: [
        EventLine(text: '春の朝、結衣さんは河川敷を軽くジョグしていた。'),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.smile,
          text: '次の大会、出ます。'
              '——勝つためじゃなくて、最後まで気持ちよく走るために。',
        ),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.normal,
          text: 'あなたが見てる、っていう前提で、たぶん私はもう走れる。'
              'それでいい？',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '何と返すか。',
        choices: [
          EventChoice(
            label: '「次の大会も、絶対見に行きます」',
            outcome: ChoiceOutcome(
              label: '伴走',
              affinityDelta: 3,
              trueAffinityDelta: 6,
            ),
          ),
          EventChoice(
            label: '「——一緒に、走ってもいいですか」',
            outcome: ChoiceOutcome(
              label: '関係を選ぶ',
              affinityDelta: 2,
              trueAffinityDelta: 8,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.yui.5',
      cgTitle: '春の朝の河川敷',
      cgCaption: '春の朝、軽いジョグの横を歩きながら次の目標を聞いた時間。',
    ),
    GameEvent(
      id: 'ind.yui.6',
      category: EventCategory.individual,
      target: CharacterId.yui,
      requiredAffinityStage: 3,
      requiredMonth: 8,
      title: '夏の朝練プラン',
      locationLabel: 'ジムのホワイトボード',
      script: [
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.smile,
          text: '——夏は5時起き、川沿いを30分。これ、一緒にやらない？',
        ),
        EventLine(text: 'ホワイトボードに描かれているのは、季節ごとに区切られたメニュー表。'),
      ],
      choice: EventChoiceScene(
        prompt: 'メニューを見ながら、どう返すか。',
        choices: [
          EventChoice(
            label: '「やります。続ける自信、もらいに来ます」',
            outcome: ChoiceOutcome(
              label: '挑戦',
              affinityDelta: 3,
              trueAffinityDelta: 3,
            ),
          ),
          EventChoice(
            label: '「週2回からでもいいですか？」',
            outcome: ChoiceOutcome(
              label: '無理しない',
              affinityDelta: 1,
              trueAffinityDelta: 5,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.yui.6',
      cgTitle: '夏のメニュー表',
      cgCaption: '色分けされたホワイトボードと、夏の早朝の予定。',
    ),
    GameEvent(
      id: 'ind.yui.7',
      category: EventCategory.individual,
      target: CharacterId.yui,
      requiredAffinityStage: 4,
      preferredSlot: 0, // morning
      title: '朝の伴走',
      locationLabel: '河川敷の朝',
      script: [
        EventLine(text: '冷えた朝、待ち合わせの河川敷に向かうと、彼女はすでに軽くアップしていた。'),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.normal,
          text: '——今日は、私のペースじゃなくて、'
              'あなたのペースで走ってみたい。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '走り出しながら、どう返すか。',
        choices: [
          EventChoice(
            label: '「ゆっくり、足音が揃うところまで」',
            outcome: ChoiceOutcome(
              label: '伴走',
              affinityDelta: 2,
              trueAffinityDelta: 5,
            ),
          ),
          EventChoice(
            label: '「最後だけ、ちょっとだけ追います」',
            outcome: ChoiceOutcome(
              label: '挑戦',
              affinityDelta: 3,
              trueAffinityDelta: 3,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.yui.7',
      cgTitle: '朝の伴走',
      cgCaption: '冷えた河川敷、足音を揃える練習をした朝。',
    ),
  ];
}

// `preferredSlot` の数値は `SlotIndex.values.indexOf(slot)` と等価：
//  morning=0, midday=1, evening=2, night=3。
// イベント定義側でハードコードしているのは、`const` 評価可能な int
// しか許容できないため。`SlotIndex.values` の宣言順が変わったらここの
// マジックナンバーも追従する必要がある（テストで気付ける構造）。
