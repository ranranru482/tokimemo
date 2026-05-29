import 'package:flutter/material.dart';

import '../app.dart';
import '../data/character_repository.dart';
import '../models/character.dart';
import '../widgets/affinity_hearts.dart';
import '../widgets/character_portrait.dart';
import '../widgets/page_transitions.dart';
import 'character_detail_screen.dart';

/// キャラ一覧画面（仕様書 §10 画面06）。
///
/// Sprint 06 で実装。`GridView.count(crossAxisCount: 2)` で 5 名分のキャラ
/// カードを表示する。
/// - 出会い済み: 立ち絵（small）+ 名前 + 役職 + 1段階目のハート列
/// - 未会い: シルエットの立ち絵 + 「？？？」表示 + 空ハート
///
/// カードタップで `CharacterDetailScreen` に push する。
class CharactersScreen extends StatelessWidget {
  const CharactersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: scope.gameState,
      builder: (context, _) {
        return Scaffold(
          key: const ValueKey('scaffold.characters'),
          appBar: AppBar(title: const Text('キャラ一覧')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                key: const ValueKey('characters.grid'),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
                children: [
                  for (final c in CharacterRepository.all)
                    _CharacterCard(
                      character: c,
                      state: scope.gameState.characterStateOf(c.id),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    required this.state,
  });

  final Character character;
  final dynamic state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMet = state.isMet as bool;
    final stage = isMet ? (state.affinityStage as int) : 0;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        key: ValueKey('characters.card.${character.id.name}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            fadeRoute<void>(
              (_) => CharacterDetailScreen(characterId: character.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CharacterPortrait(
                character: character,
                size: 72,
                isSilhouette: !isMet,
              ),
              const SizedBox(height: 8),
              Text(
                isMet ? character.displayName : '？？？',
                key: ValueKey(
                  'characters.card.${character.id.name}.name',
                ),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  isMet ? character.roleLabel : '未会い',
                  key: ValueKey(
                    'characters.card.${character.id.name}.role',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              AffinityHearts(
                key: ValueKey(
                  'characters.card.${character.id.name}.hearts',
                ),
                stage: stage,
                iconSize: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
