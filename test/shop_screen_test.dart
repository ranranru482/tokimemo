import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/data/gift_catalog.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/screens/shop_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Sprint 12: ショップ画面 widget テスト。
///
/// 仕様書 Sprint 12 受け入れ基準4:
/// 「ショップ画面でプレゼントを購入すると所持金が減り、所持アイテム一覧に追加される」。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// グリッドの全要素が viewport に入るよう縦長サーフェスにする。
  void useTallTestView(WidgetTester tester) {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 4200);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('ショップ画面が全 9 商品をグリッド表示する', (tester) async {
    useTallTestView(tester);
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

    expect(find.byKey(const ValueKey('scaffold.shop')), findsOneWidget);
    expect(find.byKey(const ValueKey('shop.grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('shop.header')), findsOneWidget);
    for (final g in GiftCatalog.all) {
      expect(find.byKey(ValueKey('shop.card.${g.id}')), findsOneWidget,
          reason: '${g.id} のカードが見つからない');
    }
  });

  testWidgets('ショップ画面のヘッダに所持金と所持アイテム数が出る', (tester) async {
    useTallTestView(tester);
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

    expect(find.byKey(const ValueKey('shop.money')), findsOneWidget);
    expect(find.byKey(const ValueKey('shop.inventoryCount')), findsOneWidget);
    // 初期所持金 50000 円が表示される。
    expect(find.textContaining('50,000円'), findsOneWidget);
    expect(find.textContaining('所持 0'), findsOneWidget);
  });

  testWidgets('購入ボタンタップで所持金が減り、Inventory に +1', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final gs = GameState();
    final before = gs.money;

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const ShopScreen(),
        settings: settings,
        gameState: gs,
      ),
    );
    await tester.pumpAndSettle();

    // 花束 (1500 円) の購入ボタンをタップ。
    await tester.tap(find.byKey(const ValueKey('shop.card.gift.bouquet.buyButton')));
    await tester.pumpAndSettle();

    expect(gs.money, before - 1500);
    expect(gs.inventory.countOf('gift.bouquet'), 1);
    // 成功 SnackBar が出る。
    expect(
      find.byKey(const ValueKey('shop.snackBar.purchased.gift.bouquet')),
      findsOneWidget,
    );
  });

  testWidgets('所持金不足の商品は購入ボタンが disable', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    // 所持金を最安 (gift.sweets=800) より少なくする。
    final gs = GameState(money: 500);

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const ShopScreen(),
        settings: settings,
        gameState: gs,
      ),
    );
    await tester.pumpAndSettle();

    // 全商品の購入ボタンが disable（onPressed=null）。
    for (final g in GiftCatalog.all) {
      final btn = tester.widget<FilledButton>(
        find.byKey(ValueKey('shop.card.${g.id}.buyButton')),
      );
      expect(btn.onPressed, isNull,
          reason: '${g.id} は所持金不足のため disable のはず');
    }
  });

  testWidgets('1500円の商品で所持金 1500 ぴったりは購入可能', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final gs = GameState(money: 1500);

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const ShopScreen(),
        settings: settings,
        gameState: gs,
      ),
    );
    await tester.pumpAndSettle();

    final btn = tester.widget<FilledButton>(
      find.byKey(const ValueKey('shop.card.gift.bouquet.buyButton')),
    );
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('複数回購入で所持金が累積減少 + Inventory も累積増加', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final gs = GameState(money: 5000);
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const ShopScreen(),
        settings: settings,
        gameState: gs,
      ),
    );
    await tester.pumpAndSettle();

    // sweets (800円) を 3 回購入。
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('shop.card.gift.sweets.buyButton')));
      await tester.pumpAndSettle();
    }
    expect(gs.money, 5000 - 800 * 3);
    expect(gs.inventory.countOf('gift.sweets'), 3);
  });
}
