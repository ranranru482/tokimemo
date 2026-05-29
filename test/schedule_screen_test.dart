import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/screens/schedule_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Sprint 05 受け入れ基準1・5:
/// - スケジュール画面で月カレンダーが表示
/// - 日付タップで 4 枠の予約状況シートが開く
/// - 予約済みをキャンセルできる
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<GameState> pumpSchedule(WidgetTester tester, {DateTime? today}) async {
    final settings = await createTestSettings();
    final gameState = GameState(currentDate: today ?? DateTime(2026, 4, 1));
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const ScheduleScreen(),
        settings: settings,
        gameState: gameState,
      ),
    );
    await tester.pumpAndSettle();
    return gameState;
  }

  group('カレンダー表示', () {
    testWidgets('月ラベルと月グリッドが表示される', (tester) async {
      await pumpSchedule(tester);
      expect(find.byKey(const ValueKey('schedule.monthLabel')), findsOneWidget);
      expect(find.byKey(const ValueKey('schedule.monthGrid')), findsOneWidget);
      expect(find.text('2026年4月'), findsOneWidget);
    });

    testWidgets('月の各日（4/1〜4/30）が DayCell として描画される', (tester) async {
      await pumpSchedule(tester);
      // 数日サンプリングして確認
      for (final day in [1, 10, 15, 30]) {
        expect(
          find.byKey(ValueKey('schedule.day.2026-4-$day')),
          findsOneWidget,
          reason: '4/$day のセルが存在するはず',
        );
      }
    });

    testWidgets('次の月へ送れる（4月 → 5月）', (tester) async {
      await pumpSchedule(tester);
      await tester.tap(find.byKey(const ValueKey('schedule.monthNext')));
      await tester.pumpAndSettle();
      expect(find.text('2026年5月'), findsOneWidget);
    });
  });

  group('日付タップでシートが開く', () {
    testWidgets('翌日の日付をタップすると 4 枠が表示される（休日 = 4/4 土）', (tester) async {
      // 今日 = 4/1（水）。タップ対象 = 4/4（土、休日）
      await pumpSchedule(tester);

      await tester.tap(find.byKey(const ValueKey('schedule.day.2026-4-4')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('schedule.daySheet.root')), findsOneWidget);
      // 4 枠すべての行がある
      for (final label in ['朝', '日中', '夕方', '夜']) {
        expect(
          find.byKey(ValueKey('schedule.daySheet.slot.$label')),
          findsOneWidget,
          reason: '$label の行があるはず',
        );
      }
      // 休日なので「予約不可」表示（仕事固定）にはならない
      expect(find.text('仕事（予約不可）'), findsNothing);
      // 朝枠は未予約 + 予約ボタンが出る
      expect(
        find.byKey(const ValueKey('schedule.daySheet.slot.朝.reserve')),
        findsOneWidget,
      );
    });

    testWidgets('翌日の平日（4/2 木）をタップすると日中は「仕事（予約不可）」', (tester) async {
      await pumpSchedule(tester);
      await tester.tap(find.byKey(const ValueKey('schedule.day.2026-4-2')));
      await tester.pumpAndSettle();

      expect(find.text('仕事（予約不可）'), findsOneWidget);
      // 日中の予約ボタンは出ない
      expect(
        find.byKey(const ValueKey('schedule.daySheet.slot.日中.reserve')),
        findsNothing,
      );
    });
  });

  group('予約のキャンセル', () {
    testWidgets('予約済みの枠でゴミ箱ボタンを押すと予約が消える', (tester) async {
      final state = await pumpSchedule(tester);
      // 4/4（土）朝に映画を予約しておく
      state.reserveAction(DateTime(2026, 4, 4), SlotIndex.morning, ActionKind.movie);
      await tester.pumpAndSettle();

      // 日付タップでシートを開く
      await tester.tap(find.byKey(const ValueKey('schedule.day.2026-4-4')));
      await tester.pumpAndSettle();

      // 「映画」が見えている
      expect(find.text('映画'), findsOneWidget);

      // キャンセルボタンを押す
      await tester.tap(
        find.byKey(const ValueKey('schedule.daySheet.slot.朝.cancel')),
      );
      await tester.pumpAndSettle();

      // 予約が消えている
      expect(
        state.schedule.reservationOf(DateTime(2026, 4, 4), SlotIndex.morning),
        isNull,
      );
      // 行はまだあるが「未予約」表示に切り替わる
      expect(find.text('未予約'), findsWidgets);
    });
  });

  group('日付セルのバッジ', () {
    testWidgets('予約のある日にはバッジが出る', (tester) async {
      final state = await pumpSchedule(tester);
      state.reserveAction(DateTime(2026, 4, 11), SlotIndex.morning, ActionKind.museum);
      state.reserveAction(DateTime(2026, 4, 11), SlotIndex.evening, ActionKind.movie);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('schedule.day.2026-4-11.badge')),
        findsOneWidget,
      );
      // バッジテキストが「2」
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('予約のない日にはバッジが出ない', (tester) async {
      await pumpSchedule(tester);
      expect(
        find.byKey(const ValueKey('schedule.day.2026-4-12.badge')),
        findsNothing,
      );
    });
  });

  group('新規予約フロー（widget）', () {
    testWidgets('4/4（土）朝枠 → 予約ボタン → 映画を選ぶと予約が保存される', (tester) async {
      final state = await pumpSchedule(tester);

      await tester.tap(find.byKey(const ValueKey('schedule.day.2026-4-4')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('schedule.daySheet.slot.朝.reserve')),
      );
      await tester.pumpAndSettle();

      // 行動ピッカーが開いている
      expect(find.byKey(const ValueKey('schedule.reservePicker.root')),
          findsOneWidget);

      // 映画を選ぶ。リストは縦スクロールで画面外にある可能性があるので
      // ensureVisible で可視範囲にスクロールしてからタップする。
      final movieFinder =
          find.byKey(const ValueKey('schedule.reservePicker.action.movie'));
      await tester.scrollUntilVisible(
        movieFinder,
        100.0,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('schedule.reservePicker.root')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(movieFinder);
      await tester.pumpAndSettle();

      expect(
        state.schedule.reservationOf(DateTime(2026, 4, 4), SlotIndex.morning),
        ActionKind.movie,
      );
    });
  });
}
