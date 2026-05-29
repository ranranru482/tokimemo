import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/settings_state.dart';
import 'package:tokimemo/screens/cg_reveal_screen.dart';
import 'package:tokimemo/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 10 受け入れ基準 4（integration test）:
/// CG 解放シーンで全画面 CG がフェードインで表示される。
///
/// 個別イベント (`ind.akari.1`) を発火 → 選択肢で完了 → 新規 CG 解放時に
/// `CgRevealScreen` が push され、`FadeTransition` の中で `CgView` が
/// 全画面表示される。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tutorial.shown': true});
  });

  testWidgets('個別イベント完了 → CgRevealScreen がフェードインで表示される',
      (tester) async {
    final gs = GameState(
      currentDate: DateTime(2026, 4, 11), // 土曜
      money: 10000,
      vitality: 100,
      vitalityMax: 100,
    );
    gs.recordEncounter(CharacterId.akari);
    gs.bumpAffinity(CharacterId.akari, 20);

    final settings = SettingsState(
      bgmVolume: SettingsState.defaultBgmVolume,
      // タイプライターを瞬時表示にして、各 next タップで 1 行ずつ進める。
      textSpeed: 1.0,
      themeMode: ThemeMode.light,
      onPersist: (_) async {},
    );

    await tester.pumpWidget(
      AppScope(
        gameState: gs,
        settings: settings,
        child: MaterialApp(
          home: HomeScreen(
            workRng: Random(0),
            randomEventRng: Random(0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // evening 枠タップで個別イベント発火
    await tester.tap(find.byKey(const ValueKey('home.timelineSlot.夕方.tap')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('eventPlayer.ind.akari.1.title')),
      findsOneWidget,
    );

    // 3 行進めて選択肢を選ぶ。タイプライター演出のため多めにタップして安定化。
    for (int i = 0; i < 8; i++) {
      if (find.byKey(const ValueKey('eventPlayer.choice.0'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.tap(find.byKey(const ValueKey('eventPlayer.next')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('eventPlayer.choice.0')));
    // CgRevealScreen がフェードインで開く（500ms）
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // フェードイン中は FadeTransition が複数存在する
    expect(find.byType(FadeTransition), findsWidgets);

    await tester.pumpAndSettle();

    // CgRevealScreen が表示されている
    expect(find.byType(CgRevealScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cgReveal.cg.ind.akari.1.root')),
      findsOneWidget,
    );

    // CG ライブラリにも登録済み
    expect(gs.cgLibrary.has('cg.ind.akari.1'), isTrue);

    // タップで閉じる
    await tester.tap(
      find.byKey(const ValueKey('cgReveal.cg.ind.akari.1.tapArea')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CgRevealScreen), findsNothing);
  });
}
