import '../models/character.dart';
import '../models/dialogue.dart';
import '../models/event.dart';

/// Sprint 08: 各キャラ 5 本ずつ（合計 25 本）の個別イベント。
///
/// character_profiles.md（社会人版・正典）の職業に沿ってモチーフを設計：
/// - 七瀬 灯（カフェ研究員）: 試作と試飲 / 商品開発
/// - 久遠 詩（出版社編集者）: ゲラと朗読会 / 企画
/// - 鴻巣 透（スポーツメーカー営業）: 製品テスト / 論理的な提案
/// - 蓮見 紗夜（デザイナー）: 夜のアトリエ / 紅茶と猫
/// - 槙原 結衣（楽器店スタッフ）: 試奏とライブ / バンド
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
  // 七瀬 灯（akari）— カフェ研究員 / 商品開発 / 試作と試飲
  // ===========================================================================
  static const List<GameEvent> _akari = [
    GameEvent(
      id: 'ind.akari.1',
      category: EventCategory.individual,
      target: CharacterId.akari,
      requiredAffinityStage: 2,
      title: '試作の一杯',
      locationLabel: 'カフェの試作カウンター',
      script: [
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.normal,
          text: '——お疲れさま。さっき味の感想、ちゃんと聞こえてたよ。よく舌が動いてる。',
        ),
        EventLine(text: '閉店後の試作カウンターで、七瀬さんが小さなカップをひとつ差し出してきた。新作ブレンドの試作だという。'),
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.smile,
          text: '私もね、最初の頃は「美味しい」しか言えなかった。だから言葉に詰まっても恥ずかしがらなくていい。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '七瀬さんに何と返そうか。',
        choices: [
          EventChoice(
            label: '「ありがとうございます。すごく好きな味です」',
            outcome: ChoiceOutcome(
              label: '無難',
              affinityDelta: 2,
              trueAffinityDelta: 1,
            ),
          ),
          EventChoice(
            label: '「七瀬さんは、最初どうやって舌を鍛えたんですか？」',
            outcome: ChoiceOutcome(
              label: '踏み込む',
              affinityDelta: 1,
              trueAffinityDelta: 4,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.akari.1',
      cgTitle: '試作カウンターの一杯',
      cgCaption: '閉店後、試作のカップを片手に立っていた研究員の横顔。',
    ),
    GameEvent(
      id: 'ind.akari.2',
      category: EventCategory.individual,
      target: CharacterId.akari,
      requiredAffinityStage: 3,
      title: '焙煎の話',
      locationLabel: 'カフェ近くの公園のベンチ',
      script: [
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.smile,
          text: '——お昼、ここで食べていい？ あ、ごめん、聞いてから座ればよかった。',
        ),
        EventLine(text: '七瀬さんのカバンから、生豆のサンプルが入った小瓶がいくつも顔をのぞかせている。'),
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.normal,
          text: '焙煎って、一度火を入れたら戻せないの。豆のポテンシャルを当日の温度や湿度で読む。'
              '失敗した日の豆ほど、忘れたころに教えてくれることがある。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '焙煎について何か聞いてみる。',
        choices: [
          EventChoice(
            label: '「いつか焙煎、見せてもらえます？」',
            outcome: ChoiceOutcome(
              label: '距離を縮める',
              affinityDelta: 2,
              trueAffinityDelta: 2,
            ),
          ),
          EventChoice(
            label: '「その小瓶の豆、飲み比べてみたいです」',
            outcome: ChoiceOutcome(
              label: '丁寧',
              affinityDelta: 1,
              trueAffinityDelta: 3,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.akari.2',
      cgTitle: '公園の生豆サンプル',
      cgCaption: '昼下がりの公園、小瓶の生豆を並べて話す人の横顔。',
    ),
    GameEvent(
      id: 'ind.akari.3',
      category: EventCategory.individual,
      target: CharacterId.akari,
      requiredAffinityStage: 3,
      requiredMonth: 9,
      title: '新作の試飲会',
      locationLabel: 'カフェの試飲イベント会場',
      script: [
        EventLine(text: '休日の昼、カフェの一角で開かれた小さな新作試飲会。'),
        EventLine(text: '会場の中ほどで、エプロン姿の七瀬さんが、こちらに小さく手を振った。'),
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.smile,
          text: '来てくれたんだ。——あの、緊張するから、感想は帰り際でいいから。',
        ),
        EventLine(text: 'カウンターに並ぶのは、季節をテーマにした数種の試作ブレンド。どれも誰かを思い浮かべて作ったような味がする。'),
      ],
      choice: EventChoiceScene(
        prompt: '帰り際、何を伝えるか。',
        choices: [
          EventChoice(
            label: '「どれも、知らない香りなのに、懐かしい気がしました」',
            outcome: ChoiceOutcome(
              label: '本音',
              affinityDelta: 2,
              trueAffinityDelta: 5,
            ),
          ),
          EventChoice(
            label: '「次の新作も、絶対飲みに来ます」',
            outcome: ChoiceOutcome(
              label: '前向き',
              affinityDelta: 3,
              trueAffinityDelta: 2,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.akari.3',
      cgTitle: 'カフェの試飲イベント',
      cgCaption: '並んだ試作ブレンドの前で、ぽつりと話した時間。',
    ),
    GameEvent(
      id: 'ind.akari.4',
      category: EventCategory.individual,
      target: CharacterId.akari,
      requiredAffinityStage: 4,
      title: '商品化の壁',
      locationLabel: 'カフェ近くの居酒屋',
      script: [
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.troubled,
          text: '——ごめん、こんな話するつもりじゃなかったんだけど。上の方針が、ちょっとね。',
        ),
        EventLine(text: '隅の席で、七瀬さんはグラスを両手で包むようにしていた。'),
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.normal,
          text: '原価を下げて量産しろって。私が一番いいと思った配合は、コストで通らなかった。'
              '——いい豆を、いい状態で届けたいだけなんだけどな。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'どう応えるか。',
        choices: [
          EventChoice(
            label: '「七瀬さんが信じた味が、一番正しいと思います」',
            outcome: ChoiceOutcome(
              label: '味方になる',
              affinityDelta: 2,
              trueAffinityDelta: 6,
            ),
          ),
          EventChoice(
            label: '「——その配合の話、もう少し聞いてもいいですか」',
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
      cgCaption: 'グラスを両手で包んで、ぽつぽつと仕事の悩みを話していた夜。',
    ),
    GameEvent(
      id: 'ind.akari.5',
      category: EventCategory.individual,
      target: CharacterId.akari,
      requiredAffinityStage: 4,
      requiredMonth: 11,
      title: '冬の朝、決めたこと',
      locationLabel: 'カフェの開店前',
      script: [
        EventLine(text: '冷たい朝、開店前のカフェで、七瀬さんが手を上げた。'),
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.normal,
          text: '——量産の話、断らなかった。代わりに、季節限定の小ロットで通すことにした。'
              '妥協じゃなくて、両方やる。',
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
            label: '「これからも、味の話、聞かせてください」',
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
      title: '五月の新メニュー会議',
      locationLabel: 'カフェのバックヤード',
      script: [
        EventLine(
          speaker: CharacterId.akari,
          expression: Expression.smile,
          text: '——五月って、ホットからアイスへ切り替える季節なの。'
              '今日の試作、よかったら味見してって。',
        ),
        EventLine(text: '作業台の脇には、彼女の手書きのレシピノートが広げられている。'),
      ],
      choice: EventChoiceScene(
        prompt: '味見のあと、どう声をかけるか。',
        choices: [
          EventChoice(
            label: '「このレシピ、店のおすすめに推していいと思います」',
            outcome: ChoiceOutcome(
              label: '広める',
              affinityDelta: 2,
              trueAffinityDelta: 3,
            ),
          ),
          EventChoice(
            label: '「今日の配合、家でも淹れてみます」',
            outcome: ChoiceOutcome(
              label: '実践',
              affinityDelta: 1,
              trueAffinityDelta: 4,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.akari.6',
      cgTitle: '五月のバックヤード',
      cgCaption: '手書きのレシピノートと、味見を待つ小さなカップ。',
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
              'いま淹れてて、思いついた配合があって。いまなら言える気がして。',
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
            label: '「明日、その一杯、お店で飲ませてください」',
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
  // 久遠 詩（uta）— 出版社編集者 / ゲラと朗読会 / 言葉
  // ===========================================================================
  static const List<GameEvent> _uta = [
    GameEvent(
      id: 'ind.uta.1',
      category: EventCategory.individual,
      target: CharacterId.uta,
      requiredAffinityStage: 2,
      preferredSlot: 0, // morning
      title: '朝の常連扱い',
      locationLabel: '通勤路の書店併設カフェ',
      script: [
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.smile,
          text: 'おはようございます。今日も窓際の席、空いてますよ。',
        ),
        EventLine(text: '出社前にゲラを読むのが日課だという。席の好みまで覚えてくれている。'),
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.normal,
          text: '朝のうちに赤を入れておくと、頭が一番冴えてるんです。'
              '始業前って、わりとそういう時間で。',
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
      cgTitle: '朝のゲラと珈琲',
      cgCaption: '窓際の席で、ゲラに赤を入れながら微笑む顔。',
    ),
    GameEvent(
      id: 'ind.uta.2',
      category: EventCategory.individual,
      target: CharacterId.uta,
      requiredAffinityStage: 3,
      title: 'テーブル越しの相談',
      locationLabel: '夕方の書店併設カフェ',
      script: [
        EventLine(text: '夕方、原稿の束を前に、詩さんは珍しくぼんやりしていた。'),
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.troubled,
          text: '——実はね、今月、ちょっと厳しくて。'
              '担当してる作家さんが、筆が止まっちゃって。締切も、部数も、宙ぶらりんで。',
        ),
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.normal,
          text: 'ごめんなさい、外の人に話すことじゃないですよね。'
              '——でも、なんか、あなたには言いたかった。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '何と返すか。',
        choices: [
          EventChoice(
            label: '「その本、出たら絶対読みます。一読者として」',
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
      cgTitle: '夕方の原稿の束',
      cgCaption: '原稿越しに、ふと素顔を見せてくれた時間。',
    ),
    GameEvent(
      id: 'ind.uta.3',
      category: EventCategory.individual,
      target: CharacterId.uta,
      requiredAffinityStage: 3,
      requiredMonth: 8,
      title: '閉店後の朗読会',
      locationLabel: '閉店後の書店',
      script: [
        EventLine(text: '閉店の札が下げられたあとの書店で、小さな朗読会が開かれた。'),
        EventLine(text: '集まったのは10人ほど。詩さんは担当した本を抱えて、低い声で一節を読み始める。'),
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.smile,
          text: '——招いてよかった。来てくれて、ありがとう。',
        ),
        EventLine(text: '読まれたのは、彼女が三年かけて世に出したという一冊の冒頭だった。'),
      ],
      choice: EventChoiceScene(
        prompt: '朗読後、声をかける。',
        choices: [
          EventChoice(
            label: '「あの一節、手元に置いておきたいくらいでした」',
            outcome: ChoiceOutcome(
              label: '素直',
              affinityDelta: 2,
              trueAffinityDelta: 5,
            ),
          ),
          EventChoice(
            label: '「続き、もう一度読んでください」',
            outcome: ChoiceOutcome(
              label: '深く',
              affinityDelta: 1,
              trueAffinityDelta: 6,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.uta.3',
      cgTitle: '閉店後の朗読会',
      cgCaption: '10人だけの朗読会、担当した本の一節を低い声で聴いた夜。',
    ),
    GameEvent(
      id: 'ind.uta.4',
      category: EventCategory.individual,
      target: CharacterId.uta,
      requiredAffinityStage: 4,
      title: '初めての企画書',
      locationLabel: '休日の喫茶店',
      script: [
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.normal,
          text: '休みの日にごめんなさい。——あの、初めて自分で企画した本、出すことになったんです。',
        ),
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.smile,
          text: '誰にも言わずに進めようとしたんだけど、結局、誰かに言いたくなって。'
              'あなたが浮かんだ。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'どう応えるか。',
        choices: [
          EventChoice(
            label: '「最初の読者になります。読ませてください」',
            outcome: ChoiceOutcome(
              label: '伴走',
              affinityDelta: 2,
              trueAffinityDelta: 6,
            ),
          ),
          EventChoice(
            label: '「あなたが選んだ本だから、ちゃんと届くと思います」',
            outcome: ChoiceOutcome(
              label: '応援',
              affinityDelta: 3,
              trueAffinityDelta: 4,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.uta.4',
      cgTitle: '休日の企画書',
      cgCaption: 'テーブルの上に置かれた、書きかけの「企画書」の一枚。',
    ),
    GameEvent(
      id: 'ind.uta.5',
      category: EventCategory.individual,
      target: CharacterId.uta,
      requiredAffinityStage: 4,
      requiredMonth: 12,
      title: '冬の朝、見本誌',
      locationLabel: '書店併設カフェの開店直前',
      script: [
        EventLine(text: '凍えるような朝、開店前のカフェにあたたかい湯気が漂っていた。'),
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.smile,
          text: '寒いですよね。よかったら、開店前に1杯どうぞ。'
              '——それと、これ。刷り上がったばかりの見本誌です。',
        ),
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.normal,
          text: '企画のこと、応援してくれて、ありがとうございました。'
              'お礼って言うほどじゃないですけど、最初の一冊はあなたに。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '見本誌を受け取りながら、何と返すか。',
        choices: [
          EventChoice(
            label: '「ここの朝の時間、当分やめられないですね」',
            outcome: ChoiceOutcome(
              label: '受け取る',
              affinityDelta: 3,
              trueAffinityDelta: 5,
            ),
          ),
          EventChoice(
            label: '「次は——お礼じゃなくて、ふつうに会いに来ます」',
            outcome: ChoiceOutcome(
              label: '関係を選ぶ',
              affinityDelta: 2,
              trueAffinityDelta: 8,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.uta.5',
      cgTitle: '冬の朝の見本誌',
      cgCaption: '開店前の店内、湯気の向こうで差し出された一冊。',
    ),
    GameEvent(
      id: 'ind.uta.6',
      category: EventCategory.individual,
      target: CharacterId.uta,
      requiredAffinityStage: 2,
      preferredSlot: 2, // evening
      title: '夕方のゲラ読み',
      locationLabel: '夕方の書店併設カフェ',
      script: [
        EventLine(
          speaker: CharacterId.uta,
          expression: Expression.smile,
          text: '今日、新しいゲラが出たんです。'
              '——一読者として、感想を聞かせてもらえますか？',
        ),
        EventLine(text: '校正刷りの束が2つ、テーブルに並んだ。'),
      ],
      choice: EventChoiceScene(
        prompt: '一節読んでから、何と返すか。',
        choices: [
          EventChoice(
            label: '「冒頭の一行、いつもより少し冷たいですね」',
            outcome: ChoiceOutcome(
              label: '言語化',
              affinityDelta: 2,
              trueAffinityDelta: 3,
            ),
          ),
          EventChoice(
            label: '「これ、絶対に世に出してほしいです」',
            outcome: ChoiceOutcome(
              label: '即決',
              affinityDelta: 3,
              trueAffinityDelta: 2,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.uta.6',
      cgTitle: '夕方のゲラ読み',
      cgCaption: '校正刷りの束2つと、夕方のテーブルに広がるインクの匂い。',
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
          text: '——明日は、珍しく定時で上がれそうなんです。'
              'よかったら、担当作家でも一読者でもなく、一緒に歩きませんか。',
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
            label: '「校了、手伝います。それから」',
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
  // 鴻巣 透（toru）— スポーツメーカー営業 / 製品テスト / 論理的な提案
  // ===========================================================================
  static const List<GameEvent> _toru = [
    GameEvent(
      id: 'ind.toru.1',
      category: EventCategory.individual,
      target: CharacterId.toru,
      requiredAffinityStage: 2,
      title: 'メールの返信、早すぎる',
      locationLabel: '退社後のメール画面',
      script: [
        EventLine(text: '退社して数分、仕事のメールが届いた。'),
        EventLine(
          speaker: CharacterId.toru,
          expression: Expression.normal,
          text: '昼間の件、提案書を作り直しました。添付の見積り、見てもらえますか。'
              '今夜じゃなくていいです。',
        ),
        EventLine(text: '——たぶん、退社後すぐに直したんだろう。フットワークの軽さと丁寧さが両立している。'),
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
            label: '「今読みました。この納入条件だけ気になります」',
            outcome: ChoiceOutcome(
              label: '即応',
              affinityDelta: 3,
              trueAffinityDelta: 2,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.toru.1',
      cgTitle: '夜の提案書',
      cgCaption: '退社直後に送られてきた、丁寧に作り直された提案書。',
    ),
    GameEvent(
      id: 'ind.toru.2',
      category: EventCategory.individual,
      target: CharacterId.toru,
      requiredAffinityStage: 3,
      title: '線引きの話',
      locationLabel: '商談後の休憩スペース',
      script: [
        EventLine(
          speaker: CharacterId.toru,
          expression: Expression.troubled,
          text: '——あの、ちょっと、前の話で。'
              '商談のあと、いつもより少し早めに上がらせてください。',
        ),
        EventLine(text: '声のトーンが、いつもより少し低い。'),
        EventLine(
          speaker: CharacterId.toru,
          expression: Expression.normal,
          text: '前の職場で、数字に追われて線引きを誤って、結構しんどい時期があったんです。'
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
            label: '「鴻巣さんが無理なく走れる方を、最優先で」',
            outcome: ChoiceOutcome(
              label: '配慮',
              affinityDelta: 1,
              trueAffinityDelta: 6,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.toru.2',
      cgTitle: '休憩スペースの窓辺',
      cgCaption: '窓の外を見ながら、過去の話を少しだけ聞かせてくれた時間。',
    ),
    GameEvent(
      id: 'ind.toru.3',
      category: EventCategory.individual,
      target: CharacterId.toru,
      requiredAffinityStage: 3,
      requiredMonth: 9,
      title: '論理的な納品調整',
      locationLabel: 'オンライン商談',
      script: [
        EventLine(text: '画面の中、鴻巣さんは資料を共有しながら淡々と話している。'),
        EventLine(
          speaker: CharacterId.toru,
          expression: Expression.normal,
          text: '結論、納品を1週間ずらせば、在庫・価格・配送、どれも安全圏に入ります。'
              '判断はそちらに委ねますが、根拠は3点あります。',
        ),
        EventLine(text: '——勢いではなく、根拠で売る人。だからこそ、信頼できる。'),
      ],
      choice: EventChoiceScene(
        prompt: '商談の最後、何と返すか。',
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
            label: '「持ち帰って、店舗側と擦り合わせます」',
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
      title: '製品テストの写真',
      locationLabel: 'チャットの画像',
      script: [
        EventLine(text: '週末、チャットに画像が1枚だけ送られてきた。'),
        EventLine(text: '新作のランニングシューズ、コーヒーのボトル、河原のトレイル。背景は朝の山並み。'),
        EventLine(
          speaker: CharacterId.toru,
          expression: Expression.normal,
          text: '新作の試走です、というだけの報告です。'
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
            label: '「いつか、そのコース、一緒に走らせてください」',
            outcome: ChoiceOutcome(
              label: '関心',
              affinityDelta: 1,
              trueAffinityDelta: 6,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.toru.4',
      cgTitle: 'トレイルと新作シューズ',
      cgCaption: 'チャットに1枚だけ届いた、静かな週末の試走の景色。',
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
              '——前に話した「線引き」の件、今の働き方なら大丈夫みたいです。',
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
      title: '秋の展示会トラブル',
      locationLabel: 'オンライン緊急通話',
      script: [
        EventLine(text: '展示会の搬入直前、画面の中で鴻巣さんが資料を共有している。'),
        EventLine(
          speaker: CharacterId.toru,
          expression: Expression.troubled,
          text: '——いま、こちらで止まってる箇所、3つ。'
              '在庫の振り分け、1つだけ、判断、頼んでもいいですか。',
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
            label: '「新作シューズ、見せてくれません？」',
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
  // 蓮見 紗夜（sayo）— デザイナー / 夜のアトリエ / 紅茶と猫
  // ===========================================================================
  static const List<GameEvent> _sayo = [
    GameEvent(
      id: 'ind.sayo.1',
      category: EventCategory.individual,
      target: CharacterId.sayo,
      requiredAffinityStage: 2,
      preferredSlot: 3, // night
      title: '深夜のコワーキング',
      locationLabel: '深夜のコワーキングスペース',
      script: [
        EventLine(text: '日付が変わったころ、給湯コーナーに行くと、紗夜さんがモニターの光の前に座っていた。'),
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.normal,
          text: 'こんばんは。——お仕事、遅かったみたいですね。'
              '無理しないようにね。',
        ),
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.smile,
          text: '私は夜型だから、こういう時間にここで会うと、なんだか嬉しい。',
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
      cgTitle: '深夜の給湯コーナー',
      cgCaption: '日付が変わる頃、モニターの光の前で交わした静かな挨拶。',
    ),
    GameEvent(
      id: 'ind.sayo.2',
      category: EventCategory.individual,
      target: CharacterId.sayo,
      requiredAffinityStage: 3,
      title: '紅茶と猫',
      locationLabel: '紗夜さんのアトリエ',
      script: [
        EventLine(text: '招かれて入ったアトリエは、色見本と作品集、それに紅茶缶でいっぱいだった。'),
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.smile,
          text: '物はあんまり買わないんだけど、作品集と紅茶だけはね、つい。'
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
            label: '「その作品集、見ていてもいいですか？」',
            outcome: ChoiceOutcome(
              label: '深く知る',
              affinityDelta: 1,
              trueAffinityDelta: 5,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.sayo.2',
      cgTitle: '作品集と紅茶缶',
      cgCaption: '足元でゆっくり尻尾を振る三毛猫と、湯気の立つカップ。',
    ),
    GameEvent(
      id: 'ind.sayo.3',
      category: EventCategory.individual,
      target: CharacterId.sayo,
      requiredAffinityStage: 3,
      requiredMonth: 6,
      title: '雨の日の窓辺',
      locationLabel: 'コワーキングの窓辺',
      script: [
        EventLine(text: '梅雨の夕方、仕事場の窓に雨が叩きつけている。'),
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
      cgTitle: '雨の窓辺',
      cgCaption: '梅雨の夕方、雨の音と一緒に聞いた小さな打ち明け話。',
    ),
    GameEvent(
      id: 'ind.sayo.4',
      category: EventCategory.individual,
      target: CharacterId.sayo,
      requiredAffinityStage: 4,
      title: '入稿前夜の差し入れ',
      locationLabel: 'アトリエの作業机',
      script: [
        EventLine(text: 'デザインの入稿前夜。アトリエから、紅茶を淹れに来てとメッセージが来た。'),
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.troubled,
          text: '——ごめん、もう手がペンタブから離せない状態で。'
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
      cgTitle: '入稿前夜の机',
      cgCaption: 'ペンタブの隣、湯気の立つ紅茶と色見本の山。',
    ),
    GameEvent(
      id: 'ind.sayo.5',
      category: EventCategory.individual,
      target: CharacterId.sayo,
      requiredAffinityStage: 4,
      requiredMonth: 6,
      title: '雨の上がった窓辺',
      locationLabel: 'コワーキングの窓辺',
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
              'そのときは、また、ここで会いましょう。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '何と返すか。',
        choices: [
          EventChoice(
            label: '「ここじゃなくて、アトリエでもいいですよ」',
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
      cgTitle: '雨上がりの窓辺',
      cgCaption: '長雨が止んだ夜、窓の外で街灯の光が静かに揺れていた。',
    ),
    GameEvent(
      id: 'ind.sayo.6',
      category: EventCategory.individual,
      target: CharacterId.sayo,
      requiredAffinityStage: 2,
      preferredSlot: 3, // night
      title: '夜の作品集貸し',
      locationLabel: '夜のアトリエ前',
      script: [
        EventLine(
          speaker: CharacterId.sayo,
          expression: Expression.smile,
          text: '——夜遅くにごめんなさい。'
              'この画集、見終わったから、よかったら。返却はいつでも。',
        ),
        EventLine(text: '差し出されたのは、紙の手触りが優しい1冊の作品集だった。'),
      ],
      choice: EventChoiceScene(
        prompt: '受け取りながら、何と返すか。',
        choices: [
          EventChoice(
            label: '「見終わったら、感想、長めに書きます」',
            outcome: ChoiceOutcome(
              label: '丁寧',
              affinityDelta: 2,
              trueAffinityDelta: 4,
            ),
          ),
          EventChoice(
            label: '「見終えたら、紅茶のお礼に伺います」',
            outcome: ChoiceOutcome(
              label: '関係を進める',
              affinityDelta: 3,
              trueAffinityDelta: 3,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.sayo.6',
      cgTitle: '夜の貸し画集',
      cgCaption: 'アトリエの灯りの下で受け取った、ひっそりした1冊。',
    ),
    GameEvent(
      id: 'ind.sayo.7',
      category: EventCategory.individual,
      target: CharacterId.sayo,
      requiredAffinityStage: 3,
      requiredMonth: 2,
      title: '冬の紅茶の差し入れ',
      locationLabel: 'コワーキングのデスク越し',
      script: [
        EventLine(text: '凍えるような夜、デスクの仕切りを軽くノックする音。'),
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
            label: '「アトリエで、一緒に淹れません？」',
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
      cgCaption: 'デスク越しのティーバッグと、冷たい指先の温度。',
    ),
  ];

  // ===========================================================================
  // 槙原 結衣（yui）— 楽器店スタッフ / 試奏とライブ / バンド
  // ===========================================================================
  static const List<GameEvent> _yui = [
    GameEvent(
      id: 'ind.yui.1',
      category: EventCategory.individual,
      target: CharacterId.yui,
      requiredAffinityStage: 2,
      title: '試奏のあとの一杯',
      locationLabel: '楽器店のスタッフルーム',
      script: [
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.smile,
          text: 'お疲れさまでした！ これ、私からのおごりです。'
              '——いつも試奏に付き合ってくれてるお礼。',
        ),
        EventLine(text: 'カウンター裏で、結衣さんは缶を差し出しながらいつもより少し饒舌だった。'),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.normal,
          text: '弾いてくれる人がいるとね、こっちも紹介のしがいが違うんですよ。'
              'ほんとに。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '一杯を受け取りながら何と返すか。',
        choices: [
          EventChoice(
            label: '「結衣さんが選んでくれる楽器、弾きやすいから」',
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
      cgTitle: 'スタッフルームの一杯',
      cgCaption: '試奏のあとのスタッフルーム、おごってくれた小さな缶。',
    ),
    GameEvent(
      id: 'ind.yui.2',
      category: EventCategory.individual,
      target: CharacterId.yui,
      requiredAffinityStage: 3,
      title: '元バンドの話',
      locationLabel: '楽器店の試奏ブース',
      script: [
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.troubled,
          text: '——前にね、バンド、やってたんです。'
              'そこそこいい線まで行って、だけど、最後のライブで、ぜんぜん鳴らせなくて。',
        ),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.normal,
          text: '今は、別の形で音楽に関わりたい。'
              'お店のSNSで弾いてみた動画を上げてるのも、その延長線。だから、続けたい。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: 'どう返すか。',
        choices: [
          EventChoice(
            label: '「結衣さんの紹介で楽器を始めた人、ちゃんといます」',
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
      cgTitle: '試奏ブースの隅',
      cgCaption: 'ギターを抱えたまま、過去の話を少しだけ聞かせてくれた時間。',
    ),
    GameEvent(
      id: 'ind.yui.3',
      category: EventCategory.individual,
      target: CharacterId.yui,
      requiredAffinityStage: 3,
      requiredMonth: 10,
      title: '路上ライブの応援',
      locationLabel: '駅前の小さな野外ステージ',
      script: [
        EventLine(text: '秋晴れの駅前広場。小さなステージの脇で、結衣さんがギターを抱え直している。'),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.smile,
          text: '見に来てくれて、ありがとう！ お店主催の路上ライブだけど、'
              '——けっこう、本気で弾きます。',
        ),
        EventLine(text: '最初の一音が鳴る。指の運びが滑らかで、聴いていてまっすぐ気持ちが良い。'),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.normal,
          text: '——ありがとう。'
              '誰かが聴いてる、っていうだけで、こんなに弾けるんだって、はじめて分かった。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '演奏後、何と声をかけるか。',
        choices: [
          EventChoice(
            label: '「めちゃくちゃ良かったです」',
            outcome: ChoiceOutcome(
              label: '事実',
              affinityDelta: 3,
              trueAffinityDelta: 4,
            ),
          ),
          EventChoice(
            label: '「これからも、聴きに来ます」',
            outcome: ChoiceOutcome(
              label: '約束',
              affinityDelta: 2,
              trueAffinityDelta: 6,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.yui.3',
      cgTitle: '駅前のステージ',
      cgCaption: '秋晴れの駅前広場、弾き終えて振り返り手を上げてくれた瞬間。',
    ),
    GameEvent(
      id: 'ind.yui.4',
      category: EventCategory.individual,
      target: CharacterId.yui,
      requiredAffinityStage: 4,
      title: 'SNSの裏側',
      locationLabel: '閉店後の楽器店',
      script: [
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.troubled,
          text: 'お店の演奏動画ってね、再生数が伸びると嬉しいんだけど、'
              'ときどき、心が削れるコメントも来るんです。',
        ),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.normal,
          text: 'こういう話、店員は普通お客さんにしないんだけど。'
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
      cgTitle: '閉店後の店内',
      cgCaption: '消灯前の店内、スマホを見ながらぽつりとこぼした本音。',
    ),
    GameEvent(
      id: 'ind.yui.5',
      category: EventCategory.individual,
      target: CharacterId.yui,
      requiredAffinityStage: 4,
      requiredMonth: 3,
      title: '次の春の目標',
      locationLabel: '開店前の楽器店',
      script: [
        EventLine(text: '春の朝、結衣さんは開店前の店内で軽く弦を鳴らしていた。'),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.smile,
          text: '次の音楽フェス、出ます。'
              '——勝つためじゃなくて、最後まで気持ちよく弾くために。',
        ),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.normal,
          text: 'あなたが聴いてる、っていう前提で、たぶん私はもう弾ける。'
              'それでいい？',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '何と返すか。',
        choices: [
          EventChoice(
            label: '「次のフェスも、絶対聴きに行きます」',
            outcome: ChoiceOutcome(
              label: '伴走',
              affinityDelta: 3,
              trueAffinityDelta: 6,
            ),
          ),
          EventChoice(
            label: '「——一緒に、ステージに立ってもいいですか」',
            outcome: ChoiceOutcome(
              label: '関係を選ぶ',
              affinityDelta: 2,
              trueAffinityDelta: 8,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.yui.5',
      cgTitle: '春の朝の楽器店',
      cgCaption: '春の朝、弦の音の横で次の目標を聞いた時間。',
    ),
    GameEvent(
      id: 'ind.yui.6',
      category: EventCategory.individual,
      target: CharacterId.yui,
      requiredAffinityStage: 3,
      requiredMonth: 8,
      title: '夏のバンド練習プラン',
      locationLabel: '楽器店のスタジオ',
      script: [
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.smile,
          text: '——夏は朝のスタジオを30分。夏フェスに向けて、これ、一緒にやらない？',
        ),
        EventLine(text: 'ホワイトボードに描かれているのは、季節ごとに区切られた練習スケジュール表。'),
      ],
      choice: EventChoiceScene(
        prompt: 'スケジュールを見ながら、どう返すか。',
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
      cgTitle: '夏の練習スケジュール',
      cgCaption: '色分けされたホワイトボードと、夏の早朝の予定。',
    ),
    GameEvent(
      id: 'ind.yui.7',
      category: EventCategory.individual,
      target: CharacterId.yui,
      requiredAffinityStage: 4,
      preferredSlot: 0, // morning
      title: '朝のセッション',
      locationLabel: '開店前のスタジオ',
      script: [
        EventLine(text: '冷えた朝、待ち合わせのスタジオに向かうと、彼女はすでに軽くチューニングしていた。'),
        EventLine(
          speaker: CharacterId.yui,
          expression: Expression.normal,
          text: '——今日は、私のテンポじゃなくて、'
              'あなたのテンポに合わせてみたい。',
        ),
      ],
      choice: EventChoiceScene(
        prompt: '弾き出しながら、どう返すか。',
        choices: [
          EventChoice(
            label: '「ゆっくり、音が揃うところまで」',
            outcome: ChoiceOutcome(
              label: '伴走',
              affinityDelta: 2,
              trueAffinityDelta: 5,
            ),
          ),
          EventChoice(
            label: '「最後のサビだけ、ちょっとだけ攻めます」',
            outcome: ChoiceOutcome(
              label: '挑戦',
              affinityDelta: 3,
              trueAffinityDelta: 3,
            ),
          ),
        ],
      ),
      cgKey: 'cg.ind.yui.7',
      cgTitle: '朝のセッション',
      cgCaption: '冷えたスタジオ、音を揃える練習をした朝。',
    ),
  ];
}

// `preferredSlot` の数値は `SlotIndex.values.indexOf(slot)` と等価：
//  morning=0, midday=1, evening=2, night=3。
// イベント定義側でハードコードしているのは、`const` 評価可能な int
// しか許容できないため。`SlotIndex.values` の宣言順が変わったらここの
// マジックナンバーも追従する必要がある（テストで気付ける構造）。
