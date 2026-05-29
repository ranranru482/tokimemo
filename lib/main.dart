import 'package:flutter/widgets.dart';

import 'app.dart';
import 'services/audio_service.dart';
import 'services/ending_archive.dart';
import 'services/save_repository.dart';
import 'services/settings_repository.dart';

/// Sprint 12: 起動シーケンスの最適化。
///
/// 仕様書 Sprint 12 受け入れ基準1: 「コールドスタートから3秒以内にタイトル表示」。
///
/// 旧実装（Sprint 11 まで）:
/// SettingsRepository.load → SaveRepository.load → EndingArchive.load を
/// **直列に await** してから runApp していた。3 連続の I/O がボトルネック。
///
/// 新実装（Sprint 12）:
/// 1. `SettingsRepository.load()` は最低限の見た目（テーマ・テキスト速度）
///    に必要なので最初に await（軽量・SharedPreferences 1 件取得）。
/// 2. SaveRepository と EndingArchive の load は **`Future.wait` で並行化**。
///    SharedPreferences のインスタンスは内部で同じものを共有するので
///    実 I/O はほぼ 1 回分のコストで済む。
/// 3. `LoggingAudioService` は `keepHistory: false` で起動。
///    本番では履歴を貯める必要が無く、長時間プレイ時の無限増殖を防止する
///    （Sprint 12 メモリリーク対策）。テストでは `keepHistory: true` で履歴を見る。
///
/// 計測方法と目標値は `docs/qa_checklist.md` に記載。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 1) Settings は UI 初期テーマに必要なので先行ロード（軽量）。
  final settings = await SettingsRepository.load();
  // 2) Save / EndingArchive は並行ロード（I/O はほぼ単一）。
  final results = await Future.wait<Object>([
    SaveRepository.load(),
    EndingArchive.load(),
  ]);
  final saveRepository = results[0] as SaveRepository;
  final endingArchive = results[1] as EndingArchive;
  // Hotfix 2026-05-18 後追い: audioplayers ベースの実音再生に切替。
  // テスト経路は引き続き LoggingAudioService（test ヘルパで直接 new）。
  // 実 mp3 アセット未投入の状態では各 play 呼び出しが内部 try/catch で
  // 握りつぶされ、無音で進行する（仕様）。
  final audio = createProductionAudioService(
    bgmVolume: settings.bgmVolume,
    seVolume: settings.seVolume,
  );
  runApp(MugenSiritoriApp(
    settings: settings,
    saveRepository: saveRepository,
    endingArchive: endingArchive,
    audio: audio,
  ));
}
