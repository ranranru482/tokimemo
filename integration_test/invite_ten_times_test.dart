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

/// Sprint 07 受け入れ基準1:
/// キャラを「誘う」を10回繰り返すと表面好感度が上がり、5段階ハートが2段階目に進む。
///
/// 「誘う」の成功時 affinity +2 → 10 回成功で +20 → ちょうど 2 段階目に到達。
///
/// 成功率は確率なので、テストでは決定論的に成功を強制するために
/// `GameState.applyInviteOutcome(success: true)` を直接呼ぶ高速ルートを使う。
/// 1 日 1 回ずつ「誘って」「残り 3 枠を read で埋める」を 10 日分繰り返す。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tutorial.shown': true});
  });

  testWidgets('10回誘い成功 → 表面好感度+20 → ハートが 2 段階目に進む', (tester) async {
    // 4/4 (土) スタートで休日から誘える状態にする。お金は十分に。
    final gameState = GameState(
      currentDate: DateTime(2026, 4, 4),
      money: 999999,
      vitality: 100,
      vitalityMax: 100,
    );
    gameState.recordEncounter(CharacterId.akari);

    final settings = SettingsState(
      bgmVolume: SettingsState.defaultBgmVolume,
      textSpeed: SettingsState.defaultTextSpeed,
      themeMode: ThemeMode.light,
      onPersist: (_) async {},
    );

    await tester.pumpWidget(
      AppScope(
        gameState: gameState,
        settings: settings,
        child: MaterialApp(
          home: AnimatedBuilder(
            animation: settings,
            builder: (context, _) {
              return const MainScaffold(key: ValueKey('integ.mainScaffold'));
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 初期は 1 段階目 (affinity=0)
    expect(gameState.characterStateOf(CharacterId.akari).affinity, 0);
    expect(gameState.characterStateOf(CharacterId.akari).affinityStage, 1);

    // 10 日連続で 1 回ずつ誘う（残り 3 枠は read で消化）
    for (int day = 0; day < 10; day++) {
      // 朝枠で誘う（成功固定）
      final ok = gameState.applyInviteOutcome(
        slot: SlotIndex.morning,
        target: CharacterId.akari,
        success: true,
      );
      expect(ok, isTrue, reason: 'day=$day で誘いが失敗してはいけない');
      // 残り 3 枠を read で消化 → 自動的に翌日へ
      for (final slot in <SlotIndex>[
        SlotIndex.midday,
        SlotIndex.evening,
        SlotIndex.night,
      ]) {
        gameState.applyAction(slot, ActionKind.read);
      }
    }
    await tester.pumpAndSettle();

    // 10 回 +2 で affinity = 20 → ちょうど 2 段階目（spec §6: 20〜39）
    expect(gameState.characterStateOf(CharacterId.akari).affinity, 20);
    expect(gameState.characterStateOf(CharacterId.akari).affinityStage, 2);

    // Hotfix 2026-05-18: 10 日進めた間に push された weeklyReview / salary 等の
    // モーダルを順に閉じてから main タブを操作する。
    for (int i = 0; i < 8; i++) {
      final review = find.byKey(const ValueKey('weeklyReview.close'));
      final salary = find.byKey(const ValueKey('salary.dialog.close'));
      if (review.evaluate().isNotEmpty) {
        await tester.tap(review);
        await tester.pumpAndSettle();
        continue;
      }
      if (salary.evaluate().isNotEmpty) {
        await tester.tap(salary);
        await tester.pumpAndSettle();
        continue;
      }
      break;
    }

    // キャラタブに移動して詳細を開く
    await tester.tap(find.byKey(const ValueKey('main.tab.キャラ')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('characters.card.akari')));
    await tester.pumpAndSettle();

    // 2 段階目: 0番目と1番目が filled、2-4 番目は outline
    expect(
      find.byKey(const ValueKey('affinityHearts.icon.0.filled')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('affinityHearts.icon.1.filled')),
      findsOneWidget,
    );
    for (int i = 2; i < 5; i++) {
      expect(
        find.byKey(ValueKey('affinityHearts.icon.$i.outline')),
        findsOneWidget,
      );
    }
  });
}
