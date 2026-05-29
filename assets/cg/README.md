# assets/cg/ 投入チェックリスト

命名規約とファイル一覧は [../../docs/assets_spec.md](../../docs/assets_spec.md) §3 CG を参照（合計 48 ファイル）。

## 投入手順

1. 論理キー `cg.X.Y.Z` → `cg_X_Y_Z.png`（`.` を `_` 置換）で配置。
2. `pubspec.yaml` の `flutter.assets:` に `- assets/cg/` を追加。
3. `flutter pub get` 後、CG リビール画面で `Image.asset` 切替確認。
