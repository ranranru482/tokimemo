import 'package:flutter/material.dart';

import '../app.dart';
import '../data/character_repository.dart';
import '../widgets/page_transitions.dart';

/// Sprint 12: 所持アイテム一覧画面。
///
/// 仕様書 Sprint 12 受け入れ基準4 の後半:
/// 「所持アイテム一覧に追加される」を可視化する画面。
///
/// 構造:
/// - 上部に「所持アイテム合計」
/// - リスト表示: 各 GiftItem 名 + 個数 + 対象キャラ
/// - 空のときは「まだ何も持っていません」プレースホルダ
///
/// 「渡す」UI は Sprint 12 範囲外（基礎枠のみ）。
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push<void>(
      fadeRoute<void>((_) => const InventoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final inventory = scope.gameState.inventory;
    final theme = Theme.of(context);
    return Scaffold(
      key: const ValueKey('scaffold.inventory'),
      appBar: AppBar(
        title: const Text('所持アイテム'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: inventory,
          builder: (context, _) {
            final entries = inventory.resolvedEntries();
            if (entries.isEmpty) {
              return Center(
                key: const ValueKey('inventory.empty'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'まだ何も持っていません',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ショップで贈り物を購入できます。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              key: const ValueKey('inventory.list'),
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final entry = entries[i];
                final gift = entry.gift;
                final targetId = gift.targetCharacterId;
                final targetLabel = targetId == null
                    ? '全員向け'
                    : '${CharacterRepository.byId(targetId).displayName}向け';
                final targetColor = targetId == null
                    ? theme.colorScheme.outline
                    : CharacterRepository.byId(targetId).themeColor;
                return Container(
                  key: ValueKey('inventory.item.${gift.id}'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: targetColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.card_giftcard,
                          color: theme.colorScheme.surface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gift.displayName,
                              key: ValueKey('inventory.item.${gift.id}.name'),
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              targetLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              gift.description,
                              style: theme.textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'x${entry.quantity}',
                          key:
                              ValueKey('inventory.item.${gift.id}.quantity'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
