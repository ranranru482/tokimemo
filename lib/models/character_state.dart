/// 実行時に変化するキャラ状態。
///
/// プロフィール（[Character]）と分離して管理することで、
/// 「セーブデータに載るのはこちらだけ」「プロフィール変更はホットフィックス可能」
/// という分割を保つ。
///
/// Sprint 07 で 2 層好感度の本実装に切り替えた：
/// - [affinity]      : 表面好感度（0〜100）。プレイヤーに見えるハート段階の元値。
/// - [trueAffinity]  : 真の好感度（-50〜+100）。完全に非表示。
///                     エンディング判定とイベント解放の真の判定軸。
///                     負値を許容することで「上辺だけで内心は冷めている」状態を表現できる。
/// - [lastInteractedDate] : 最後に交流した日付（疎遠ペナルティの基準）。
///   `recordEncounter` で初期化、誘い・会話イベントで更新する。
class CharacterState {
  CharacterState({
    this.isMet = false,
    this.affinity = 0,
    this.trueAffinity = 0,
    this.lastInteractedDate,
    Set<String>? unlockedEventIds,
  }) : unlockedEventIds = <String>{...?unlockedEventIds};

  /// 出会いイベントが発火済みかどうか。
  /// true の間はキャラ一覧でシルエットではなく立ち絵が表示される。
  bool isMet;

  /// 表面好感度（0〜100）。仕様書 §6 の段階構造に対応する。
  int affinity;

  /// 真の好感度。仕様書 §6 の「真の好感度」に対応する隠しゲージ。
  /// Sprint 07 では -50〜+100 の範囲で動かす。
  int trueAffinity;

  /// 最後に交流した日付（疎遠ペナルティの基準）。
  /// null は「まだ出会っていない / 初期化前」を意味する。
  /// `GameState.recordEncounter` で初回設定され、誘い行動・会話で更新される。
  DateTime? lastInteractedDate;

  /// Sprint 08: このキャラに紐づく解放済みイベント ID 集合。
  /// 個別イベント・節目イベントの「同じ id を二度発火しない」判定に使う。
  /// 共通/ランダムイベントの解放管理は [GameState] 側の別 Set で管理する。
  final Set<String> unlockedEventIds;

  /// 表面好感度の有効最小値（クランプ用）。仕様書 §6: 0〜100。
  static const int kAffinityMin = 0;
  static const int kAffinityMax = 100;

  /// 真の好感度の有効範囲。負値を許容することで
  /// 「上辺ばかりで内心は冷め切っている」状態をモデル化できる。
  static const int kTrueAffinityMin = -50;
  static const int kTrueAffinityMax = 100;

  /// 表面好感度を加算してクランプする。差分は負値も可。
  void bumpAffinity(int delta) {
    affinity = (affinity + delta).clamp(kAffinityMin, kAffinityMax);
  }

  /// 真の好感度を加算してクランプする。差分は負値も可。
  void bumpTrueAffinity(int delta) {
    trueAffinity =
        (trueAffinity + delta).clamp(kTrueAffinityMin, kTrueAffinityMax);
  }

  /// 現在の表面好感度の段階（1〜5）。
  ///
  /// 仕様書 §6 の 5 段階定義に従う：
  /// - 1 段階目: 0〜19   （他人）
  /// - 2 段階目: 20〜39  （顔見知り）
  /// - 3 段階目: 40〜59  （友人）
  /// - 4 段階目: 60〜79  （特別な存在）
  /// - 5 段階目: 80〜100 （大切な人）
  ///
  /// 出会い済キャラは「他人」段階でも最低 1 段階目を表示する。
  /// 未会いキャラに対しては UI 側で 0 段階扱い（[isMet] が false の場合）とする。
  int get affinityStage {
    if (affinity >= 80) return 5;
    if (affinity >= 60) return 4;
    if (affinity >= 40) return 3;
    if (affinity >= 20) return 2;
    return 1; // 0〜19（出会い済なら最低でも「他人」段階）
  }

  /// JSON 風スナップショット（Sprint 09 のセーブ/ロード前提のための土台）。
  Map<String, dynamic> toMap() => <String, dynamic>{
        'isMet': isMet,
        'affinity': affinity,
        'trueAffinity': trueAffinity,
        'lastInteractedDate': lastInteractedDate?.toIso8601String(),
        'unlockedEventIds': unlockedEventIds.toList(),
      };

  factory CharacterState.fromMap(Map<String, dynamic> map) {
    final dateStr = map['lastInteractedDate'] as String?;
    final rawIds = map['unlockedEventIds'];
    final ids = <String>{
      if (rawIds is Iterable)
        for (final v in rawIds)
          if (v is String) v,
    };
    return CharacterState(
      isMet: (map['isMet'] as bool?) ?? false,
      affinity: (map['affinity'] as int?) ?? 0,
      trueAffinity: (map['trueAffinity'] as int?) ?? 0,
      lastInteractedDate: dateStr == null ? null : DateTime.tryParse(dateStr),
      unlockedEventIds: ids,
    );
  }
}
