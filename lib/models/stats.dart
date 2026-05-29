/// 主人公の能力値パラメータ。spec.md §3 に準拠した7種。
///
/// すべて 0〜100 のスケールで管理される。
/// 表示名は日本語、英名は仕様書に併記されているもの。
enum StatKind {
  intellect(label: '知性', english: 'Intellect'),
  vitality(label: '体力', english: 'Vitality'),
  sensibility(label: '感性', english: 'Sensibility'),
  sociability(label: '社交', english: 'Sociability'),
  career(label: '仕事評価', english: 'Career'),
  wallet(label: '所持金', english: 'Wallet'),
  stress(label: 'ストレス', english: 'Stress');

  const StatKind({required this.label, required this.english});

  final String label;
  final String english;
}

/// 能力値の最小値と最大値。すべてのパラメータで共通。
class StatRange {
  const StatRange._();
  static const int min = 0;
  static const int max = 100;
}

/// ストレス値からホーム画面で表示する3段階の表情区分。
enum StressMood {
  /// ストレスが低く満足。
  satisfied,

  /// 中程度、無表情。
  neutral,

  /// 高ストレス、不満。
  dissatisfied;

  /// ストレス値 (0-100) から表情区分を判定する。
  /// 〜34: satisfied, 35〜69: neutral, 70〜: dissatisfied。
  static StressMood fromStress(int stress) {
    if (stress < 35) {
      return StressMood.satisfied;
    }
    if (stress < 70) {
      return StressMood.neutral;
    }
    return StressMood.dissatisfied;
  }
}
