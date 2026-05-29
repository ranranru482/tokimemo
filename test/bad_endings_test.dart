import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/data/endings.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/character_state.dart';
import 'package:tokimemo/models/ending.dart';
import 'package:tokimemo/models/ending_resolver.dart';

void main() {
  const resolver = EndingResolver();

  Map<CharacterId, CharacterState> happyAllRoute() {
    return <CharacterId, CharacterState>{
      for (final id in CharacterId.values)
        id: CharacterState(
          isMet: true,
          affinity: 70,
          trueAffinity: 40,
          unlockedEventIds: <String>{'confession_eve.${id.name}'},
        ),
    };
  }

  group('燃え尽きED の判定', () {
    test('ストレス 90 で燃え尽きED（他条件が真EDでも上書き）', () {
      final result = resolver.resolve(
        characterStates: happyAllRoute(),
        stress: 90,
        career: 60,
        cgUnlockCount: 15,
      );
      expect(result, EndingKind.burnoutEd);
    });

    test('ストレス 100 でも燃え尽きED', () {
      final result = resolver.resolve(
        characterStates: happyAllRoute(),
        stress: 100,
        career: 60,
        cgUnlockCount: 15,
      );
      expect(result, EndingKind.burnoutEd);
    });

    test('ストレス 89 では燃え尽きEDにならない（最低 90）', () {
      final result = resolver.resolve(
        characterStates: <CharacterId, CharacterState>{
          for (final id in CharacterId.values) id: CharacterState(),
        },
        stress: 89,
        career: 30,
        cgUnlockCount: 0,
      );
      expect(result, isNot(EndingKind.burnoutEd));
    });
  });

  group('左遷ED の判定', () {
    test('仕事評価 10 で左遷ED（個別ED条件を満たしていても上書き）', () {
      final akariRoute = <CharacterId, CharacterState>{
        for (final id in CharacterId.values) id: CharacterState(),
      };
      akariRoute[CharacterId.akari] = CharacterState(
        isMet: true,
        affinity: 85,
        trueAffinity: 25,
        unlockedEventIds: <String>{'confession_eve.akari'},
      );
      final result = resolver.resolve(
        characterStates: akariRoute,
        stress: 30,
        career: 10,
        cgUnlockCount: 3,
      );
      expect(result, EndingKind.demotionEd);
    });

    test('仕事評価 0 でも左遷ED', () {
      final result = resolver.resolve(
        characterStates: <CharacterId, CharacterState>{
          for (final id in CharacterId.values) id: CharacterState(),
        },
        stress: 30,
        career: 0,
        cgUnlockCount: 0,
      );
      expect(result, EndingKind.demotionEd);
    });

    test('仕事評価 11 では左遷EDにならない（最大 10）', () {
      final result = resolver.resolve(
        characterStates: <CharacterId, CharacterState>{
          for (final id in CharacterId.values) id: CharacterState(),
        },
        stress: 30,
        career: 11,
        cgUnlockCount: 0,
      );
      expect(result, EndingKind.normalEd);
    });
  });

  group('バッドED 優先順位', () {
    test('ストレス 90 + 仕事評価 5 → 宣言順で先頭の burnoutEd を採用', () {
      final result = resolver.resolve(
        characterStates: <CharacterId, CharacterState>{
          for (final id in CharacterId.values) id: CharacterState(),
        },
        stress: 95,
        career: 5,
        cgUnlockCount: 0,
      );
      expect(result, EndingKind.burnoutEd);
    });
  });

  group('EndingBodyCatalog', () {
    test('burnoutEd / demotionEd の本文とヒントが揃っている', () {
      for (final k in [EndingKind.burnoutEd, EndingKind.demotionEd]) {
        final body = EndingBodyCatalog.bodyOf(k);
        expect(body.lines, isNotEmpty);
        expect(body.credit, isNotEmpty);
        expect(body.hints, hasLength(3));
        for (final h in body.hints) {
          expect(h, isNotEmpty);
        }
      }
    });

    test('EndingKind は全 9 種になる', () {
      expect(EndingKind.values.length, 9);
    });
  });
}
