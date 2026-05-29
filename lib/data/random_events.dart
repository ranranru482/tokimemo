import '../models/dialogue.dart';
import '../models/event.dart';

/// Sprint 08: 出勤途中の小ネタ（ランダム遭遇）イベント。
///
/// spec §7: 出勤・通勤・ランチ・カフェ等で 5〜15% の確率で発火する
/// 「短い会話 / 小幅な能力値変動 / 隠しフラグ蓄積」が目的。
///
/// 内容は無難な日常イベント。既存IPに触れる固有名詞は使わない。
///
/// 各イベントは 2〜4 行で完結し、選択肢は付けない（瞬間的な遭遇）。
/// 効果は [GameEvent.choice] ではなく、`unlockMessage` を画面に出すことと、
/// 必要に応じて HomeScreen 側で軽い能力値変動を適用する想定。
/// Sprint 08 では「unlock した」事実のみ記録し、能力値変動は EventPlayer から
/// 単一の固定 ChoiceOutcome（自動採用）として渡す形を採用する。
class RandomEventCatalog {
  RandomEventCatalog._();

  static final List<GameEvent> all = List<GameEvent>.unmodifiable(<GameEvent>[
    _stationEncounter,
    _conveniCoupon,
    _crowdedTrain,
    _strayCat,
    _morningWalk,
    _busDelay,
    _vendingMachine,
    _kindStranger,
  ]);

  // ランダム遭遇では選択肢を出さない代わりに、効果を「採用済の単一の
  // ChoiceOutcome」としてイベント末尾に持たせる。EventPlayer から
  // 自動的に GameState.applyChoiceOutcome 相当の処理が呼ばれる構造。
  // 影響対象キャラはいないため、ストレスや所持金のみが動く形にする。

  static const GameEvent _stationEncounter = GameEvent(
    id: 'rnd.station_encounter',
    category: EventCategory.random,
    title: '駅で知人を見かける',
    locationLabel: '通勤駅のホーム',
    script: [
      EventLine(text: '改札を抜けたところで、昔の同期にそっくりな後ろ姿を見かけた。'),
      EventLine(text: '——たぶん、人違い。けれど、思い出すきっかけにはなる。'),
    ],
    choice: EventChoiceScene(
      choices: [
        EventChoice(
          label: '（先を急ぐ）',
          outcome: ChoiceOutcome(label: 'ふつう', stressDelta: -1),
        ),
      ],
    ),
    unlockMessage: '昔の同期を思い出した。少しだけ気分が引き締まる。',
  );

  static const GameEvent _conveniCoupon = GameEvent(
    id: 'rnd.conveni_coupon',
    category: EventCategory.random,
    title: 'コンビニで割引クーポン',
    locationLabel: '通勤路のコンビニ',
    script: [
      EventLine(text: 'コーヒーを買おうとレジに並ぶと、店員が新発売の引換券をそっと渡してくれた。'),
      EventLine(text: 'なんでもない朝に、なんでもない得をした気分になる。'),
    ],
    choice: EventChoiceScene(
      choices: [
        EventChoice(
          label: '（受け取る）',
          outcome: ChoiceOutcome(label: 'ふつう', stressDelta: -2),
        ),
      ],
    ),
    unlockMessage: '小さな得をした。ストレスが少し下がった。',
  );

  static const GameEvent _crowdedTrain = GameEvent(
    id: 'rnd.crowded_train',
    category: EventCategory.random,
    title: '満員電車',
    locationLabel: '通勤電車の車内',
    script: [
      EventLine(text: '人身事故のあおりで、いつもより一段密度の高い車内。'),
      EventLine(text: '吊り革にも届かず、ただ揺られる10分間。'),
    ],
    choice: EventChoiceScene(
      choices: [
        EventChoice(
          label: '（耐える）',
          outcome: ChoiceOutcome(label: 'ふつう', stressDelta: 4),
        ),
      ],
    ),
    unlockMessage: '満員電車に揉まれた。少し疲れた。',
  );

  static const GameEvent _strayCat = GameEvent(
    id: 'rnd.stray_cat',
    category: EventCategory.random,
    title: 'のら猫に癒される',
    locationLabel: '路地の塀の上',
    script: [
      EventLine(text: '出勤途中の路地で、塀の上にいたキジトラと目が合った。'),
      EventLine(text: 'ゆっくり瞬きを返してくれる。それだけで、1日が少し優しくなる。'),
    ],
    choice: EventChoiceScene(
      choices: [
        EventChoice(
          label: '（手を振って通り過ぎる）',
          outcome: ChoiceOutcome(label: 'ふつう', stressDelta: -3),
        ),
      ],
    ),
    unlockMessage: 'のら猫に癒された。ストレスが少し和らいだ。',
  );

  static const GameEvent _morningWalk = GameEvent(
    id: 'rnd.morning_walk',
    category: EventCategory.random,
    title: '一駅手前で降りる',
    locationLabel: '通勤路の歩道',
    script: [
      EventLine(text: '気まぐれで、いつもより一駅手前で降りて歩く。'),
      EventLine(text: '知らない街の朝も、案外、悪くない。'),
    ],
    choice: EventChoiceScene(
      choices: [
        EventChoice(
          label: '（軽い歩幅で進む）',
          outcome: ChoiceOutcome(label: 'ふつう', stressDelta: -2),
        ),
      ],
    ),
    unlockMessage: '一駅歩いた。少しだけ体が温まる。',
  );

  static const GameEvent _busDelay = GameEvent(
    id: 'rnd.bus_delay',
    category: EventCategory.random,
    title: 'バスが遅れている',
    locationLabel: 'バス停の屋根の下',
    script: [
      EventLine(text: '時刻表より10分以上遅れていて、人が次々に通り過ぎる。'),
      EventLine(text: '——スマホの予定表を、少し早めにずらしておこう。'),
    ],
    choice: EventChoiceScene(
      choices: [
        EventChoice(
          label: '（諦めて待つ）',
          outcome: ChoiceOutcome(label: 'ふつう', stressDelta: 3),
        ),
      ],
    ),
    unlockMessage: 'バスが遅れて少しイライラした。',
  );

  static const GameEvent _vendingMachine = GameEvent(
    id: 'rnd.vending_machine',
    category: EventCategory.random,
    title: '当たり付きの自販機',
    locationLabel: '駅前の自動販売機',
    script: [
      EventLine(text: '何の気なしに押した自販機で、画面に「もう1本」の文字が光った。'),
      EventLine(text: '誰に話すでもない、ちょっとした事件。'),
    ],
    choice: EventChoiceScene(
      choices: [
        EventChoice(
          label: '（もう1本もらう）',
          outcome: ChoiceOutcome(label: 'ふつう', stressDelta: -2),
        ),
      ],
    ),
    unlockMessage: '当たりが出た。今日の小さなご褒美。',
  );

  static const GameEvent _kindStranger = GameEvent(
    id: 'rnd.kind_stranger',
    category: EventCategory.random,
    title: '見知らぬ人の親切',
    locationLabel: '横断歩道の前',
    script: [
      EventLine(text: '落としたICカードを、後ろを歩いていた人が拾って手渡してくれた。'),
      EventLine(text: '「お礼を言う暇もなく信号が変わる」が、こっちが恥ずかしくなるくらい綺麗だった。'),
    ],
    choice: EventChoiceScene(
      choices: [
        EventChoice(
          label: '（深くお辞儀する）',
          outcome: ChoiceOutcome(label: 'ふつう', stressDelta: -2),
        ),
      ],
    ),
    unlockMessage: '見知らぬ人の親切に少しだけ救われた。',
  );
}
