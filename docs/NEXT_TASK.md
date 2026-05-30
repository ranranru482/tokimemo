# NEXT_TASK — 次タスク単一ソース

> ChatGPT ↔ Claude Code ↔ GitHub Actions ↔ Codex Review の受け渡し用。
> 「次に何をやるか」はここだけを見れば分かる状態を維持する。
> 完了したタスクは `docs/progress.md` に追記し、本ファイルは次タスクへ更新する。

---

## 現在のフェーズ

**ハーネス仕上げ完了 → アセット投入フェーズ（背景から）**

- アプリ本体: Sprint 01〜12 + Hotfix + Feature Pack A〜E 完了。
- 検証実績: `flutter analyze` clean / `flutter test` 435 pass / Android emulator integration 29 pass。
- ハーネス: CI / Codex Review 稼働。main ブランチ保護 ai_keiba レベル設定済み（必須チェック2件・enforce_admins=true・直push防止）。
- 実アセット（音声 14 / 立ち絵 15 / CG 65 / 背景 16）は未投入。プレースホルダで動作中。

---

## 次タスク（最優先）

### 優先1: `feat/background-assets` — 背景アセット投入

**画像生成は ChatGPT 担当。Claude Code は画像生成を行わない（実装と検証に専念）。**

- ChatGPT: 背景16件（`<season>_<morning|noon|evening|night>.png`, 1920×1080）を生成・提供。
- Claude Code 担当:
  - [ ] `docs/asset_checklist.md` の背景チェックボックスを管理・更新。
  - [ ] 提供画像を `assets/backgrounds/` に命名規約どおり配置。
  - [ ] `pubspec.yaml` の `- assets/backgrounds/` を有効化（コメント解除）。
  - [ ] `lib/widgets/scenic_background.dart` を `Image.asset('assets/backgrounds/${season}_${phase}.png')` に差し替え。
  - [ ] `errorBuilder` で従来のグラデーション描画にフォールバック（部分投入でもクラッシュさせない）。
  - [ ] `flutter analyze`（clean）/ `flutter test`（435 維持）。
  - [ ] 可能なら integration test（背景切替）を確認。
  - [ ] commit → PR → CI green / Codex green → マージ準備。

> 実画像が未提供の間は「投入準備の検証」（フォールバック実装・手順整備）までに留め、生成は肩代わりしない。

## 次タスク候補（背景の後）

- [ ] `feat/character-assets`: 立ち絵15件投入 + `CharacterPortrait` の `Image.asset` 化（errorBuilder フォールバック）。
- [ ] `feat/cg-assets`: CG 65件投入 + `CgView` の `Image.asset` 化。
- [ ] `feat/audio-assets`: BGM 6 / SE 8 投入 + `pubspec.yaml` の `assets/audio/` 有効化。

---

## 受け渡しルール

1. ChatGPT が次タスクを決め、本ファイルを更新（または指示文を提示）。画像が必要なら ChatGPT が生成・提供。
2. Claude Code が feature branch で実装し、CI green + Codex Review green を確認。
3. 完了報告（変更ファイル / CI結果 / Codex結果 / PR / 次タスク候補 / リスク残件）。
4. 人間（管理者）が PR をマージ。
5. ChatGPT が次タスクを決め、本ファイルを更新。
