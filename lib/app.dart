import 'package:flutter/material.dart';

import 'models/game_state.dart';
import 'models/settings_state.dart';
import 'screens/title_screen.dart';
import 'services/audio_service.dart';
import 'services/ending_archive.dart';
import 'services/save_repository.dart';

/// アプリのルート Widget。
///
/// 状態管理は最小限の [InheritedNotifier] ベース。Sprint 01 では十分。
/// Sprint 03 で [SettingsState] のテーマモードを [MaterialApp.themeMode] に
/// 反映するため、[AnimatedBuilder] で settings を購読する。
/// 後続スプリントで状態が増えたら Riverpod などへの移行を検討する。
class MugenSiritoriApp extends StatefulWidget {
  const MugenSiritoriApp({
    super.key,
    required this.settings,
    this.saveRepository,
    this.endingArchive,
    this.audio,
  });

  final SettingsState settings;

  /// Sprint 09: セーブ/ロードリポジトリ。`AppScope` 経由で全画面に公開する。
  /// 既存の integration test（Sprint 01〜08）との後方互換のため optional。
  /// null の場合は build 時に内部で非同期ロードする。
  final SaveRepository? saveRepository;

  /// Sprint 09: エンディング達成アーカイブ。`AppScope` 経由で全画面に公開する。
  /// 既存の integration test（Sprint 01〜08）との後方互換のため optional。
  /// null の場合は build 時に内部で非同期ロードする。
  final EndingArchive? endingArchive;

  /// Sprint 11: 音再生サービス。`AppScope` 経由で全画面に公開する。
  /// 既存テストとの後方互換のため optional。
  /// null の場合は build 時に [LoggingAudioService] を内部で生成する。
  final AudioService? audio;

  @override
  State<MugenSiritoriApp> createState() => _MugenSiritoriAppState();
}

class _MugenSiritoriAppState extends State<MugenSiritoriApp> {
  final GameState _gameState = GameState();
  SaveRepository? _saveRepository;
  EndingArchive? _endingArchive;
  late AudioService _audio;
  VoidCallback? _settingsListener;

  /// 共通シードカラー（夜の珈琲をイメージしたブラウン系）。
  static const Color _seedColor = Color(0xFF4A2C2A);

  @override
  void initState() {
    super.initState();
    _saveRepository = widget.saveRepository;
    _endingArchive = widget.endingArchive;
    _audio = widget.audio ?? LoggingAudioService(
      bgmVolume: widget.settings.bgmVolume,
      seVolume: widget.settings.seVolume,
    );
    // Sprint 11: settings.bgmVolume / seVolume の変更を AudioService に同期。
    _settingsListener = () {
      _audio.bgmVolume = widget.settings.bgmVolume;
      _audio.seVolume = widget.settings.seVolume;
    };
    widget.settings.addListener(_settingsListener!);
    if (_saveRepository == null) {
      SaveRepository.load().then((repo) {
        if (mounted) setState(() => _saveRepository = repo);
      });
    }
    if (_endingArchive == null) {
      EndingArchive.load().then((arc) {
        if (mounted) setState(() => _endingArchive = arc);
      });
    }
  }

  @override
  void dispose() {
    if (_settingsListener != null) {
      widget.settings.removeListener(_settingsListener!);
    }
    _gameState.dispose();
    widget.settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = _saveRepository;
    final arc = _endingArchive;
    if (repo == null || arc == null) {
      // 初期ロード中は仮の空アプリを表示。SharedPreferences はモック済みで
      // ほぼ同期解決されるが、テスト時に setMockInitialValues 前ロードを避ける。
      return AnimatedBuilder(
        animation: widget.settings,
        builder: (context, _) {
          return MaterialApp(
            title: 'Tsuki to Kohi',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: widget.settings.themeMode,
            home: const Scaffold(body: SizedBox.shrink()),
          );
        },
      );
    }
    return AppScope(
      gameState: _gameState,
      settings: widget.settings,
      saveRepository: repo,
      endingArchive: arc,
      audio: _audio,
      child: AnimatedBuilder(
        animation: widget.settings,
        builder: (context, _) {
          return MaterialApp(
            title: 'Tsuki to Kohi',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: widget.settings.themeMode,
            home: const TitleScreen(),
          );
        },
      ),
    );
  }

  static ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}

/// アプリ全体で共有する状態のアクセサ。
class AppScope extends InheritedWidget {
  AppScope({
    super.key,
    required this.gameState,
    required this.settings,
    this.saveRepository,
    this.endingArchive,
    AudioService? audio,
    required super.child,
  }) : audio = audio ?? _defaultAudio;

  /// Sprint 11: AppScope に AudioService が未注入の場合の安全フォールバック。
  /// 既存テスト（Sprint 01〜10）はこの AppScope を直接 `const AppScope(...)` で
  /// 構築している可能性があったが、本 Sprint で AudioService が必須となるため、
  /// optional + デフォルト LoggingAudioService の組み合わせで後方互換を維持する。
  static final AudioService _defaultAudio = LoggingAudioService();

  final GameState gameState;
  final SettingsState settings;

  /// Sprint 09: optional. 既存テスト互換のため null 許容。
  /// UI 側は `saveRepositoryOrThrow` を介して取得する想定。
  final SaveRepository? saveRepository;

  /// Sprint 09: optional. 同上。
  final EndingArchive? endingArchive;

  /// Sprint 11: 音再生サービス。null で AppScope を構築しても
  /// [_defaultAudio]（LoggingAudioService の唯一のインスタンス）が入る。
  /// テストでも `LoggingAudioService` を必要に応じて注入できる。
  final AudioService audio;

  /// セーブ機能が必要な UI 側で安全に取り出すアクセサ。
  /// null（テスト用 AppScope 等）の場合は assert で落ちる。
  SaveRepository get requireSaveRepository {
    final repo = saveRepository;
    assert(repo != null, 'SaveRepository was not provided to AppScope');
    return repo!;
  }

  /// 同上（EndingArchive 用）。
  EndingArchive get requireEndingArchive {
    final arc = endingArchive;
    assert(arc != null, 'EndingArchive was not provided to AppScope');
    return arc!;
  }

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return gameState != oldWidget.gameState ||
        settings != oldWidget.settings ||
        saveRepository != oldWidget.saveRepository ||
        endingArchive != oldWidget.endingArchive ||
        audio != oldWidget.audio;
  }
}
