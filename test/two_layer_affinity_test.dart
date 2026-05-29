import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/dialogue.dart';
import 'package:tokimemo/models/game_state.dart';

/// Sprint 07 受け入れ基準2:
/// 真の好感度が下がる選択肢を選ぶと、表面ハートは変わらず内部の真の好感度のみ減る。
void main() {
  group('2 層好感度: applyChoiceOutcome の独立性', () {
    test('真の好感度のみ減る選択肢は、表面 affinity を動かさない', () {
      final gs = GameState();
      gs.recordEncounter(CharacterId.akari);
      final beforeStage =
          gs.characterStateOf(CharacterId.akari).affinityStage;
      final beforeAffinity = gs.characterStateOf(CharacterId.akari).affinity;
      final beforeTrue = gs.characterStateOf(CharacterId.akari).trueAffinity;

      // 「上辺だけ取り繕う」選択肢: 表面 0 / 真 -5
      const outcome = ChoiceOutcome(
        label: '（表向きだけ繕う）',
        affinityDelta: 0,
        trueAffinityDelta: -5,
      );
      gs.applyChoiceOutcome(target: CharacterId.akari, outcome: outcome);

      final after = gs.characterStateOf(CharacterId.akari);
      expect(after.affinity, beforeAffinity, reason: '表面は変わらない');
      expect(after.affinityStage, beforeStage, reason: 'ハート段階も変わらない');
      expect(after.trueAffinity, beforeTrue - 5, reason: '真の好感度だけ減る');
    });

    test('「無難な相づち」: 表面+1 / 真 0', () {
      final gs = GameState();
      gs.recordEncounter(CharacterId.uta);

      const outcome = ChoiceOutcome(
        label: '（無難な相づち）',
        affinityDelta: 1,
        trueAffinityDelta: 0,
      );
      gs.applyChoiceOutcome(target: CharacterId.uta, outcome: outcome);

      final s = gs.characterStateOf(CharacterId.uta);
      expect(s.affinity, 1);
      expect(s.trueAffinity, 0);
    });

    test('「本音を話す」: 表面 0 / 真 +3', () {
      final gs = GameState();
      gs.recordEncounter(CharacterId.uta);

      const outcome = ChoiceOutcome(
        label: '（本音を話す）',
        affinityDelta: 0,
        trueAffinityDelta: 3,
      );
      gs.applyChoiceOutcome(target: CharacterId.uta, outcome: outcome);

      final s = gs.characterStateOf(CharacterId.uta);
      expect(s.affinity, 0, reason: '表面は変わらない');
      expect(s.affinityStage, 1, reason: 'ハート段階は 1（他人）のまま');
      expect(s.trueAffinity, 3);
    });

    test('複数回適用しても表面と真は独立に動く', () {
      final gs = GameState();
      gs.recordEncounter(CharacterId.toru);

      const honest = ChoiceOutcome(label: '本音', affinityDelta: 0, trueAffinityDelta: 3);
      const surface = ChoiceOutcome(label: '無難', affinityDelta: 1, trueAffinityDelta: 0);

      for (int i = 0; i < 10; i++) {
        gs.applyChoiceOutcome(target: CharacterId.toru, outcome: honest);
      }
      // 真の好感度だけ +30、表面は 0
      final s1 = gs.characterStateOf(CharacterId.toru);
      expect(s1.affinity, 0);
      expect(s1.trueAffinity, 30);
      expect(s1.affinityStage, 1); // 表面 0 のまま → 1 段階目

      for (int i = 0; i < 20; i++) {
        gs.applyChoiceOutcome(target: CharacterId.toru, outcome: surface);
      }
      // 表面 +20、真は +30 のまま
      final s2 = gs.characterStateOf(CharacterId.toru);
      expect(s2.affinity, 20);
      expect(s2.trueAffinity, 30);
      expect(s2.affinityStage, 2); // 表面 20 で 2 段階目に到達
    });
  });
}
