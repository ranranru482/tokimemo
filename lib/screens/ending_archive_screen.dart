import 'package:flutter/material.dart';

import '../app.dart';
import '../data/character_repository.dart';
import '../data/endings.dart';
import '../models/ending.dart';
import '../widgets/page_transitions.dart';
import 'ending_screen.dart';

/// Sprint 09: エンディング図鑑画面（仕様書 §10 画面13）。
///
/// 全 7 ED をグリッドで表示し、達成済みは彩色、未達成はシルエット +
/// 鍵アイコンで表示する。タップで全文再生（達成済みのみ）。
///
/// 表示要素:
/// - 上部: 達成数 / 全 7 種
/// - グリッド: 各 ED のカード（タイトル + サマリーまたはヒント + 達成日時）
class EndingArchiveScreen extends StatelessWidget {
  const EndingArchiveScreen({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push<void>(
      fadeRoute<void>((_) => const EndingArchiveScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final archive = scope.requireEndingArchive;
    return Scaffold(
      key: const ValueKey('scaffold.endingArchive'),
      appBar: AppBar(
        title: const Text('エンディング図鑑'),
        actions: [
          AnimatedBuilder(
            animation: archive,
            builder: (context, _) {
              final achieved = archive.achievedCount;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    '$achieved / ${EndingKind.values.length}',
                    key: const ValueKey('endingArchive.counter'),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: archive,
          builder: (context, _) {
            return ListView(
              key: const ValueKey('endingArchive.grid'),
              padding: const EdgeInsets.all(12),
              children: [
                for (final section in _kEndingSections)
                  _EndingSection(
                    section: section,
                    archive: archive,
                    onCardTap: (kind) {
                      final entry = archive.entries[kind];
                      if (entry == null) {
                        _showHintDialog(context, kind);
                      } else {
                        EndingScreen.show(context, kind: kind);
                      }
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Sprint 12: 未達成 ED をタップしたときに表示するヒントダイアログ。
///
/// 仕様書 Sprint 12 受け入れ基準3:
/// 「エンディング図鑑で未達成EDをタップすると条件ヒントが3つ表示される」。
///
/// ヒントは [EndingBody.hints]（3 行）から取得。
/// 条件を直接書かず、雰囲気で示唆するトーンに統一済み。
Future<void> _showHintDialog(BuildContext context, EndingKind kind) {
  final body = EndingBodyCatalog.bodyOf(kind);
  final hints = body.hints;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        key: ValueKey('endingArchive.hintDialog.${kind.id}'),
        title: const Text('まだ見ぬエンディング'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '到達するための、ささやかなヒント：',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < hints.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hints[i],
                        key: ValueKey(
                          'endingArchive.hintDialog.${kind.id}.hint.$i',
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            key: ValueKey('endingArchive.hintDialog.${kind.id}.close'),
            onPressed: () => Navigator.of(dialogContext).maybePop(),
            child: const Text('閉じる'),
          ),
        ],
      );
    },
  );
}

/// Task #5: ED 種別ごとのセクション定義。9 種を 4 グループに分けて見せる。
class _EndingSectionSpec {
  const _EndingSectionSpec({
    required this.id,
    required this.label,
    required this.kinds,
  });
  final String id;
  final String label;
  final List<EndingKind> kinds;
}

const List<_EndingSectionSpec> _kEndingSections = <_EndingSectionSpec>[
  _EndingSectionSpec(
    id: 'bad',
    label: 'バッドED',
    kinds: [EndingKind.burnoutEd, EndingKind.demotionEd],
  ),
  _EndingSectionSpec(
    id: 'individual',
    label: '個別ED',
    kinds: [
      EndingKind.akariEd,
      EndingKind.utaEd,
      EndingKind.toruEd,
      EndingKind.sayoEd,
      EndingKind.yuiEd,
    ],
  ),
  _EndingSectionSpec(
    id: 'normal',
    label: 'ノーマルED',
    kinds: [EndingKind.normalEd],
  ),
  _EndingSectionSpec(
    id: 'true',
    label: '真ED',
    kinds: [EndingKind.trueEd],
  ),
];

class _EndingSection extends StatelessWidget {
  const _EndingSection({
    required this.section,
    required this.archive,
    required this.onCardTap,
  });

  final _EndingSectionSpec section;
  final dynamic archive; // EndingArchive (ChangeNotifier)
  final void Function(EndingKind) onCardTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    int achieved = 0;
    for (final k in section.kinds) {
      if (archive.entries[k] != null) achieved++;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
            child: Row(
              children: [
                Text(
                  section.label,
                  key: ValueKey('endingArchive.section.${section.id}.label'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$achieved / ${section.kinds.length}',
                  key: ValueKey('endingArchive.section.${section.id}.counter'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            key: ValueKey('endingArchive.section.${section.id}.grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: section.kinds.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, i) {
              final kind = section.kinds[i];
              final entry = archive.entries[kind];
              return _EndingCard(
                key: ValueKey('endingArchive.card.${kind.id}'),
                kind: kind,
                achievedAt: entry?.achievedAt,
                onTap: () => onCardTap(kind),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EndingCard extends StatelessWidget {
  const _EndingCard({
    super.key,
    required this.kind,
    required this.achievedAt,
    required this.onTap,
  });

  final EndingKind kind;
  final DateTime? achievedAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final achieved = achievedAt != null;
    final themeColor = _themeColorFor(kind);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: achieved
                ? theme.colorScheme.surfaceContainerHigh
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: achieved
                    ? _ColoredThumb(
                        kind: kind,
                        themeColor: themeColor,
                      )
                    : _SilhouetteThumb(kind: kind),
              ),
              const SizedBox(height: 8),
              Text(
                achieved ? kind.displayName : '???',
                key: ValueKey('endingArchive.card.${kind.id}.title'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                achieved ? kind.summary : 'まだ見ぬエンディング',
                key: ValueKey('endingArchive.card.${kind.id}.summary'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (achieved)
                Text(
                  '達成: ${_formatDate(achievedAt!)}',
                  key: ValueKey('endingArchive.card.${kind.id}.achievedAt'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _themeColorFor(EndingKind kind) {
    final t = kind.target;
    if (t == null) return const Color(0xFF4A2C2A);
    return CharacterRepository.byId(t).themeColor;
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y/$mo/$d';
  }
}

class _ColoredThumb extends StatelessWidget {
  const _ColoredThumb({required this.kind, required this.themeColor});

  final EndingKind kind;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: ValueKey('endingArchive.thumb.${kind.id}.colored'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColor.withValues(alpha: 0.85),
            themeColor.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          kind == EndingKind.trueEd ? Icons.nightlight_round : Icons.bookmark,
          color: Colors.white,
          size: 36,
          shadows: [
            Shadow(
              blurRadius: 4,
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ).animate(theme),
    );
  }
}

class _SilhouetteThumb extends StatelessWidget {
  const _SilhouetteThumb({required this.kind});

  final EndingKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: ValueKey('endingArchive.thumb.${kind.id}.locked'),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Center(
        child: Icon(
          Icons.lock_outline,
          color: theme.colorScheme.onSurfaceVariant,
          size: 32,
        ),
      ),
    );
  }
}

extension _Centerable on Widget {
  Widget animate(ThemeData theme) => this; // animation hook (Sprint 10 で拡張)
}
