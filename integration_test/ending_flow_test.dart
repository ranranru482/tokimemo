import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tokimemo/app.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/ending.dart';
import 'package:tokimemo/models/ending_resolver.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/settings_state.dart';
import 'package:tokimemo/services/ending_archive.dart';
import 'package:tokimemo/services/save_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 09 integration test:
/// - 受け入れ基準 3: 1 年プレイして 3/31 到達でエンディングが再生される。
/// - 受け入れ基準 4: 異なる条件で 2 周プレイして別のエンディングに到達。
///
/// 真のプレイループ 1 年分は重いため、`GameState.debugFastForward` を使って
/// 日付を 3/31 へ加速させ、`debugTriggerEndingResolution` でエンディング判定を
/// 直接トリガする方式に依存する。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('1 年プレイ → 3/31 到達 → ノーマル ED に到達できる', (tester) async {
    final repo = await SaveRepository.load();
    final arc = await EndingArchive.load();
    final settings = SettingsState(
      bgmVolume: 0.5,
      textSpeed: 0.5,
      themeMode: ThemeMode.light,
      onPersist: (_) async {},
    );
    final gs = GameState(heroName: '一周目');
    // 4/1 → 翌年 3/31 までジャンプ（365 日）。
    final daysToYearEnd =
        DateTime(2027, 3, 31).difference(gs.currentDate).inDays;
    gs.debugFastForward(daysToYearEnd);
    expect(gs.currentDate, DateTime(2027, 3, 31));

    // エンディング判定。誰とも会っていないのでノーマル ED になる想定。
    gs.debugTriggerEndingResolution();
    expect(gs.pendingEnding, EndingKind.normalEd);

    // 図鑑に記録。
    await arc.recordAchievement(gs.pendingEnding!, DateTime.now());
    expect(arc.isAchieved(EndingKind.normalEd), isTrue);

    // pump で AppScope を構築できることだけ確認（再生 UI は EndingScreen の
    // widget test で個別に検証）。
    await tester.pumpWidget(MaterialApp(
      home: AppScope(
        gameState: gs,
        settings: settings,
        saveRepository: repo,
        endingArchive: arc,
        child: const SizedBox.shrink(),
      ),
    ));
    await tester.pump();
  });

  testWidgets('別条件で 2 周目 → 別の ED（個別 ED）に到達', (tester) async {
    final repo = await SaveRepository.load();
    final arc = await EndingArchive.load();
    final settings = SettingsState(
      bgmVolume: 0.5,
      textSpeed: 0.5,
      themeMode: ThemeMode.light,
      onPersist: (_) async {},
    );

    // 1 周目: 何もしないとノーマル ED。
    final gs1 = GameState(heroName: '一周目');
    gs1.debugFastForward(
        DateTime(2027, 3, 31).difference(gs1.currentDate).inDays);
    gs1.debugTriggerEndingResolution();
    expect(gs1.pendingEnding, EndingKind.normalEd);
    await arc.recordAchievement(gs1.pendingEnding!, DateTime(2027, 4, 1));

    // 2 周目: akari に集中したルートを擬似的に作る。
    final gs2 = GameState(heroName: '二周目');
    gs2.recordEncounter(CharacterId.akari);
    gs2.bumpAffinity(CharacterId.akari, 85);
    gs2.bumpTrueAffinity(CharacterId.akari, 25);
    // 告白前夜イベントを通過済みにする（AND 条件のため）。
    gs2.characterStates[CharacterId.akari]!
        .unlockedEventIds
        .add('confession_eve.akari');
    // 他キャラとも一応出会っておくが、ED 条件は満たさない。
    gs2.recordEncounter(CharacterId.uta);
    gs2.debugFastForward(
        DateTime(2027, 3, 31).difference(gs2.currentDate).inDays);
    gs2.debugTriggerEndingResolution();
    expect(gs2.pendingEnding, EndingKind.akariEd);
    await arc.recordAchievement(gs2.pendingEnding!, DateTime(2028, 4, 1));

    // 図鑑に 2 種類が記録される。
    expect(arc.achievedCount, 2);
    expect(arc.isAchieved(EndingKind.normalEd), isTrue);
    expect(arc.isAchieved(EndingKind.akariEd), isTrue);

    await tester.pumpWidget(MaterialApp(
      home: AppScope(
        gameState: gs2,
        settings: settings,
        saveRepository: repo,
        endingArchive: arc,
        child: const SizedBox.shrink(),
      ),
    ));
    await tester.pump();
  });

  testWidgets('真ED条件をすべて満たすと月と珈琲EDが発火する', (tester) async {
    final gs = GameState(heroName: '完璧太郎');
    // 全 5 キャラと深く付き合う。
    for (final id in CharacterId.values) {
      gs.recordEncounter(id);
      gs.bumpAffinity(id, 70);
      gs.bumpTrueAffinity(id, 40);
    }
    // 仕事評価とストレスを真ED 条件まで一気に上げる。
    // 内部 API がないので bumpStress / applyAction(overtime) を繰り返す代わりに、
    // toMap → 編集 → restoreFromMap で テストだけ調整する。
    final map = gs.toMap();
    map['stats']['career'] = 60;
    map['stress'] = 30;
    gs.restoreFromMap(map);
    // CG を 12 件以上解放。
    for (int i = 0; i < 15; i++) {
      gs.cgLibrary.unlock('cg.bulk.$i');
    }

    gs.debugFastForward(
        DateTime(2027, 3, 31).difference(gs.currentDate).inDays);
    gs.debugTriggerEndingResolution();
    expect(gs.pendingEnding, EndingKind.trueEd);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  });

  testWidgets('isEndOfYear ヘルパは 3/31 のみ true を返す', (tester) async {
    expect(isEndOfYear(DateTime(2027, 3, 31)), isTrue);
    expect(isEndOfYear(DateTime(2027, 3, 30)), isFalse);
    expect(isEndOfYear(DateTime(2027, 4, 1)), isFalse);
  });
}
