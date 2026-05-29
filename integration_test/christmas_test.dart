import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/settings_state.dart';
import 'package:tokimemo/screens/main_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 08 受け入れ基準 3（integration test）:
/// 12/24 のクリスマスで「誰と過ごすか」選択画面が出て、選んだキャラとの
/// 専用シーンが再生される。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tutorial.shown': true});
  });

  testWidgets('12/23 → 12/24 で ChristmasChoiceScreen が出て akari を選ぶと専用シーンが再生',
      (tester) async {
    final gs = GameState(
      currentDate: DateTime(2026, 12, 23),
      vitality: 100,
      vitalityMax: 100,
    );
    gs.recordEncounter(CharacterId.akari);

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

    // 12/23 の 4 枠を埋めて 12/24 に進める
    for (final slot in SlotIndex.values) {
      gs.applyAction(slot, ActionKind.read);
    }
    await tester.pumpAndSettle();

    expect(gs.currentDate, DateTime(2026, 12, 24));
    // ChristmasChoiceScreen が開いている
    expect(find.byKey(const ValueKey('christmasChoice.root')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('christmasChoice.pick.akari')),
      findsOneWidget,
    );
    // 未会いは出ない
    expect(
      find.byKey(const ValueKey('christmasChoice.pick.uta')),
      findsNothing,
    );

    // akari を選ぶ → 専用 EventPlayer が起動する
    await tester.tap(find.byKey(const ValueKey('christmasChoice.pick.akari')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('eventPlayer.milestone.christmas.akari.title'),
      ),
      findsOneWidget,
    );

    // 4 行進む（akari は 4 line + 1 choice）。タイプライター演出のため多めにタップ。
    for (int i = 0; i < 10; i++) {
      if (find.byKey(const ValueKey('eventPlayer.choice.0'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.tap(find.byKey(const ValueKey('eventPlayer.next')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('eventPlayer.choice.0')));
    await tester.pumpAndSettle();

    // 解放処理が走り、CG が登録される
    expect(gs.cgLibrary.has('cg.milestone.christmas.akari'), isTrue);
    // クリスマス本体イベントも記録済（再発火しない）
    expect(
      gs.unlockedGlobalEventIds,
      contains('common.christmas.dec'),
    );
  });
}
