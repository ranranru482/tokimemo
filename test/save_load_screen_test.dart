import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/save_snapshot.dart';
import 'package:tokimemo/screens/save_load_screen.dart';
import 'package:tokimemo/services/save_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Sprint 09: セーブ/ロード画面の widget test。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// ListView だが、項目が 14 件あり実機サイズではビルドされない要素が
  /// 出るためサーフェスを縦長にする。
  void useTallTestView(WidgetTester tester) {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('全 10 手動スロット + 1 クイック + 3 オートが描画される',
      (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final repo = await SaveRepository.load();
    final gs = GameState(heroName: 'テスト');

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const SaveLoadScreen(mode: SaveLoadMode.save),
        settings: settings,
        gameState: gs,
        saveRepository: repo,
      ),
    );
    await tester.pumpAndSettle();

    // クイック
    expect(find.byKey(const ValueKey('saveLoad.slot.quick')), findsOneWidget);
    // 手動 10 スロット
    for (int i = 0; i < SaveRepository.manualSlotCount; i++) {
      expect(find.byKey(ValueKey('saveLoad.slot.manual.$i')), findsOneWidget);
    }
    // オート 3 スロット
    for (int i = 0; i < SaveRepository.autoSlotCount; i++) {
      expect(find.byKey(ValueKey('saveLoad.slot.auto.$i')), findsOneWidget);
    }
  });

  testWidgets('空スロットは --- 表示', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final repo = await SaveRepository.load();
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const SaveLoadScreen(mode: SaveLoadMode.save),
        settings: settings,
        saveRepository: repo,
      ),
    );
    await tester.pumpAndSettle();
    // 最低 1 件は空スロット表示があるはず。
    expect(find.text('---'), findsWidgets);
  });

  testWidgets('既存セーブのある手動スロットはサマリーを表示する', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final repo = await SaveRepository.load();
    final gs = GameState(heroName: '太郎');
    await repo.write(SaveSlotKey.manual(0), gs);

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const SaveLoadScreen(mode: SaveLoadMode.save),
        settings: settings,
        gameState: gs,
        saveRepository: repo,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('save.slot.0.heroName')), findsOneWidget);
    expect(find.byKey(const ValueKey('save.slot.0.summary')), findsOneWidget);
    expect(find.text('太郎'), findsOneWidget);
  });

  testWidgets('空スロットをタップ → 新規セーブ可能', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final repo = await SaveRepository.load();
    final gs = GameState(heroName: '新規太郎');

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const SaveLoadScreen(mode: SaveLoadMode.save),
        settings: settings,
        gameState: gs,
        saveRepository: repo,
      ),
    );
    await tester.pumpAndSettle();

    // 手動スロット 0 番をタップ → ボトムシートが出て「新規セーブ」が選べる。
    await tester.tap(find.byKey(const ValueKey('save.slot.0.tap')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('save.slot.0.action.save')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save.slot.0.action.save')));
    await tester.pumpAndSettle();

    // 保存後、サマリーが描画される。
    expect(find.text('新規太郎'), findsOneWidget);
  });

  testWidgets('上書きセーブ → 削除フロー', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final repo = await SaveRepository.load();
    final gs = GameState(heroName: '上書き太郎');
    await repo.write(SaveSlotKey.manual(2), gs);

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const SaveLoadScreen(mode: SaveLoadMode.save),
        settings: settings,
        gameState: gs,
        saveRepository: repo,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save.slot.2.tap')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('save.slot.2.action.delete')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save.slot.2.action.delete')));
    await tester.pumpAndSettle();

    // 削除後はサマリーが消えて --- が表示される。
    expect(find.byKey(const ValueKey('save.slot.2.heroName')), findsNothing);
    expect(find.byKey(const ValueKey('save.slot.2.empty')), findsOneWidget);
  });

  testWidgets('ロードモードでは空スロットの ListTile は無効化される',
      (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final repo = await SaveRepository.load();

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const SaveLoadScreen(mode: SaveLoadMode.load),
        settings: settings,
        saveRepository: repo,
      ),
    );
    await tester.pumpAndSettle();
    // 空スロットタップしてもボトムシートに「ロード」「セーブ」のどちらも出ない
    // （onTap が null になっているため反応しない）。
    await tester.tap(find.byKey(const ValueKey('save.slot.0.tap')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('save.slot.0.action.load')), findsNothing);
    expect(find.byKey(const ValueKey('save.slot.0.action.save')), findsNothing);
  });
}
