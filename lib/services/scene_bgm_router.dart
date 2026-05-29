import '../models/audio_keys.dart';
import 'audio_service.dart';

/// Sprint 11: 画面遷移と BGM をマッピングするルータ。
///
/// 仕様書 §14 Sprint 11「シーン別音楽切替」「画面遷移するとシーンに応じて
/// BGM がクロスフェードで切り替わる」に対応。
///
/// 設計:
/// - `NavigatorObserver` として実装するのではなく、各シーン進入時に
///   明示的に `SceneBgmRouter.enter(scene)` を呼ぶ運用にする。
///   理由:
///     1. fadeRoute / slideUpRoute が `RouteSettings` を持たないため、
///        observer ベースだと「どの画面に遷移したか」の判定が脆い。
///     2. 進入時の AudioService 呼び出しは「タイトル進入時 = bgm.title」
///        のようにシンプルかつテスト容易（mock の crossfadeBgm 呼び出しを
///        history で確認できる）。
/// - シーン定義は [BgmScene] enum で集約。BGM キーマップは静的 const Map。
/// - 同じシーン → 同じ key への重複呼び出しは AudioService 側で no-op。
///
/// 使い方:
/// ```dart
/// // タイトル画面 initState で:
/// SceneBgmRouter.enter(context, BgmScene.title);
/// ```
class SceneBgmRouter {
  const SceneBgmRouter._();

  /// シーン → BGM キーの対応表。
  static const Map<BgmScene, String> _bgmByScene = <BgmScene, String>{
    BgmScene.title: AudioKeys.bgmTitle,
    BgmScene.home: AudioKeys.bgmHome,
    BgmScene.dialogue: AudioKeys.bgmDialogue,
    BgmScene.event: AudioKeys.bgmEvent,
    BgmScene.ending: AudioKeys.bgmEnding,
    BgmScene.album: AudioKeys.bgmAlbum,
  };

  /// [scene] に対応する BGM キーを取り出す（テスト等の純粋関数として使える）。
  static String bgmKeyOf(BgmScene scene) {
    final key = _bgmByScene[scene];
    assert(key != null, 'No BGM key registered for scene=$scene');
    return key!;
  }

  /// [scene] に対応する BGM へクロスフェードで切り替える。
  ///
  /// [audio] を直接渡せばテストから純粋に呼べる。
  /// [context] からは [AppScope] 経由で audio を取得する。
  static Future<void> enterWithService(
    AudioService audio,
    BgmScene scene,
  ) {
    return audio.crossfadeBgm(bgmKeyOf(scene));
  }
}

/// 画面の論理シーン区分。
///
/// 物理的な画面（StatefulWidget）と 1:1 とは限らない（例: CharacterDetail と
/// CharactersScreen はどちらも home の延長と見なす）。BGM 切替の単位として
/// 「タイトル / ホーム系 / 会話系 / イベント系 / エンディング / アルバム系」
/// の 6 種類に丸めている。
enum BgmScene {
  title,
  home,
  dialogue,
  event,
  ending,
  album,
}
