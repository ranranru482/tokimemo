import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/settings_state.dart';
import 'package:tokimemo/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 08 受け入れ基準 2（integration test）:
/// 各キャラの好感度 2 段階目で個別イベントが解放され、特定の枠でそれが優先発火する。
///
/// 戦略: 4/11（土）に akari と出会い済 + affinity 20（=段階 2）の状態で
/// HomeScreen の evening 枠をタップすると、通常の行動シートではなく
/// 個別イベント (`ind.akari.1`) の EventPlayer が起動する。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tutorial.shown': true});
  });

  testWidgets('affinity 20 + evening タップ → 個別イベントが優先発火', (tester) async {
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
      textSpeed: SettingsState.defaultTextSpeed,
      themeMode: ThemeMode.light,
      onPersist: (_) async {},
    );

    await tester.pumpWidget(
      AppScope(
        gameState: gs,
        settings: settings,
        // ランダム遭遇判定を確実に「発火しない」にするため、seed を固定して
        // nextInt(100) >= 15 が出る Random を渡す（Random(0).nextInt(100)=44）。
        child: MaterialApp(
          home: HomeScreen(
            workRng: Random(0),
            randomEventRng: Random(0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // evening 枠タップ
    await tester.tap(find.byKey(const ValueKey('home.timelineSlot.夕方.tap')));
    await tester.pumpAndSettle();

    // EventPlayer が ind.akari.1 で開いている
    expect(
      find.byKey(const ValueKey('eventPlayer.ind.akari.1.title')),
      findsOneWidget,
    );

    // 最後まで進めて選択肢を選ぶ。
    // ind.akari.1 は 3 行のスクリプト + 1 つの選択肢。
    // タイプライター演出があるため、選択肢が現れるまで safety で多めにタップ。
    for (int i = 0; i < 8; i++) {
      if (find.byKey(const ValueKey('eventPlayer.choice.0'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.tap(find.byKey(const ValueKey('eventPlayer.next')));
      await tester.pumpAndSettle();
    }
    // 選択肢 0 を選ぶ
    await tester.tap(find.byKey(const ValueKey('eventPlayer.choice.0')));
    await tester.pumpAndSettle();

    // Sprint 10: 新規 CG 解放時は CgRevealScreen が push されるため、
    // 閉じてから後続のスロット状態を検証する（消費は CgReveal pop 後に走る）。
    final cgArea = find.byKey(const ValueKey('cgReveal.cg.ind.akari.1.tapArea'));
    if (cgArea.evaluate().isNotEmpty) {
      await tester.tap(cgArea);
      await tester.pumpAndSettle();
    }

    // 解放済イベントに ind.akari.1 が入っている
    expect(
      gs.characterStateOf(CharacterId.akari).unlockedEventIds,
      contains('ind.akari.1'),
    );
    // CG ライブラリに登録される
    expect(gs.cgLibrary.has('cg.ind.akari.1'), isTrue);
    // 枠は done に変わる
    expect(gs.slotStateOf(SlotIndex.evening), SlotState.done);
  });
}
