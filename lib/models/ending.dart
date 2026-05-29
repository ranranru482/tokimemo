/// Sprint 09: エンディング判定結果を表す列挙型と判定条件のメタ情報。
///
/// 仕様書 §8 に従い、合計 7 種類のエンディングを定義する：
/// - 個別 ED ×5（各キャラの「結婚」「同棲」「遠距離継続」等の着地）
/// - ノーマル ED（「独立して生きる」未来）
/// - 真 ED「月と珈琲ED」（複数キャラとの友情 + 自分自身との和解）
///
/// バッド系 ED（燃え尽き End / 左遷 End）は当初「カウント外」として保留して
/// いたが、後追いで spec §8 の派生 ED として正式追加：
/// - [burnoutEd] : ストレス 90 以上で年度末を迎えたときに発火（最優先）。
/// - [demotionEd]: 仕事評価 10 以下で年度末を迎えたときに発火（最優先）。
/// 両方該当する場合は宣言順で burnoutEd を優先。図鑑カウントには含める。
///
/// オリジナリティ: ED 名・本文は既存 IP（ときめきメモリアル等）に依存しない
/// 完全オリジナル。ED 名 / 本文 / CG キーも社会人らしい大人びたトーンで統一。
library;

import 'character.dart';

/// エンディングの種類。
///
/// 宣言順は「図鑑画面の左上から右下への並び」も兼ねる。
/// 真 ED が末尾に来るよう意図的に最後に置く。バッド系は冒頭に配置。
enum EndingKind {
  burnoutEd(
    id: 'ending.burnout',
    displayName: '燃え尽きED',
    target: null,
    cgKey: 'cg.ending.burnout',
    summary: 'ストレスを抱えたまま、立ち止まれなかった一年。',
  ),
  demotionEd(
    id: 'ending.demotion',
    displayName: '左遷ED',
    target: null,
    cgKey: 'cg.ending.demotion',
    summary: '仕事の評価を取り戻せないまま、辞令を受け取る春。',
  ),
  akariEd(
    id: 'ending.akari',
    displayName: '七瀬 灯ED',
    target: CharacterId.akari,
    cgKey: 'cg.ending.akari',
    summary: '同社の先輩との、ゆっくり進める関係。',
  ),
  utaEd(
    id: 'ending.uta',
    displayName: '久遠 詩ED',
    target: CharacterId.uta,
    cgKey: 'cg.ending.uta',
    summary: '小さなカフェに通い続けた一年の、その先。',
  ),
  toruEd(
    id: 'ending.toru',
    displayName: '鴻巣 透ED',
    target: CharacterId.toru,
    cgKey: 'cg.ending.toru',
    summary: '取引先のエンジニアと築いた、不器用な信頼。',
  ),
  sayoEd(
    id: 'ending.sayo',
    displayName: '蓮見 紗夜ED',
    target: CharacterId.sayo,
    cgKey: 'cg.ending.sayo',
    summary: '深夜の廊下で出会った隣人と、選んだ静かな日々。',
  ),
  yuiEd(
    id: 'ending.yui',
    displayName: '槙原 結衣ED',
    target: CharacterId.yui,
    cgKey: 'cg.ending.yui',
    summary: 'ジムで会ったトレーナーと、走り続ける約束。',
  ),
  normalEd(
    id: 'ending.normal',
    displayName: 'ノーマルED',
    target: null,
    cgKey: 'cg.ending.normal',
    summary: '誰のものでもない、自分のための一年。',
  ),
  trueEd(
    id: 'ending.true',
    displayName: '月と珈琲ED',
    target: null,
    cgKey: 'cg.ending.true_moon_coffee',
    summary: '誰かを大切にすることと、自分を大切にすることの両立。',
  );

  const EndingKind({
    required this.id,
    required this.displayName,
    required this.target,
    required this.cgKey,
    required this.summary,
  });

  /// 一意 ID（セーブデータ・図鑑のキー用）。
  final String id;

  /// 図鑑画面に表示する正式名。
  final String displayName;

  /// 個別 ED の対象キャラ。ノーマル/真 ED では null。
  final CharacterId? target;

  /// CG キー。図鑑のサムネ表示に使う。
  final String cgKey;

  /// 図鑑カードの 1 行サマリー。未解放時はヒントとしても流用できる。
  final String summary;

  /// 達成済 ED の本文を取得する `endingBodyFor` のキーとしても使う。
  String get bodyKey => id;
}

/// 1 件の図鑑エントリ。`EndingArchive` から取り出して表示する。
class EndingArchiveEntry {
  const EndingArchiveEntry({
    required this.kind,
    required this.achievedAt,
  });

  final EndingKind kind;
  final DateTime achievedAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'kind': kind.id,
        'achievedAt': achievedAt.toIso8601String(),
      };

  static EndingArchiveEntry? fromMap(Map<String, dynamic> map) {
    final id = map['kind'] as String?;
    final dateStr = map['achievedAt'] as String?;
    if (id == null || dateStr == null) return null;
    EndingKind? kind;
    for (final k in EndingKind.values) {
      if (k.id == id) {
        kind = k;
        break;
      }
    }
    final date = DateTime.tryParse(dateStr);
    if (kind == null || date == null) return null;
    return EndingArchiveEntry(kind: kind, achievedAt: date);
  }
}
