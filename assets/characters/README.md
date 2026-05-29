# assets/characters/ 投入チェックリスト

命名規約とファイル一覧は [../../docs/assets_spec.md](../../docs/assets_spec.md) §2 立ち絵 を参照。

## 投入手順

1. `<character_id>_<expression>.png` 命名で 15 ファイル配置（透過 PNG）。
2. `pubspec.yaml` の `flutter.assets:` に `- assets/characters/` を追加（コメントアウト解除）。
3. `flutter pub get` 後、`lib/widgets/character_portrait.dart` を `Image.asset` 経路に切替。
