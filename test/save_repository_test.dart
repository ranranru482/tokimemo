import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/save_snapshot.dart';
import 'package:tokimemo/models/stats.dart';
import 'package:tokimemo/services/save_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 09: SaveRepository の JSON round-trip と
/// オートセーブ（リングバッファ）の挙動を unit で検証。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('SaveRepository: 手動スロット round-trip', () {
    test('write → read で完全に同じ状態が復元される', () async {
      final repo = await SaveRepository.load();
      final source = GameState(heroName: 'テスト太郎');
      source.applyAction(SlotIndex.morning, ActionKind.read);
      source.bumpAffinity(CharacterId.akari, 25);
      source.cgLibrary.unlock('cg.test.alpha');
      source.cgLibrary.unlock('cg.test.beta');

      final snap = await repo.write(SaveSlotKey.manual(3), source);
      expect(snap.slot.prefsKey, 'save.slot.3');

      final restored = GameState();
      final read = repo.read(SaveSlotKey.manual(3))!;
      restored.restoreFromMap(read.payload);

      expect(restored.heroName, 'テスト太郎');
      expect(restored.currentDate, source.currentDate);
      expect(restored.vitality, source.vitality);
      expect(restored.allStats[StatKind.intellect],
          source.allStats[StatKind.intellect]);
      expect(restored.slotStateOf(SlotIndex.morning), SlotState.done);
      expect(restored.characterStateOf(CharacterId.akari).affinity, 25);
      expect(restored.cgLibrary.has('cg.test.alpha'), isTrue);
      expect(restored.cgLibrary.has('cg.test.beta'), isTrue);
    });

    test('delete でスロットがクリアされる', () async {
      final repo = await SaveRepository.load();
      await repo.write(SaveSlotKey.manual(0), GameState(heroName: 'A'));
      expect(repo.read(SaveSlotKey.manual(0)), isNotNull);
      await repo.delete(SaveSlotKey.manual(0));
      expect(repo.read(SaveSlotKey.manual(0)), isNull);
    });

    test('空スロットの read は null を返す', () async {
      final repo = await SaveRepository.load();
      expect(repo.read(SaveSlotKey.manual(7)), isNull);
      expect(repo.readQuick(), isNull);
    });
  });

  group('SaveRepository: クイックセーブ', () {
    test('クイックスロットは独立して保存される', () async {
      final repo = await SaveRepository.load();
      final gs = GameState(heroName: 'クイック');
      await repo.write(SaveSlotKey.quick(), gs);
      expect(repo.readQuick(), isNotNull);
      expect(repo.read(SaveSlotKey.manual(0)), isNull);
    });
  });

  group('SaveRepository: オートセーブ（リングバッファ）', () {
    test('writeAuto は 0→1→2→0 の順で循環する', () async {
      final repo = await SaveRepository.load();
      expect(repo.peekAutoCursor(), 0);
      await repo.writeAuto(GameState(heroName: 'A'));
      expect(repo.peekAutoCursor(), 1);
      await repo.writeAuto(GameState(heroName: 'B'));
      expect(repo.peekAutoCursor(), 2);
      await repo.writeAuto(GameState(heroName: 'C'));
      expect(repo.peekAutoCursor(), 0);
      await repo.writeAuto(GameState(heroName: 'D'));
      // 4 回目で 0 番が D に上書きされる。
      final entries = repo.readAllAuto();
      expect(entries[0]!.heroName, 'D');
      expect(entries[1]!.heroName, 'B');
      expect(entries[2]!.heroName, 'C');
    });
  });

  group('SaveRepository: 最新セーブ取得', () {
    test('readLatest は手動・クイック・オートを横断して最新を返す', () async {
      final repo = await SaveRepository.load();
      // 古い順に書き込む。書き込み時刻を明示的に指定して検証を決定論にする。
      await repo.write(
        SaveSlotKey.manual(0),
        GameState(heroName: '古い'),
        now: DateTime(2026, 5, 1, 10),
      );
      await repo.write(
        SaveSlotKey.quick(),
        GameState(heroName: 'クイック中間'),
        now: DateTime(2026, 5, 2, 10),
      );
      await repo.writeAuto(
        GameState(heroName: 'オート最新'),
        now: DateTime(2026, 5, 3, 10),
      );
      final latest = repo.readLatest();
      expect(latest, isNotNull);
      expect(latest!.heroName, 'オート最新');
    });

    test('全スロット空なら null', () async {
      final repo = await SaveRepository.load();
      expect(repo.readLatest(), isNull);
    });
  });

  group('SaveRepository: clearAll', () {
    test('全スロットを消去する', () async {
      final repo = await SaveRepository.load();
      await repo.write(SaveSlotKey.manual(0), GameState(heroName: 'A'));
      await repo.write(SaveSlotKey.quick(), GameState(heroName: 'B'));
      await repo.writeAuto(GameState(heroName: 'C'));
      await repo.clearAll();
      expect(repo.readQuick(), isNull);
      expect(repo.read(SaveSlotKey.manual(0)), isNull);
      expect(repo.read(SaveSlotKey.auto(0)), isNull);
      expect(repo.peekAutoCursor(), 0);
    });
  });

  group('SaveRepository: サマリー生成', () {
    test('「N月N日 / 体力X / 出会い済Y名」形式', () {
      final gs = GameState(heroName: '太郎')
        ..recordEncounter(CharacterId.akari)
        ..recordEncounter(CharacterId.uta);
      final summary = SaveRepository.buildSummary(gs);
      expect(summary, contains('月'));
      expect(summary, contains('体力'));
      expect(summary, contains('出会い済2名'));
    });
  });
}
