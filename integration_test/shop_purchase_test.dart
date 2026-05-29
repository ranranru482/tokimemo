import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/screens/inventory_screen.dart';
import 'package:tokimemo/screens/shop_screen.dart';
import 'package:tokimemo/services/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 12 integration test: 受け入れ基準4 を end-to-end で検証。
///
/// ホーム画面のショップ導線 → ショップ画面で花束を購入 → 所持アイテム画面で
/// 花束が x1 で見える、までを通しで確認する。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tutorial.shown': true});
  });

  testWidgets('ホーム→ショップ→花束購入→所持アイテムで花束が見える', (tester) async {
    final settings = await SettingsRepository.load();
    await tester.pumpWidget(MugenSiritoriApp(settings: settings));
    await tester.pumpAndSettle();

    // タイトル → はじめから
    await tester.tap(find.byKey(const ValueKey('title.startButton')));
    await tester.pumpAndSettle();

    // 名前入力 → 決定
    await tester.enterText(
      find.byKey(const ValueKey('nameInput.field')),
      'ショップ太郎',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nameInput.submitButton')));
    await tester.pumpAndSettle();

    // ホーム画面に到達。
    expect(find.byKey(const ValueKey('scaffold.home')), findsOneWidget);

    // ホーム AppBar のショップアイコンをタップ。
    await tester.tap(find.byKey(const ValueKey('home.shopButton')));
    await tester.pumpAndSettle();

    expect(find.byType(ShopScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('shop.grid')), findsOneWidget);

    // 花束を購入する。
    await tester.tap(find.byKey(const ValueKey('shop.card.gift.bouquet.buyButton')));
    await tester.pumpAndSettle();

    // 購入成功 SnackBar が出る（少しの間表示される）。
    expect(
      find.byKey(const ValueKey('shop.snackBar.purchased.gift.bouquet')),
      findsOneWidget,
    );

    // 所持アイテム画面に遷移。
    await tester.tap(find.byKey(const ValueKey('shop.inventoryButton')));
    await tester.pumpAndSettle();

    expect(find.byType(InventoryScreen), findsOneWidget);
    // 花束が x1 で表示される。
    expect(
      find.byKey(const ValueKey('inventory.item.gift.bouquet')),
      findsOneWidget,
    );
    expect(find.text('x1'), findsOneWidget);
  });
}
