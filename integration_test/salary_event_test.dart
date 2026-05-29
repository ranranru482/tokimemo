import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/services/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 04 受け入れ基準5:
/// 月初（毎月1日）に給料受領演出が表示され、所持金が増加する。
///
/// 4月1日（水）から開始し、ループで日付を 4/30 まで進める。
/// 4/30 の最終枠を消化した時点で 5/1 に進み、salary ダイアログが出る想定。
///
/// 仕事評価が増減することで給料額にバラつきが出るため、所持金の検証は
/// 「初期値より増えている」かつ「下限給料以上」までを確認する。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tutorial.shown': true});
  });

  /// Hotfix 2026-05-18: ランダム遭遇 EventPlayer が平日朝に push されたとき、
  /// 右上の「閉じる」(`Icons.close` tooltip='閉じる') で即離脱する
  /// （途中閉じは応答 null = 効果反映なしの扱い、テストはサルベージのみ）。
  Future<void> dismissRandomEventIfShown(WidgetTester tester) async {
    for (int n = 0; n < 4; n++) {
      final closeButton = find.byTooltip('閉じる');
      if (closeButton.evaluate().isEmpty) return;
      await tester.tap(closeButton.first);
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapAndChoose(
    WidgetTester tester,
    String slotLabel,
    String actionKeyName,
  ) async {
    await tester.tap(find.byKey(ValueKey('home.timelineSlot.$slotLabel.tap')));
    await tester.pumpAndSettle();
    // ランダム遭遇 EventPlayer が出ていれば先に閉じる（平日朝のみ確率発火）。
    await dismissRandomEventIfShown(tester);
    await tester.tap(
      find.byKey(ValueKey('actionSheet.action.$actionKeyName')),
    );
    await tester.pumpAndSettle();
  }

  /// Hotfix 2026-05-18 (B4): 確認ダイアログ廃止。日中枠タップで即結果ダイアログ。
  /// Sprint C: 35% の確率で仕事中イベントダイアログが代わりに出る。両経路に対応する。
  Future<void> resolveWorkSlot(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('home.timelineSlot.日中.tap')));
    await tester.pumpAndSettle();
    final workEventChoice = find.byWidgetPredicate((w) {
      final k = w.key;
      return k is ValueKey<String> &&
          k.value.startsWith('workEvent.') &&
          k.value.endsWith('.choice.0');
    });
    if (workEventChoice.evaluate().isNotEmpty) {
      await tester.tap(workEventChoice.first);
      await tester.pumpAndSettle();
      final workEventClose = find.byWidgetPredicate((w) {
        final k = w.key;
        return k is ValueKey<String> &&
            k.value.startsWith('workEvent.') &&
            k.value.endsWith('.close');
      });
      await tester.tap(workEventClose.first);
      await tester.pumpAndSettle();
    } else {
      await tester.tap(find.byKey(const ValueKey('work.resultDialog.close')));
      await tester.pumpAndSettle();
    }
  }

  /// 平日か休日かを 4/X の日付から判定（祝日は無し）。
  bool isWeekdayLocal(int month, int day) {
    final wd = DateTime(2026, month, day).weekday;
    return wd >= DateTime.monday && wd <= DateTime.friday;
  }

  /// Hotfix 2026-05-18: 4 月中の encounter (4/10 akari, 4/15 uta, 4/20 toru) や
  /// 共通/節目イベント、週次ふりかえりが 1 日進むたびに直列キューで push される。
  /// 各 advance 後にまとめて閉じる。
  Future<void> dismissAllModals(WidgetTester tester) async {
    await tester.pumpAndSettle();
    for (int n = 0; n < 8; n++) {
      final review = find.byKey(const ValueKey('weeklyReview.close'));
      if (review.evaluate().isNotEmpty) {
        await tester.tap(review);
        await tester.pumpAndSettle();
        continue;
      }
      // DialogueModal / EventPlayer はどちらも tooltip='閉じる' の右上アイコンを持つ。
      // 途中閉じ扱い（応答 null）で離脱する。
      final closeButton = find.byTooltip('閉じる');
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton.first);
        await tester.pumpAndSettle();
        continue;
      }
      break;
    }
  }

  /// 1日分を消化。途中で「週次ふりかえり」/「出会い」モーダルが出てきたら閉じる。
  Future<void> playOneDay(WidgetTester tester, int month, int day) async {
    final weekday = isWeekdayLocal(month, day);

    if (weekday) {
      await tapAndChoose(tester, '朝', ActionKind.read.name);
      await resolveWorkSlot(tester);
      await tapAndChoose(tester, '夕方', ActionKind.read.name);
      await tapAndChoose(tester, '夜', ActionKind.read.name);
    } else {
      await tapAndChoose(tester, '朝', ActionKind.read.name);
      await tapAndChoose(tester, '日中', ActionKind.read.name);
      await tapAndChoose(tester, '夕方', ActionKind.read.name);
      await tapAndChoose(tester, '夜', ActionKind.read.name);
    }
    await dismissAllModals(tester);
  }

  Future<void> bootToHome(WidgetTester tester) async {
    final settings = await SettingsRepository.load();
    await tester.pumpWidget(MugenSiritoriApp(settings: settings));
    await tester.pumpAndSettle();
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

  testWidgets('4/30 → 5/1 で給料ダイアログが表示され、所持金が増える', (tester) async {
    await bootToHome(tester);

    // 4/1 〜 4/30 を順次消化
    for (int day = 1; day <= 30; day++) {
      await playOneDay(tester, 4, day);
    }

    // 5/1 に進んだタイミングで給料ダイアログが push される
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('salary.dialog')),
      findsOneWidget,
      reason: '5月1日の朝、給料ダイアログが表示されるはず',
    );
    // 「給料 X円 を受け取りました」の本文
    expect(
      find.byKey(const ValueKey('salary.dialog.amount')),
      findsOneWidget,
    );
    // 「5月 給料日」のタイトル
    expect(find.textContaining('5月 給料日'), findsOneWidget);

    // 閉じる
    await tester.tap(find.byKey(const ValueKey('salary.dialog.close')));
    await tester.pumpAndSettle();

    // 所持金がステータスバーで増えていることを確認
    // 初期 50,000 円 + 給料下限 180,000 円 = 230,000 円以上
    final moneyChip = find.byKey(const ValueKey('statusBar.money'));
    expect(moneyChip, findsOneWidget);
    // 「数値,数値,数値円」の形式で 6 桁以上の値が見えていればよい
    final moneyText = tester.widget<Text>(
      find.descendant(of: moneyChip, matching: find.byType(Text)),
    );
    final str = moneyText.data ?? '';
    // 数値部分を抽出（カンマ・「円」を除去）
    final numeric = int.tryParse(
      str.replaceAll(',', '').replaceAll('円', '').trim(),
    );
    expect(numeric, isNotNull);
    expect(numeric, greaterThanOrEqualTo(50000 + 180000));
  }, timeout: const Timeout(Duration(minutes: 10)));
}
