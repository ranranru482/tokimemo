# assets/ui/ 投入チェックリスト

アプリ内アイコン等のサブ UI 素材置き場。アプリアイコン（ic_launcher）は
[../../docs/assets_spec.md](../../docs/assets_spec.md) §5 を参照（mipmap-* / Assets.xcassets）。

## 投入手順

1. UI 素材（カスタムアイコン PNG 等）を配置。命名規約は `docs/assets_spec.md` に追記して運用。
2. `pubspec.yaml` の `flutter.assets:` に `- assets/ui/` を追加。
3. `flutter pub get` 後、参照箇所（Widget）で `Image.asset('assets/ui/...')` を有効化。
