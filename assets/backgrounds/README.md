# assets/backgrounds/ 投入チェックリスト

命名規約とファイル一覧は [../../docs/assets_spec.md](../../docs/assets_spec.md) §4 背景 を参照（16 ファイル）。

## 投入手順

1. `<season>_<day_phase>.png` 命名で 16 ファイル配置。
2. `pubspec.yaml` の `flutter.assets:` に `- assets/backgrounds/` を追加。
3. `flutter pub get` 後、`lib/widgets/scenic_background.dart` を `Image.asset` 切替。
