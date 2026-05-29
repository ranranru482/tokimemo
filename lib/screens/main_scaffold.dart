import 'dart:math';

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/audio_keys.dart';
import '../services/scene_bgm_router.dart';
import 'album_screen.dart';
import 'characters_screen.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'stats_screen.dart';

/// ホーム画面以下の 5 タブナビゲーションを提供する親 Scaffold。
///
/// 仕様書 §10 画面02「下部に5つのナビゲーションタブ」に対応する。
/// タブ構成は仕様書のホーム画面要件と他画面の存在から
/// 「ホーム」「スケジュール」「キャラ」「能力値」「アルバム」の 5 つとする。
/// （設定はホーム画面 AppBar の歯車アイコンからアクセスするため、
///   ここでは含めずアルバム枠を Sprint 02 から確保する。
///   Material 3 推奨の [NavigationBar] を使用する。）
///
/// タブ切替時に各画面のスクロール位置や状態を保持するため
/// [IndexedStack] で全画面を生存させる。
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, this.initialIndex = 0});

  /// 初期表示するタブのインデックス。テスト等で直接遷移したい時に使う。
  final int initialIndex;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  /// Sprint 08: 実プレイ時にランダム遭遇を有効化するため、
  /// HomeScreen に常に Random() を渡す（State 内で 1 つ生成して再利用）。
  final Random _randomEventRng = Random();

  /// Sprint C: 実プレイ時に仕事中イベントを有効化するための Random。
  final Random _workEventRng = Random();

  static const List<_TabSpec> _tabs = <_TabSpec>[
    _TabSpec(
      label: 'ホーム',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _TabSpec(
      label: 'スケジュール',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    _TabSpec(
      label: 'キャラ',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    ),
    _TabSpec(
      label: '能力値',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
    _TabSpec(
      label: 'アルバム',
      icon: Icons.photo_library_outlined,
      selectedIcon: Icons.photo_library,
    ),
  ];

  bool _bgmRequested = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _tabs.length - 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bgmRequested) return;
    _bgmRequested = true;
    // Sprint 11: MainScaffold（ホーム拠点）進入時に bgm.home をクロスフェード。
    final audio = AppScope.of(context).audio;
    SceneBgmRouter.enterWithService(audio, BgmScene.home);
  }

  @override
  Widget build(BuildContext context) {
    final audio = AppScope.of(context).audio;
    return Scaffold(
      key: const ValueKey('scaffold.main'),
      body: IndexedStack(
        key: const ValueKey('main.indexedStack'),
        index: _currentIndex,
        children: <Widget>[
          HomeScreen(
            randomEventRng: _randomEventRng,
            workEventRng: _workEventRng,
          ),
          const ScheduleScreen(),
          const CharactersScreen(),
          const StatsScreen(),
          const AlbumScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: const ValueKey('main.bottomNav'),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          // Sprint 11: タブ切替時にタップ SE。
          audio.playSe(AudioKeys.seTap);
          setState(() => _currentIndex = i);
        },
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              key: ValueKey('main.tab.${t.label}'),
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
