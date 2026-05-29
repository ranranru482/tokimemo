import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/screens/album_screen.dart';
import 'package:tokimemo/screens/characters_screen.dart';
import 'package:tokimemo/screens/home_screen.dart';
import 'package:tokimemo/screens/schedule_screen.dart';
import 'package:tokimemo/screens/stats_screen.dart';
import 'package:tokimemo/services/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 02 受け入れ基準3: 下部タブをタップすると対応するスタブ画面が開く。
///
/// タイトル → はじめから → 名前入力 → MainScaffold を経て、
/// 5 タブそれぞれをタップして対応する画面が表に出ることを確認する。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tutorial.shown': true});
  });

  testWidgets('5 タブそれぞれをタップして対応する画面が前面に出る', (tester) async {
    final settings = await SettingsRepository.load();
    await tester.pumpWidget(MugenSiritoriApp(settings: settings));
    await tester.pumpAndSettle();

    // タイトル → はじめから
    await tester.tap(find.byKey(const ValueKey('title.startButton')));
    await tester.pumpAndSettle();

    // 名前入力
    await tester.enterText(
      find.byKey(const ValueKey('nameInput.field')),
      'テスト太郎',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nameInput.submitButton')));
    await tester.pumpAndSettle();

    // 初期はホームタブ
    expect(find.byType(HomeScreen), findsOneWidget);

    Future<void> tapAndExpect(String tabName, Finder placeholder) async {
      await tester.tap(find.byKey(ValueKey('main.tab.$tabName')));
      await tester.pumpAndSettle();
      expect(placeholder, findsOneWidget,
          reason: '$tabName タブを開くと対応する画面が表に出るはず');
    }

    await tapAndExpect('スケジュール', find.byType(ScheduleScreen));
    await tapAndExpect('キャラ', find.byType(CharactersScreen));
    await tapAndExpect('能力値', find.byType(StatsScreen));
    await tapAndExpect('アルバム', find.byType(AlbumScreen));
    await tapAndExpect('ホーム', find.byKey(const ValueKey('home.statusBar')));
  });
}
