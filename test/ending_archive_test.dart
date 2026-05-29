import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/ending.dart';
import 'package:tokimemo/screens/ending_archive_screen.dart';
import 'package:tokimemo/services/ending_archive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Sprint 09: エンディング図鑑画面のテスト。
///
/// 受け入れ基準5: 達成済みEDが彩色、未達成がシルエットで表示される。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// GridView は viewport 外の子をビルドしないため、縦長サーフェスで描画する。
  void useTallTestView(WidgetTester tester) {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('未達成のEDはシルエット表示、達成済は彩色表示', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final archive = await EndingArchive.load();
    // akari ED のみ達成済みにする。
    await archive.recordAchievement(EndingKind.akariEd, DateTime(2027, 3, 31));

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const EndingArchiveScreen(),
        settings: settings,
        endingArchive: archive,
      ),
    );
    await tester.pumpAndSettle();

    // 全 ED のカードが描画されていること（バッド ED 2 種を含む 9 種）。
    expect(EndingKind.values.length, 9);
    for (final k in EndingKind.values) {
      expect(find.byKey(ValueKey('endingArchive.card.${k.id}')), findsOneWidget);
    }

    // akari は彩色サムネ、それ以外はロックサムネ。
    expect(
      find.byKey(const ValueKey('endingArchive.thumb.${'ending.akari'}.colored')),
      findsOneWidget,
    );
    for (final k in EndingKind.values) {
      if (k == EndingKind.akariEd) continue;
      expect(
        find.byKey(ValueKey('endingArchive.thumb.${k.id}.locked')),
        findsOneWidget,
        reason: '${k.id} は未達成なのでロック表示のはず',
      );
    }
  });

  testWidgets('カウンタが「達成数 / 9」を表示する', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final archive = await EndingArchive.load();
    await archive.recordAchievement(EndingKind.akariEd, DateTime(2027, 3, 31));
    await archive.recordAchievement(EndingKind.utaEd, DateTime(2027, 3, 31));

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const EndingArchiveScreen(),
        settings: settings,
        endingArchive: archive,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('endingArchive.counter')),
      findsOneWidget,
    );
    expect(find.text('2 / 9'), findsOneWidget);
  });

  testWidgets('達成済 ED は displayName を表示、未達成は ???', (tester) async {
    useTallTestView(tester);
    final settings = await createTestSettings();
    final archive = await EndingArchive.load();
    await archive.recordAchievement(EndingKind.trueEd, DateTime(2027, 3, 31));

    await tester.pumpWidget(
      wrapWithAppScope(
        child: const EndingArchiveScreen(),
        settings: settings,
        endingArchive: archive,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('月と珈琲ED'), findsOneWidget);
    // 未達成キャラには ??? が並ぶ（全 9 種中 8 種が未達成）。
    expect(find.text('???'), findsNWidgets(8));
  });

  group('EndingArchive: 永続化と再ロード', () {
    test('recordAchievement の後、別インスタンスでロードしても残る', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final a1 = await EndingArchive.load();
      await a1.recordAchievement(EndingKind.trueEd, DateTime(2027, 3, 31));
      final a2 = await EndingArchive.load();
      expect(a2.isAchieved(EndingKind.trueEd), isTrue);
      expect(a2.entries[EndingKind.trueEd]!.achievedAt,
          DateTime(2027, 3, 31));
    });

    test('初回達成のみ記録され、2 回目は上書きされない', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final a = await EndingArchive.load();
      await a.recordAchievement(EndingKind.akariEd, DateTime(2027, 3, 31));
      await a.recordAchievement(EndingKind.akariEd, DateTime(2028, 3, 31));
      expect(a.entries[EndingKind.akariEd]!.achievedAt,
          DateTime(2027, 3, 31));
    });

    test('clear で全消去', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final a = await EndingArchive.load();
      await a.recordAchievement(EndingKind.akariEd, DateTime(2027, 3, 31));
      await a.clear();
      expect(a.achievedCount, 0);
    });
  });
}
