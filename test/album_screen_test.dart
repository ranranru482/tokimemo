import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/screens/album_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pump(WidgetTester tester, GameState gs) async {
    final settings = await createTestSettings();
    // 大きめ画面で全件をレイアウトに乗せる
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      wrapWithAppScope(
        gameState: gs,
        settings: settings,
        child: const AlbumScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('初期状態: 全 CG がシルエット表示', (tester) async {
    final gs = GameState();
    await pump(tester, gs);
    expect(find.byKey(const ValueKey('album.grid')), findsOneWidget);
    // 既知の CG キーがロック表示で出ているはず（健康診断 6/15）
    expect(
      find.byKey(const ValueKey('cgLocked.cg.common.health_check_jun')),
      findsOneWidget,
    );
    // カウンタは 0 / N
    final counter = tester.widget<Text>(find.byKey(const ValueKey('album.counter')));
    expect(counter.data, startsWith('0 / '));
  });

  testWidgets('CG を解放するとサムネ表示になる', (tester) async {
    final gs = GameState();
    gs.cgLibrary.unlock('cg.common.health_check_jun');
    await pump(tester, gs);
    expect(
      find.byKey(const ValueKey('cgLocked.cg.common.health_check_jun')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('album.thumb.cg.common.health_check_jun')),
      findsOneWidget,
    );
  });

  testWidgets('サムネタップで全画面プレビューが開く', (tester) async {
    final gs = GameState();
    gs.cgLibrary.unlock('cg.common.health_check_jun');
    await pump(tester, gs);
    await tester.tap(
      find.byKey(const ValueKey('album.thumb.cg.common.health_check_jun')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('album.fullView.cg.common.health_check_jun')),
      findsOneWidget,
    );
    // 閉じる
    await tester.tap(find.byKey(const ValueKey('album.fullView.close')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('album.fullView.cg.common.health_check_jun')),
      findsNothing,
    );
  });
}
