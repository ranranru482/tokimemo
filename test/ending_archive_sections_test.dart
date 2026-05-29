import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/ending.dart';
import 'package:tokimemo/screens/ending_archive_screen.dart';
import 'package:tokimemo/services/ending_archive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Task #5: ED 図鑑のセクション化テスト。
///
/// 9 種のエンディングをバッド/個別/ノーマル/真の 4 グループに分けて
/// 見せている。既存の card key は維持しつつ、セクションヘッダーと
/// 各セクションのカウンタが追加されている。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  void useTallTestView(WidgetTester tester) {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('4 セクション（バッド/個別/ノーマル/真）のヘッダーが表示される',
      (tester) async {
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
    for (final id in ['bad', 'individual', 'normal', 'true']) {
      expect(
        find.byKey(ValueKey('endingArchive.section.$id.label')),
        findsOneWidget,
        reason: 'セクション $id のラベルが見当たらない',
      );
      expect(
        find.byKey(ValueKey('endingArchive.section.$id.counter')),
        findsOneWidget,
      );
    }
  });

  testWidgets('各セクションのカウンタは達成数 / グループ総数を表示する', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final archive = await EndingArchive.load();
    // バッドED 1 件達成。
    await archive.recordAchievement(
        EndingKind.burnoutEd, DateTime(2027, 3, 31));
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const EndingArchiveScreen(),
        settings: settings,
        endingArchive: archive,
      ),
    );
    await tester.pumpAndSettle();
    // バッドED 2 件中 1 件達成。
    expect(find.text('1 / 2'), findsOneWidget);
    // 個別ED は 0/5、ノーマルは 0/1、真は 0/1。
    expect(find.text('0 / 5'), findsOneWidget);
    expect(find.text('0 / 1'), findsNWidgets(2));
  });

  testWidgets('既存のカードキーは維持されている（全 9 件）', (tester) async {
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
    expect(EndingKind.values.length, 9);
    for (final k in EndingKind.values) {
      expect(
        find.byKey(ValueKey('endingArchive.card.${k.id}')),
        findsOneWidget,
        reason: '${k.id} のカードが見つからない',
      );
    }
  });
}
