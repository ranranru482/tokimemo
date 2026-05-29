import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/services/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 04 受け入れ基準4:
/// 日曜日終了時に週次ふりかえり画面が表示され、能力値の週間変動が確認できる。
///
/// 開始日 2026/4/1（水）。7日進めれば次の日曜（4/5）の翌日 4/6 月曜になり、
/// 4/5 の最終枠を終えた時点で週次ふりかえりがモーダル表示される想定。
///
/// 仕事ミニ判定はランダム性があるため、結果ダイアログがどちらでも閉じる
/// ヘルパを用意する。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tutorial.shown': true});
  });

  Future<void> tapAndChoose(
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

  /// 平日の日中（仕事ミニ判定）を 1 回処理する。Hotfix 2026-05-18 (B4) 以降、
  /// 確認ダイアログは廃止され、日中枠タップで即ロール → 結果ダイアログ 1 つに短縮。
  Future<void> resolveWorkSlot(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('home.timelineSlot.日中.tap')));
    await tester.pumpAndSettle();
    // success / failure いずれかの close ボタンを押す
    await tester.tap(find.byKey(const ValueKey('work.resultDialog.close')));
    await tester.pumpAndSettle();
  }

  /// 1 日を消化（平日：朝/夕方/夜は read、日中は仕事判定）。
  /// 休日：4 枠とも read。
  Future<void> playOneDay(WidgetTester tester, {required bool weekday}) async {
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

  testWidgets('4/1(水)〜4/5(日)を進めて日曜終了で週次ふりかえりが表示される',
      (tester) async {
    await bootToHome(tester);

    // 4/1 (水) 〜 4/3 (金) は平日
    await playOneDay(tester, weekday: true); // 4/1
    await playOneDay(tester, weekday: true); // 4/2
    await playOneDay(tester, weekday: true); // 4/3
    // 4/4 (土), 4/5 (日) は休日
    await playOneDay(tester, weekday: false); // 4/4
    await playOneDay(tester, weekday: false); // 4/5

    // 日曜の最終枠を終えた直後、postFrame で WeeklyReviewScreen が push される
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('weeklyReview.scaffold')),
      findsOneWidget,
      reason: '日曜終了で週次ふりかえり画面が表示されるはず',
    );
    // 期間表示
    expect(find.textContaining('4月1日'), findsWidgets);
    expect(find.textContaining('4月5日'), findsWidgets);

    // 閉じる → ホームに戻る
    await tester.tap(find.byKey(const ValueKey('weeklyReview.close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('weeklyReview.scaffold')), findsNothing);
  });
}
