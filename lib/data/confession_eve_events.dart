import '../models/character.dart';
import '../models/dialogue.dart';
import '../models/event.dart';

/// 告白前夜イベント（5 名分）。
///
/// 個別 ED の AND 条件として組み込まれる「最後の選択」シーン。
/// 既存の個別イベント 5 本を消化し、表面好感度 75 以上 + 真の好感度 15 以上に
/// 達したキャラに対して 1 度だけ発火する。
///
/// 発火後は `CharacterState.unlockedEventIds` に `confession_eve.{id}` が追加され、
/// `EndingResolver._resolveIndividual` の AND 条件としてチェックされる。
///
/// イベントカテゴリは [EventCategory.individual] を流用するが、
/// `IndividualEventCatalog.all` には **含めない**（既存個別イベントの優先発火と
/// 経路を分離するため）。`EventResolver.resolveConfessionEve` が独立に走査する。
class ConfessionEveCatalog {
  ConfessionEveCatalog._();

  /// 告白前夜の発火しきい値: 表面好感度（80 = 個別 ED 必要値 の手前）。
  static const int kConfessionEveAffinityFloor = 75;

  /// 告白前夜の発火しきい値: 真の好感度（20 = 個別 ED 必要値 の手前）。
  static const int kConfessionEveTrueAffinityFloor = 15;

  /// 指定キャラ向けの「告白前夜 ID」。`CharacterState.unlockedEventIds` のキー。
  static String idFor(CharacterId id) => 'confession_eve.${id.name}';

  static final List<GameEvent> all = List<GameEvent>.unmodifiable(<GameEvent>[
    _akari,
    _uta,
    _toru,
    _sayo,
    _yui,
  ]);

  static GameEvent? forCharacter(CharacterId id) {
    for (final ev in all) {
      if (ev.target == id) return ev;
    }
    return null;
  }

  static final GameEvent _akari = GameEvent(
    id: 'confession_eve.akari',
    category: EventCategory.individual,
    target: CharacterId.akari,
    title: '告白前夜 ― 春のあと',
    locationLabel: '帰り道の歩道橋',
    script: const [
      EventLine(text: '会社からの帰り、歩道橋の上で七瀬さんと並んだ。'),
      EventLine(
        speaker: CharacterId.akari,
        expression: Expression.normal,
        text: '——明日、ちょっと話していい時間、もらえる？ 大事なこと。',
      ),
      EventLine(text: '街灯の光が、彼女の頬を半分だけ照らしていた。'),
      EventLine(
        speaker: CharacterId.akari,
        expression: Expression.troubled,
        text: '言いたいこと、ずっと考えてた。'
            '——でも、その前に、あなたの返事を聞かせてほしい。',
      ),
    ],
    choice: EventChoiceScene(
      prompt: '七瀬さんの言葉に、どう応えるか。',
      choices: [
        EventChoice(
          label: '「次の春も、隣で歩いていたいです」',
          outcome: ChoiceOutcome(
            label: '受け止める',
            affinityDelta: 5,
            trueAffinityDelta: 8,
          ),
        ),
        EventChoice(
          label: '「明日、ちゃんと聞きます。準備していきます」',
          outcome: ChoiceOutcome(
            label: '誠実',
            affinityDelta: 3,
            trueAffinityDelta: 6,
          ),
        ),
      ],
    ),
    cgKey: 'cg.confession_eve.akari',
    cgTitle: '歩道橋の宵',
    cgCaption: '街灯に半分だけ照らされた横顔と、夜風の中の小さな約束。',
  );

  static final GameEvent _uta = GameEvent(
    id: 'confession_eve.uta',
    category: EventCategory.individual,
    target: CharacterId.uta,
    title: '告白前夜 ― 看板を下ろす前に',
    locationLabel: '閉店間際のカフェ',
    script: const [
      EventLine(text: '閉店時間ぎりぎりのカフェ、客は自分ひとりだった。'),
      EventLine(
        speaker: CharacterId.uta,
        expression: Expression.normal,
        text: '——看板を下ろす前に、一度だけ、ちゃんと話したくて。',
      ),
      EventLine(
        speaker: CharacterId.uta,
        expression: Expression.troubled,
        text: 'お店のことも、私自身のことも、'
            'あなたに伝えたいことが、たぶん同じ場所にある。',
      ),
      EventLine(text: 'カウンターに置かれた珈琲は、湯気が立ったままだった。'),
    ],
    choice: EventChoiceScene(
      prompt: '珈琲を一口飲んでから、何と返すか。',
      choices: [
        EventChoice(
          label: '「あなたの店の、最後のお客さんでいさせてください」',
          outcome: ChoiceOutcome(
            label: '関係を選ぶ',
            affinityDelta: 4,
            trueAffinityDelta: 9,
          ),
        ),
        EventChoice(
          label: '「明日、改めて、ちゃんと聞かせてください」',
          outcome: ChoiceOutcome(
            label: '誠実',
            affinityDelta: 3,
            trueAffinityDelta: 6,
          ),
        ),
      ],
    ),
    cgKey: 'cg.confession_eve.uta',
    cgTitle: '湯気の立つ閉店前',
    cgCaption: '閉店間際のカウンター、ひと組ぶんの珈琲と静かな夜。',
  );

  static final GameEvent _toru = GameEvent(
    id: 'confession_eve.toru',
    category: EventCategory.individual,
    target: CharacterId.toru,
    title: '告白前夜 ― 線引きの外側',
    locationLabel: '深夜のチャット',
    script: const [
      EventLine(text: '深夜、業務外のチャネルに、見慣れない宛名で通知が来た。'),
      EventLine(
        speaker: CharacterId.toru,
        expression: Expression.normal,
        text: '仕事の話じゃないです。——明日、業務時間の外で、'
            '少しだけ時間をもらえませんか。',
      ),
      EventLine(
        speaker: CharacterId.toru,
        expression: Expression.troubled,
        text: '線を引いたつもりで、結局、線の外側で考えてしまうことがある。'
            'それを、ちゃんと言葉にしておきたい。',
      ),
    ],
    choice: EventChoiceScene(
      prompt: '深夜の返信に、何と書くか。',
      choices: [
        EventChoice(
          label: '「業務時間の外で、ちゃんと聞きます」',
          outcome: ChoiceOutcome(
            label: '線の外側',
            affinityDelta: 4,
            trueAffinityDelta: 9,
          ),
        ),
        EventChoice(
          label: '「明日、いつでも。ちゃんと準備しておきます」',
          outcome: ChoiceOutcome(
            label: '誠実',
            affinityDelta: 3,
            trueAffinityDelta: 6,
          ),
        ),
      ],
    ),
    cgKey: 'cg.confession_eve.toru',
    cgTitle: '深夜のチャット',
    cgCaption: '業務外チャネルに灯った、いつもと違う宛名の通知。',
  );

  static final GameEvent _sayo = GameEvent(
    id: 'confession_eve.sayo',
    category: EventCategory.individual,
    target: CharacterId.sayo,
    title: '告白前夜 ― ドアの内側',
    locationLabel: 'マンションの七階・廊下',
    script: const [
      EventLine(text: '日付が変わった廊下、紗夜さんは部屋のドアを少しだけ開けていた。'),
      EventLine(
        speaker: CharacterId.sayo,
        expression: Expression.normal,
        text: '——明日、もう一度、廊下じゃなくて、ちゃんとドアの内側で話したい。',
      ),
      EventLine(
        speaker: CharacterId.sayo,
        expression: Expression.troubled,
        text: '一度しくじってるから、慎重になりすぎる。'
            'でも、いまの距離は、もう怖いだけじゃない。',
      ),
    ],
    choice: EventChoiceScene(
      prompt: 'ドアの前で、何と返すか。',
      choices: [
        EventChoice(
          label: '「明日、ドアの内側で、ちゃんと話を聞きます」',
          outcome: ChoiceOutcome(
            label: '受け止める',
            affinityDelta: 4,
            trueAffinityDelta: 9,
          ),
        ),
        EventChoice(
          label: '「あなたのペースで、いつでも」',
          outcome: ChoiceOutcome(
            label: '寄り添う',
            affinityDelta: 3,
            trueAffinityDelta: 7,
          ),
        ),
      ],
    ),
    cgKey: 'cg.confession_eve.sayo',
    cgTitle: '半分開いたドア',
    cgCaption: '深夜の廊下、半分だけ開けられたドアと小さな灯り。',
  );

  static final GameEvent _yui = GameEvent(
    id: 'confession_eve.yui',
    category: EventCategory.individual,
    target: CharacterId.yui,
    title: '告白前夜 ― スタートラインの前夜',
    locationLabel: '河川敷のベンチ',
    script: const [
      EventLine(text: '大会前夜の河川敷、結衣さんはストレッチを終えてベンチに腰掛けていた。'),
      EventLine(
        speaker: CharacterId.yui,
        expression: Expression.normal,
        text: '——明日のゴールの後、少しだけ、走らない話をしてもいい？',
      ),
      EventLine(
        speaker: CharacterId.yui,
        expression: Expression.troubled,
        text: '勝ち負けじゃないことを、誰かと並んで決めたいときがある。'
            'いま、ちょうど、そういう夜です。',
      ),
    ],
    choice: EventChoiceScene(
      prompt: 'ベンチの隣で、何と返すか。',
      choices: [
        EventChoice(
          label: '「明日のゴールの後で、ちゃんと聞きます」',
          outcome: ChoiceOutcome(
            label: '伴走',
            affinityDelta: 4,
            trueAffinityDelta: 9,
          ),
        ),
        EventChoice(
          label: '「走らない夜の話、今夜、少しだけ」',
          outcome: ChoiceOutcome(
            label: '隣に居る',
            affinityDelta: 3,
            trueAffinityDelta: 7,
          ),
        ),
      ],
    ),
    cgKey: 'cg.confession_eve.yui',
    cgTitle: 'スタートライン前夜',
    cgCaption: '大会前夜のベンチ、隣に並んで聞いた走らない話。',
  );
}
