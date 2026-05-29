import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/data/character_repository.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/widgets/character_portrait.dart';

void main() {
  Future<void> pumpPortrait(
    WidgetTester tester, {
    required Expression expression,
    bool isSilhouette = false,
  }) async {
    final character = CharacterRepository.byId(CharacterId.akari);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CharacterPortrait(
              character: character,
              expression: expression,
              isSilhouette: isSilhouette,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('normal 表情で root key と expression key が出る', (tester) async {
    await pumpPortrait(tester, expression: Expression.normal);
    expect(
      find.byKey(const ValueKey('characterPortrait.akari.normal')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('characterPortrait.akari.expression.normal')),
      findsOneWidget,
    );
  });

  testWidgets('smile 表情に切り替わると expression key が更新される', (tester) async {
    await pumpPortrait(tester, expression: Expression.smile);
    expect(
      find.byKey(const ValueKey('characterPortrait.akari.smile')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('characterPortrait.akari.expression.smile')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('characterPortrait.akari.expression.normal')),
      findsNothing,
    );
  });

  testWidgets('troubled 表情でも key が変わる（差分検証）', (tester) async {
    await pumpPortrait(tester, expression: Expression.troubled);
    expect(
      find.byKey(const ValueKey('characterPortrait.akari.troubled')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('characterPortrait.akari.expression.troubled')),
      findsOneWidget,
    );
  });

  testWidgets('isSilhouette=true で silhouette key が出る / 表情アイコンは出ない',
      (tester) async {
    await pumpPortrait(
      tester,
      expression: Expression.normal,
      isSilhouette: true,
    );
    expect(
      find.byKey(const ValueKey('characterPortrait.akari.silhouette')),
      findsOneWidget,
    );
    // 表情アイコンは描画されない
    expect(
      find.byKey(const ValueKey('characterPortrait.akari.expression.normal')),
      findsNothing,
    );
  });
}
