import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/data/character_repository.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/settings_state.dart';
import 'package:tokimemo/screens/main_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 06 受け入れ基準2 + 基準5（統合シナリオ）:
/// - 4/9 で全枠埋めて 4/10 に進むと DialogueModal が自動で開く
/// - DialogueModal で「次へ」を進めると normal → smile → normal の表情差分が
///   描画上 key として切り替わる
/// - 閉じた後、GameState.hasMet(akari) が true になり、キャラ一覧の
///   akari カードが「？？？」から正式名（七瀬 灯）に切り替わる
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tutorial.shown': true});
  });

  testWidgets('4/9 → 4/10 で akari の出会いイベントが発火し、表情差分が出る + 一覧に反映',
      (tester) async {
    final today = DateTime(2026, 4, 9); // 木曜（平日）
    final gameState = GameState(
      currentDate: today,
      money: 30000,
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
        gameState: gameState,
        settings: settings,
        child: MaterialApp(
          home: AnimatedBuilder(
            animation: settings,
            builder: (context, _) {
              return MainScaffold(
                key: const ValueKey('integ.mainScaffold'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 4/9 (木) の 4 枠を直接 GameState 経由で埋める（HomeScreen 内の
    // 仕事ミニ判定ダイアログを介さない高速ルート）。midday も applyAction
    // で done にできる。
    for (final slot in SlotIndex.values) {
      gameState.applyAction(slot, ActionKind.read);
    }
    await tester.pumpAndSettle();

    expect(gameState.currentDate, DateTime(2026, 4, 10));

    // DialogueModal が自動的に開いているはず
    expect(find.byKey(const ValueKey('dialogueModal.root')), findsOneWidget);
    // 最初の発話は normal 表情
    final akari = CharacterRepository.byId(CharacterId.akari);
    expect(
      find.byKey(ValueKey(
          'characterPortrait.${akari.id.name}.expression.normal')),
      findsOneWidget,
    );

    // Sprint 10: タイプライター演出が入ったため、各発話で
    //   1 タップ目: 行内のタイプライターを瞬時表示（_lineCompleted=true へ）
    //   2 タップ目: 次の発話に進む（_index += 1）
    // とは限らない（pumpAndSettle で typewriter が完了している場合は 1 タップで進む）。
    // 表情が変わるまで複数回タップする安定ヘルパを用意。
    Future<void> advanceUntilExpression(String expressionName) async {
      const maxTaps = 4;
      for (int i = 0; i < maxTaps; i++) {
        await tester.tap(find.byKey(const ValueKey('dialogueModal.next')));
        await tester.pumpAndSettle();
        final hit = find.byKey(ValueKey(
            'characterPortrait.${akari.id.name}.expression.$expressionName'));
        if (hit.evaluate().isNotEmpty) return;
      }
      fail('${akari.id.name}.expression.$expressionName が $maxTaps タップで現れなかった');
    }

    // 次へ → 2 発話目は smile 表情
    await advanceUntilExpression('smile');
    // 次へ → 3 発話目は normal 表情
    await advanceUntilExpression('normal');

    // 最終発話で「閉じる」をタップ（残りタップで閉じるまで進める）
    for (int i = 0; i < 4; i++) {
      if (find.byKey(const ValueKey('dialogueModal.root')).evaluate().isEmpty) {
        break;
      }
      await tester.tap(find.byKey(const ValueKey('dialogueModal.next')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('dialogueModal.root')), findsNothing);

    // GameState 上 akari は出会い済
    expect(gameState.hasMet(CharacterId.akari), isTrue);

    // キャラタブに移動して一覧で akari の名前が「？？？」ではなくなっている
    await tester.tap(find.byKey(const ValueKey('main.tab.キャラ')));
    await tester.pumpAndSettle();
    final nameText = tester.widget<Text>(
      find.byKey(const ValueKey('characters.card.akari.name')),
    );
    expect(nameText.data, '七瀬 灯');
  });

  testWidgets('表情差分: troubled 表情のイベント（toru: 4/19 → 4/20）',
      (tester) async {
    // toru の出会いには troubled 表情の発話が含まれる（spec §5 「線引きに敏感」）
    final today = DateTime(2026, 4, 19); // 日曜（休日）
    final gameState = GameState(
      currentDate: today,
      money: 30000,
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
        gameState: gameState,
        settings: settings,
        child: MaterialApp(
          home: AnimatedBuilder(
            animation: settings,
            builder: (context, _) {
              return MainScaffold(
                key: const ValueKey('integ.mainScaffold'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 4/19 の 4 枠を埋める
    for (final slot in SlotIndex.values) {
      gameState.applyAction(slot, ActionKind.read);
    }
    await tester.pumpAndSettle();

    expect(gameState.currentDate, DateTime(2026, 4, 20));

    // 日曜終了 → weeklyReview と encounter が両方 push される。
    // Hotfix 2026-05-18 直列キュー化により、weeklyReview を先に閉じる必要がある。
    if (find.byKey(const ValueKey('weeklyReview.scaffold'))
        .evaluate()
        .isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('weeklyReview.close')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('dialogueModal.root')), findsOneWidget);

    // 1発話目: normal → 2発話目: troubled の表情差分を踏みに行く
    // タイプライター演出のため、表情が現れるまで複数タップする安定ヘルパ。
    Future<void> advanceUntilExpression(String expressionName) async {
      const maxTaps = 4;
      for (int i = 0; i < maxTaps; i++) {
        await tester.tap(find.byKey(const ValueKey('dialogueModal.next')));
        await tester.pumpAndSettle();
        final hit = find.byKey(
          ValueKey('characterPortrait.toru.expression.$expressionName'),
        );
        if (hit.evaluate().isNotEmpty) return;
      }
      fail('toru.expression.$expressionName が $maxTaps タップで現れなかった');
    }

    await advanceUntilExpression('troubled');

    // 最後まで進めて閉じる
    for (int i = 0; i < 6; i++) {
      if (find.byKey(const ValueKey('dialogueModal.root')).evaluate().isEmpty) {
        break;
      }
      await tester.tap(find.byKey(const ValueKey('dialogueModal.next')));
      await tester.pumpAndSettle();
    }

    expect(gameState.hasMet(CharacterId.toru), isTrue);
  });
}
