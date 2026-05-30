# アセット命名規約 — 月と珈琲 (tokimemo)

> ジャンル: **社会人恋愛ADV**（学園ものではない）。世界観は
> [`world_setting.md`](world_setting.md)、キャラ設定は
> [`character_profiles.md`](character_profiles.md) を参照。

外部発注・フリー素材投入時のチェックリスト兼ファイル名対応表。
すべてのキー名は **実コードから抽出** している（手書きの推測は含まない）。

抽出元:
- BGM/SE: `lib/models/audio_keys.dart`
- 立ち絵: `lib/models/character.dart`（`CharacterId` × `Expression`）
- CG: `lib/data/common_events.dart`, `lib/data/individual_events.dart`,
  `lib/screens/christmas_choice_screen.dart`, `lib/models/ending.dart`
- 背景: `lib/widgets/scenic_background.dart`（`Season` × `DayPhase`）

---

## 1. 音声（audio）— 14 ファイル

ディレクトリ: `assets/audio/`
詳細は `assets/audio/README.md` 参照。

### BGM（6）
`AudioKeys.knownBgmKeys` に対応。論理キー `bgm.X` → ファイル `bgm_X.mp3`。

| 論理キー | ファイル名 | 用途 |
| --- | --- | --- |
| `bgm.title` | `bgm_title.mp3` | タイトル画面 |
| `bgm.home` | `bgm_home.mp3` | ホーム / メインスカフォールド |
| `bgm.dialogue` | `bgm_dialogue.mp3` | 会話シーン |
| `bgm.event` | `bgm_event.mp3` | イベントシーン（共通・個別・節目） |
| `bgm.ending` | `bgm_ending.mp3` | エンディング再生 |
| `bgm.album` | `bgm_album.mp3` | メモリーアルバム / CG リビール |

### SE（8）
`AudioKeys.knownSeKeys` に対応。

| 論理キー | ファイル名 | 用途 |
| --- | --- | --- |
| `se.tap` | `se_tap.mp3` | 通常タップ |
| `se.confirm` | `se_confirm.mp3` | 決定ボタン |
| `se.cancel` | `se_cancel.mp3` | キャンセル / 戻る |
| `se.statUp` | `se_statUp.mp3` | 能力値上昇 |
| `se.affinityUp` | `se_affinityUp.mp3` | 好感度上昇 |
| `se.eventFire` | `se_eventFire.mp3` | イベント発火 |
| `se.error` | `se_error.mp3` | エラー / 不足通知 |
| `se.heartUp` | `se_heartUp.mp3` | 好感度ハート段階上昇 |

---

## 2. 立ち絵（characters）— 15 ファイル

ディレクトリ: `assets/characters/`
拡張子: `png`（透過 PNG 推奨）。
ファイル名規約: `<character_id>_<expression>.png`

`CharacterId` × `Expression` = 5 × 3 = 15 通り。

| キャラ | normal | smile | troubled |
| --- | --- | --- | --- |
| akari（七瀬 灯） | `akari_normal.png` | `akari_smile.png` | `akari_troubled.png` |
| uta（久遠 詩） | `uta_normal.png` | `uta_smile.png` | `uta_troubled.png` |
| toru（鴻巣 透） | `toru_normal.png` | `toru_smile.png` | `toru_troubled.png` |
| sayo（蓮見 紗夜） | `sayo_normal.png` | `sayo_smile.png` | `sayo_troubled.png` |
| yui（槙原 結衣） | `yui_normal.png` | `yui_smile.png` | `yui_troubled.png` |

導入時は `lib/widgets/character_portrait.dart` を `Image.asset` ベースに
切り替える（feat/character-assets で実装済み・未投入時はイニシャル円へフォールバック）。

### 立ち絵キャラ設定（社会人版・正典）

立ち絵生成時の人物像。詳細は [`character_profiles.md`](character_profiles.md)。

| id | 名前 | 年齢 | 職業 | テーマ色 |
| --- | --- | --- | --- | --- |
| akari | 七瀬 灯 | 25 | カフェ研究員（商品開発担当） | テラコッタ `#B66E5C` |
| uta | 久遠 詩 | 27 | 出版社編集者 | モスグリーン `#5E8D7A` |
| toru | 鴻巣 透 | 26 | スポーツメーカー営業 | インディゴブルー `#4C6B9A` |
| sayo | 蓮見 紗夜 | 28 | デザイナー | モーブ `#6F4F8C` |
| yui | 槙原 結衣 | 24 | 楽器店スタッフ | オレンジゴールド `#C97A3F` |

> ⚠️ この年齢/職業は **2026-05-30 確定の新設定**。コード（`character_repository.dart`）は
> 旧設定のままで差異がある。差異一覧と反映方針は `character_profiles.md` の
> 「コードとの差異」節を参照（コード反映は別タスク）。

---

## 3. CG — 48 ファイル

ディレクトリ: `assets/cg/`
拡張子: `png`（横長レイアウト前提）。
ファイル名規約: 論理キー `cg.X.Y.Z` → `cg_X_Y_Z.png`
（`.` をすべて `_` に置換）

### 3-1. 共通イベント CG（10）
`lib/data/common_events.dart` 抽出。

| 論理キー | ファイル名 |
| --- | --- |
| `cg.common.entrance_apr` | `cg_common_entrance_apr.png` |
| `cg.common.golden_week_may` | `cg_common_golden_week_may.png` |
| `cg.common.health_check_jun` | `cg_common_health_check_jun.png` |
| `cg.common.summer_bonus_jul` | `cg_common_summer_bonus_jul.png` |
| `cg.common.summer_festival_aug` | `cg_common_summer_festival_aug.png` |
| `cg.common.halloween_oct` | `cg_common_halloween_oct.png` |
| `cg.common.mid_year_review_nov` | `cg_common_mid_year_review_nov.png` |
| `cg.common.christmas_dec` | `cg_common_christmas_dec.png` |
| `cg.common.valentine_feb` | `cg_common_valentine_feb.png` |
| `cg.common.year_end_mar` | `cg_common_year_end_mar.png` |

### 3-2. 個別イベント CG（35 = 5 名 × 7 段階）
`lib/data/individual_events.dart` 抽出。
Feature Pack D（2026-05-29）で各キャラ 2 本追加（6 / 7）し、25 → 35 に拡張。

| キャラ | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| akari | `cg_ind_akari_1.png` | `cg_ind_akari_2.png` | `cg_ind_akari_3.png` | `cg_ind_akari_4.png` | `cg_ind_akari_5.png` | `cg_ind_akari_6.png` | `cg_ind_akari_7.png` |
| uta | `cg_ind_uta_1.png` | `cg_ind_uta_2.png` | `cg_ind_uta_3.png` | `cg_ind_uta_4.png` | `cg_ind_uta_5.png` | `cg_ind_uta_6.png` | `cg_ind_uta_7.png` |
| toru | `cg_ind_toru_1.png` | `cg_ind_toru_2.png` | `cg_ind_toru_3.png` | `cg_ind_toru_4.png` | `cg_ind_toru_5.png` | `cg_ind_toru_6.png` | `cg_ind_toru_7.png` |
| sayo | `cg_ind_sayo_1.png` | `cg_ind_sayo_2.png` | `cg_ind_sayo_3.png` | `cg_ind_sayo_4.png` | `cg_ind_sayo_5.png` | `cg_ind_sayo_6.png` | `cg_ind_sayo_7.png` |
| yui | `cg_ind_yui_1.png` | `cg_ind_yui_2.png` | `cg_ind_yui_3.png` | `cg_ind_yui_4.png` | `cg_ind_yui_5.png` | `cg_ind_yui_6.png` | `cg_ind_yui_7.png` |

### 3-3. 告白前夜 CG（5）
`lib/data/confession_eve_events.dart` 抽出。Feature Pack A（2026-05-29）で追加。
個別 ED の AND 条件（表面 ≥75 + 真 ≥15）で発火する 1 本ずつのシーン。

| 論理キー | ファイル名 |
| --- | --- |
| `cg.confession_eve.akari` | `cg_confession_eve_akari.png` |
| `cg.confession_eve.uta` | `cg_confession_eve_uta.png` |
| `cg.confession_eve.toru` | `cg_confession_eve_toru.png` |
| `cg.confession_eve.sayo` | `cg_confession_eve_sayo.png` |
| `cg.confession_eve.yui` | `cg_confession_eve_yui.png` |

### 3-5. 節目（クリスマス）CG（6）
`lib/screens/christmas_choice_screen.dart` 抽出。

| 論理キー | ファイル名 |
| --- | --- |
| `cg.milestone.christmas.alone` | `cg_milestone_christmas_alone.png` |
| `cg.milestone.christmas.akari` | `cg_milestone_christmas_akari.png` |
| `cg.milestone.christmas.uta` | `cg_milestone_christmas_uta.png` |
| `cg.milestone.christmas.toru` | `cg_milestone_christmas_toru.png` |
| `cg.milestone.christmas.sayo` | `cg_milestone_christmas_sayo.png` |
| `cg.milestone.christmas.yui` | `cg_milestone_christmas_yui.png` |

### 3-6. エンディング CG（9）
`lib/models/ending.dart` 抽出。
Feature Pack B（2026-05-29）でバッドED 2 種を追加し、7 → 9 に拡張。

| 論理キー | ファイル名 |
| --- | --- |
| `cg.ending.burnout` | `cg_ending_burnout.png` |
| `cg.ending.demotion` | `cg_ending_demotion.png` |
| `cg.ending.akari` | `cg_ending_akari.png` |
| `cg.ending.uta` | `cg_ending_uta.png` |
| `cg.ending.toru` | `cg_ending_toru.png` |
| `cg.ending.sayo` | `cg_ending_sayo.png` |
| `cg.ending.yui` | `cg_ending_yui.png` |
| `cg.ending.normal` | `cg_ending_normal.png` |
| `cg.ending.true_moon_coffee` | `cg_ending_true_moon_coffee.png` |

**合計 CG: 10 + 35 + 5 + 6 + 9 = 65 ファイル**

---

## 4. 背景（backgrounds）— 16 ファイル

ディレクトリ: `assets/backgrounds/`
ファイル名規約: `<season>_<day_phase>.png`

`Season` = `spring | summer | autumn | winter`
`DayPhase` = `morning | noon | evening | night`

| | morning | noon | evening | night |
| --- | --- | --- | --- | --- |
| spring | `spring_morning.png` | `spring_noon.png` | `spring_evening.png` | `spring_night.png` |
| summer | `summer_morning.png` | `summer_noon.png` | `summer_evening.png` | `summer_night.png` |
| autumn | `autumn_morning.png` | `autumn_noon.png` | `autumn_evening.png` | `autumn_night.png` |
| winter | `winter_morning.png` | `winter_noon.png` | `winter_evening.png` | `winter_night.png` |

導入時は `lib/widgets/scenic_background.dart` の現在のグラデーション描画を
`Image.asset` 切替に置き換える（現状はライブラリ追加禁止方針で純色グラデのみ）。

---

## 5. アプリアイコン / スプラッシュ（未実装、将来作業）

今回は範囲外。投入予定一覧のみ列挙する。

### Android（mipmap-*/ic_launcher.png）
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48×48)
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72×72)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96×96)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144×144)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192×192)

### iOS（Assets.xcassets/AppIcon.appiconset/）
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png`（標準セット）

### スプラッシュ
- `flutter_native_splash` パッケージで自動生成する想定（将来導入）。
  ライブラリ追加が伴うため本ファイルでは仕様メモのみ。

---

## 投入合計

| 種別 | ファイル数 |
| --- | --- |
| 音声（BGM + SE） | 14 |
| 立ち絵 | 15 |
| CG | 65 |
| 背景 | 16 |
| アプリアイコン | 5（Android） + iOS セット |
| **合計（アイコン除く）** | **110** |

---

## 6. リスクと考慮事項

### Android APK サイズ増加リスク
BGM 6×1MB、SE 8×100KB、立ち絵 15×300KB、CG 65×500KB、背景 16×400KB の
合計 ≒ 約 45〜50MB の増加見込み（Feature Pack A/B/D で CG が 48 → 65 に増えた分を反映）。
100MB を超えなければ Google Play 通常公開 OK、超える場合は App Bundle (.aab) 分割配信を検討する。

### iOS アセット圧縮
PNG は Xcode 自動で App Slicing & PNG Crush 適用、CG 48 件は @2x/@3x 別バージョン
不要（Flutter の `AssetImage` がデバイス密度を自動選択）。
mp3 は再圧縮されないので AAC 128kbps に事前変換推奨。

### メモリ常駐リスク
BGM は LRU 1 件のみ常駐（`_bgmPlayer`）、SE プールは 3 個 × 100KB 程度。
立ち絵/CG は `ImageCache` のデフォルト 100MB 上限内に収まる想定。
48 件同時表示は無い（イベント中は 1 件のみ画面）ため問題なし。

### 音声同時再生設計
BGM=1ch（クロスフェード時は一時的に 2ch）、SE=3ch（プール）、
Voice=将来 voiceKey 経由で SE と同経路で再生（同じ 3ch プールを共有予定）。
同時 6ch 程度なら低スペック端末でも問題なし。

### 低スペック端末負荷
立ち絵/CG は WebP 形式（24bit + alpha）推奨でファイルサイズ 30〜50% 削減。
背景は静止画 16 枚で Animation 無し（`ScenicBackground` は Color グラデーションのみ）
のため負荷ゼロ。

---

## 7. 実アセット投入時の手順

1. 該当ディレクトリ（`assets/audio/` 等）にファイル名規約通りで配置。
2. `pubspec.yaml` の `flutter.assets:` のコメントアウト解除（該当ディレクトリのみ）。
3. `flutter pub get` 実行。
4. 実機（例: Android `emulator-5554`）で `flutter run -d emulator-5554` で再生確認。
5. 既知の挙動（無音 mp3 でも握りつぶし無音化、命名規約と key の `.` → `_` 変換）を
   本ファイル §1〜§4 命名規約セクションで再確認。
