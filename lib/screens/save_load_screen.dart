import 'package:flutter/material.dart';

import '../app.dart';
import '../models/save_snapshot.dart';
import '../services/save_repository.dart';
import '../widgets/page_transitions.dart';
import 'main_scaffold.dart';

/// Sprint 09: セーブ/ロード画面（仕様書 §10 画面12）。
///
/// 表示要素:
/// - 上部: クイックスロット 1 件のカード。
/// - 中段: 手動 10 スロットのリスト（番号付き）。
/// - 下段: オート 3 スロット（リングバッファ）。
///
/// 各スロットをタップすると、以下の選択肢を持つボトムシートが開く：
/// - ロード（空スロットなら表示しない）
/// - 上書き保存（mode = save のときのみ表示）
/// - 削除（空スロットなら表示しない）
///
/// 起動時の [mode] によって UI 文言と振る舞いを切り替える：
/// - [SaveLoadMode.save]: タイトル「セーブ」、空スロットでも「新規セーブ」可。
/// - [SaveLoadMode.load]: タイトル「ロード」、空スロットは無効化。
enum SaveLoadMode { save, load }

class SaveLoadScreen extends StatefulWidget {
  const SaveLoadScreen({super.key, this.mode = SaveLoadMode.save});

  final SaveLoadMode mode;

  /// 設定画面 / ホーム画面 / タイトル画面から呼び出すためのヘルパ。
  static Future<void> push(BuildContext context,
      {SaveLoadMode mode = SaveLoadMode.save}) {
    return Navigator.of(context).push<void>(
      fadeRoute<void>((_) => SaveLoadScreen(mode: mode)),
    );
  }

  @override
  State<SaveLoadScreen> createState() => _SaveLoadScreenState();
}

class _SaveLoadScreenState extends State<SaveLoadScreen> {
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final repo = scope.requireSaveRepository;
    return Scaffold(
      key: const ValueKey('scaffold.saveLoad'),
      appBar: AppBar(
        title: Text(widget.mode == SaveLoadMode.save ? 'セーブ' : 'ロード'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: repo,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _SectionHeader(title: 'クイックセーブ'),
                _SlotTile(
                  key: const ValueKey('saveLoad.slot.quick'),
                  slot: SaveSlotKey.quick(),
                  snapshot: repo.readQuick(),
                  mode: widget.mode,
                  onAction: _handleAction,
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: '手動スロット'),
                for (int i = 0; i < SaveRepository.manualSlotCount; i++)
                  _SlotTile(
                    key: ValueKey('saveLoad.slot.manual.$i'),
                    slot: SaveSlotKey.manual(i),
                    snapshot: repo.read(SaveSlotKey.manual(i)),
                    mode: widget.mode,
                    onAction: _handleAction,
                  ),
                const SizedBox(height: 16),
                _SectionHeader(title: 'オートセーブ（最新3件）'),
                for (int i = 0; i < SaveRepository.autoSlotCount; i++)
                  _SlotTile(
                    key: ValueKey('saveLoad.slot.auto.$i'),
                    slot: SaveSlotKey.auto(i),
                    snapshot: repo.read(SaveSlotKey.auto(i)),
                    mode: widget.mode,
                    onAction: _handleAction,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleAction(_SlotAction action, SaveSlotKey slot) async {
    final scope = AppScope.of(context);
    final repo = scope.requireSaveRepository;
    final state = scope.gameState;
    switch (action) {
      case _SlotAction.save:
        await repo.write(slot, state);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${slot.displayLabel} に保存しました')),
        );
        break;
      case _SlotAction.load:
        final snap = repo.read(slot);
        if (snap == null) return;
        state.restoreFromMap(snap.payload);
        if (!mounted) return;
        // タイトル等から来たとき向けに、MainScaffold を root として置換する。
        Navigator.of(context).pushAndRemoveUntil(
          fadeRoute<void>((_) => const MainScaffold()),
          (_) => false,
        );
        break;
      case _SlotAction.delete:
        await repo.delete(slot);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${slot.displayLabel} を削除しました')),
        );
        break;
    }
  }
}

enum _SlotAction { save, load, delete }

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    super.key,
    required this.slot,
    required this.snapshot,
    required this.mode,
    required this.onAction,
  });

  final SaveSlotKey slot;
  final SaveSnapshot? snapshot;
  final SaveLoadMode mode;
  final Future<void> Function(_SlotAction, SaveSlotKey) onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = snapshot == null;
    final canSave = mode == SaveLoadMode.save;
    final canLoad = mode == SaveLoadMode.load && !isEmpty;
    final enabled = !isEmpty || canSave;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('${slot.prefsKey}.tap'),
          onTap: enabled
              ? () => _showSheet(context, isEmpty: isEmpty, canSave: canSave, canLoad: canLoad)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _Thumb(snapshot: snapshot, label: slot.displayLabel),
                const SizedBox(width: 12),
                Expanded(
                  child: isEmpty
                      ? Text('---', key: ValueKey('${slot.prefsKey}.empty'))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snapshot!.heroName.isEmpty
                                  ? '名無し'
                                  : snapshot!.heroName,
                              key: ValueKey('${slot.prefsKey}.heroName'),
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              snapshot!.summary,
                              key: ValueKey('${slot.prefsKey}.summary'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              _formatSavedAt(snapshot!.savedAt),
                              key: ValueKey('${slot.prefsKey}.savedAt'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                ),
                Icon(
                  isEmpty ? Icons.add : Icons.chevron_right,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSheet(BuildContext context,
      {required bool isEmpty,
      required bool canSave,
      required bool canLoad}) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canLoad)
                ListTile(
                  key: ValueKey('${slot.prefsKey}.action.load'),
                  leading: const Icon(Icons.upload_file),
                  title: const Text('ロード'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onAction(_SlotAction.load, slot);
                  },
                ),
              if (canSave)
                ListTile(
                  key: ValueKey('${slot.prefsKey}.action.save'),
                  leading: const Icon(Icons.save),
                  title: Text(isEmpty ? '新規セーブ' : '上書きセーブ'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onAction(_SlotAction.save, slot);
                  },
                ),
              if (!isEmpty)
                ListTile(
                  key: ValueKey('${slot.prefsKey}.action.delete'),
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('削除'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onAction(_SlotAction.delete, slot);
                  },
                ),
              ListTile(
                key: ValueKey('${slot.prefsKey}.action.cancel'),
                leading: const Icon(Icons.close),
                title: const Text('キャンセル'),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatSavedAt(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '保存: $y/$mo/$d $h:$mi';
  }
}

/// セーブのサムネ枠（プレースホルダ）。
class _Thumb extends StatelessWidget {
  const _Thumb({required this.snapshot, required this.label});

  final SaveSnapshot? snapshot;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final season = snapshot == null ? null : _seasonOf(snapshot!.inGameDate);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: snapshot == null
            ? theme.colorScheme.surface
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Center(
        child: snapshot == null
            ? Icon(Icons.bookmark_border, color: theme.colorScheme.outline)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(season!.icon, size: 22, color: theme.colorScheme.primary),
                  const SizedBox(height: 2),
                  Text(
                    '${snapshot!.inGameDate.month}月',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
      ),
    );
  }

  static _Season _seasonOf(DateTime date) {
    final m = date.month;
    if (m >= 3 && m <= 5) return const _Season(icon: Icons.local_florist);
    if (m >= 6 && m <= 8) return const _Season(icon: Icons.wb_sunny_outlined);
    if (m >= 9 && m <= 11) return const _Season(icon: Icons.eco_outlined);
    return const _Season(icon: Icons.ac_unit);
  }
}

class _Season {
  const _Season({required this.icon});

  final IconData icon;
}
