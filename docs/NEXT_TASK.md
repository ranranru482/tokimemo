# NEXT_TASK — 次タスク単一ソース

> ChatGPT ↔ Claude Code ↔ GitHub Actions ↔ Codex Review の受け渡し用。
> 「次に何をやるか」はここだけを見れば分かる状態を維持する。
> 完了したタスクは `docs/progress.md` に追記し、本ファイルは次タスクへ更新する。

---

## 現在のフェーズ

**立ち絵アセット投入フェーズ（feat/character-assets-placeholder）**

- アプリ本体: Sprint 01〜12 + Hotfix + Feature Pack A〜E 完了。
- ハーネス: CI / Codex Review 稼働、main ブランチ保護 ai_keiba レベル。
- 設定: 社会人版キャラ設定（`character_profiles.md`）を**マスタデータ＋シナリオ本文**の双方へ同期済み（PR #8 / #9）。
- 背景: 仮素材16枚投入済み + `ScenicBackground` の `Image.asset` 化（PR #4 / #5）。
- 立ち絵: `CharacterPortrait` の `Image.asset` 化 + errorBuilder フォールバック実装済み（PR #6）。**実画像は未投入**。
- 検証: `flutter analyze` clean / `flutter test` 445 pass。

---

## 次タスク（最優先）

### 優先1: `feat/character-assets-placeholder` — 立ち絵PNGの投入

**画像生成は ChatGPT 担当。Claude Code は画像生成を行わない（配置・検証・PRのみ）。**

- ChatGPT: 立ち絵15件（`<id>_<expression>.png`、akari/uta/toru/sayo/yui × normal/smile/troubled、透過 PNG 1024×1536 推奨）を生成し、ZIP 等で提供。
- Claude Code 担当（ZIP 受領後）:
  - [ ] ZIP を展開し、`python tools/verify_character_assets.py` で検証（命名規約 `<id>_<expression>.png` 過不足 / PNG署名 / 解像度 / 透過）。exit 0 を確認。
  - [ ] 15件を `assets/characters/` に配置（README.txt 等は除外、既存 README.md は保持）。
  - [ ] `pubspec.yaml` の `- assets/characters/` は**有効化済み**（追加編集不要）。
  - [ ] `flutter pub get` → `flutter analyze`（clean）→ `flutter test`（445 維持）。
  - [ ] 立ち絵表示確認（一覧カード小・詳細大・表情切替・シルエットは漏れない）。
  - [ ] `docs/asset_checklist.md` §2 の立ち絵15件を `[x]` に更新（仮素材なら注記）。
  - [ ] 大容量 ZIP 本体は `.gitignore`（`/*.zip`）で対象外。
  - [ ] commit → PR → CI green / Codex green → マージ準備。

> 実画像が未提供の間は、`CharacterPortrait` は errorBuilder でイニシャル円にフォールバックし続ける（クラッシュしない）。投入はファイルを置くだけ。

## 次タスク候補（立ち絵の後）

- [ ] `feat/cg-assets`: CG 65件投入 + `CgView` の `Image.asset` 化（errorBuilder フォールバック）。
- [ ] `feat/audio-assets`: BGM 6 / SE 8 投入（`pubspec` の `assets/audio/` 有効化）。
- [ ] 背景・立ち絵の本番素材差し替え（仮素材 → 本番、同名上書き）。

---

## 受け渡しルール

1. ChatGPT が次タスクを決め、本ファイルを更新（または指示文を提示）。画像が必要なら ChatGPT が生成・提供。
2. Claude Code が feature branch で実装し、CI green + Codex Review green を確認。
3. 完了報告（変更ファイル / CI結果 / Codex結果 / PR / 次タスク候補 / リスク残件）。
4. 人間（管理者）が PR をマージ。
5. ChatGPT が次タスクを決め、本ファイルを更新。
