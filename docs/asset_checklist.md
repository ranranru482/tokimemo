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

#### BGM 部分投入 / 仮素材差替えの最小手順

実音源が一部しか揃っていない段階でも安全に投入・検証できる。

1. `assets/audio/` に投入できる分だけ mp3 を配置（残りは仮 mp3 でも可）。
2. `pubspec.yaml` の `flutter.assets:` の `- assets/audio/` 行を解除。
3. `flutter pub get` → `flutter run -d <device>` で動作確認。
4. 欠損ファイルは `_RealAudioService` 内 `try/catch` で握りつぶされ、当該シーンは
   無音のまま継続する（クラッシュしない）。`debugPrint` に `[Audio] playBgm missing
   asset for bgm.xxx: ...` がログ出力されるため、未投入分の把握に使える。
5. 仮素材を差し替えるときはファイル名そのままで上書きすれば、次回起動から反映される。
   Dart 側の変更は不要。アプリ再起動のみ。

#### BGM 投入時の検証ポイント

- [ ] タイトル画面起動で `bgm_title` がループ再生される。
- [ ] 「はじめから」→ホーム画面遷移で `bgm_title → bgm_home` がクロスフェード（500 ms）。
- [ ] 会話モーダル進入で `bgm_dialogue` に切替、閉じると `bgm_home` に戻る。
- [ ] イベント発火（共通/個別/節目）で `bgm_event` に切替。
- [ ] エンディング画面で `bgm_ending` 再生、本文進行中もループ。
- [ ] アルバム / CG リビールで `bgm_album` 再生。
- [ ] 設定画面で BGM 音量スライダーを動かすと即時反映（音が小さくなる/大きくなる）。
- [ ] 同じ BGM キーが連続要求されても再開始しない（no-op、進行中のループが続く）。

### 1-2. SE（8 ファイル）

- [ ] `se_tap.mp3` — 通常タップ
- [ ] `se_confirm.mp3` — 決定ボタン
- [ ] `se_cancel.mp3` — キャンセル / 戻る
- [ ] `se_statUp.mp3` — 能力値上昇
- [ ] `se_affinityUp.mp3` — 好感度上昇
- [ ] `se_eventFire.mp3` — イベント発火
- [ ] `se_error.mp3` — エラー / 不足通知
- [ ] `se_heartUp.mp3` — ハート段階上昇

#### SE 部分投入 / 仮素材差替えの最小手順

BGM と同一の `assets/audio/` ディレクトリを共有するため、pubspec の解除は 1 回で済む。

1. `assets/audio/` に投入できる分だけ mp3 を配置（残りは仮 mp3 でも可）。
2. `pubspec.yaml` の `flutter.assets:` の `- assets/audio/` 行を解除（BGM と同じ行）。
3. `flutter pub get` → `flutter run -d <device>` で動作確認。
4. 欠損ファイルは `_RealAudioService.playSe` 内 `try/catch` で握りつぶされ、当該操作は
   無音のまま継続する。`debugPrint` に `[Audio] playSe missing asset for se.xxx: ...`
   が記録されるので未投入分の把握に使える。
5. 仮素材を差し替えるときはファイル名そのままで上書きすれば、次回起動から反映される。

#### SE 同時再生プールの設計（コード変更不要、参考情報）

- `_RealAudioService._sePool` は **固定 3 個の `AudioPlayer`** をラウンドロビン使用。
- 連打しても 4 件目以降は最古のスロットを上書き再生（途切れる可能性はあるが割り込み
  ノイズは出ない）。
- BGM は別プレイヤー（`_bgmPlayer`）で独立稼働するため、SE プールが満杯になっても
  BGM ループは継続する。
- 将来 voiceKey を有効化した場合、同じ 3ch プールで再生される予定。同時 BGM 1 + SE 3
  までは低スペック端末でも安全（仕様メモ §6）。

#### BGM と SE の共存リスク

- ✅ **音量独立**: `bgmVolume` / `seVolume` は別フィールドで管理、設定画面のスライダー
  2 本がそれぞれ独立反映される。
- ✅ **チャンネル独立**: BGM は `_bgmPlayer`、SE は `_sePool[0..2]` で別 AudioPlayer
  インスタンス → 同時再生で混ざらない。
- ⚠️ **クロスフェード中の SE 発火**: 500 ms のクロスフェード中に SE を再生しても影響
  しない（別プレイヤーのため）。ただしフェード途中の BGM 音量上で SE が鳴るため、
  SE が相対的に大きく聞こえる可能性。気になる場合は SE のマスタリングで -3 dB 程度
  控えめにする。
- ⚠️ **mp3 デコード負荷**: 同時 4 ファイル（BGM 1 + SE 3）デコードはローエンド端末で
  CPU 負荷増。SE は 100 KB 未満 / 2 秒以内のショートクリップに揃える。

#### SE 投入時の検証ポイント

- [ ] タイトル「はじめから」タップで `se_confirm` 再生。
- [ ] ホーム AppBar の歯車 / ショップアイコンタップで `se_tap` 再生。
- [ ] 設定画面の戻るボタンで `se_cancel` 再生。
- [ ] 行動実行で能力値上昇時に `se_statUp` 再生（連打しても破綻しない）。
- [ ] イベント発火（共通/個別/節目）の白フラッシュと同時に `se_eventFire` 再生。
- [ ] 所持金不足の SnackBar 表示で `se_error` 再生。
- [ ] 好感度ハート段階アップ時に `se_heartUp` 再生（誘い 10 回連続成功で確認）。
- [ ] 設定画面で SE 音量スライダーを動かすと次回 SE 発火時から即時反映。
- [ ] BGM を再生中に SE を連打しても BGM ループが途切れない。

---

## 2. 立ち絵（assets/characters/） — 15 ファイル

| キャラ | normal | smile | troubled |
| --- | :-: | :-: | :-: |
| 七瀬 灯 (akari) | [ ] `akari_normal.png` | [ ] `akari_smile.png` | [ ] `akari_troubled.png` |
| 久遠 詩 (uta) | [ ] `uta_normal.png` | [ ] `uta_smile.png` | [ ] `uta_troubled.png` |
| 鴻巣 透 (toru) | [ ] `toru_normal.png` | [ ] `toru_smile.png` | [ ] `toru_troubled.png` |
| 蓮見 紗夜 (sayo) | [ ] `sayo_normal.png` | [ ] `sayo_smile.png` | [ ] `sayo_troubled.png` |
| 槙原 結衣 (yui) | [ ] `yui_normal.png` | [ ] `yui_smile.png` | [ ] `yui_troubled.png` |

> 命名規約: `<character_id>_<expression>.png`。`character_id` は `CharacterId.name`
> （`akari | uta | toru | sayo | yui`）、`expression` は `Expression.name`
> （`normal | smile | troubled`）に一致させる。差替えコードが
> `${character.id.name}_${expression.name}.png` を生成するため、表記揺れは解決されない。

#### 立ち絵 部分投入 / 仮素材差替えの最小手順

⚠️ **音声と性質が異なる（背景と同じ）。** `CharacterPortrait` は現状
`Container`（themeColor 円 + イニシャル + 表情アイコン）で擬似描画し、`Image.asset` を
一切呼んでいない。そのため「立ち絵が無い／一部だけ」の状態でも **実行時依存はゼロ＝
クラッシュしない**（参照していないため try/catch も不要）。

1. `assets/characters/` に投入できる分だけ `<id>_<expression>.png`（透過 PNG）を配置。
   キャラ単位（例: akari の 3 表情のみ）でも表情単位でも部分投入可。
2. `pubspec.yaml` の `flutter.assets:` の `- assets/characters/` 行を解除。
   - 現状ディレクトリは `.gitkeep` / `README.md` のみで非空のため、`flutter pub get` /
     build は **エラーにならない**（無関係ファイルがバンドルされるだけ）。
3. `flutter pub get` を実行。**この段階では立ち絵はプレースホルダのままで画像は出ない**
   （コードがまだ `Image.asset` を呼んでいないため。pubspec 解除だけでは描画は変わらない）。
4. 実画像を反映するには `lib/widgets/character_portrait.dart` の差替えが必要（下記）。
   このとき **必ず `errorBuilder` で現行プレースホルダ（円 + イニシャル）へフォールバック**
   させること。立ち絵には欠損ガードが無いため、未投入ファイルを直接 `Image.asset` すると
   当該キャラ/表情が例外/灰色になる。フォールバックを付ければ部分投入でも安全。
5. 仮素材を差し替えるときはファイル名そのままで上書きすれば、次回起動から反映される。

#### 立ち絵の差替えポイント（コード側）

`lib/widgets/character_portrait.dart` の `build` 内 `Stack`（円 Container + Text +
表情アイコン）を
`Image.asset('assets/characters/${character.id.name}_${expression.name}.png', errorBuilder: 現行プレースホルダ)`
に置換する。`isSilhouette` 分岐・`AnimatedSwitcher`（200ms クロスフェード）・`_expressionIcon`
はフォールバック用に残す。`size` は透過画像の表示枠としてそのまま使える。

#### 立ち絵投入時の検証ポイント

- [ ] キャラ一覧カードで各キャラの `*_normal.png` が表示される（小サイズ ≈56）。
- [ ] キャラ詳細画面で立ち絵が大サイズ（≈160）で表示される。
- [ ] 会話モーダル進行中に表情が `normal → smile → troubled` へ 200ms クロスフェードで切替。
- [ ] 未会いキャラはシルエット（`isSilhouette`）表示のままで実画像が漏れない。
- [ ] 一部のみ投入時、未投入のキャラ/表情はプレースホルダへフォールバックしクラッシュしない。
- [ ] 透過 PNG の背景が抜けており、重ねた背景/カード色が透けて見える。

#### 低スペック端末でのメモリリスク

- 立ち絵 15 枚を一括プリロードしない。`Image.asset` は表示中のもののみデコードされ、
  `ImageCache`（既定 1000 枚 / 100 MB）が LRU 管理する。
- 推奨 1024×1536（縦長 + アルファ）は **decode 後 RGBA で約 6.3 MB/枚**。ファイルが透過 PNG /
  WebP で ~300 KB でも、デコード後メモリは解像度依存でファイルサイズと無関係。
- カード用（≈56px）と詳細用（≈160px）で同一原寸をデコードすると無駄が大きい。低スペック端末では
  `cacheWidth`（カード用は端末 dpr × 56px 程度）指定で実メモリを削減できる（必要時のみ・現状不要）。
- WebP 透過（lossy 80%, alpha 100）はファイル容量 30–50% 削減だが **デコード後メモリは PNG と同じ**。
  メモリ削減ではなく APK サイズ削減効果として扱う。
- 会話中の表情切替は同一キャラ 3 枚を行き来する程度で、`ImageCache` 上限に対し十分小さく
  明示的 `evict` は不要。

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

> 🟡 **2026-05-30: 仮素材（プレースホルダ）16 枚を投入済み**（`feat/background-assets-placeholder`）。
> 全て 1920×1080 PNG。本番背景が用意でき次第、**同じファイル名で上書き**すれば Dart 変更なしで
> 差し替わる。仮素材はファイルサイズが ~1.6–2.5MB/枚と推奨（~400KB）より大きいため、本番では
> WebP 化 / 圧縮で削減すること。チェックは「投入済み」を意味し、本番品質確定ではない。

| | morning | noon | evening | night |
| --- | :-: | :-: | :-: | :-: |
| spring | [x] `spring_morning.png` | [x] `spring_noon.png` | [x] `spring_evening.png` | [x] `spring_night.png` |
| summer | [x] `summer_morning.png` | [x] `summer_noon.png` | [x] `summer_evening.png` | [x] `summer_night.png` |
| autumn | [x] `autumn_morning.png` | [x] `autumn_noon.png` | [x] `autumn_evening.png` | [x] `autumn_night.png` |
| winter | [x] `winter_morning.png` | [x] `winter_noon.png` | [x] `winter_evening.png` | [x] `winter_night.png` |

> ⚠️ **時間帯トークンは `noon`（昼）であって `day` ではない。** ファイル名は
> `DayPhase.name`（`morning | noon | evening | night`）に一致させる必要がある
> （差替えコードが `${season}_${phase}.png` を生成するため）。`spring_day.png`
> 等の命名は解決されず無視される。

#### 背景 部分投入 / 仮素材差替えの最小手順

✅ **`Image.asset` 化 + `errorBuilder` フォールバック実装済み（feat/background-assets）。**
`pubspec.yaml` の `- assets/backgrounds/` は **有効化済み**。`ScenicBackground` は
`assets/backgrounds/<season>_<phase>.png` を `Image.asset` で描画し、未投入 / 欠損時は
`errorBuilder` で従来のグラデーション背景へ自動フォールバックする。
そのため **画像が無い／一部だけの状態でもクラッシュしない**。投入はファイルを置くだけ。

1. `assets/backgrounds/` に投入できる分だけ `<season>_<noon|...>.png` を配置（残りは未配置で可）。
2. `flutter pub get` を実行（`pubspec` は有効化済みなので追加編集は不要）。
3. アプリを再起動 → 投入済みの季節/時間帯は実画像、未投入分はグラデーションで表示される。
4. 仮素材を差し替えるときはファイル名そのままで上書きすれば、次回起動から反映される。Dart 変更不要。

> 注: ディレクトリは `.gitkeep` / `README.md` を含み非空なので、画像 0 件でも
> `flutter pub get` / build はエラーにならない。

#### 背景の差替えポイント（コード側・実装済み）

`lib/widgets/scenic_background.dart` の `build` は
`Image.asset(ScenicBackground.assetPathForPalette(palette), fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: _GradientBackdrop)`
を `AnimatedSwitcher` でラップして描画する。
- パス生成は静的メソッド `ScenicBackground.assetPathForPalette(palette)`（テスト対象）。
- フォールバックは private `_GradientBackdrop`。色決定関数 `_topColorFor` / `_midColorFor` /
  `_bottomColorFor` はフォールバック用に維持。
- 季節/時間帯キー `scenicBackground.<season>.<phase>` は維持（既存テスト互換）。

#### 背景投入時の検証ポイント

- [ ] 4 月（春）ホーム起動で `spring_*` 系背景が表示される。
- [ ] スロット進行（morning→midday→evening→night）で `*_morning → *_noon → *_evening → *_night` が
      500 ms クロスフェードで切り替わる。
- [ ] 月跨ぎ（3-5 春 / 6-8 夏 / 9-11 秋 / 12-2 冬）で季節背景が切り替わる。
- [ ] 一部のみ投入時、未投入の季節/時間帯はグラデーションへフォールバックしクラッシュしない。
- [ ] 前景（StatusBar / 行動枠）が背景に埋もれず読める（現状 `Opacity 0.35` で重ねている。
      実写背景は立ち絵前提でローコントラスト推奨。コントラストが強い場合は Opacity 調整を検討）。

#### 低スペック端末でのメモリリスク

- 背景 16 枚を **一括プリロードしない**。`Image.asset` は表示中の 1 枚のみデコードされ、
  Flutter の `ImageCache`（既定 1000 枚 / 100 MB）が LRU 管理するため、同時常駐は実質 1〜2 枚。
- 1920×1080 を **decode 後 RGBA で約 8.3 MB/枚** 占有する（ファイルが PNG/WebP で 400 KB でも
  デコード後はファイルサイズと無関係に解像度依存）。低スペック端末では `ResizeImage` または
  `cacheWidth: <端末幅px>` の指定で実メモリを削減できる（必要時のみ・現状は不要）。
- WebP（lossy 80%）はファイル容量を 30–50% 削減するが **デコード後メモリは PNG と同じ**。
  メモリ削減効果ではなく APK サイズ削減効果として扱う。
- 季節/時間帯切替時、旧背景は次フレームで GC 対象になるが `ImageCache` には残る。16 枚程度なら
  100 MB 上限に収まるため明示的 `evict` は不要。

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
