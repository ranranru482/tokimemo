import 'package:flutter/material.dart';

import '../app.dart';
import '../data/character_repository.dart';
import '../models/character.dart';
import '../widgets/affinity_hearts.dart';
import '../widgets/character_portrait.dart';

/// キャラ詳細画面（仕様書 §10 画面07）。
///
/// 構成:
/// - 上部: 立ち絵（large、normal 表情）+ 名前 + 年齢 + 役職
/// - 中部: bioShort / bioLong / appealText
/// - 下部: 5 段階ハート + 「誘う」ボタン（未会いなら disable）
///
/// Sprint 06 では「誘う」ボタンはホーム画面の休日枠から起動する設計のため、
/// 詳細画面側の「誘う」ボタンはタップ時に SnackBar で
/// 「ホーム画面の休日枠で誘ってください」と案内するだけにする。
/// Sprint 07 で詳細画面から直接誘えるショートカットを実装する想定。
class CharacterDetailScreen extends StatelessWidget {
  const CharacterDetailScreen({super.key, required this.characterId});

  final CharacterId characterId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final character = CharacterRepository.byId(characterId);
    final scope = AppScope.of(context);

    return AnimatedBuilder(
      animation: scope.gameState,
      builder: (context, _) {
        final state = scope.gameState.characterStateOf(characterId);
        final isMet = state.isMet;
        final stage = isMet ? state.affinityStage : 0;

        return Scaffold(
          key: ValueKey('scaffold.characterDetail.${characterId.name}'),
          appBar: AppBar(
            title: Text(isMet ? character.displayName : '？？？'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 立ち絵
                  Center(
                    child: CharacterPortrait(
                      key: ValueKey(
                        'characterDetail.${characterId.name}.portrait',
                      ),
                      character: character,
                      size: 160,
                      isSilhouette: !isMet,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 名前と役職
                  Text(
                    isMet ? character.displayName : '？？？',
                    key: ValueKey(
                      'characterDetail.${characterId.name}.name',
                    ),
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isMet ? '${character.age}歳 / ${character.roleLabel}' : '未会い',
                    key: ValueKey(
                      'characterDetail.${characterId.name}.role',
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // 5段階ハート
                  Center(
                    child: AffinityHearts(
                      key: ValueKey(
                        'characterDetail.${characterId.name}.hearts',
                      ),
                      stage: stage,
                      iconSize: 26,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isMet) ...[
                    _SectionLabel(text: 'プロフィール'),
                    Text(
                      character.bioShort,
                      key: ValueKey(
                        'characterDetail.${characterId.name}.bioShort',
                      ),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      character.bioLong,
                      key: ValueKey(
                        'characterDetail.${characterId.name}.bioLong',
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel(text: '魅力'),
                    Text(
                      character.appealText,
                      key: ValueKey(
                        'characterDetail.${characterId.name}.appeal',
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ] else
                    Text(
                      'まだ出会っていません。日々を過ごしているうちに、'
                      'どこかで巡り合うかもしれません。',
                      key: ValueKey(
                        'characterDetail.${characterId.name}.unmetNote',
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 24),
                  // 「誘う」ボタン
                  FilledButton.icon(
                    key: ValueKey(
                      'characterDetail.${characterId.name}.inviteButton',
                    ),
                    onPressed: isMet
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'ホーム画面の休日枠から「誘う」を選んでください。',
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.coffee),
                    label: const Text('誘う'),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
