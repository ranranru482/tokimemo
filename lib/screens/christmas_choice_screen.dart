import 'package:flutter/material.dart';

import '../app.dart';
import '../data/character_repository.dart';
import '../models/character.dart';
import '../models/dialogue.dart';
import '../models/event.dart';
import '../widgets/character_portrait.dart';
import '../widgets/event_player.dart';
import '../widgets/page_transitions.dart';

/// Sprint 08: 12/24 クリスマスの「誰と過ごすか」選択画面（節目イベント）。
///
/// 仕様書 §7「節目イベントは『誰と過ごすか』を選択する画面が出る。
/// 誰も選ばず一人で過ごす選択肢もあり、これは特定エンディングの分岐条件」。
///
/// 出会い済みのキャラから 1 名を選んで「専用シーン」を再生する。
/// 「一人で過ごす」も選択肢の一つとして提示する（特定 ED フラグとして
/// 利用される予定。Sprint 08 では UI とシーン再生まで実装）。
class ChristmasChoiceScreen extends StatelessWidget {
  const ChristmasChoiceScreen({super.key});

  static Future<ChristmasChoiceResult?> show(BuildContext context) {
    return Navigator.of(context).push<ChristmasChoiceResult>(
      slideUpRoute<ChristmasChoiceResult>(
        (_) => const ChristmasChoiceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = AppScope.of(context);
    final met = <Character>[
      for (final c in CharacterRepository.all)
        if (scope.gameState.hasMet(c.id)) c,
    ];

    return Scaffold(
      key: const ValueKey('christmasChoice.root'),
      appBar: AppBar(
        title: const Text('クリスマスイブの夜'),
        leading: IconButton(
          key: const ValueKey('christmasChoice.close'),
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '今夜、誰と過ごしますか？',
                key: const ValueKey('christmasChoice.title'),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '出会った人の中から1名選ぶか、'
                '「一人で過ごす」を選ぶこともできます。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: met.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    if (i < met.length) {
                      final c = met[i];
                      return _ChoiceTile(
                        keyValue: 'christmasChoice.pick.${c.id.name}',
                        leading: CharacterPortrait(character: c, size: 48),
                        title: c.displayName,
                        subtitle: c.roleLabel,
                        onTap: () async {
                          final result = await _runChristmasFor(context, c);
                          if (context.mounted) {
                            Navigator.of(context).pop(result);
                          }
                        },
                      );
                    }
                    // 一人で過ごす
                    return _ChoiceTile(
                      keyValue: 'christmasChoice.pick.alone',
                      leading: const Icon(Icons.brightness_2, size: 40),
                      title: '一人で過ごす',
                      subtitle: '自分の時間を選ぶ',
                      onTap: () async {
                        final result = await _runAlone(context);
                        if (context.mounted) {
                          Navigator.of(context).pop(result);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// キャラを選んだ場合の専用シーンを再生する。
  Future<ChristmasChoiceResult> _runChristmasFor(
    BuildContext context,
    Character target,
  ) async {
    final ev = buildChristmasEventFor(target.id);
    await EventPlayer.show(context, event: ev);
    return ChristmasChoiceResult(
      pickedCharacter: target.id,
      eventId: ev.id,
      cgKey: ev.cgKey,
    );
  }

  Future<ChristmasChoiceResult> _runAlone(BuildContext context) async {
    final ev = _buildAloneEvent();
    await EventPlayer.show(context, event: ev);
    return ChristmasChoiceResult(
      pickedCharacter: null,
      eventId: ev.id,
      cgKey: ev.cgKey,
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.keyValue,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String keyValue;
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        key: ValueKey(keyValue),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// クリスマスの結果データ。`HomeScreen` 側で受けて
/// `GameState.applyChoiceOutcome` を呼ぶ + CG を解放する。
class ChristmasChoiceResult {
  const ChristmasChoiceResult({
    required this.pickedCharacter,
    required this.eventId,
    required this.cgKey,
  });

  final CharacterId? pickedCharacter; // null は「一人で過ごす」
  final String eventId;
  final String? cgKey;
}

/// 一人で過ごすルートの簡素なシーン（Sprint 08）。
GameEvent _buildAloneEvent() {
  return const GameEvent(
    id: 'milestone.christmas.alone',
    category: EventCategory.milestone,
    title: '一人のクリスマス',
    locationLabel: '自宅のソファ',
    script: [
      EventLine(text: '部屋の電気を少し落として、ホットココアを淹れた。'),
      EventLine(text: '——誰かと過ごす夜も悪くないが、一人の夜にも、ちゃんとした重みがある。'),
      EventLine(text: '明日の自分を、今日の自分が静かに迎えにいく。そんな24日があってもいい。'),
    ],
    cgKey: 'cg.milestone.christmas.alone',
    cgTitle: '一人のクリスマス',
    cgCaption: '電気を落とした部屋で、ホットココアの湯気を見ていた夜。',
  );
}

/// キャラ別クリスマスシーンを動的に組み立てる。
///
/// テスト・本実装の両方から呼ぶため、トップレベル関数として公開する。
GameEvent buildChristmasEventFor(CharacterId id) {
  switch (id) {
    case CharacterId.akari:
      return const GameEvent(
        id: 'milestone.christmas.akari',
        category: EventCategory.milestone,
        target: CharacterId.akari,
        title: '七瀬さんと過ごすイブ',
        locationLabel: '灯さんのカフェ、閉店後',
        script: [
          EventLine(
            speaker: CharacterId.akari,
            expression: Expression.smile,
            text: '——来てくれて、ありがとう。家族とすごす日じゃない、私たちらしいクリスマスね。',
          ),
          EventLine(text: '窓の外、街路樹のイルミネーションがゆっくり点滅している。'),
          EventLine(
            speaker: CharacterId.akari,
            expression: Expression.normal,
            text: 'なんでもない夜が、こうして特別になるのって、'
                '実は結構、難しいことだと思う。',
          ),
          EventLine(
            speaker: CharacterId.akari,
            expression: Expression.smile,
            text: '——よかったら、来年の今日も、また予定空けておいて。',
          ),
        ],
        choice: EventChoiceScene(
          prompt: '何と返すか。',
          choices: [
            EventChoice(
              label: '「ちゃんと、空けておきます」',
              outcome: ChoiceOutcome(
                label: '約束',
                affinityDelta: 4,
                trueAffinityDelta: 6,
              ),
            ),
          ],
        ),
        cgKey: 'cg.milestone.christmas.akari',
        cgTitle: '夜のカフェの窓辺',
        cgCaption: 'イルミネーションを背にして「来年も」と言ってくれた夜。',
      );
    case CharacterId.uta:
      return const GameEvent(
        id: 'milestone.christmas.uta',
        category: EventCategory.milestone,
        target: CharacterId.uta,
        title: '詩さんと過ごすイブ',
        locationLabel: '閉店後の書店併設カフェ',
        script: [
          EventLine(
            speaker: CharacterId.uta,
            expression: Expression.smile,
            text: 'いらっしゃい。今夜は貸切ってことにしました。'
                '——あなただけのために。',
          ),
          EventLine(text: 'テーブルにはホットチョコレートと、淹れたての珈琲が並んでいる。'),
          EventLine(
            speaker: CharacterId.uta,
            expression: Expression.normal,
            text: '今夜、一節だけ読みます。誰にも見せていない、書きかけの企画書の前書き。',
          ),
          EventLine(text: '低く読み上げる声が、静かな店内に染みていく。'),
        ],
        choice: EventChoiceScene(
          prompt: '聴き終えた後、何と返すか。',
          choices: [
            EventChoice(
              label: '「最初に読んでくれて、本当にありがとう」',
              outcome: ChoiceOutcome(
                label: '受け取る',
                affinityDelta: 4,
                trueAffinityDelta: 7,
              ),
            ),
          ],
        ),
        cgKey: 'cg.milestone.christmas.uta',
        cgTitle: '貸切の閉店後',
        cgCaption: '読み上げる声が、静かな店内に染みていった夜。',
      );
    case CharacterId.toru:
      return const GameEvent(
        id: 'milestone.christmas.toru',
        category: EventCategory.milestone,
        target: CharacterId.toru,
        title: '鴻巣さんと過ごすイブ',
        locationLabel: '走り納めのあとの河川敷',
        script: [
          EventLine(
            speaker: CharacterId.toru,
            expression: Expression.normal,
            text: '——イブに走り納めって、変ですか。'
                '人が多い場所より、こっちの方が、たぶん、合ってる。',
          ),
          EventLine(text: '携帯バーナーの火に手をかざすと、街の音が遠くなる。'),
          EventLine(
            speaker: CharacterId.toru,
            expression: Expression.smile,
            text: 'コーヒー、淹れます。豆だけは持ってきたので。',
          ),
        ],
        choice: EventChoiceScene(
          prompt: '何と返すか。',
          choices: [
            EventChoice(
              label: '「合ってます。この夜、すごく」',
              outcome: ChoiceOutcome(
                label: '受け止める',
                affinityDelta: 4,
                trueAffinityDelta: 6,
              ),
            ),
          ],
        ),
        cgKey: 'cg.milestone.christmas.toru',
        cgTitle: '河川敷の走り納め',
        cgCaption: '街の音が遠くなる夜、コーヒー豆だけ持ってきた人と。',
      );
    case CharacterId.sayo:
      return const GameEvent(
        id: 'milestone.christmas.sayo',
        category: EventCategory.milestone,
        target: CharacterId.sayo,
        title: '蓮見さんと過ごすイブ',
        locationLabel: '紗夜さんのアトリエ',
        script: [
          EventLine(
            speaker: CharacterId.sayo,
            expression: Expression.smile,
            text: '——うちのアトリエでよかったら、どうぞ。'
                '紅茶、新しい缶を開けたの。',
          ),
          EventLine(text: '足元では三毛猫が一番暖かい場所を陣取って、目を細めている。'),
          EventLine(
            speaker: CharacterId.sayo,
            expression: Expression.normal,
            text: '前のクリスマスは、なかったことにしてた。'
                '——今年は、ちゃんと過ごせて、よかった。',
          ),
        ],
        choice: EventChoiceScene(
          prompt: '何と返すか。',
          choices: [
            EventChoice(
              label: '「来年も、ここで紅茶、飲ませてください」',
              outcome: ChoiceOutcome(
                label: '関係を選ぶ',
                affinityDelta: 4,
                trueAffinityDelta: 7,
              ),
            ),
          ],
        ),
        cgKey: 'cg.milestone.christmas.sayo',
        cgTitle: '紅茶の缶と三毛猫',
        cgCaption: '新しく開けた紅茶缶と、足元で目を細める猫。',
      );
    case CharacterId.yui:
      return const GameEvent(
        id: 'milestone.christmas.yui',
        category: EventCategory.milestone,
        target: CharacterId.yui,
        title: '槙原さんと過ごすイブ',
        locationLabel: '夜の楽器店の小さな打ち上げ',
        script: [
          EventLine(
            speaker: CharacterId.yui,
            expression: Expression.smile,
            text: '今夜は閉店後の貸切！ 一緒に打ち上げです。'
                '——試奏、よく付き合ってくれましたよね。',
          ),
          EventLine(text: 'ホワイトボードに「今年もありがとう」とマーカーで書いてある。'),
          EventLine(
            speaker: CharacterId.yui,
            expression: Expression.normal,
            text: '来年は、ふたりでフェスのステージに立ってみたいんです。'
                '——一緒に。',
          ),
        ],
        choice: EventChoiceScene(
          prompt: '何と返すか。',
          choices: [
            EventChoice(
              label: '「一緒に、立ちます」',
              outcome: ChoiceOutcome(
                label: '伴走',
                affinityDelta: 4,
                trueAffinityDelta: 7,
              ),
            ),
          ],
        ),
        cgKey: 'cg.milestone.christmas.yui',
        cgTitle: '貸切の夜の楽器店',
        cgCaption: 'ホワイトボードの「今年もありがとう」と、来年への約束。',
      );
  }
}
