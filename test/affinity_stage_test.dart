import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/character_state.dart';

/// Sprint 07: CharacterState.affinityStage の閾値テスト。
///
/// 仕様書 §6 の段階定義に従う：
/// - 1 段階目: 0〜19   （他人）
/// - 2 段階目: 20〜39  （顔見知り）
/// - 3 段階目: 40〜59  （友人）
/// - 4 段階目: 60〜79  （特別な存在）
/// - 5 段階目: 80〜100 （大切な人）
void main() {
  group('affinityStage の境界値', () {
    test('0〜19 は 1 段階目', () {
      for (final v in <int>[0, 1, 10, 19]) {
        final s = CharacterState(isMet: true, affinity: v);
        expect(s.affinityStage, 1, reason: 'affinity=$v should be stage 1');
      }
    });

    test('20〜39 は 2 段階目', () {
      for (final v in <int>[20, 25, 39]) {
        final s = CharacterState(isMet: true, affinity: v);
        expect(s.affinityStage, 2, reason: 'affinity=$v should be stage 2');
      }
    });

    test('40〜59 は 3 段階目', () {
      for (final v in <int>[40, 50, 59]) {
        final s = CharacterState(isMet: true, affinity: v);
        expect(s.affinityStage, 3, reason: 'affinity=$v should be stage 3');
      }
    });

    test('60〜79 は 4 段階目', () {
      for (final v in <int>[60, 70, 79]) {
        final s = CharacterState(isMet: true, affinity: v);
        expect(s.affinityStage, 4, reason: 'affinity=$v should be stage 4');
      }
    });

    test('80〜100 は 5 段階目', () {
      for (final v in <int>[80, 90, 100]) {
        final s = CharacterState(isMet: true, affinity: v);
        expect(s.affinityStage, 5, reason: 'affinity=$v should be stage 5');
      }
    });

    test('段階の遷移ちょうど（19→20、39→40 等）で 1 段階上がる', () {
      expect(CharacterState(isMet: true, affinity: 19).affinityStage, 1);
      expect(CharacterState(isMet: true, affinity: 20).affinityStage, 2);
      expect(CharacterState(isMet: true, affinity: 39).affinityStage, 2);
      expect(CharacterState(isMet: true, affinity: 40).affinityStage, 3);
      expect(CharacterState(isMet: true, affinity: 59).affinityStage, 3);
      expect(CharacterState(isMet: true, affinity: 60).affinityStage, 4);
      expect(CharacterState(isMet: true, affinity: 79).affinityStage, 4);
      expect(CharacterState(isMet: true, affinity: 80).affinityStage, 5);
    });
  });

  group('bumpAffinity / bumpTrueAffinity の範囲クランプ', () {
    test('表面好感度は 0〜100 にクランプされる', () {
      final s = CharacterState(isMet: true, affinity: 0);
      s.bumpAffinity(-10);
      expect(s.affinity, 0);
      s.bumpAffinity(150);
      expect(s.affinity, 100);
    });

    test('真の好感度は -50〜+100 にクランプされる', () {
      final s = CharacterState(isMet: true, trueAffinity: 0);
      s.bumpTrueAffinity(-100);
      expect(s.trueAffinity, CharacterState.kTrueAffinityMin); // -50
      s.bumpTrueAffinity(300);
      expect(s.trueAffinity, CharacterState.kTrueAffinityMax); // 100
    });

    test('真の好感度は負値を取れる（上辺だけの会話を表現）', () {
      final s = CharacterState(isMet: true, trueAffinity: 0);
      s.bumpTrueAffinity(-5);
      expect(s.trueAffinity, -5);
    });
  });
}
