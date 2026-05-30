# SPRINT_TEMPLATE — スプリント雛形

> 新しいスプリント/タスクを起こすときのコピー元。`.codex/agents/planner.toml` の
> 「What だけ書く / 検証可能な終了条件」方針に整合させる。
> 実装は必ず feature branch・最小差分・既存テスト維持。

---

## スプリント名

`<種別>/<短い説明>`（例: `feat/background-assets`, `ci/branch-protection`）

## 目的（What・1〜3行）

- このスプリントで「ユーザー/開発者にとって何ができるようになるか」を書く。
- How（実装手段・ライブラリ選定・内部構造）はここに書かない。

## 受け入れ基準（検証可能な形で）

- [ ] 基準1（例: `flutter test` が green を維持）
- [ ] 基準2（例: 背景16件が時刻/季節で切り替わり、未投入分はフォールバックする）
- [ ] 基準3（…）

## スコープ外（やらないこと）

- 既存ゲーム機能の挙動変更。
- セーブスキーマ / 公開 API シグネチャの破壊的変更。
- 大規模リファクタ。

## 影響範囲（変更予定ファイル）

- 追加: …
- 変更: …
- 触らない: …

## 検証手順

1. `flutter analyze` → clean
2. `flutter test` → 全 pass（件数を記録）
3. 必要なら `flutter test integration_test/ -d <device>`
4. PR 作成 → CI green → Codex Review green

## 完了時の締め

- [ ] `docs/progress.md` 末尾に成果を追記。
- [ ] `docs/NEXT_TASK.md` を次タスクへ更新。
- [ ] 完了報告（変更ファイル / CI / Codex / PR / 次タスク候補 / リスク残件）。
