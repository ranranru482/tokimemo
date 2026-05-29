import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/data/endings.dart';
import 'package:tokimemo/models/ending.dart';
import 'package:tokimemo/screens/ending_archive_screen.dart';
import 'package:tokimemo/services/ending_archive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Sprint 12: エンディング図鑑のヒント機能テスト。
///
/// 仕様書 Sprint 12 受け入れ基準3:
/// 「エンディング図鑑で未達成EDをタップすると条件ヒントが3つ表示される」。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  void useTallTestView(WidgetTester tester) {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('未達成EDをタップするとヒント3つがダイアログ表示される', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final archive = await EndingArchive.load();
    // 真EDのみ達成済みにする → 個別ED 5 種類は未達成のまま。
    await archive.recordAchievement(EndingKind.trueEd, DateTime(2027, 3, 31));

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const EndingArchiveScreen(),
        settings: settings,
        endingArchive: archive,
      ),
    );
    await tester.pumpAndSettle();

    // 未達成の akari ED カードをタップ。
    await tester.tap(find.byKey(const ValueKey('endingArchive.card.ending.akari')));
    await tester.pumpAndSettle();

    // ヒントダイアログが開く。
    expect(
      find.byKey(const ValueKey('endingArchive.hintDialog.ending.akari')),
      findsOneWidget,
    );
    // ヒントが 3 つ表示される。
    for (int i = 0; i < 3; i++) {
      expect(
        find.byKey(ValueKey('endingArchive.hintDialog.ending.akari.hint.$i')),
        findsOneWidget,
      );
    }
    // 「閉じる」ボタンがある。
    expect(
      find.byKey(const ValueKey('endingArchive.hintDialog.ending.akari.close')),
      findsOneWidget,
    );
  });

  testWidgets('未達成 ED のヒントは EndingBody.hints の内容と一致する', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final archive = await EndingArchive.load();
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const EndingArchiveScreen(),
        settings: settings,
        endingArchive: archive,
      ),
    );
    await tester.pumpAndSettle();

    // 真ED（未達成）のヒントを開く。
    await tester.tap(find.byKey(const ValueKey('endingArchive.card.ending.true')));
    await tester.pumpAndSettle();

    final body = EndingBodyCatalog.bodyOf(EndingKind.trueEd);
    expect(body.hints, hasLength(3));
    for (final hint in body.hints) {
      expect(find.text(hint), findsOneWidget);
    }
  });

  testWidgets('達成済 ED タップではヒントダイアログではなく本文再生に進む', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final archive = await EndingArchive.load();
    await archive.recordAchievement(EndingKind.akariEd, DateTime(2027, 3, 31));
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const EndingArchiveScreen(),
        settings: settings,
        endingArchive: archive,
      ),
    );
    await tester.pumpAndSettle();

    // 達成済 akari をタップ → ヒントダイアログは出ない（=本文画面遷移）。
    await tester.tap(find.byKey(const ValueKey('endingArchive.card.ending.akari')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('endingArchive.hintDialog.ending.akari')),
      findsNothing,
    );
  });

  testWidgets('「閉じる」ボタンでヒントダイアログが閉じる', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final archive = await EndingArchive.load();
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const EndingArchiveScreen(),
        settings: settings,
        endingArchive: archive,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('endingArchive.card.ending.normal')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('endingArchive.hintDialog.ending.normal')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('endingArchive.hintDialog.ending.normal.close')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('endingArchive.hintDialog.ending.normal')),
      findsNothing,
    );
  });

  group('EndingBody.hints: 全7種にヒント3行', () {
    test('全 ED のヒントが 3 行ずつある', () {
      for (final k in EndingKind.values) {
        final body = EndingBodyCatalog.bodyOf(k);
        expect(body.hints, hasLength(3),
            reason: '${k.id} のヒントは 3 行であるべき');
        for (final hint in body.hints) {
          expect(hint, isNotEmpty,
              reason: '${k.id} のヒント文が空になっている');
        }
      }
    });
  });
}
