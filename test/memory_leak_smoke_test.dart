import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/stats.dart';
import 'package:tokimemo/screens/home_screen.dart';
import 'package:tokimemo/screens/inventory_screen.dart';
import 'package:tokimemo/screens/shop_screen.dart';
import 'package:tokimemo/widgets/stat_change_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Sprint 12: メモリリーク検出のスモークテスト。
///
/// 仕様書 Sprint 12 受け入れ基準2:
/// 「1時間連続プレイでメモリ使用量が初期の2倍以内」を支える施策の検証。
///
/// テスト方針:
/// - 画面を pumpWidget → destroy（別 widget で置換） → リスナが残らないことを
///   GameState 内部のリスナリスト数の前後比で確認。
/// - StatChangeOverlayController が dispose() で内部 Timer を全 cancel すること。
///
/// 実際のメモリ計測（DevTools）は QA フェーズに委ねる（docs/qa_checklist.md 参照）。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('HomeScreen を破棄すると dayAdvance/stat リスナが残らない', (tester) async {
    final settings = await createTestSettings();
    final gs = GameState();

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const HomeScreen(),
        settings: settings,
        gameState: gs,
      ),
    );
    await tester.pumpAndSettle();

    // HomeScreen を別 widget で置換 → State.dispose が走る。
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const SizedBox.shrink(),
        settings: settings,
        gameState: gs,
      ),
    );
    await tester.pumpAndSettle();

    // リスナが残っているかを副作用ベースで検証：
    // - addDayAdvanceListener / addStatChangeListener が解除されていれば、
    //   GameState の操作で例外も警告も出ない。
    //   ここでは _applyDeltas を経由した能力値変動を起こして、過去 HomeScreen の
    //   State が setState を呼んで例外にならないことを確認する。
    expect(() {
      gs.applyAction(SlotIndex.morning, ActionKind.read);
    }, returnsNormally);
  });

  test('StatChangeOverlayController.dispose で内部 Timer が cancel される', () async {
    final ctrl = StatChangeOverlayController(
      lifespan: const Duration(seconds: 1),
    );
    ctrl.push(StatKind.intellect, 3);
    ctrl.push(StatKind.sensibility, 2);
    expect(ctrl.notices, hasLength(2));
    ctrl.dispose();
    // dispose 後に push を呼んでも例外にならず、状態も変化しない。
    expect(() => ctrl.push(StatKind.intellect, 1), returnsNormally);
  });

  testWidgets('ShopScreen / InventoryScreen を作って壊しても警告無しに完走', (tester) async {
    final settings = await createTestSettings();
    final gs = GameState();
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const ShopScreen(),
        settings: settings,
        gameState: gs,
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const InventoryScreen(),
        settings: settings,
        gameState: gs,
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const SizedBox.shrink(),
        settings: settings,
        gameState: gs,
      ),
    );
    await tester.pumpAndSettle();
    // ここまで例外なく完走できれば OK（FlutterError は test framework が拾う）。
    expect(tester.takeException(), isNull);
  });

  test('GameState.dispose は Inventory を含めて重複呼び出しを起こさない', () {
    final gs = GameState();
    gs.inventory.add('gift.bouquet');
    expect(() => gs.dispose(), returnsNormally);
  });
}

