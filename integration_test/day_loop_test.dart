import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/services/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 03 受け入れ基準4・5:
/// - 4 枠すべて実行（または「就寝」で残りスキップ）すると日付が翌日に進む
/// - 最低 3 日間ループしても落ちず、能力値の累積が画面に反映されている
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tutorial.shown': true});
  });

  Future<void> tapSlotAndChoose(
    WidgetTester tester,
    String slotLabel,
    String actionKeyName,
  ) async {
    await tester.tap(find.byKey(ValueKey('home.timelineSlot.$slotLabel.tap')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('actionSheet.action.$actionKeyName')),
    );
    await tester.pumpAndSettle();
  }

  /// Hotfix 2026-05-18 (B4): 平日日中は action sheet が出ず、即仕事ロール → 結果ダイアログ。
  Future<void> resolveWorkSlot(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('home.timelineSlot.日中.tap')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('work.resultDialog.close')));
    await tester.pumpAndSettle();
  }

  Future<void> bootToHome(WidgetTester tester) async {
    final settings = await SettingsRepository.load();
    await tester.pumpWidget(MugenSiritoriApp(settings: settings));
    await tester.pumpAndSettle();

    // タイトル → はじめから
    await tester.tap(find.byKey(const ValueKey('title.startButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('nameInput.field')),
      'テスト太郎',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nameInput.submitButton')));
    await tester.pumpAndSettle();
  }

  testWidgets('4 枠すべて実行すると 4月1日 → 4月2日 へ進む', (tester) async {
    await bootToHome(tester);

    expect(find.textContaining('4月1日'), findsWidgets);

    // 4/1 は水曜（平日）→ 日中は仕事固定で action sheet は出ない。
    await tapSlotAndChoose(tester, '朝', ActionKind.read.name);
    await resolveWorkSlot(tester);
    await tapSlotAndChoose(tester, '夕方', ActionKind.read.name);
    await tapSlotAndChoose(tester, '夜', ActionKind.read.name);

    // 翌日へ進んでいる
    expect(find.textContaining('4月2日'), findsWidgets);
    expect(find.textContaining('4月1日'), findsNothing);
  });

  testWidgets('朝に「就寝」を選ぶと残り枠スキップで翌日へ進む', (tester) async {
    await bootToHome(tester);

    expect(find.textContaining('4月1日'), findsWidgets);

    await tapSlotAndChoose(tester, '朝', ActionKind.sleep.name);

    expect(find.textContaining('4月2日'), findsWidgets);
  });

  testWidgets('3 日間ループしても落ちず、能力値（体力）の累積が反映されている', (tester) async {
    await bootToHome(tester);

    // 体力初期値 80。3 日分（合計 12 枠）「読書」で -2 × 12 = -24 → 56 となる
    // ただしクランプは 0 までなので、初期 80 なら 56 になる想定。
    // 4/1(水)・4/2(木)・4/3(金) は平日なので日中は仕事ロール（read ではない）。
    for (int day = 0; day < 3; day++) {
      await tapSlotAndChoose(tester, '朝', ActionKind.read.name);
      await resolveWorkSlot(tester);
      await tapSlotAndChoose(tester, '夕方', ActionKind.read.name);
      await tapSlotAndChoose(tester, '夜', ActionKind.read.name);
    }

    // 4月4日 になっている
    expect(find.textContaining('4月4日'), findsWidgets);
    // Hotfix 2026-05-18 (B4): 平日日中は仕事ロール（vitality 変動なし）。
    // 読書枠は 3 日 × 3 枠 = 9 回 → -2 × 9 = -18 → 80 - 18 = 62/100。
    expect(find.text('62/100'), findsOneWidget);
  });
}
