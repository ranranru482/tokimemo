import 'package:flutter/material.dart';

import '../app.dart';
import '../models/actions.dart';
import '../models/audio_keys.dart';

/// ホーム画面でスロットがタップされたときに開く、行動選択ボトムシート。
///
/// Sprint 03 では自宅行動 3 種（読書・運動・就寝）のみを表示。
/// Sprint 04 で平日夕方のリストに「残業」を追加。
/// Sprint 05 で休日のリストに外出4種（カフェ・映画・美術館・ジム）を追加し、
/// 所持金不足の行動はグレーアウト（タップ不可）で表示する。
///
/// 使い方:
/// ```dart
/// final ActionKind? selected = await showActionSheet(
///   context,
///   slotLabel: '朝',
///   actions: kHolidayActionList,
///   currentMoney: gameState.money,
/// );
/// if (selected != null) {
///   gameState.applyAction(slot, selected);
/// }
/// ```
///
/// シートのスクロール領域は [DraggableScrollableSheet] を使わず、
/// `useSafeArea: true` の `showModalBottomSheet` 内に固定高で配置する。
///
/// [actions] を省略した場合は [kHomeActionList]（自宅3行動）を表示する。
/// [currentMoney] を省略した場合は所持金チェックを行わない（全行動が選択可）。
Future<ActionKind?> showActionSheet(
  BuildContext context, {
  required String slotLabel,
  List<ActionEffect>? actions,
  int? currentMoney,
}) {
  return showModalBottomSheet<ActionKind>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      return ActionSheetContent(
        slotLabel: slotLabel,
        actions: actions ?? kHomeActionList,
        currentMoney: currentMoney,
      );
    },
  );
}

/// シート本体。テストから直接 pump できるよう Widget として独立させてある。
class ActionSheetContent extends StatelessWidget {
  const ActionSheetContent({
    super.key,
    required this.slotLabel,
    required this.actions,
    this.currentMoney,
  });

  /// 例: 「朝」「日中」など、どの枠に対する行動かを示すラベル。
  final String slotLabel;

  /// 表示する行動の一覧。通常は [kHomeActionList]。
  final List<ActionEffect> actions;

  /// 現在の所持金（円）。null の場合は所持金チェックを行わない。
  /// 各行動の [ActionEffect.requiredMoney] と比較してグレーアウト判定する。
  final int? currentMoney;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('actionSheet.root'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '$slotLabelの行動を選ぶ',
              key: const ValueKey('actionSheet.title'),
              style: theme.textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          // Sprint 04 で行動が 3 → 4 種、Sprint 05 で休日に最大 7 種まで
          // 増えたため、シート本体は内側でスクロール可能にして狭幅・狭高でも
          // 崩れないようにする。
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final a in actions)
                    _ActionTile(
                      effect: a,
                      enabled: _isAffordable(a),
                      onTap: _isAffordable(a)
                          ? () {
                              // Sprint 11: 行動シートの決定で confirm SE。
                              // AppScope が無いテスト経路は無視（try/catch）。
                              try {
                                AppScope.of(context)
                                    .audio
                                    .playSe(AudioKeys.seConfirm);
                              } catch (e) {
                                debugPrint(
                                    '[ActionSheet] AudioService unavailable: $e');
                              }
                              Navigator.of(context).pop(a.kind);
                            }
                          : null,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isAffordable(ActionEffect effect) {
    if (currentMoney == null) return true;
    return currentMoney! >= effect.requiredMoney;
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.effect,
    required this.enabled,
    required this.onTap,
  });

  final ActionEffect effect;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);
    final subFg = enabled
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38);
    final iconColor = enabled
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: 0.38);

    return ListTile(
      key: ValueKey('actionSheet.action.${effect.kind.name}'),
      enabled: enabled,
      leading: Icon(_iconFor(effect.kind), color: iconColor),
      title: Text(effect.label, style: theme.textTheme.titleMedium?.copyWith(color: fg)),
      subtitle: Text(
        enabled ? effect.description : '${effect.description}\n（所持金が足りません）',
        style: theme.textTheme.bodyMedium?.copyWith(color: subFg),
      ),
      onTap: onTap,
      // タッチターゲットを 48px 以上に保つ。
      minVerticalPadding: 12,
    );
  }

  static IconData _iconFor(ActionKind kind) {
    switch (kind) {
      case ActionKind.read:
        return Icons.menu_book;
      case ActionKind.exercise:
        return Icons.fitness_center;
      case ActionKind.sleep:
        return Icons.bedtime;
      case ActionKind.overtime:
        return Icons.work;
      case ActionKind.cafe:
        return Icons.coffee;
      case ActionKind.movie:
        return Icons.local_movies;
      case ActionKind.museum:
        return Icons.museum;
      case ActionKind.gym:
        return Icons.sports_gymnastics;
      case ActionKind.invite:
        return Icons.favorite_outline;
    }
  }
}
