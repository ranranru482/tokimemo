# assets/audio/ 投入チェックリスト

`lib/services/audio_service.dart` の `_RealAudioService` は、論理キー
`bgm.title` を `assets/audio/bgm_title.mp3` のように `.` を `_` に置換した
ファイルパスで再生します。本ディレクトリには以下のファイルを **mp3** で
配置してください（外部発注・フリー素材投入時のチェックリスト）。

ファイルが未投入の状態でも、`_RealAudioService` の各 play 呼び出しは
`try/catch` で握りつぶされ、無音のままアプリは進行します（クラッシュしません）。

## BGM（6 ファイル）

`lib/models/audio_keys.dart` の `AudioKeys.knownBgmKeys` に対応。

- [ ] `bgm_title.mp3`    タイトル画面
- [ ] `bgm_home.mp3`     ホーム / メインスカフォールド
- [ ] `bgm_dialogue.mp3` 会話シーン（出会いイベント等）
- [ ] `bgm_event.mp3`    イベントシーン（共通・個別・節目）
- [ ] `bgm_ending.mp3`   エンディング再生
- [ ] `bgm_album.mp3`    メモリーアルバム / CG リビール

## SE（8 ファイル）

`lib/models/audio_keys.dart` の `AudioKeys.knownSeKeys` に対応。

- [ ] `se_tap.mp3`        通常タップ
- [ ] `se_confirm.mp3`    決定ボタン
- [ ] `se_cancel.mp3`     キャンセル / 戻る
- [ ] `se_statUp.mp3`     能力値上昇
- [ ] `se_affinityUp.mp3` 好感度上昇
- [ ] `se_eventFire.mp3`  イベント発火
- [ ] `se_error.mp3`      エラー / 不足通知
- [ ] `se_heartUp.mp3`    好感度ハート段階上昇

## 投入完了時の作業

1. 上記 14 ファイルを本ディレクトリに配置。
2. `pubspec.yaml` の以下のコメントアウトを解除：
   ```yaml
   flutter:
     assets:
       - assets/audio/
   ```
3. `flutter pub get && flutter build apk --debug` でビルドが通ることを確認。
4. 実機で音量が反映されるかと、シーン切替時のクロスフェードを確認。

## 命名規約の補足

- 拡張子は **mp3 固定**。`_RealAudioService._assetPathFor` の実装と整合。
- ループ前提の BGM はデフォルト `ReleaseMode.loop` で再生されるので、
  ファイルそのものを長尺にする必要は無い（短いループ素材で OK）。
- SE は再生中に新しい SE が来ると割り込まれる仕様（プール化は将来課題）。
