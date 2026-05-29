import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/character_state.dart';
import 'package:tokimemo/models/ending.dart';
import 'package:tokimemo/models/ending_resolver.dart';

/// Sprint 09: EndingResolver の境界値テスト。
///
/// 7 種類の ED 各々について、発火条件と非発火条件の境界を確認する。
void main() {
  const resolver = EndingResolver();

  Map<CharacterId, CharacterState> makeCharacterStates({
    Map<CharacterId, ({int affinity, int trueAffinity, bool isMet})>?
        overrides,
    bool unlockConfessionEveForAll = true,
  }) {
    return <CharacterId, CharacterState>{
      for (final id in CharacterId.values)
        id: () {
          final o = overrides?[id];
          return CharacterState(
            isMet: o?.isMet ?? true,
            affinity: o?.affinity ?? 0,
            trueAffinity: o?.trueAffinity ?? 0,
            unlockedEventIds: unlockConfessionEveForAll
                ? <String>{'confession_eve.${id.name}'}
                : <String>{},
          );
        }(),
    };
  }

  group('真EDの判定', () {
    test('全条件を満たすと真ED', () {
      final result = resolver.resolve(
        characterStates: makeCharacterStates(
          overrides: {
            for (final id in CharacterId.values)
              id: (affinity: 70, trueAffinity: 40, isMet: true),
          },
        ),
        stress: 30,
        career: 60,
        cgUnlockCount: 15,
      );
      expect(result, EndingKind.trueEd);
    });

    test('ストレス 41 で真EDに行かない（最大 40）', () {
      final result = resolver.resolve(
        characterStates: makeCharacterStates(
          overrides: {
            for (final id in CharacterId.values)
              id: (affinity: 70, trueAffinity: 40, isMet: true),
          },
        ),
        stress: 41,
        career: 60,
        cgUnlockCount: 15,
      );
      expect(result, isNot(EndingKind.trueEd));
    });

    test('仕事評価 49 で真EDに行かない（最低 50）', () {
      final result = resolver.resolve(
        characterStates: makeCharacterStates(
          overrides: {
            for (final id in CharacterId.values)
              id: (affinity: 70, trueAffinity: 40, isMet: true),
          },
        ),
        stress: 30,
        career: 49,
        cgUnlockCount: 15,
      );
      expect(result, isNot(EndingKind.trueEd));
    });

    test('CG解放 11 件で真EDに行かない（最低 12）', () {
      final result = resolver.resolve(
        characterStates: makeCharacterStates(
          overrides: {
            for (final id in CharacterId.values)
              id: (affinity: 70, trueAffinity: 40, isMet: true),
          },
        ),
        stress: 30,
        career: 60,
        cgUnlockCount: 11,
      );
      expect(result, isNot(EndingKind.trueEd));
    });

    test('1 人でも affinity 59 で真EDに行かない', () {
      final overrides = <CharacterId,
          ({int affinity, int trueAffinity, bool isMet})>{
        for (final id in CharacterId.values)
          id: (affinity: 70, trueAffinity: 40, isMet: true),
      };
      overrides[CharacterId.yui] =
          (affinity: 59, trueAffinity: 40, isMet: true);
      final result = resolver.resolve(
        characterStates: makeCharacterStates(overrides: overrides),
        stress: 30,
        career: 60,
        cgUnlockCount: 15,
      );
      expect(result, isNot(EndingKind.trueEd));
    });

    test('1 人でも trueAffinity 29 で真EDに行かない（最低 30）', () {
      final overrides = <CharacterId,
          ({int affinity, int trueAffinity, bool isMet})>{
        for (final id in CharacterId.values)
          id: (affinity: 70, trueAffinity: 40, isMet: true),
      };
      overrides[CharacterId.toru] =
          (affinity: 70, trueAffinity: 29, isMet: true);
      final result = resolver.resolve(
        characterStates: makeCharacterStates(overrides: overrides),
        stress: 30,
        career: 60,
        cgUnlockCount: 15,
      );
      expect(result, isNot(EndingKind.trueEd));
    });
  });

  group('個別EDの判定', () {
    test('akari のみ閾値を超えれば akariEd', () {
      final result = resolver.resolve(
        characterStates: makeCharacterStates(
          overrides: {
            CharacterId.akari:
                (affinity: 85, trueAffinity: 25, isMet: true),
            CharacterId.uta: (affinity: 10, trueAffinity: 0, isMet: true),
            CharacterId.toru: (affinity: 0, trueAffinity: 0, isMet: true),
            CharacterId.sayo: (affinity: 0, trueAffinity: 0, isMet: true),
            CharacterId.yui: (affinity: 0, trueAffinity: 0, isMet: true),
          },
        ),
        stress: 60,
        career: 30,
        cgUnlockCount: 3,
      );
      expect(result, EndingKind.akariEd);
    });

    test('複数キャラが閾値を超えたら表面好感度が高い方を採用', () {
      final result = resolver.resolve(
        characterStates: makeCharacterStates(
          overrides: {
            CharacterId.akari:
                (affinity: 85, trueAffinity: 25, isMet: true),
            CharacterId.uta: (affinity: 92, trueAffinity: 25, isMet: true),
            CharacterId.toru: (affinity: 0, trueAffinity: 0, isMet: true),
            CharacterId.sayo: (affinity: 0, trueAffinity: 0, isMet: true),
            CharacterId.yui: (affinity: 0, trueAffinity: 0, isMet: true),
          },
        ),
        stress: 60,
        career: 30,
        cgUnlockCount: 3,
      );
      expect(result, EndingKind.utaEd);
    });

    test('affinity 79 ではノーマル ED 扱い（最低 80）', () {
      final result = resolver.resolve(
        characterStates: makeCharacterStates(
          overrides: {
            CharacterId.akari:
                (affinity: 79, trueAffinity: 50, isMet: true),
          },
        ),
        stress: 60,
        career: 30,
        cgUnlockCount: 3,
      );
      expect(result, EndingKind.normalEd);
    });

    test('trueAffinity 19 で個別 ED 不発（最低 20）', () {
      final result = resolver.resolve(
        characterStates: makeCharacterStates(
          overrides: {
            CharacterId.toru:
                (affinity: 90, trueAffinity: 19, isMet: true),
          },
        ),
        stress: 60,
        career: 30,
        cgUnlockCount: 3,
      );
      expect(result, EndingKind.normalEd);
    });

    test('全 5 キャラを個別ED条件で別シナリオ', () {
      // sayo に集中したルート
      expect(
        resolver.resolve(
          characterStates: makeCharacterStates(
            overrides: {
              CharacterId.sayo:
                  (affinity: 81, trueAffinity: 21, isMet: true),
            },
          ),
          stress: 50,
          career: 30,
          cgUnlockCount: 3,
        ),
        EndingKind.sayoEd,
      );
      // yui に集中したルート
      expect(
        resolver.resolve(
          characterStates: makeCharacterStates(
            overrides: {
              CharacterId.yui:
                  (affinity: 85, trueAffinity: 22, isMet: true),
            },
          ),
          stress: 50,
          career: 30,
          cgUnlockCount: 3,
        ),
        EndingKind.yuiEd,
      );
    });
  });

  group('ノーマルEDの判定', () {
    test('誰とも親しくなければノーマル ED', () {
      final result = resolver.resolve(
        characterStates: makeCharacterStates(),
        stress: 50,
        career: 30,
        cgUnlockCount: 0,
      );
      expect(result, EndingKind.normalEd);
    });

    test('全員 affinity 60 だが trueAffinity が足りない → ノーマル', () {
      // 表面 60 は spec の「特別な存在」段階。trueAffinity 0 は冷めている。
      final result = resolver.resolve(
        characterStates: makeCharacterStates(
          overrides: {
            for (final id in CharacterId.values)
              id: (affinity: 60, trueAffinity: 0, isMet: true),
          },
        ),
        stress: 50,
        career: 30,
        cgUnlockCount: 3,
      );
      expect(result, EndingKind.normalEd);
    });
  });
}
