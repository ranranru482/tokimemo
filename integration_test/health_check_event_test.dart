import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/settings_state.dart';
import 'package:tokimemo/screens/main_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 08 受け入れ基準 1（integration test）:
/// 6 月の健康診断イベントが自動発火し、共通イベントとして全プレイヤーに表示される。
///
/// 戦略: 5/31 から始めて 4 枠埋めて 6/1 → そこから 14 日進めて 6/15 → 発火確認。
/// HomeScreen のフックで EventPlayer が push されることを確認する。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tutorial.shown': true});
  });

  testWidgets('5/31 → 6/15 で健康診断イベントが自動発火する', (tester) async {
    final gs = GameState(
      currentDate: DateTime(2026, 6, 14),
      vitality: 100,
      vitalityMax: 100,
    );

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
        child: const MaterialApp(home: MainScaffold()),
      ),
    );
    await tester.pumpAndSettle();

    // 6/14 の 4 枠を applyAction で埋めて 6/15 に進める
    for (final slot in SlotIndex.values) {
      gs.applyAction(slot, ActionKind.read);
    }
    await tester.pumpAndSettle();

    expect(gs.currentDate, DateTime(2026, 6, 15));
    // Hotfix 2026-05-18: 6/14(日) → 6/15(月) で weeklyReview も発火する。
    // 直列キューで先に push されるため、閉じてから共通イベントを検証する。
    final review = find.byKey(const ValueKey('weeklyReview.close'));
    if (review.evaluate().isNotEmpty) {
      await tester.tap(review);
      await tester.pumpAndSettle();
    }
    // EventPlayer が共通イベントとして開いている
    expect(
      find.byKey(const ValueKey('eventPlayer.common.health_check.jun.title')),
      findsOneWidget,
    );

    // 最後まで進める。タイプライター演出のため多めにタップ。
    // health_check イベントには選択肢が無いので、root が消えるまで連打。
    for (int i = 0; i < 20; i++) {
      if (find.byKey(const ValueKey(
          'eventPlayer.common.health_check.jun.title'))
          .evaluate()
          .isEmpty) {
        break;
      }
      await tester.tap(find.byKey(const ValueKey('eventPlayer.next')));
      await tester.pumpAndSettle();
    }

    // 解放後は CG ライブラリに健康診断 CG が登録される
    expect(gs.cgLibrary.has('cg.common.health_check_jun'), isTrue);
  });
}
