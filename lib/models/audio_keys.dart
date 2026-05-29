/// Sprint 11: BGM / SE / Voice のキー定数集約。
///
/// 仕様書 §14 Sprint 11「全画面BGM / SE / シーン別音楽切替 /
/// 設定画面の音量反映 / ボイスフィールドの空配置（将来拡張用）」を支える。
///
/// 命名規約:
/// - BGM は `bgm.<scene>`, SE は `se.<action>`, Voice は `voice.<character>.<id>`。
/// - 将来 audioplayers などの実ライブラリを導入する際に、
///   `bgm.title` → `assets/audio/bgm_title.mp3` のように `.` を `_` に
///   置換すれば 1:1 でアセットファイル名に対応する形を意図している。
///
/// 依存パッケージは追加しない方針（Sprint 11 メモ参照）。
/// 実音の再生は AudioService 実装（[LoggingAudioService] / 将来のライブラリ実装）
/// 側の責務とし、本ファイルはあくまでキー名の宣言のみ。
library;

/// BGM のキー定数。
///
/// シーンごとに異なる楽曲を割り当てる前提。シーンマッピングは
/// `lib/services/scene_bgm_router.dart` の `SceneBgmRouter` 側で持つ。
class AudioKeys {
  const AudioKeys._();

  // --- BGM ---
  /// タイトル画面の専用BGM。
  static const String bgmTitle = 'bgm.title';

  /// ホーム画面 / メインスカフォールド全般のBGM。
  static const String bgmHome = 'bgm.home';

  /// 会話シーン（出会いイベント・誘い成功後のミニ会話）のBGM。
  static const String bgmDialogue = 'bgm.dialogue';

  /// イベントシーン（共通・個別・節目イベント）のBGM。
  static const String bgmEvent = 'bgm.event';

  /// エンディング再生時のBGM。
  static const String bgmEnding = 'bgm.ending';

  /// メモリーアルバム / CG リビールのBGM（タイトル/ホーム以外の静かな画面）。
  static const String bgmAlbum = 'bgm.album';

  // --- SE ---
  /// 通常タップ（情報パネル等）の軽い効果音。
  static const String seTap = 'se.tap';

  /// 決定ボタン（「はじめから」「次へ」「決定」等）。
  static const String seConfirm = 'se.confirm';

  /// キャンセル / 戻るボタン。
  static const String seCancel = 'se.cancel';

  /// 能力値が上昇したときのチャイム。
  static const String seStatUp = 'se.statUp';

  /// 好感度が上昇したときのチャイム。
  static const String seAffinityUp = 'se.affinityUp';

  /// イベント発火時のフラッシュと同期する短いアクセント。
  static const String seEventFire = 'se.eventFire';

  /// エラー / 不足通知（所持金不足など）。
  static const String seError = 'se.error';

  /// 好感度ハート段階が 1 段階上がる瞬間の演出音。
  static const String seHeartUp = 'se.heartUp';

  // --- BGM / SE のキー集合（テストや router の検証で使う） ---
  /// 既知の BGM キー一覧（順序保証は無い）。
  static const List<String> knownBgmKeys = <String>[
    bgmTitle,
    bgmHome,
    bgmDialogue,
    bgmEvent,
    bgmEnding,
    bgmAlbum,
  ];

  /// 既知の SE キー一覧。
  static const List<String> knownSeKeys = <String>[
    seTap,
    seConfirm,
    seCancel,
    seStatUp,
    seAffinityUp,
    seEventFire,
    seError,
    seHeartUp,
  ];
}
