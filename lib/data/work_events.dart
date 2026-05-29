import 'dart:math';

import '../models/character.dart';
import '../models/stats.dart';

/// Sprint C: 仕事中イベントカタログ。
///
/// 平日日中の枠タップ時、確率 [kWorkEventPercent]% で WorkResolver の即ロール
/// 代わりに 1 件のイベントを抽選する。各イベントは 2 つの選択肢を持ち、
/// 選んだ結果が仕事評価・ストレス・所持金・能力値・特定キャラとの好感度に反映される。
///
/// 既存の `WorkResolver`/`WorkOutcome` は無変更。本ファイルは並列ルートを足すだけ。
class WorkEvent {
  const WorkEvent({
    required this.id,
    required this.category,
    required this.title,
    required this.situation,
    required this.choices,
  });

  /// 一意 ID（命名規約: `work_event.<category>.<short>`）。
  final String id;
  final WorkEventCategory category;
  final String title;

  /// プロンプト本文（地の文 + 状況説明）。Speaker は category に応じた呼び名を
  /// ダイアログ側で差し込む。
  final String situation;

  final List<WorkChoice> choices;
}

enum WorkEventCategory {
  boss,
  colleague,
  project,
  mistake,
  chance,
}

class WorkChoice {
  const WorkChoice({
    required this.label,
    required this.resultText,
    required this.effect,
  });

  final String label;

  /// 選択後にダイアログに表示する 1〜2 行の結果テキスト。
  final String resultText;

  final WorkChoiceEffect effect;
}

/// 選択肢の効果。`Map<StatKind, int>` に展開可能。
/// 同僚イベントでは `affinityTarget` + `affinityDelta` で表面好感度を動かす。
class WorkChoiceEffect {
  const WorkChoiceEffect({
    this.career = 0,
    this.stress = 0,
    this.vitality = 0,
    this.money = 0,
    this.intellect = 0,
    this.sensibility = 0,
    this.sociability = 0,
    this.affinityTarget,
    this.affinityDelta = 0,
    this.trueAffinityDelta = 0,
  });

  final int career;
  final int stress;
  final int vitality;
  final int money;
  final int intellect;
  final int sensibility;
  final int sociability;

  /// 出会い済みのキャラに好感度を加算する場合の対象。未会いキャラなら無視。
  final CharacterId? affinityTarget;
  final int affinityDelta;
  final int trueAffinityDelta;

  Map<StatKind, int> toDeltas() {
    final m = <StatKind, int>{};
    if (career != 0) m[StatKind.career] = career;
    if (stress != 0) m[StatKind.stress] = stress;
    if (vitality != 0) m[StatKind.vitality] = vitality;
    if (money != 0) m[StatKind.wallet] = money;
    if (intellect != 0) m[StatKind.intellect] = intellect;
    if (sensibility != 0) m[StatKind.sensibility] = sensibility;
    if (sociability != 0) m[StatKind.sociability] = sociability;
    return m;
  }
}

/// 仕事中イベントの発火確率（％）。35% で抽選し、外れたら従来の WorkResolver。
const int kWorkEventPercent = 35;

class WorkEventCatalog {
  WorkEventCatalog._();

  static final List<WorkEvent> all = List<WorkEvent>.unmodifiable(<WorkEvent>[
    // ----------------------------------------------------------------
    // 上司イベント
    // ----------------------------------------------------------------
    const WorkEvent(
      id: 'work_event.boss.big_deal',
      category: WorkEventCategory.boss,
      title: '大型案件の打診',
      situation:
          '部長に呼ばれて会議室へ。\n「来期の主要クライアント、君に任せてみたい。受けるか？」',
      choices: [
        WorkChoice(
          label: '受ける（責任は重いが、評価が上がる）',
          resultText:
              '腹を括って受けた。徹夜気味のスケジュールが組まれたが、\n仕事評価が大きく上がった。',
          effect: WorkChoiceEffect(
            career: 8,
            stress: 6,
            intellect: 2,
            vitality: -4,
          ),
        ),
        WorkChoice(
          label: '今は手一杯と伝える（安全策）',
          resultText:
              '正直に伝えた。部長は少し残念そうだったが、\n無理せず済んで気は楽だ。',
          effect: WorkChoiceEffect(
            career: -1,
            stress: -2,
            sociability: 1,
          ),
        ),
      ],
    ),
    const WorkEvent(
      id: 'work_event.boss.scolded',
      category: WorkEventCategory.boss,
      title: '進捗の遅れを叱責された',
      situation:
          '昨日提出した資料の不備で、課長から呼び出された。\n「言い訳より、どう取り戻すかを聞かせてくれ」',
      choices: [
        WorkChoice(
          label: '即座に謝罪し、改善案を 3 つ示す',
          resultText:
              '段取りで返した。課長の表情がほぐれ、\n仕事評価は微増、信頼はわずかに戻った。',
          effect: WorkChoiceEffect(
            career: 3,
            stress: 2,
            intellect: 1,
          ),
        ),
        WorkChoice(
          label: '体調不良を理由に弁明する',
          resultText:
              '言い訳になってしまった。気まずさだけが残り、\nストレスが増した。',
          effect: WorkChoiceEffect(
            career: -3,
            stress: 6,
          ),
        ),
      ],
    ),
    // ----------------------------------------------------------------
    // 同僚イベント
    // ----------------------------------------------------------------
    const WorkEvent(
      id: 'work_event.colleague.help_request',
      category: WorkEventCategory.colleague,
      title: '会議資料の手伝いを頼まれた',
      situation:
          '隣席の同僚が、午後の会議資料に追加スライドが要ると慌てている。\n「30 分だけ、見てもらえないかな」',
      choices: [
        WorkChoice(
          label: '手を止めて手伝う',
          resultText:
              '結局 1 時間かかったが、同僚は心底ほっとしていた。\n社交スキルが少し伸びた気がする。',
          effect: WorkChoiceEffect(
            career: 1,
            stress: 3,
            sociability: 3,
            affinityTarget: CharacterId.akari,
            affinityDelta: 1,
            trueAffinityDelta: 2,
          ),
        ),
        WorkChoice(
          label: '自分の案件を優先する',
          resultText:
              '自分の進捗を優先した。同僚は別の人に頼んでいた。\n仕事は前に進んだが、少し罪悪感が残る。',
          effect: WorkChoiceEffect(
            career: 3,
            stress: 1,
          ),
        ),
      ],
    ),
    const WorkEvent(
      id: 'work_event.colleague.lunch_invite',
      category: WorkEventCategory.colleague,
      title: 'ランチに誘われる',
      situation:
          '昼休み、同期から「久しぶりに、外でランチでもどう？」と声をかけられた。\n気になっていたパスタの店らしい。',
      choices: [
        WorkChoice(
          label: '同行する',
          resultText:
              '気分転換になった。話の中で、\n別部署の動きをいくつか聞けた。',
          effect: WorkChoiceEffect(
            stress: -5,
            money: -1200,
            sociability: 2,
            sensibility: 1,
          ),
        ),
        WorkChoice(
          label: 'デスクで仕事を進める',
          resultText:
              'コンビニで済ませ、午後の予定を片付けた。\n効率は良かったが、頭は休まらない。',
          effect: WorkChoiceEffect(
            career: 2,
            money: -500,
            stress: 2,
          ),
        ),
      ],
    ),
    // ----------------------------------------------------------------
    // プロジェクトイベント
    // ----------------------------------------------------------------
    const WorkEvent(
      id: 'work_event.project.client_change',
      category: WorkEventCategory.project,
      title: 'クライアントから急な仕様変更',
      situation:
          '進行中のプロジェクトに、クライアントから「設計の一部を変えたい」との連絡。\n対応の判断が求められている。',
      choices: [
        WorkChoice(
          label: '当日中に対応案を返す',
          resultText:
              '迅速さで信頼を得た。仕事評価が上がり、\n知性も少し磨かれた。',
          effect: WorkChoiceEffect(
            career: 5,
            stress: 5,
            intellect: 2,
            vitality: -2,
          ),
        ),
        WorkChoice(
          label: '影響範囲を整理してから明日返す',
          resultText:
              '丁寧に整理して翌日返答した。慌てずに済み、\nストレスを抑えられた。',
          effect: WorkChoiceEffect(
            career: 2,
            stress: -1,
            intellect: 1,
          ),
        ),
      ],
    ),
    const WorkEvent(
      id: 'work_event.project.deadline_crunch',
      category: WorkEventCategory.project,
      title: '締切前夜のトラブル',
      situation:
          '締切前夜、サーバの構成ミスが見つかった。\n今夜中に対応するか、明朝早出で取り戻すか。',
      choices: [
        WorkChoice(
          label: '今夜のうちに片付ける',
          resultText:
              '深夜まで残って原因を潰した。間に合ったが、\n体力もストレスも削られた。',
          effect: WorkChoiceEffect(
            career: 6,
            stress: 8,
            vitality: -8,
            intellect: 1,
          ),
        ),
        WorkChoice(
          label: '明朝早出で取り戻す',
          resultText:
              '一度寝てから朝に向き合った。集中力は戻ったが、\n間に合わせるのに評価は伸び悩んだ。',
          effect: WorkChoiceEffect(
            career: 2,
            stress: 3,
            vitality: -3,
          ),
        ),
      ],
    ),
    // ----------------------------------------------------------------
    // ミス系イベント
    // ----------------------------------------------------------------
    const WorkEvent(
      id: 'work_event.mistake.send_error',
      category: WorkEventCategory.mistake,
      title: '誤送信',
      situation:
          '別件のメールに、社外秘の添付ファイルを付けて送ってしまった。\nまだ気づかれていない様子。',
      choices: [
        WorkChoice(
          label: 'すぐに報告して回収する',
          resultText:
              '怒られはしたが、被害は最小限で止まった。\n誠実さで評価は持ち直した。',
          effect: WorkChoiceEffect(
            career: -2,
            stress: 5,
            sociability: 1,
          ),
        ),
        WorkChoice(
          label: '黙ってログを消そうとする',
          resultText:
              '一瞬は逃れた気がしたが、\n夜中まで罪悪感で眠れなかった。',
          effect: WorkChoiceEffect(
            career: -5,
            stress: 10,
          ),
        ),
      ],
    ),
    // ----------------------------------------------------------------
    // チャンス系イベント
    // ----------------------------------------------------------------
    const WorkEvent(
      id: 'work_event.chance.bonus_offer',
      category: WorkEventCategory.chance,
      title: '臨時インセンティブの打診',
      situation:
          '小さな副案件を 1 件、上司から個別に振られた。\n納期は短いが、成功すれば臨時の手当が出るという。',
      choices: [
        WorkChoice(
          label: '受けて全力で仕上げる',
          resultText:
              '短期集中で仕上げた。臨時手当が振り込まれ、\n仕事評価も上がった。',
          effect: WorkChoiceEffect(
            career: 4,
            stress: 5,
            money: 8000,
            intellect: 1,
            vitality: -3,
          ),
        ),
        WorkChoice(
          label: '丁重に断る',
          resultText:
              '無理せず断った。本業に集中でき、\n日中の疲労は最小限だった。',
          effect: WorkChoiceEffect(
            career: 0,
            stress: -2,
            vitality: 2,
          ),
        ),
      ],
    ),
  ]);

  /// 全イベントから 1 件を抽選する。
  static WorkEvent pick(Random rng) {
    final i = rng.nextInt(all.length);
    return all[i];
  }

  /// 確率判定。`rng.nextInt(100) < kWorkEventPercent` なら true。
  static bool shouldFire(Random rng) {
    return rng.nextInt(100) < kWorkEventPercent;
  }
}
