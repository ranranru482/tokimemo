import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/screens/album_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Task #5: アルバム画面のフィルタ / ヒント / 告白前夜統合のテスト。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pump(WidgetTester tester, GameState gs) async {
    final settings = await createTestSettings();
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      wrapWithAppScope(
        gameState: gs,
        settings: settings,
        child: const AlbumScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('告白前夜 CG のアルバム統合', () {
    testWidgets('告白前夜 5 件がアルバムに表示される', (tester) async {
      final gs = GameState();
      await pump(tester, gs);
      for (final id in CharacterId.values) {
        expect(
          find.byKey(ValueKey('cgLocked.cg.confession_eve.${id.name}')),
          findsOneWidget,
          reason: 'confession_eve.${id.name} がアルバムに含まれていない',
        );
      }
    });

    testWidgets('告白前夜 CG を解放するとサムネ表示される', (tester) async {
      final gs = GameState();
      gs.cgLibrary.unlock('cg.confession_eve.akari');
      await pump(tester, gs);
      expect(
        find.byKey(const ValueKey('cgLocked.cg.confession_eve.akari')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('album.thumb.cg.confession_eve.akari')),
        findsOneWidget,
      );
    });
  });

  group('カテゴリフィルタ', () {
    testWidgets('告白前夜カテゴリで絞ると共通イベント CG が消える', (tester) async {
      final gs = GameState();
      await pump(tester, gs);
      // 初期: 共通イベント（健康診断）と告白前夜（akari）が両方見える。
      expect(
        find.byKey(const ValueKey('cgLocked.cg.common.health_check_jun')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cgLocked.cg.confession_eve.akari')),
        findsOneWidget,
      );
      // フィルタを開いて「告白前夜」を選ぶ。
      await tester.tap(find.byKey(const ValueKey('album.filter.category')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('album.filter.category.confessionEve')));
      await tester.pumpAndSettle();
      // 共通イベントは消え、告白前夜のみ残る。
      expect(
        find.byKey(const ValueKey('cgLocked.cg.common.health_check_jun')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('cgLocked.cg.confession_eve.akari')),
        findsOneWidget,
      );
    });
  });

  group('キャラフィルタ', () {
    testWidgets('akari で絞ると akari 関連 CG のみ残り、uta 関連は消える', (tester) async {
      final gs = GameState();
      await pump(tester, gs);
      await tester.tap(find.byKey(const ValueKey('album.filter.character')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('album.filter.character.akari')));
      await tester.pumpAndSettle();
      // uta 関連は viewport 上どこにも見えない（フィルタで除外）。
      expect(
        find.byKey(const ValueKey('cgLocked.cg.ind.uta.1')),
        findsNothing,
      );
      // akari の Event 1 は残る（filter 後は件数が減るので viewport 内に収まる）。
      expect(
        find.byKey(const ValueKey('cgLocked.cg.ind.akari.1')),
        findsOneWidget,
      );
      // 告白前夜 akari も残る（akari に紐づく）。
      expect(
        find.byKey(const ValueKey('cgLocked.cg.confession_eve.akari')),
        findsOneWidget,
      );
    });
  });

  group('未解放ヒントダイアログ', () {
    testWidgets('ロックタイルをタップするとヒントダイアログが出る', (tester) async {
      final gs = GameState();
      await pump(tester, gs);
      await tester.tap(
        find.byKey(const ValueKey('cgLocked.cg.confession_eve.akari')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('album.hintDialog.cg.confession_eve.akari')),
        findsOneWidget,
      );
      expect(
        find.byKey(
            const ValueKey('album.hintDialog.cg.confession_eve.akari.hint')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
            const ValueKey('album.hintDialog.cg.confession_eve.akari.close')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('album.hintDialog.cg.confession_eve.akari')),
        findsNothing,
      );
    });
  });

  group('解放済み詳細画面のカテゴリバッジ', () {
    testWidgets('全画面プレビュー上部にカテゴリバッジが表示される', (tester) async {
      final gs = GameState();
      gs.cgLibrary.unlock('cg.confession_eve.uta');
      await pump(tester, gs);
      await tester.tap(
        find.byKey(const ValueKey('album.thumb.cg.confession_eve.uta')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
            const ValueKey('album.fullView.cg.confession_eve.uta.badge')),
        findsOneWidget,
      );
    });
  });
}
