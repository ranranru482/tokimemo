# NEXT_TASK — 次タスク単一ソース

> ChatGPT ↔ Claude Code ↔ GitHub Actions ↔ Codex Review の受け渡し用。
> 「次に何をやるか」はここだけを見れば分かる状態を維持する。
> 完了したタスクは `docs/progress.md` に追記し、本ファイルは次タスクへ更新する。

---

## 現在のフェーズ

**半自動開発ハーネス導入 → アセット投入準備フェーズ**

- アプリ本体: Sprint 01〜12 + Hotfix + Feature Pack A〜E 完了。
- 検証実績: `flutter analyze` clean / `flutter test` 435 pass / Android emulator integration 29 pass。
- 実アセット（音声 14 / 立ち絵 15 / CG 65 / 背景 16）は未投入。プレースホルダで動作中。

---

## 次タスク（最優先）

- [ ] ハーネス導入 PR (`chore/dev-harness-bootstrap`) の CI green / Codex Review green を確認しマージ。
- [ ] マージ後、main ブランチ保護を設定（PR必須・CI必須チェック・直push禁止）。
- [ ] GitHub repo secrets に `OPENAI_API_KEY` を登録（Codex Review 有効化）。

## 次タスク候補（ハーネス安定後）

- [ ] 背景アセット投入（16件、`<season>_<noon|...>.png`）+ `ScenicBackground` の `Image.asset` 化（errorBuilder フォールバック必須）。
- [ ] 立ち絵アセット投入（15件、`<id>_<expression>.png`）+ `CharacterPortrait` の `Image.asset` 化。
- [ ] CG アセット投入（65件）+ `CgView` の `Image.asset` 化。
- [ ] 音声アセット投入（BGM 6 / SE 8）+ `pubspec.yaml` の `assets/audio/` 解除。

---

## 受け渡しルール

1. ChatGPT が本ファイルを更新（または Claude へ指示文を提示）。
2. Claude Code が feature branch で実装し、CI green + Codex Review green を確認。
3. 完了報告（変更ファイル / CI結果 / Codex結果 / PR / 次タスク候補 / リスク残件）。
4. ChatGPT が次タスクを決め、本ファイルを更新。
