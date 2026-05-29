import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/data/work_events.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/stats.dart';
import 'package:tokimemo/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WorkEventCatalog', () {
    test('イベントは 7 本以上ある', () {
      expect(WorkEventCatalog.all.length, greaterThanOrEqualTo(7));
    });

    test('全イベントの id がユニーク', () {
      final ids = WorkEventCatalog.all.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('全イベントが 2 つ以上の選択肢を持ち、ラベルと結果文が空でない', () {
      for (final ev in WorkEventCatalog.all) {
        expect(ev.choices.length, greaterThanOrEqualTo(2),
            reason: '${ev.id} の選択肢は 2 つ以上必要');
        for (final c in ev.choices) {
          expect(c.label, isNotEmpty);
          expect(c.resultText, isNotEmpty);
        }
      }
    });

    test('5 カテゴリすべて 1 本以上のイベントが含まれる', () {
      for (final cat in WorkEventCategory.values) {
        expect(
          WorkEventCatalog.all.any((e) => e.category == cat),
          isTrue,
          reason: 'カテゴリ $cat のイベントが定義されていない',
        );
      }
    });

    test('shouldFire は roll<35 で true、35 以上で false', () {
      // 0 で必ず true
      expect(WorkEventCatalog.shouldFire(_FixedRng(0)), isTrue);
      // 34 で true
      expect(WorkEventCatalog.shouldFire(_FixedRng(34)), isTrue);
      // 35 で false
      expect(WorkEventCatalog.shouldFire(_FixedRng(35)), isFalse);
      // 99 で false
      expect(WorkEventCatalog.shouldFire(_FixedRng(99)), isFalse);
    });

    test('pick で先頭インデックス 0 のイベントを返す', () {
      final ev = WorkEventCatalog.pick(_FixedRng(0));
      expect(ev.id, WorkEventCatalog.all.first.id);
    });
  });

  group('WorkChoiceEffect.toDeltas', () {
    test('0 のフィールドはマップに含めない', () {
      const e = WorkChoiceEffect(career: 5, stress: -3);
      final m = e.toDeltas();
      expect(m, containsPair(StatKind.career, 5));
      expect(m, containsPair(StatKind.stress, -3));
      expect(m.containsKey(StatKind.intellect), isFalse);
      expect(m.containsKey(StatKind.wallet), isFalse);
    });

    test('全フィールドが 0 なら空マップ', () {
      const e = WorkChoiceEffect();
      expect(e.toDeltas(), isEmpty);
    });

    test('money / intellect / sensibility / sociability / vitality を反映', () {
      const e = WorkChoiceEffect(
        money: 1000,
        intellect: 2,
        sensibility: 3,
        sociability: 4,
        vitality: -5,
      );
      final m = e.toDeltas();
      expect(m[StatKind.wallet], 1000);
      expect(m[StatKind.intellect], 2);
      expect(m[StatKind.sensibility], 3);
      expect(m[StatKind.sociability], 4);
      expect(m[StatKind.vitality], -5);
    });
  });

  group('GameState.applyWorkChoice', () {
    test('日中枠を done にし、能力値を変動させる', () {
      final gs = GameState(
        currentDate: DateTime(2026, 4, 1), // 水曜
        stats: <StatKind, int>{StatKind.career: 30},
      );
      expect(gs.slotStateOf(SlotIndex.midday), SlotState.pending);
      final ok = gs.applyWorkChoice(
        const WorkChoiceEffect(career: 5, stress: 3, money: 1000),
      );
      expect(ok, isTrue);
      expect(gs.slotStateOf(SlotIndex.midday), SlotState.done);
      expect(gs.allStats[StatKind.career], 35);
      expect(gs.money, 51000);
      expect(gs.stress, 23); // 初期 20 + 3
    });

    test('既に done なら false を返し副作用なし', () {
      final gs = GameState(
        currentDate: DateTime(2026, 4, 1),
        slotStates: const {SlotIndex.midday: SlotState.done},
      );
      final ok = gs.applyWorkChoice(const WorkChoiceEffect(career: 5));
      expect(ok, isFalse);
      expect(gs.allStats[StatKind.career], 20); // 初期値のまま
    });

    test('affinityTarget が出会い済みなら好感度を加算する', () {
      final gs = GameState(currentDate: DateTime(2026, 4, 1));
      gs.recordEncounter(CharacterId.akari);
      final beforeAff = gs.characterStates[CharacterId.akari]!.affinity;
      final beforeTrue = gs.characterStates[CharacterId.akari]!.trueAffinity;
      gs.applyWorkChoice(const WorkChoiceEffect(
        affinityTarget: CharacterId.akari,
        affinityDelta: 1,
        trueAffinityDelta: 2,
      ));
      expect(gs.characterStates[CharacterId.akari]!.affinity, beforeAff + 1);
      expect(
        gs.characterStates[CharacterId.akari]!.trueAffinity,
        beforeTrue + 2,
      );
    });

    test('affinityTarget が未会いなら好感度は変動しない', () {
      final gs = GameState(currentDate: DateTime(2026, 4, 1));
      final beforeAff = gs.characterStates[CharacterId.akari]!.affinity;
      gs.applyWorkChoice(const WorkChoiceEffect(
        affinityTarget: CharacterId.akari,
        affinityDelta: 5,
      ));
      expect(gs.characterStates[CharacterId.akari]!.affinity, beforeAff);
    });
  });

  group('HomeScreen 平日日中フロー（widget）', () {
    testWidgets('workEventRng=null なら従来の即ロール挙動を維持する', (tester) async {
      final settings = await createTestSettings();
      final gs = GameState(
        currentDate: DateTime(2026, 4, 1),
        stats: <StatKind, int>{StatKind.career: 90},
      );
      await tester.pumpWidget(
        wrapWithAppScope(
          child: HomeScreen(workRng: Random(0)), // workEventRng は渡さない
          settings: settings,
          gameState: gs,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('home.timelineSlot.日中.tap')));
      await tester.pumpAndSettle();
      // 仕事中イベントダイアログは出ず、従来の resultDialog が出る。
      expect(find.byKey(const ValueKey('work.resultDialog.success')),
          findsOneWidget);
    });

    testWidgets('workEventRng でイベント発火 → 選択肢タップで applyWorkChoice',
        (tester) async {
      final settings = await createTestSettings();
      final gs = GameState(
        currentDate: DateTime(2026, 4, 1),
        stats: <StatKind, int>{StatKind.career: 30},
      );
      // _FixedRng(0) を渡せば shouldFire=true（roll=0<35）, pick=先頭(0)
      await tester.pumpWidget(
        wrapWithAppScope(
          child: HomeScreen(
            workRng: Random(0),
            workEventRng: _FixedRng(0),
          ),
          settings: settings,
          gameState: gs,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('home.timelineSlot.日中.tap')));
      await tester.pumpAndSettle();

      // 先頭イベント（boss.big_deal）のダイアログが表示される。
      final firstEv = WorkEventCatalog.all.first;
      expect(find.byKey(ValueKey('workEvent.${firstEv.id}')), findsOneWidget);

      // 選択肢 0（受ける）をタップ。
      await tester
          .tap(find.byKey(ValueKey('workEvent.${firstEv.id}.choice.0')));
      await tester.pumpAndSettle();

      // 結果テキストに切り替わる。
      expect(find.byKey(ValueKey('workEvent.${firstEv.id}.result')),
          findsOneWidget);
      // 閉じるで pop。
      await tester.tap(find.byKey(ValueKey('workEvent.${firstEv.id}.close')));
      await tester.pumpAndSettle();

      // 効果が適用され、日中枠が done。
      final effect = firstEv.choices[0].effect;
      expect(gs.slotStateOf(SlotIndex.midday), SlotState.done);
      expect(gs.allStats[StatKind.career], 30 + effect.career);
    });
  });
}

/// テスト用の固定値 Random。`nextInt(n)` で常に `value` を返す。
class _FixedRng implements Random {
  _FixedRng(this.value);
  final int value;

  @override
  bool nextBool() => value != 0;

  @override
  double nextDouble() => value / 100.0;

  @override
  int nextInt(int max) => value % max;
}
