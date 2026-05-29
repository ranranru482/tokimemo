import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/screens/inventory_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Sprint 12: 所持アイテム画面 widget テスト。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('空のときは empty プレースホルダが出る', (tester) async {
    final settings = await createTestSettings();
    final gs = GameState();
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const InventoryScreen(),
        settings: settings,
        gameState: gs,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inventory.empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('inventory.list')), findsNothing);
    expect(find.text('まだ何も持っていません'), findsOneWidget);
  });

  testWidgets('購入済みアイテムが一覧に表示される', (tester) async {
    final settings = await createTestSettings();
    final gs = GameState();
    gs.purchaseGift(itemId: 'gift.bouquet', price: 1500);
    gs.purchaseGift(itemId: 'gift.book', price: 2000);
    gs.purchaseGift(itemId: 'gift.book', price: 2000);

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const InventoryScreen(),
        settings: settings,
        gameState: gs,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('inventory.list')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('inventory.item.gift.bouquet')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('inventory.item.gift.book')),
      findsOneWidget,
    );
    // bouquet は x1、book は x2。
    expect(
      find.byKey(const ValueKey('inventory.item.gift.bouquet.quantity')),
      findsOneWidget,
    );
    expect(find.text('x1'), findsOneWidget);
    expect(find.text('x2'), findsOneWidget);
  });

  testWidgets('Inventory が ChangeNotifier として変化を反映する', (tester) async {
    final settings = await createTestSettings();
    final gs = GameState();
    gs.purchaseGift(itemId: 'gift.sweets', price: 800);

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const InventoryScreen(),
        settings: settings,
        gameState: gs,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inventory.item.gift.sweets')), findsOneWidget);
    expect(find.text('x1'), findsOneWidget);

    // 追加購入で再描画される。
    gs.purchaseGift(itemId: 'gift.sweets', price: 800);
    await tester.pumpAndSettle();
    expect(find.text('x2'), findsOneWidget);
  });
}
