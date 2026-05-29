import 'package:flutter/material.dart';

import '../app.dart';
import '../data/character_repository.dart';
import '../data/gift_catalog.dart';
import '../models/audio_keys.dart';
import '../models/gift_item.dart';
import '../widgets/page_transitions.dart';
import 'inventory_screen.dart';

/// Sprint 12: ショップ画面（プレゼント購入）。
///
/// 仕様書 Sprint 12 受け入れ基準4:
/// 「ショップ画面でプレゼントを購入すると所持金が減り、所持アイテム一覧に追加される」。
///
/// 構造:
/// - 上部に「所持金 / 所持アイテム数」と所持アイテム画面への導線
/// - グリッド表示：[GiftCatalog.all] を 2 列で並べる
/// - 各カードに価格・対象キャラ・購入ボタンを表示
/// - 所持金不足の商品は購入ボタン disable
///
/// 「渡す」UI は仕様メモで「基礎枠のみ」とされており Sprint 12 範囲外。
/// 所持アイテム一覧画面で「いつか役立つかもしれない品々」として表示する。
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push<void>(
      fadeRoute<void>((_) => const ShopScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final gameState = scope.gameState;
    final theme = Theme.of(context);
    return Scaffold(
      key: const ValueKey('scaffold.shop'),
      appBar: AppBar(
        title: const Text('ショップ'),
        actions: [
          IconButton(
            key: const ValueKey('shop.inventoryButton'),
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: '所持アイテム',
            onPressed: () {
              scope.audio.playSe(AudioKeys.seTap);
              InventoryScreen.push(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: gameState,
          builder: (context, _) {
            return AnimatedBuilder(
              animation: gameState.inventory,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Container(
                        key: const ValueKey('shop.header'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.payments,
                                color: theme.colorScheme.primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '所持金 ${_formatYen(gameState.money)}円',
                              key: const ValueKey('shop.money'),
                              style: theme.textTheme.titleMedium,
                            ),
                            const Spacer(),
                            Icon(Icons.inventory_2_outlined,
                                color: theme.colorScheme.primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '所持 ${gameState.inventory.totalCount}',
                              key: const ValueKey('shop.inventoryCount'),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        key: const ValueKey('shop.grid'),
                        padding: const EdgeInsets.all(12),
                        itemCount: GiftCatalog.all.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemBuilder: (context, i) {
                          final gift = GiftCatalog.all[i];
                          final canAfford = gameState.money >= gift.price;
                          return _GiftCard(
                            key: ValueKey('shop.card.${gift.id}'),
                            gift: gift,
                            canAfford: canAfford,
                            onBuy: () => _onPurchase(context, gift),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _onPurchase(BuildContext context, GiftItem gift) async {
    final scope = AppScope.of(context);
    final gameState = scope.gameState;
    final ok = gameState.purchaseGift(itemId: gift.id, price: gift.price);
    if (!ok) {
      scope.audio.playSe(AudioKeys.seError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const ValueKey('shop.snackBar.insufficient'),
          content: const Text('所持金が足りません'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    scope.audio.playSe(AudioKeys.seConfirm);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: ValueKey('shop.snackBar.purchased.${gift.id}'),
        content: Text('${gift.displayName}を購入しました'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static String _formatYen(int yen) {
    final s = yen.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write(',');
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _GiftCard extends StatelessWidget {
  const _GiftCard({
    super.key,
    required this.gift,
    required this.canAfford,
    required this.onBuy,
  });

  final GiftItem gift;
  final bool canAfford;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetId = gift.targetCharacterId;
    final targetLabel = targetId == null
        ? '全員向け'
        : '${CharacterRepository.byId(targetId).displayName}向け';
    final targetColor = targetId == null
        ? theme.colorScheme.outline
        : CharacterRepository.byId(targetId).themeColor;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品アイコン領域（実画像が無いのでテーマカラーのチップ）
          Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  targetColor.withValues(alpha: 0.5),
                  targetColor.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.card_giftcard,
                color: theme.colorScheme.surface,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            gift.displayName,
            key: ValueKey('shop.card.${gift.id}.name'),
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            targetLabel,
            key: ValueKey('shop.card.${gift.id}.target'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              gift.description,
              style: theme.textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.payments,
                  size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 2),
              Text(
                '${gift.price}円',
                key: ValueKey('shop.card.${gift.id}.price'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: FilledButton(
              key: ValueKey('shop.card.${gift.id}.buyButton'),
              onPressed: canAfford ? onBuy : null,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(canAfford ? '購入する' : '所持金不足'),
            ),
          ),
        ],
      ),
    );
  }
}
