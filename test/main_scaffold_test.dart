import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/screens/album_screen.dart';
import 'package:tokimemo/screens/characters_screen.dart';
import 'package:tokimemo/screens/home_screen.dart';
import 'package:tokimemo/screens/main_scaffold.dart';
import 'package:tokimemo/screens/schedule_screen.dart';
import 'package:tokimemo/screens/stats_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpMain(WidgetTester tester) async {
    final settings = await createTestSettings();
    await tester.pumpWidget(
      wrapWithAppScope(child: const MainScaffold(), settings: settings),
    );
  }

  testWidgets('初期表示はホームタブで HomeScreen が見える', (tester) async {
    await pumpMain(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('main.bottomNav')), findsOneWidget);
  });

  testWidgets('5 タブ（ホーム/スケジュール/キャラ/能力値/アルバム）がすべて表示される',
      (tester) async {
    await pumpMain(tester);
    for (final name in ['ホーム', 'スケジュール', 'キャラ', '能力値', 'アルバム']) {
      expect(
        find.byKey(ValueKey('main.tab.$name')),
        findsOneWidget,
        reason: '$name タブが BottomNav に存在するはず',
      );
    }
  });

  testWidgets('スケジュールタブをタップするとスケジュール画面が前面に出る', (tester) async {
    await pumpMain(tester);
    await tester.tap(find.byKey(const ValueKey('main.tab.スケジュール')));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleScreen), findsOneWidget);
    // Sprint 05 で実装に置き換わり、月カレンダーのグリッドが描画される。
    expect(find.byKey(const ValueKey('schedule.monthGrid')), findsOneWidget);
  });

  testWidgets('キャラタブをタップするとキャラ一覧画面が前面に出る', (tester) async {
    await pumpMain(tester);
    await tester.tap(find.byKey(const ValueKey('main.tab.キャラ')));
    await tester.pumpAndSettle();
    expect(find.byType(CharactersScreen), findsOneWidget);
    // Sprint 06 で実装に置き換わり、5名のグリッドが描画される。
    expect(find.byKey(const ValueKey('characters.grid')), findsOneWidget);
  });

  testWidgets('能力値タブをタップすると StatsScreen が前面に出る', (tester) async {
    await pumpMain(tester);
    await tester.tap(find.byKey(const ValueKey('main.tab.能力値')));
    await tester.pumpAndSettle();
    expect(find.byType(StatsScreen), findsOneWidget);
    // 先頭の能力値行は必ずビューポート内にあるはず（受け入れ基準4の補強）。
    // 7 行すべての存在チェックは stats_screen_test.dart 側で行う。
    expect(find.byKey(const ValueKey('stats.row.intellect')), findsOneWidget);
  });

  testWidgets('アルバムタブをタップするとアルバム画面が前面に出る', (tester) async {
    await pumpMain(tester);
    await tester.tap(find.byKey(const ValueKey('main.tab.アルバム')));
    await tester.pumpAndSettle();
    expect(find.byType(AlbumScreen), findsOneWidget);
    // Sprint 08 で実装に置き換わり、CG グリッドが描画される。
    expect(find.byKey(const ValueKey('album.grid')), findsOneWidget);
  });

  testWidgets('能力値タブ → ホームタブで HomeScreen に戻る（デモシナリオ）',
      (tester) async {
    await pumpMain(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('main.tab.能力値')));
    await tester.pumpAndSettle();
    expect(find.byType(StatsScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('main.tab.ホーム')));
    await tester.pumpAndSettle();
    // IndexedStack なので HomeScreen は最初から tree にあるが、
    // 切り替え後にステータスバーが見えていることでホーム表示を確認する
    expect(find.byKey(const ValueKey('home.statusBar')), findsOneWidget);
  });
}
