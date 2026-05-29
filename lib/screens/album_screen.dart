import 'package:flutter/material.dart';

import '../app.dart';
import '../data/character_repository.dart';
import '../data/common_events.dart';
import '../data/confession_eve_events.dart';
import '../data/individual_events.dart';
import '../models/character.dart';
import '../screens/christmas_choice_screen.dart';
import '../widgets/cg_view.dart';
import '../widgets/page_transitions.dart';

/// Sprint 08 → Task #5: メモリーアルバム画面（仕様書 §10 画面14）。
///
/// 表示要素:
/// - 全 CG をグリッド表示（解放/未解放を区別）。
/// - 解放済みはサムネ（[CgView]）として、未解放はシルエット（[CgLockedTile]）。
/// - サムネタップで全画面プレビュー、ロックタップでヒントダイアログ（Task #5）。
/// - AppBar の 2 つのフィルタ（カテゴリ / キャラ）で絞り込み可能（Task #5）。
///
/// CG は以下から集約する：
/// - 共通/節目イベント（[CommonEventCatalog.all]）
/// - 個別イベント全 35 本（[IndividualEventCatalog.all]）
/// - 告白前夜 5 本（[ConfessionEveCatalog.all]、Task #5 で追加）
/// - クリスマス専用キャラ別シーン（5 キャラ + 一人）
class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  AlbumCategoryFilter _category = AlbumCategoryFilter.all;
  AlbumCharacterFilter _character = AlbumCharacterFilter.all;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: scope.gameState.cgLibrary,
      builder: (context, _) {
        final library = scope.gameState.cgLibrary;
        final allEntries = _collectAllCgEntries();
        final entries = _applyFilters(allEntries);
        return Scaffold(
          key: const ValueKey('scaffold.album'),
          appBar: AppBar(
            title: const Text('メモリーアルバム'),
            actions: [
              PopupMenuButton<AlbumCategoryFilter>(
                key: const ValueKey('album.filter.category'),
                tooltip: 'カテゴリ',
                icon: const Icon(Icons.filter_list),
                initialValue: _category,
                onSelected: (v) => setState(() => _category = v),
                itemBuilder: (context) => [
                  for (final f in AlbumCategoryFilter.values)
                    PopupMenuItem<AlbumCategoryFilter>(
                      key: ValueKey('album.filter.category.${f.name}'),
                      value: f,
                      child: Text(f.label),
                    ),
                ],
              ),
              PopupMenuButton<AlbumCharacterFilter>(
                key: const ValueKey('album.filter.character'),
                tooltip: 'キャラクター',
                icon: const Icon(Icons.person_outline),
                initialValue: _character,
                onSelected: (v) => setState(() => _character = v),
                itemBuilder: (context) => [
                  for (final f in AlbumCharacterFilter.values)
                    PopupMenuItem<AlbumCharacterFilter>(
                      key: ValueKey('album.filter.character.${f.name}'),
                      value: f,
                      child: Text(f.label),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    '${_unlockedCountIn(entries, library)} / ${entries.length}',
                    key: const ValueKey('album.counter'),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: entries.isEmpty
                  ? const Center(
                      key: ValueKey('album.empty'),
                      child: Text('該当する CG はありません'),
                    )
                  : GridView.builder(
                      key: const ValueKey('album.grid'),
                      itemCount: entries.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (context, i) {
                        final entry = entries[i];
                        final unlocked = library.has(entry.cgKey);
                        if (!unlocked) {
                          return CgLockedTile(
                            cgKey: entry.cgKey,
                            onTap: () => _showHintDialog(context, entry),
                          );
                        }
                        return _AlbumThumbnail(
                          entry: entry,
                          onTap: () => _openFullView(context, entry),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }

  int _unlockedCountIn(List<CgEntry> entries, dynamic library) {
    int n = 0;
    for (final e in entries) {
      if (library.has(e.cgKey) as bool) n++;
    }
    return n;
  }

  List<CgEntry> _applyFilters(List<CgEntry> entries) {
    return entries.where((e) {
      if (!_category.matches(e.category)) return false;
      if (!_character.matches(e.characterId)) return false;
      return true;
    }).toList();
  }

  Future<void> _openFullView(BuildContext context, CgEntry entry) {
    return Navigator.of(context).push<void>(
      slideUpRoute<void>((_) => CgFullView(entry: entry)),
    );
  }

  Future<void> _showHintDialog(BuildContext context, CgEntry entry) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          key: ValueKey('album.hintDialog.${entry.cgKey}'),
          title: const Text('まだ見ぬ思い出'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _categoryBadge(entry.category, entry.characterId),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.hint,
                key: ValueKey('album.hintDialog.${entry.cgKey}.hint'),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              key: ValueKey('album.hintDialog.${entry.cgKey}.close'),
              onPressed: () => Navigator.of(dialogContext).maybePop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }
}

/// アルバム画面のカテゴリフィルタ。
enum AlbumCategoryFilter {
  all('すべて'),
  common('共通'),
  individual('個別'),
  confessionEve('告白前夜'),
  milestone('節目');

  const AlbumCategoryFilter(this.label);
  final String label;

  bool matches(CgCategory c) {
    switch (this) {
      case AlbumCategoryFilter.all:
        return true;
      case AlbumCategoryFilter.common:
        return c == CgCategory.common;
      case AlbumCategoryFilter.individual:
        return c == CgCategory.individual;
      case AlbumCategoryFilter.confessionEve:
        return c == CgCategory.confessionEve;
      case AlbumCategoryFilter.milestone:
        return c == CgCategory.milestone;
    }
  }
}

/// アルバム画面のキャラフィルタ。
enum AlbumCharacterFilter {
  all('全キャラ'),
  akari('七瀬 灯'),
  uta('久遠 詩'),
  toru('鴻巣 透'),
  sayo('蓮見 紗夜'),
  yui('槙原 結衣'),
  none('対象なし');

  const AlbumCharacterFilter(this.label);
  final String label;

  CharacterId? get characterId {
    switch (this) {
      case AlbumCharacterFilter.akari:
        return CharacterId.akari;
      case AlbumCharacterFilter.uta:
        return CharacterId.uta;
      case AlbumCharacterFilter.toru:
        return CharacterId.toru;
      case AlbumCharacterFilter.sayo:
        return CharacterId.sayo;
      case AlbumCharacterFilter.yui:
        return CharacterId.yui;
      case AlbumCharacterFilter.all:
      case AlbumCharacterFilter.none:
        return null;
    }
  }

  bool matches(CharacterId? entryCharacter) {
    switch (this) {
      case AlbumCharacterFilter.all:
        return true;
      case AlbumCharacterFilter.none:
        return entryCharacter == null;
      default:
        return entryCharacter == characterId;
    }
  }
}

/// CG の分類。アルバム画面のフィルタとヒント生成に使う。
enum CgCategory { common, individual, confessionEve, milestone }

class _AlbumThumbnail extends StatelessWidget {
  const _AlbumThumbnail({required this.entry, required this.onTap});

  final CgEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('album.thumb.${entry.cgKey}'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: CgView(
        cgKey: entry.cgKey,
        title: entry.title,
        themeColor: entry.themeColor,
      ),
    );
  }
}

/// 全画面 CG ビュー。Task #5: 上部にカテゴリバッジを追加。
class CgFullView extends StatelessWidget {
  const CgFullView({super.key, required this.entry});

  final CgEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: ValueKey('album.fullView.${entry.cgKey}'),
      appBar: AppBar(
        title: Text(entry.title),
        leading: IconButton(
          key: const ValueKey('album.fullView.close'),
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                key: ValueKey('album.fullView.${entry.cgKey}.badge'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _categoryBadge(entry.category, entry.characterId),
                  style: theme.textTheme.labelMedium,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: CgView(
                  cgKey: entry.cgKey,
                  title: entry.title,
                  themeColor: entry.themeColor,
                  caption: entry.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// アルバム内部で扱う 1 件分のメタデータ。
///
/// Task #5: [category] / [characterId] / [hint] を追加（フィルタとヒント用）。
class CgEntry {
  const CgEntry({
    required this.cgKey,
    required this.title,
    required this.themeColor,
    required this.category,
    this.characterId,
    this.caption,
    this.hint = '条件を満たしたとき、不意に訪れる景色。',
  });

  final String cgKey;
  final String title;
  final Color themeColor;
  final CgCategory category;
  final CharacterId? characterId;
  final String? caption;
  final String hint;
}

const Color _kCommonColor = Color(0xFF4A2C2A);

String _categoryBadge(CgCategory c, CharacterId? id) {
  final base = switch (c) {
    CgCategory.common => '共通イベント',
    CgCategory.individual => '個別イベント',
    CgCategory.confessionEve => '告白前夜',
    CgCategory.milestone => '節目',
  };
  if (id == null) return base;
  return '$base ／ ${CharacterRepository.byId(id).displayName}';
}

String _hintForIndividual(String id, CharacterId target) {
  final name = CharacterRepository.byId(target).displayName;
  if (id.endsWith('.6') || id.endsWith('.7')) {
    return '$name と関係を深めたあとの、季節か時間帯にひっそり訪れる場面。';
  }
  if (id.endsWith('.3') || id.endsWith('.5')) {
    return '$name と特定の季節に交わす、一歩踏み込んだ会話。';
  }
  return '$name の好感度が一定段階に達すると見える日常の断片。';
}

String _hintForConfessionEve(CharacterId target) {
  final name = CharacterRepository.byId(target).displayName;
  return '$name と表面・真の好感度が十分に育ったとき、'
      'ED の手前で訪れる夜の景色。';
}

/// 全イベント（共通 / 個別 / 告白前夜 / 節目 / クリスマス専用シーン）から
/// CG エントリを集める。
List<CgEntry> _collectAllCgEntries() {
  final entries = <CgEntry>[];
  // 共通イベント（節目も含む）
  for (final ev in CommonEventCatalog.all) {
    final key = ev.cgKey;
    if (key == null) continue;
    final isMilestone = CommonEventCatalog.milestones.any((m) => m.id == ev.id);
    entries.add(CgEntry(
      cgKey: key,
      title: ev.cgTitle ?? ev.title,
      themeColor: _kCommonColor,
      caption: ev.cgCaption,
      category: isMilestone ? CgCategory.milestone : CgCategory.common,
      hint: isMilestone
          ? '季節の節目に、誰と過ごすかで枝分かれする景色。'
          : '年度を通じて、その日付に必ず訪れる出来事。',
    ));
  }
  // 告白前夜（Task #5 で追加）。共通イベントの直後に並べて、
  // GridView の viewport 外に流れにくくする。
  for (final ev in ConfessionEveCatalog.all) {
    final key = ev.cgKey;
    if (key == null) continue;
    final target = ev.target;
    final color = target == null
        ? _kCommonColor
        : CharacterRepository.byId(target).themeColor;
    entries.add(CgEntry(
      cgKey: key,
      title: ev.cgTitle ?? ev.title,
      themeColor: color,
      caption: ev.cgCaption,
      category: CgCategory.confessionEve,
      characterId: target,
      hint: target == null
          ? '告白の前夜にだけ訪れる場面。'
          : _hintForConfessionEve(target),
    ));
  }
  // 個別イベント
  for (final ev in IndividualEventCatalog.all) {
    final key = ev.cgKey;
    if (key == null) continue;
    final target = ev.target;
    final color = target == null
        ? _kCommonColor
        : CharacterRepository.byId(target).themeColor;
    entries.add(CgEntry(
      cgKey: key,
      title: ev.cgTitle ?? ev.title,
      themeColor: color,
      caption: ev.cgCaption,
      category: CgCategory.individual,
      characterId: target,
      hint: target == null
          ? '条件を満たしたとき、不意に訪れる景色。'
          : _hintForIndividual(ev.id, target),
    ));
  }
  // クリスマス専用シーン（5 キャラ + 一人）
  for (final c in CharacterRepository.all) {
    final ev = buildChristmasEventFor(c.id);
    final key = ev.cgKey;
    if (key == null) continue;
    entries.add(CgEntry(
      cgKey: key,
      title: ev.cgTitle ?? ev.title,
      themeColor: c.themeColor,
      caption: ev.cgCaption,
      category: CgCategory.milestone,
      characterId: c.id,
      hint: '12 月の節目で ${c.displayName} を選んだとき訪れる場面。',
    ));
  }
  // 一人で過ごすクリスマス
  entries.add(const CgEntry(
    cgKey: 'cg.milestone.christmas.alone',
    title: '一人のクリスマス',
    themeColor: _kCommonColor,
    caption: '電気を落とした部屋で、ホットココアの湯気を見ていた夜。',
    category: CgCategory.milestone,
    hint: '12 月の節目に、誰も選ばなかった夜の景色。',
  ));
  return entries;
}

// Hotfix 2026-05-18: debug ヘルパは本番 import グラフから切り離すため
// `test/test_helpers.dart` に移動した。
