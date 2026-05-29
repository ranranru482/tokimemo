import 'package:tokimemo/models/actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/game_state.dart';
import 'package:tokimemo/models/invite_balance.dart';

/// Sprint 07 受け入れ基準3:
/// 1ヶ月誰とも会わないと、その対象の好感度が -3 される。
void main() {
  /// `_advanceDay` を強制的に走らせるヘルパー：4枠を read で埋める。
  void advanceOneDay(GameState gs) {
    for (final s in SlotIndex.values) {
      // applyAction の戻り値が false でも次のスロットへ進める。
      gs.applyAction(s, ActionKind.read);
    }
  }

  test('出会い直後の同日に lastInteractedDate が初期化される', () {
    final gs = GameState(currentDate: DateTime(2026, 4, 10));
    gs.recordEncounter(CharacterId.akari);
    expect(
      gs.characterStateOf(CharacterId.akari).lastInteractedDate,
      DateTime(2026, 4, 10),
    );
  });

  test('出会いから 30 日後の日付進行で affinity が -3 される', () {
    // 4/10 出会い → 5/10 が 30 日後。5/10 の advanceDay で発火。
    // applyAction で日付を進めるのは煩雑なので、適度に高初期値で開始。
    final gs = GameState(
      currentDate: DateTime(2026, 4, 10),
      money: 999999,
      vitality: 100,
      vitalityMax: 100,
    );
    gs.recordEncounter(CharacterId.akari);
    // 初期 affinity を 50 にセット（疎遠後でも 0 にならず観測可能にする）
    gs.bumpAffinity(CharacterId.akari, 50);
    gs.bumpTrueAffinity(CharacterId.akari, 50);

    final beforeAffinity = gs.characterStateOf(CharacterId.akari).affinity;
    final beforeTrue = gs.characterStateOf(CharacterId.akari).trueAffinity;
    expect(beforeAffinity, 50);

    // 30 日進める（30 回 advanceOneDay）
    for (int i = 0; i < 30; i++) {
      advanceOneDay(gs);
    }

    expect(gs.currentDate, DateTime(2026, 5, 10));

    final after = gs.characterStateOf(CharacterId.akari);
    expect(after.affinity, beforeAffinity + kEstrangementAffinityDelta,
        reason: '表面好感度が -3 される');
    expect(after.affinity, 47);
    expect(after.trueAffinity, beforeTrue + kEstrangementTrueAffinityDelta,
        reason: '真の好感度も -1 される');
    // ペナルティ後 lastInteractedDate が当日まで進んでいる（次の発火を防ぐ）
    expect(after.lastInteractedDate, DateTime(2026, 5, 10));
  });

  test('30 日未満では発火しない', () {
    final gs = GameState(
      currentDate: DateTime(2026, 4, 10),
      money: 999999,
      vitality: 100,
      vitalityMax: 100,
    );
    gs.recordEncounter(CharacterId.akari);
    gs.bumpAffinity(CharacterId.akari, 50);

    // 29 日だけ進める
    for (int i = 0; i < 29; i++) {
      advanceOneDay(gs);
    }
    expect(gs.characterStateOf(CharacterId.akari).affinity, 50,
        reason: '29 日では発火しない');
  });

  test('2 ヶ月（60 日）放置すると -6 になる（30 日ごとに -3 が 2 回）', () {
    final gs = GameState(
      currentDate: DateTime(2026, 4, 10),
      money: 999999,
      vitality: 100,
      vitalityMax: 100,
    );
    gs.recordEncounter(CharacterId.akari);
    gs.bumpAffinity(CharacterId.akari, 50);

    for (int i = 0; i < 60; i++) {
      advanceOneDay(gs);
    }
    // -3 が 2 回 = 50 - 6 = 44
    expect(gs.characterStateOf(CharacterId.akari).affinity, 44);
  });

  test('誘い行動で lastInteractedDate を更新すると疎遠タイマーがリセットされる', () {
    final gs = GameState(
      currentDate: DateTime(2026, 4, 10),
      money: 999999,
      vitality: 100,
      vitalityMax: 100,
    );
    gs.recordEncounter(CharacterId.akari);
    gs.bumpAffinity(CharacterId.akari, 50);

    // 25 日進めてから誘う → lastInteractedDate が更新される
    for (int i = 0; i < 25; i++) {
      advanceOneDay(gs);
    }
    // 残りの 4 枠を埋める前に「誘う」で交流をリセット。
    // ただし invite は slot を消費するため、新規日でリセットされた pending スロット
    // を使う。
    final beforeDate = gs.currentDate;
    gs.applyInviteOutcome(
      slot: SlotIndex.morning,
      target: CharacterId.akari,
      success: true,
    );
    expect(gs.characterStateOf(CharacterId.akari).lastInteractedDate, beforeDate);

    // この後さらに 25 日進めても発火しないはず
    // （beforeDate から 30 日経たないと発火しない）
    for (int i = 0; i < 25; i++) {
      advanceOneDay(gs);
    }
    // applyInviteOutcome で affinity +2 になっているのが基準
    final afterInvite = gs.characterStateOf(CharacterId.akari).affinity;
    // beforeDate から 25 日後 → まだ 30 日に達していない
    expect(afterInvite >= 50, isTrue,
        reason: '誘い後 25 日では疎遠ペナルティは発火しない');
  });

  test('未会いキャラには疎遠ペナルティが発火しない', () {
    final gs = GameState(
      currentDate: DateTime(2026, 4, 1),
      money: 999999,
      vitality: 100,
      vitalityMax: 100,
    );
    // 誰とも出会わない
    final beforeUta = gs.characterStateOf(CharacterId.uta).affinity;

    for (int i = 0; i < 60; i++) {
      advanceOneDay(gs);
    }
    expect(gs.characterStateOf(CharacterId.uta).affinity, beforeUta);
  });
}
