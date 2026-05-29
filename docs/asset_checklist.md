# アセット投入チェックリスト — 月と珈琲 (tokimemo)

コンテンツ投入作業者向けのワンストップチェックリスト。
詳細な命名規約・リスク考慮は [`docs/assets_spec.md`](assets_spec.md) を参照。

---

## サマリ

| 種別 | ファイル数 | ディレクトリ | 推奨形式 |
| --- | --- | --- | --- |
| BGM | **6** | `assets/audio/` | mp3 (44.1 kHz / 128–192 kbps / ステレオ / ループ前提) |
| SE | **8** | `assets/audio/` | mp3 (44.1 kHz / 128 kbps / モノラル可 / < 2 秒) |
| 立ち絵 | **15** | `assets/characters/` | png 透過 (1024×1536 推奨) |
| CG | **65** | `assets/cg/` | png (1920×1080 推奨) |
| 背景 | **16** | `assets/backgrounds/` | png (1920×1080 推奨) |
| **合計（アイコン除く）** | **110** | | |

容量見込: 約 45–50 MB。Google Play 単独配信の 100 MB 制限内。
WebP 利用で立ち絵 / CG / 背景は 30–50% 削減可能。

---

## 1. 音声（assets/audio/）

### 1-1. BGM（6 ファイル）

- [ ] `bgm_title.mp3` — タイトル画面
- [ ] `bgm_home.mp3` — ホーム / メインスカフォールド
- [ ] `bgm_dialogue.mp3` — 会話シーン
- [ ] `bgm_event.mp3` — イベント（共通 / 個別 / 節目）
- [ ] `bgm_ending.mp3` — エンディング再生
- [ ] `bgm_album.mp3` — アルバム / CG リビール

### 1-2. SE（8 ファイル）

- [ ] `se_tap.mp3` — 通常タップ
- [ ] `se_confirm.mp3` — 決定ボタン
- [ ] `se_cancel.mp3` — キャンセル / 戻る
- [ ] `se_statUp.mp3` — 能力値上昇
- [ ] `se_affinityUp.mp3` — 好感度上昇
- [ ] `se_eventFire.mp3` — イベント発火
- [ ] `se_error.mp3` — エラー / 不足通知
- [ ] `se_heartUp.mp3` — ハート段階上昇

---

## 2. 立ち絵（assets/characters/） — 15 ファイル

| キャラ | normal | smile | troubled |
| --- | :-: | :-: | :-: |
| 七瀬 灯 (akari) | [ ] `akari_normal.png` | [ ] `akari_smile.png` | [ ] `akari_troubled.png` |
| 久遠 詩 (uta) | [ ] `uta_normal.png` | [ ] `uta_smile.png` | [ ] `uta_troubled.png` |
| 鴻巣 透 (toru) | [ ] `toru_normal.png` | [ ] `toru_smile.png` | [ ] `toru_troubled.png` |
| 蓮見 紗夜 (sayo) | [ ] `sayo_normal.png` | [ ] `sayo_smile.png` | [ ] `sayo_troubled.png` |
| 槙原 結衣 (yui) | [ ] `yui_normal.png` | [ ] `yui_smile.png` | [ ] `yui_troubled.png` |

---

## 3. CG（assets/cg/） — 65 ファイル

### 3-1. 共通イベント CG（10）

- [ ] `cg_common_entrance_apr.png` — 4 月 新年度の朝
- [ ] `cg_common_golden_week_may.png` — 5 月 GW
- [ ] `cg_common_health_check_jun.png` — 6 月 健康診断
- [ ] `cg_common_summer_bonus_jul.png` — 7 月 夏季賞与
- [ ] `cg_common_summer_festival_aug.png` — 8 月 夏祭り
- [ ] `cg_common_halloween_oct.png` — 10 月 ハロウィン残業
- [ ] `cg_common_mid_year_review_nov.png` — 11 月 期末評価面談
- [ ] `cg_common_christmas_dec.png` — 12 月 クリスマス（節目本体）
- [ ] `cg_common_valentine_feb.png` — 2 月 バレンタイン
- [ ] `cg_common_year_end_mar.png` — 3 月 年度末

### 3-2. 個別イベント CG（35 = 5 名 × 7 段階）

| | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
| --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| akari | [ ] `cg_ind_akari_1.png` | [ ] `_2` | [ ] `_3` | [ ] `_4` | [ ] `_5` | [ ] `_6` | [ ] `_7` |
| uta | [ ] `cg_ind_uta_1.png` | [ ] `_2` | [ ] `_3` | [ ] `_4` | [ ] `_5` | [ ] `_6` | [ ] `_7` |
| toru | [ ] `cg_ind_toru_1.png` | [ ] `_2` | [ ] `_3` | [ ] `_4` | [ ] `_5` | [ ] `_6` | [ ] `_7` |
| sayo | [ ] `cg_ind_sayo_1.png` | [ ] `_2` | [ ] `_3` | [ ] `_4` | [ ] `_5` | [ ] `_6` | [ ] `_7` |
| yui | [ ] `cg_ind_yui_1.png` | [ ] `_2` | [ ] `_3` | [ ] `_4` | [ ] `_5` | [ ] `_6` | [ ] `_7` |

### 3-3. 告白前夜 CG（5）

- [ ] `cg_confession_eve_akari.png`
- [ ] `cg_confession_eve_uta.png`
- [ ] `cg_confession_eve_toru.png`
- [ ] `cg_confession_eve_sayo.png`
- [ ] `cg_confession_eve_yui.png`

### 3-4. 節目（クリスマス）CG（6）

- [ ] `cg_milestone_christmas_akari.png`
- [ ] `cg_milestone_christmas_uta.png`
- [ ] `cg_milestone_christmas_toru.png`
- [ ] `cg_milestone_christmas_sayo.png`
- [ ] `cg_milestone_christmas_yui.png`
- [ ] `cg_milestone_christmas_alone.png` — 一人で過ごすクリスマス

### 3-5. エンディング CG（9）

- [ ] `cg_ending_burnout.png` — バッドED: 燃え尽き
- [ ] `cg_ending_demotion.png` — バッドED: 左遷
- [ ] `cg_ending_akari.png`
- [ ] `cg_ending_uta.png`
- [ ] `cg_ending_toru.png`
- [ ] `cg_ending_sayo.png`
- [ ] `cg_ending_yui.png`
- [ ] `cg_ending_normal.png` — ノーマルED
- [ ] `cg_ending_true_moon_coffee.png` — 真ED「月と珈琲ED」

---

## 4. 背景（assets/backgrounds/） — 16 ファイル

| | morning | noon | evening | night |
| --- | :-: | :-: | :-: | :-: |
| spring | [ ] `spring_morning.png` | [ ] `spring_noon.png` | [ ] `spring_evening.png` | [ ] `spring_night.png` |
| summer | [ ] `summer_morning.png` | [ ] `summer_noon.png` | [ ] `summer_evening.png` | [ ] `summer_night.png` |
| autumn | [ ] `autumn_morning.png` | [ ] `autumn_noon.png` | [ ] `autumn_evening.png` | [ ] `autumn_night.png` |
| winter | [ ] `winter_morning.png` | [ ] `winter_noon.png` | [ ] `winter_evening.png` | [ ] `winter_night.png` |

---

## 5. 推奨アセット仕様

### 音声
| 種別 | 形式 | 標本化 | ビットレート | チャンネル | 長さ目安 |
| --- | --- | --- | --- | --- | --- |
| BGM | mp3 | 44.1 kHz | 128–192 kbps | ステレオ | 60–120 秒（ループ前提） |
| SE | mp3 | 44.1 kHz | 128 kbps | モノラル可 | < 2 秒 |

- iOS は AAC 128 kbps への事前変換推奨（mp3 は Xcode 再圧縮対象外のため）。
- BGM はループ境界に無音を入れない（クロスフェード 500 ms の都合上ノイズ要因）。

### 画像
| 種別 | 形式 | 推奨解像度 | 容量目安 | 備考 |
| --- | --- | --- | --- | --- |
| 立ち絵 | png 透過 / WebP | 1024×1536（縦長） | ~300 KB / 枚 | アルファ必須、表情差分は同サイズで揃える |
| CG | png / WebP | 1920×1080（横長） | ~500 KB / 枚 | 16:9 厳守、文字キャプションは焼かない |
| 背景 | png / WebP | 1920×1080（横長） | ~400 KB / 枚 | 立ち絵を重ねる前提でローコントラスト推奨 |

- WebP（lossy 80%, alpha 100）が推奨。30–50% の容量削減 + Flutter ネイティブ対応。
- @2x/@3x の派生バリアントは不要（Flutter `AssetImage` がスケール自動選択）。

---

## 6. 実投入手順

1. 上記命名規約通りで該当ディレクトリにアセットを配置。
2. `pubspec.yaml` の `flutter.assets:` 該当行のコメントを解除。
   ```yaml
   flutter:
     uses-material-design: true
     assets:
       - assets/audio/
       - assets/characters/
       - assets/cg/
       - assets/backgrounds/
   ```
3. `flutter pub get` を実行。
4. `flutter test` で既存テストが回帰なく通ることを確認（アセット解決は警告のみで失敗しない）。
5. 実機 / エミュレータで `flutter run -d emulator-5554` を起動して再生・描画を目視確認。
6. 一部のみ投入したい場合: 該当ディレクトリのみコメント解除でよい（例: BGM だけなら `assets/audio/` のみ）。
7. 投入完了後、本ファイルのチェックボックスを `[x]` に更新してコミット。

### 差替えポイント（コード側、既に準備済み）

- BGM/SE: `lib/services/audio_service.dart` の `_RealAudioService`（`createProductionAudioService()` 経由で `main.dart` から注入済み）。アセット欠損時は debugPrint で握りつぶし無音化。
- 立ち絵: `lib/widgets/character_portrait.dart` の Container 描画 → `Image.asset('assets/characters/${id}_${expression}.png')` に置換。
- CG: `lib/widgets/cg_view.dart` の Container 描画 → `Image.asset('assets/cg/${cgKey.replaceAll('.', '_')}.png')` に置換。
- 背景: `lib/widgets/scenic_background.dart` の `_topColorFor` / `_midColorFor` / `_bottomColorFor` グラデーション 3 関数 → `Image.asset('assets/backgrounds/${season}_${phase}.png')` に置換。

各差替えポイントはコード内コメントで明記されている。

---

## 7. リリース前チェック

- [ ] `flutter analyze`: clean
- [ ] `flutter test`: 全件 pass
- [ ] `flutter test integration_test/ -d <device>`: 全件 pass
- [ ] Android APK サイズが 100 MB 未満（`flutter build apk --release` 後に確認）
- [ ] 全 BGM / SE が無音切替なしで再生される
- [ ] 立ち絵の表情切替が滑らかにクロスフェードする
- [ ] CG 解放時の全画面リビールが意図通り再生される
- [ ] 背景が時刻 / 季節で切り替わる
- [ ] アプリアイコン / スプラッシュ画像（別途投入）
