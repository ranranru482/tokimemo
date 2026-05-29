import 'package:flutter/material.dart';

import '../app.dart';
import '../models/stats.dart';

/// 能力値詳細画面（仕様書 §10 画面05）。
///
/// Sprint 02 では 7 パラメータの数値とバーをスクロール可能なリストで表示する。
/// スパークラインや変動履歴は後続スプリントで追加する。
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      key: const ValueKey('scaffold.stats'),
      appBar: AppBar(title: const Text('能力値')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: scope.gameState,
          builder: (context, _) {
            final entries = scope.gameState.allStats.entries.toList();
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _StatRow(kind: entry.key, value: entry.value);
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.kind, required this.value});

  final StatKind kind;
  final int value;

  /// バー描画用の正規化値（0.0〜1.0）。
  ///
  /// 所持金（Wallet）だけは円単位で値域が広いため、別途上限を設けて正規化する。
  double get _normalized {
    if (kind == StatKind.wallet) {
      const cap = 200000; // 表示上のキャップ。実値はテキスト側で正確に出す。
      final v = value.clamp(0, cap);
      return v / cap;
    }
    final v = value.clamp(StatRange.min, StatRange.max);
    return v / StatRange.max;
  }

  /// 右側に出す数値テキスト。所持金は「50,000円」、その他は「42 / 100」。
  String get _valueText {
    if (kind == StatKind.wallet) {
      return '${_formatYen(value)}円';
    }
    return '$value / ${StatRange.max}';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: ValueKey('stats.row.${kind.name}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(kind.label, style: theme.textTheme.titleMedium),
              Text(
                _valueText,
                key: ValueKey('stats.value.${kind.name}'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              key: ValueKey('stats.bar.${kind.name}'),
              value: _normalized,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
