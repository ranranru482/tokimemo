# CLAUDE_RUNBOOK — Claude Code 運用手順書

> tokimemo（月と珈琲）の半自動開発ハーネスにおける Claude Code の動き方。
> フロー: **ChatGPT → Claude Code → GitHub Actions(CI) → Codex Review → Claude報告 → ChatGPT次指示**

---

## 絶対ルール

1. **main 直コミット禁止。** 作業は必ず feature branch で行う。
2. **既存ゲーム機能・セーブ互換・既存テストを壊さない。** 追加は新規ファイル、改修は最小差分。
3. **CI green 必須 / Codex Review green 必須。** どちらかが赤のままマージしない。
4. **アセット/機能変更とハーネス変更を混ぜない。** 1 PR = 1 関心事。
5. secrets / token / key / .env をコミットしない（`.gitignore` で除外済み）。

---

## 標準フロー

### 1. 着手
- `docs/NEXT_TASK.md` で次タスクを確認。
- ブランチ作成: `git switch -c <種別>/<説明>`（例 `feat/background-assets`）。
- 未コミットの無関係差分があれば先に別コミットで確定するか stash する。

### 2. 実装
- `docs/SPRINT_TEMPLATE.md` をコピーして受け入れ基準を明確化。
- 最小差分で実装。プレースホルダ（`CgView`/`CharacterPortrait`/`ScenicBackground`/`LoggingAudioService`）方針を尊重。

### 3. ローカル検証
```sh
flutter pub get
flutter analyze        # clean であること
flutter test           # 全 pass（件数を記録。現基準 435）
```
- integration test が要るタスクのみ: `flutter test integration_test/ -d <device>`。

### 4. PR
- `git push -u origin <branch>`。
- `gh pr create` で PR 作成（タイトル/本文に目的・受け入れ基準・検証結果）。
- **CI(`.github/workflows/ci.yml`)** が green か確認。
- **Codex Review(`.github/workflows/codex-review.yml`)** のコメントを確認し、指摘に対応。
  - Codex は **コメントのみ**（auto-merge / auto-push しない）。最終判断は人間。
  - `OPENAI_API_KEY` 未設定時は Codex job はスキップ（green）。有効化には repo secrets 登録が必要。

### 5. マージ
- CI green + Codex Review 対応完了を確認 → PR をマージ（main 保護下なので PR 経由のみ）。

### 6. 締め
- `docs/progress.md` 末尾に成果を追記。
- `docs/NEXT_TASK.md` を次タスクへ更新。
- 報告フォーマット（下記）で完了報告。

---

## CI / Codex 仕様メモ

- **CI**: Flutter `3.38.9` / channel stable に固定（Dart 3.10.8、pubspec `^3.10.8` 整合）。`pub get → analyze → test`。
  - 初回除外: `integration_test/`（実機必須）、`dart format`（既存未フォーマットのため）。
- **Codex Review**: `pull_request` トリガ、`pull_request_target` 不使用、権限 `contents:read` + `pull-requests:write`、`secrets.OPENAI_API_KEY` 使用、差分は 120KB で打ち切り。

---

## 報告フォーマット（毎回これで返す）

1. 変更ファイル一覧
2. CI結果
3. Codex Review結果
4. PR作成有無（URL）
5. 次タスク候補
6. リスク残件
