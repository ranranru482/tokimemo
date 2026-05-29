import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/stats.dart';

/// Sprint 05 受け入れ基準4: 外出4種それぞれの能力値変動が正しい（unit）。
///
/// `kActionCatalog` の値そのものと、`GameState.applyAction` を通した
/// 副作用の両方を検証する。
void main() {
  group('カフェ', () {
    test('catalog: ストレス -5 / 感性 +1 / 所持金 -800 / requiredMoney 800', () {
      final e = kActionCatalog[ActionKind.cafe]!;
      expect(e.label, 'カフェ');
      expect(e.deltas[StatKind.stress], -5);
      expect(e.deltas[StatKind.sensibility], 1);
      expect(e.deltas[StatKind.wallet], -800);
      expect(e.requiredMoney, 800);
    });

    test('applyAction: 副作用が正しく反映される', () {
      final s = GameState(money: 50000, stress: 30);
      final sensBefore = s.allStats[StatKind.sensibility]!;
      final ok = s.applyAction(SlotIndex.morning, ActionKind.cafe);
      expect(ok, isTrue);
      expect(s.stress, 30 - 5);
      expect(s.allStats[StatKind.sensibility], sensBefore + 1);
      expect(s.money, 50000 - 800);
    });
  });

  group('映画', () {
    test('catalog: ストレス -8 / 感性 +3 / 所持金 -2000 / requiredMoney 2000', () {
      final e = kActionCatalog[ActionKind.movie]!;
      expect(e.label, '映画');
      expect(e.deltas[StatKind.stress], -8);
      expect(e.deltas[StatKind.sensibility], 3);
      expect(e.deltas[StatKind.wallet], -2000);
      expect(e.requiredMoney, 2000);
    });

    test('applyAction: 副作用が正しく反映される', () {
      final s = GameState(money: 50000, stress: 40);
      final sensBefore = s.allStats[StatKind.sensibility]!;
      s.applyAction(SlotIndex.morning, ActionKind.movie);
      expect(s.stress, 40 - 8);
      expect(s.allStats[StatKind.sensibility], sensBefore + 3);
      expect(s.money, 50000 - 2000);
    });
  });

  group('美術館', () {
    test('catalog: 感性 +5 / 知性 +2 / 所持金 -1800 / requiredMoney 1800', () {
      final e = kActionCatalog[ActionKind.museum]!;
      expect(e.label, '美術館');
      expect(e.deltas[StatKind.sensibility], 5);
      expect(e.deltas[StatKind.intellect], 2);
      expect(e.deltas[StatKind.wallet], -1800);
      expect(e.requiredMoney, 1800);
    });

    test('applyAction: 副作用が正しく反映される', () {
      final s = GameState(money: 50000);
      final sensBefore = s.allStats[StatKind.sensibility]!;
      final intBefore = s.allStats[StatKind.intellect]!;
      s.applyAction(SlotIndex.morning, ActionKind.museum);
      expect(s.allStats[StatKind.sensibility], sensBefore + 5);
      expect(s.allStats[StatKind.intellect], intBefore + 2);
      expect(s.money, 50000 - 1800);
    });
  });

  group('ジム', () {
    test('catalog: 体力 +6 / ストレス -4 / 所持金 -1500 / requiredMoney 1500', () {
      final e = kActionCatalog[ActionKind.gym]!;
      expect(e.label, 'ジム');
      expect(e.deltas[StatKind.vitality], 6);
      expect(e.deltas[StatKind.stress], -4);
      expect(e.deltas[StatKind.wallet], -1500);
      expect(e.requiredMoney, 1500);
    });

    test('applyAction: 副作用が正しく反映される（体力上限でクランプ）', () {
      final s = GameState(money: 50000, stress: 20, vitality: 50);
      s.applyAction(SlotIndex.morning, ActionKind.gym);
      expect(s.vitality, 50 + 6);
      expect(s.stress, 20 - 4);
      expect(s.money, 50000 - 1500);
    });

    test('体力上限でクランプされる', () {
      final s = GameState(money: 50000, vitality: 98, vitalityMax: 100);
      s.applyAction(SlotIndex.morning, ActionKind.gym);
      expect(s.vitality, 100);
    });
  });

  group('外出4種すべてが catalog に登録されている', () {
    test('4種それぞれが ActionKind と紐づいている', () {
      for (final k in [
        ActionKind.cafe,
        ActionKind.movie,
        ActionKind.museum,
        ActionKind.gym,
      ]) {
        expect(kActionCatalog.containsKey(k), isTrue, reason: '$k not in catalog');
      }
    });

    test('休日のリストに 4 種すべてが含まれる', () {
      final kinds = kHolidayActionList.map((e) => e.kind).toSet();
      expect(kinds.contains(ActionKind.cafe), isTrue);
      expect(kinds.contains(ActionKind.movie), isTrue);
      expect(kinds.contains(ActionKind.museum), isTrue);
      expect(kinds.contains(ActionKind.gym), isTrue);
    });

    test('平日のリスト（kHomeActionList / kWeekdayEveningActionList）には外出が含まれない',
        () {
      for (final list in [kHomeActionList, kWeekdayEveningActionList]) {
        final kinds = list.map((e) => e.kind).toSet();
        expect(kinds.contains(ActionKind.cafe), isFalse);
        expect(kinds.contains(ActionKind.movie), isFalse);
        expect(kinds.contains(ActionKind.museum), isFalse);
        expect(kinds.contains(ActionKind.gym), isFalse);
      }
    });
  });
}
