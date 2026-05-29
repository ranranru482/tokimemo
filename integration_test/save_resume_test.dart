import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/save_snapshot.dart';
import 'package:tokimemo/models/settings_state.dart';
import 'package:tokimemo/models/stats.dart';
import 'package:tokimemo/services/ending_archive.dart';
import 'package:tokimemo/services/save_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 09 integration test: 任意の場面で手動セーブ → アプリ再起動 →
/// ロードで完全に同じ状態に復元されることを end-to-end で確認する。
///
/// 仕様書 Sprint 09 受け入れ基準 1 に対応。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('セーブ → 再構築 → ロードで完全に同じ状態が復元される', (tester) async {
    // 1) 初期状態を構築。プレイ進行に変動を加える。
    SettingsState settings = SettingsState(
      bgmVolume: SettingsState.defaultBgmVolume,
      textSpeed: SettingsState.defaultTextSpeed,
      themeMode: ThemeMode.light,
      onPersist: (_) async {},
    );
    SaveRepository repo = await SaveRepository.load();
    EndingArchive arc = await EndingArchive.load();

    final gs = GameState(heroName: '保存テスト太郎');
    gs.applyAction(SlotIndex.morning, ActionKind.read);
    gs.applyAction(SlotIndex.evening, ActionKind.exercise);
    gs.bumpAffinity(CharacterId.akari, 23);
    gs.bumpTrueAffinity(CharacterId.uta, -3);
    gs.cgLibrary.unlock('cg.test.resume.1');
    gs.cgLibrary.unlock('cg.test.resume.2');

    final beforeIntellect = gs.allStats[StatKind.intellect]!;
    final beforeVitality = gs.vitality;
    final beforeDate = gs.currentDate;

    // 2) 手動スロット 5 番にセーブ。
    await repo.write(SaveSlotKey.manual(5), gs);

    // 3) AppScope を破棄して新規構築（アプリ再起動相当）。
    await tester.pumpWidget(MaterialApp(home: AppScope(
      gameState: GameState(),
      settings: settings,
      saveRepository: repo,
      endingArchive: arc,
      child: const SizedBox.shrink(),
    )));
    await tester.pump();

    // 4) 新しい GameState を SaveSnapshot で復元。
    final reloadedRepo = await SaveRepository.load();
    final snap = reloadedRepo.read(SaveSlotKey.manual(5));
    expect(snap, isNotNull);
    final reloaded = GameState();
    reloaded.restoreFromMap(snap!.payload);

    // 5) 完全一致を検証。
    expect(reloaded.heroName, '保存テスト太郎');
    expect(reloaded.currentDate, beforeDate);
    expect(reloaded.allStats[StatKind.intellect], beforeIntellect);
    expect(reloaded.vitality, beforeVitality);
    expect(reloaded.slotStateOf(SlotIndex.morning), SlotState.done);
    expect(reloaded.slotStateOf(SlotIndex.evening), SlotState.done);
    expect(reloaded.characterStateOf(CharacterId.akari).affinity, 23);
    expect(reloaded.characterStateOf(CharacterId.uta).trueAffinity, -3);
    expect(reloaded.cgLibrary.has('cg.test.resume.1'), isTrue);
    expect(reloaded.cgLibrary.has('cg.test.resume.2'), isTrue);
  });

  testWidgets('オートセーブも再起動を超えて読み出せる', (tester) async {
    SettingsState settings = SettingsState(
      bgmVolume: 0.5,
      textSpeed: 0.5,
      themeMode: ThemeMode.light,
      onPersist: (_) async {},
    );
    SaveRepository repo = await SaveRepository.load();

    final gs = GameState(heroName: 'オート保存太郎');
    await repo.writeAuto(gs, now: DateTime(2026, 5, 1, 7, 0));

    // 再構築。
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();

    final reloaded = await SaveRepository.load();
    final auto = reloaded.read(SaveSlotKey.auto(0));
    expect(auto, isNotNull);
    expect(auto!.heroName, 'オート保存太郎');
    expect(auto.savedAt, DateTime(2026, 5, 1, 7, 0));
    expect(settings.themeMode, ThemeMode.light); // settings は維持
  });
}
