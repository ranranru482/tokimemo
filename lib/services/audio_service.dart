import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sprint 11: 音再生の抽象インターフェース。
///
/// 仕様書 §14 Sprint 11 の「全画面BGM / SE / シーン別音楽切替 /
/// 設定画面の音量反映」を支える。実音再生ライブラリ（audioplayers 等）は
/// **本スプリントでは追加しない**（仕様メモ「依存パッケージは追加しない」）。
///
/// 理由:
/// - 実際のサウンドアセットが無い状態でライブラリだけ入れても無意味。
/// - インフラ層を抽象化し、後でライブラリ実装を差し替えれば実音が出る構造に。
/// - テストではモック相当の [LoggingAudioService] を使えばよく、依存を増やさない
///   方が CI も健全。
///
/// 実装契約:
/// - [playBgm] は「即時切替」を意味する。タイトル → ホームのような大きな
///   シーンチェンジでは [crossfadeBgm] を使う。
/// - [crossfadeBgm] は同じキーで呼ばれた場合は何もしない（[currentBgmKey] が
///   一致するなら no-op）。
/// - [bgmVolume] / [seVolume] は 0.0〜1.0 にクランプされる。
/// - すべてのメソッドは Future を返すが、現状の [LoggingAudioService] は
///   実音再生を伴わないため同期完了する（`Future.value()` 相当）。
abstract class AudioService {
  /// 指定キーのBGMを即時再生する（フェード無し）。
  /// 同じキーが現在再生中なら no-op。
  Future<void> playBgm(String key);

  /// 指定キーのBGMにクロスフェードで切り替える（フェード時間は実装依存、
  /// LoggingAudioService では 1 秒の論理切替＝即値変更）。
  /// 同じキーが現在再生中なら no-op。
  Future<void> crossfadeBgm(String key);

  /// 現在のBGMを停止する（[currentBgmKey] は null になる）。
  Future<void> stopBgm();

  /// 指定キーのSEを 1 回再生する。BGMには影響しない。
  Future<void> playSe(String key);

  /// BGMボリューム。0.0〜1.0 にクランプ。
  /// SettingsState.bgmVolume と連動する想定。
  set bgmVolume(double value);
  double get bgmVolume;

  /// SEボリューム。0.0〜1.0 にクランプ。
  set seVolume(double value);
  double get seVolume;

  /// 現在再生中の BGM キー。停止中なら null。
  String? get currentBgmKey;
}

/// Sprint 11: 1 件分の AudioService 呼び出しログ。
///
/// テストやデバッグで `LoggingAudioService.history` を検査する用途。
@immutable
class AudioCall {
  const AudioCall.bgm({required this.key, required this.crossfade})
      : kind = AudioCallKind.bgm,
        volume = null;

  const AudioCall.se({required this.key})
      : kind = AudioCallKind.se,
        crossfade = false,
        volume = null;

  const AudioCall.stop()
      : kind = AudioCallKind.stop,
        key = null,
        crossfade = false,
        volume = null;

  const AudioCall.bgmVolume(double value)
      : kind = AudioCallKind.bgmVolume,
        key = null,
        crossfade = false,
        volume = value;

  const AudioCall.seVolume(double value)
      : kind = AudioCallKind.seVolume,
        key = null,
        crossfade = false,
        volume = value;

  final AudioCallKind kind;
  final String? key;
  final bool crossfade;
  final double? volume;

  @override
  String toString() {
    switch (kind) {
      case AudioCallKind.bgm:
        return 'AudioCall.bgm($key, crossfade=$crossfade)';
      case AudioCallKind.se:
        return 'AudioCall.se($key)';
      case AudioCallKind.stop:
        return 'AudioCall.stop()';
      case AudioCallKind.bgmVolume:
        return 'AudioCall.bgmVolume($volume)';
      case AudioCallKind.seVolume:
        return 'AudioCall.seVolume($volume)';
    }
  }
}

enum AudioCallKind { bgm, se, stop, bgmVolume, seVolume }

/// Sprint 11: 「ログを取るだけのスタブ実装」。
///
/// 本番でも当面これを `AppScope.audio` として inject する。
/// 実アセットが入って audioplayers 等を導入するタイミングで、本クラスを
/// `_RealAudioService implements AudioService` に差し替えるだけで切替完了。
///
/// テストでは [history] / [currentBgmKey] / [bgmVolume] を直接検査する。
class LoggingAudioService implements AudioService {
  /// Sprint 12: [keepHistory] を追加。
  /// - true（テスト/開発用デフォルト）: 全呼び出しを履歴に蓄積する。
  /// - false（本番デフォルト想定）: 履歴を蓄積せず、長時間プレイ時の
  ///   無限増殖を防ぐ。`currentBgmKey` / `bgmVolume` などの状態は引き続き保持。
  ///
  /// `main.dart` の本番は `keepHistory: false` を指定する。テストは未指定
  /// （= true）で利用するため、既存テストの `history` 検査は維持される。
  LoggingAudioService({
    double bgmVolume = 0.7,
    double seVolume = 0.7,
    bool keepHistory = true,
  })  : _bgmVolume = bgmVolume.clamp(0.0, 1.0),
        _seVolume = seVolume.clamp(0.0, 1.0),
        _keepHistory = keepHistory;

  final List<AudioCall> _history = <AudioCall>[];
  String? _currentBgm;
  double _bgmVolume;
  double _seVolume;
  final bool _keepHistory;

  /// テストや内省で参照する呼び出し履歴（追加順）。
  /// `keepHistory=false` の場合は常に空。
  List<AudioCall> get history => List<AudioCall>.unmodifiable(_history);

  /// テストで履歴をリセットしたい場合に使う。
  void clearHistory() => _history.clear();

  void _record(AudioCall call) {
    if (!_keepHistory) return;
    _history.add(call);
  }

  @override
  Future<void> playBgm(String key) async {
    if (_currentBgm == key) return;
    _currentBgm = key;
    _record(AudioCall.bgm(key: key, crossfade: false));
  }

  @override
  Future<void> crossfadeBgm(String key) async {
    if (_currentBgm == key) return;
    _currentBgm = key;
    _record(AudioCall.bgm(key: key, crossfade: true));
  }

  @override
  Future<void> stopBgm() async {
    if (_currentBgm == null) return;
    _currentBgm = null;
    _record(const AudioCall.stop());
  }

  @override
  Future<void> playSe(String key) async {
    _record(AudioCall.se(key: key));
  }

  @override
  double get bgmVolume => _bgmVolume;

  @override
  set bgmVolume(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (clamped == _bgmVolume) return;
    _bgmVolume = clamped;
    _record(AudioCall.bgmVolume(clamped));
  }

  @override
  double get seVolume => _seVolume;

  @override
  set seVolume(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (clamped == _seVolume) return;
    _seVolume = clamped;
    _record(AudioCall.seVolume(clamped));
  }

  @override
  String? get currentBgmKey => _currentBgm;
}

/// Sprint 13 (Hotfix 2026-05-18 後追い): 実音再生実装。
///
/// audioplayers パッケージを使い、`bgm.title` のような論理キーを
/// `assets/audio/bgm_title.mp3` というアセットパスに変換して再生する。
///
/// 設計上の注意:
/// - BGM 用は [AudioPlayer] を 1 つ、SE 用は **固定 3 個のプール** を持ち、
///   ラウンドロビンで使い回す（連打時の割り込みを回避するため）。
/// - `crossfadeBgm` は 500ms のフェードアウト → 新 BGM 開始 → 500ms フェードイン
///   を `Timer.periodic` で簡易補間する（audioplayers にネイティブのクロスフェード
///   が無いため）。
/// - アセットが投入されていない場合、再生 API は例外を投げる可能性があるが、
///   リリース未投入の現状で全画面クラッシュさせないよう **try/catch で握りつぶす**
///   方針。実アセット投入後はログを見て不足を検知する想定。
class _RealAudioService implements AudioService {
  _RealAudioService({
    double bgmVolume = 0.7,
    double seVolume = 0.7,
  })  : _bgmVolume = bgmVolume.clamp(0.0, 1.0),
        _seVolume = seVolume.clamp(0.0, 1.0) {
    // BGM はループ前提。
    unawaited(_bgmPlayer.setReleaseMode(ReleaseMode.loop));
    unawaited(_bgmPlayer.setVolume(_bgmVolume));
    for (final p in _sePool) {
      unawaited(p.setVolume(_seVolume));
    }
  }

  final AudioPlayer _bgmPlayer = AudioPlayer();
  // SE 用 3 個プール。`playSe` でラウンドロビン使用。
  final List<AudioPlayer> _sePool =
      List<AudioPlayer>.generate(3, (_) => AudioPlayer());
  int _seCursor = 0;
  String? _currentBgm;
  double _bgmVolume;
  double _seVolume;
  Timer? _crossfadeTimer;

  /// 論理キー `bgm.title` → アセット相対パス `audio/bgm_title.mp3`。
  /// audioplayers の [AssetSource] は `assets/` プレフィックスを自前で付ける
  /// ため、ここでは付けない。
  String _assetPathFor(String key) => 'audio/${key.replaceAll('.', '_')}.mp3';

  @override
  Future<void> playBgm(String key) async {
    if (_currentBgm == key) return;
    _currentBgm = key;
    _crossfadeTimer?.cancel();
    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.play(AssetSource(_assetPathFor(key)));
    } catch (e) {
      debugPrint('[Audio] playBgm missing asset for $key: $e');
    }
  }

  @override
  Future<void> crossfadeBgm(String key) async {
    if (_currentBgm == key) return;
    _currentBgm = key;
    _crossfadeTimer?.cancel();
    const fadeMs = 500;
    const stepMs = 50;
    final steps = fadeMs ~/ stepMs;
    final startVol = _bgmVolume;
    var i = 0;
    final completer = Completer<void>();
    // フェードアウト → 新規再生 → フェードイン を 1 つの Timer で進める。
    _crossfadeTimer = Timer.periodic(const Duration(milliseconds: stepMs),
        (Timer t) async {
      i++;
      if (i <= steps) {
        final v = startVol * (1 - i / steps);
        try {
          await _bgmPlayer.setVolume(v.clamp(0.0, 1.0));
        } catch (_) {}
      } else if (i == steps + 1) {
        // 新 BGM 開始（音量 0）。
        try {
          await _bgmPlayer.stop();
          await _bgmPlayer.setVolume(0);
          await _bgmPlayer.play(AssetSource(_assetPathFor(key)));
        } catch (e) {
          debugPrint('[Audio] crossfadeBgm missing asset for $key: $e');
        }
      } else if (i <= steps * 2 + 1) {
        final v = startVol * ((i - steps - 1) / steps);
        try {
          await _bgmPlayer.setVolume(v.clamp(0.0, 1.0));
        } catch (_) {}
      } else {
        t.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });
    return completer.future;
  }

  @override
  Future<void> stopBgm() async {
    if (_currentBgm == null) return;
    _currentBgm = null;
    _crossfadeTimer?.cancel();
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      debugPrint('[Audio] stopBgm failed: $e');
    }
  }

  @override
  Future<void> playSe(String key) async {
    final player = _sePool[_seCursor];
    _seCursor = (_seCursor + 1) % _sePool.length;
    try {
      await player.stop();
      await player.setVolume(_seVolume);
      await player.play(AssetSource(_assetPathFor(key)));
    } catch (e) {
      debugPrint('[Audio] playSe missing asset for $key: $e');
    }
  }

  @override
  double get bgmVolume => _bgmVolume;

  @override
  set bgmVolume(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (clamped == _bgmVolume) return;
    _bgmVolume = clamped;
    try {
      unawaited(_bgmPlayer.setVolume(clamped));
    } catch (e) {
      debugPrint('[Audio] setBgmVolume failed: $e');
    }
  }

  @override
  double get seVolume => _seVolume;

  @override
  set seVolume(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (clamped == _seVolume) return;
    _seVolume = clamped;
    for (final p in _sePool) {
      try {
        unawaited(p.setVolume(clamped));
      } catch (e) {
        debugPrint('[Audio] setSeVolume failed: $e');
      }
    }
  }

  @override
  String? get currentBgmKey => _currentBgm;

  /// アプリ終了時等に呼び出すリソース解放。
  /// BGM プレイヤー + SE プール 3 個すべてを release する。
  /// 例外は内部で握りつぶす（既に release 済み等の二重呼び対策）。
  Future<void> dispose() async {
    _crossfadeTimer?.cancel();
    try {
      await _bgmPlayer.release();
    } catch (_) {}
    for (final p in _sePool) {
      try {
        await p.release();
      } catch (_) {}
    }
  }
}

/// 本番用 AudioService のファクトリ。
///
/// main.dart からは `createProductionAudioService(...)` で取得する。
/// テストや [LoggingAudioService] 経路は影響を受けない（直接 new する）。
AudioService createProductionAudioService({
  double bgmVolume = 0.7,
  double seVolume = 0.7,
}) =>
    _RealAudioService(bgmVolume: bgmVolume, seVolume: seVolume);
