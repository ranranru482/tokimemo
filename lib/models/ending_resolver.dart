import '../data/confession_eve_events.dart';
import 'character.dart';
import 'character_state.dart';
import 'ending.dart';
import 'game_state.dart';
import 'stats.dart';

/// Sprint 09: 3/31 終了時のエンディング判定。
///
/// 仕様書 §8 に基づく分岐ロジックを純粋関数として実装する。
/// `GameState` を直接読み込まず、必要なスナップショットを引数で受ける形に
/// することで、テスト時に境界値ケースを容易に組めるようにしている。
///
/// バランス指針:
/// - 真 ED は「全キャラと程よく付き合い、自分を保てた人」のみ達成可能。
///   ハードル: 全キャラ真好感度 +30 以上、表面好感度 60 以上、ストレス 40 以下、
///   仕事評価 50 以上、解放済 CG 12 件以上。
///   → 真っ直ぐ 1 人を狙えば取れる難易度ではなく、3〜4 周目で初めて到達できる
///     程度の総合点を要求する設計。
/// - 個別 ED は「該当キャラ表面 80 以上 + 真 +20 以上」の段階で発火。
///   → 集中攻略で 1 周目に到達可能。
/// - 上記いずれも満たさなければノーマル ED。
class EndingResolver {
  const EndingResolver();

  /// 真 ED の発火閾値。
  ///
  /// 設計判断: 真好感度合計が +30 を全キャラで超え、かつ全員が「特別な存在」段階
  /// （表面好感度 60 以上）に到達していることを必須とする。
  /// CG ライブラリ 12 件以上は「個別イベントを各キャラ満遍なく解放した証拠」
  /// として要求し、特定 1 人に集中したプレイでは到達できない設計にする。
  static const int kTrueEndAffinityFloor = 60;
  static const int kTrueEndTrueAffinityFloor = 30;
  static const int kTrueEndMaxStress = 40;
  static const int kTrueEndMinCareer = 50;
  static const int kTrueEndMinCgUnlocks = 12;

  /// 個別 ED の発火閾値。
  ///
  /// spec §8: 真の好感度 80 以上 + 告白イベント通過。
  /// 本実装では「表面 80 以上 + 真 20 以上」とすることで、真の好感度に
  /// 影響を与える「上辺だけの会話」を多用したルートを除外する。
  /// 「告白イベント」相当の解放確認は CG キー（cg.ind.{id}.5）の所持で代用。
  static const int kIndividualEndAffinityFloor = 80;
  static const int kIndividualEndTrueAffinityFloor = 20;

  /// ノーマル ED に向かう「対人接触の薄さ」しきい値。
  ///
  /// 個別 ED 条件を満たすキャラが 1 人もおらず、かつ全キャラの表面好感度が
  /// 60 未満なら spec §8 通りノーマル ED に向かう。
  static const int kNormalEndMaxAnyAffinity = 60;

  /// バッド系 ED の発火閾値。
  ///
  /// 真ED・個別ED・ノーマルED より優先的に評価する。
  /// - 燃え尽き: ストレスが 90 以上で年度末を迎えた場合。
  /// - 左遷:     仕事評価が 10 以下で年度末を迎えた場合。
  /// 両方該当する場合は宣言順（[EndingKind.values]）で先頭の burnoutEd を採用。
  static const int kBurnoutMinStress = 90;
  static const int kDemotionMaxCareer = 10;

  /// メインの判定関数。
  ///
  /// 引数は `GameState` 由来のスナップショット。3/31 終了直後に呼ばれる想定。
  /// 戻り値は必ず 1 つの [EndingKind]。
  EndingKind resolve({
    required Map<CharacterId, CharacterState> characterStates,

    required int stress,
    required int career,
    required int cgUnlockCount,
  }) {
    // 0) バッド系 ED 判定（最優先）。仕事評価とストレスは年度を通しての
    //    平均ではなく「現時点の値」をスナップショットで見る。
    //    両方該当した場合は宣言順で burnout を採用。
    if (stress >= kBurnoutMinStress) {
      return EndingKind.burnoutEd;
    }
    if (career <= kDemotionMaxCareer) {
      return EndingKind.demotionEd;
    }
    // 1) 真 ED 判定。全キャラ揃って閾値を満たす必要がある。
    if (_isTrueEnd(
      characterStates: characterStates,
      stress: stress,
      career: career,
      cgUnlockCount: cgUnlockCount,
    )) {
      return EndingKind.trueEd;
    }
    // 2) 個別 ED 判定。閾値を満たすキャラがいれば、表面好感度が一番高い
    //    キャラを選ぶ（複数人が同じ値なら enum 宣言順）。
    final ind = _resolveIndividual(characterStates);
    if (ind != null) return ind;
    // 3) いずれでもなければノーマル ED。
    return EndingKind.normalEd;
  }

  bool _isTrueEnd({
    required Map<CharacterId, CharacterState> characterStates,
    required int stress,
    required int career,
    required int cgUnlockCount,
  }) {
    if (stress > kTrueEndMaxStress) return false;
    if (career < kTrueEndMinCareer) return false;
    if (cgUnlockCount < kTrueEndMinCgUnlocks) return false;
    // 5 キャラ全員が両層の閾値を満たすか。
    final ids = CharacterId.values;
    for (final id in ids) {
      final cs = characterStates[id];
      if (cs == null) return false;
      if (!cs.isMet) return false;
      if (cs.affinity < kTrueEndAffinityFloor) return false;
      if (cs.trueAffinity < kTrueEndTrueAffinityFloor) return false;
    }
    return true;
  }

  EndingKind? _resolveIndividual(
      Map<CharacterId, CharacterState> characterStates) {
    EndingKind? best;
    int bestAffinity = -1;
    for (final id in CharacterId.values) {
      final cs = characterStates[id];
      if (cs == null || !cs.isMet) continue;
      if (cs.affinity < kIndividualEndAffinityFloor) continue;
      if (cs.trueAffinity < kIndividualEndTrueAffinityFloor) continue;
      // 告白前夜イベントの通過を AND 条件として要求する。
      // unlockedEventIds に `confession_eve.{id.name}` が含まれていない限り
      // 個別 ED は発火しない。
      if (!cs.unlockedEventIds.contains(ConfessionEveCatalog.idFor(id))) {
        continue;
      }
      // この時点でこのキャラは個別 ED 候補。
      if (cs.affinity > bestAffinity) {
        bestAffinity = cs.affinity;
        best = _endingForCharacter(id);
      }
    }
    return best;
  }

  EndingKind _endingForCharacter(CharacterId id) {
    switch (id) {
      case CharacterId.akari:
        return EndingKind.akariEd;
      case CharacterId.uta:
        return EndingKind.utaEd;
      case CharacterId.toru:
        return EndingKind.toruEd;
      case CharacterId.sayo:
        return EndingKind.sayoEd;
      case CharacterId.yui:
        return EndingKind.yuiEd;
    }
  }
}

/// 3/31 を迎えたかどうかを判定する小ヘルパ（純粋関数）。
///
/// 仕様書 §2:「12ヶ月＝1年で物語が完結し、エンディング判定へ」。
/// 開始日 = 4/1（2026 年度の場合は 2026/4/1）から数えて翌年の 3/31 に
/// 達した瞬間を「年度末」とみなす。
bool isEndOfYear(DateTime date) {
  return date.month == 3 && date.day == 31;
}

/// 与えられた `GameState` から `EndingResolver.resolve` を呼ぶ薄いラッパ。
///
/// `GameState` の保有する全フィールドを resolver の引数に詰め替えるだけ。
/// テスト時にだけ resolver を差し替えたいケース向けに切り出してある。
EndingKind resolveEndingFromGameState(GameState state,
    {EndingResolver resolver = const EndingResolver()}) {
  final stats = state.allStats;
  return resolver.resolve(
    characterStates: state.characterStates,
    stress: state.stress,
    career: stats[StatKind.career] ?? 0,
    cgUnlockCount: state.cgLibrary.unlockedCount,
  );
}
