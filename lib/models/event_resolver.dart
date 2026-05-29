import 'dart:math';

import '../data/common_events.dart';
import '../data/confession_eve_events.dart';
import '../data/individual_events.dart';
import '../data/random_events.dart';
import 'actions.dart';
import 'calendar.dart';
import 'character.dart';
import 'character_state.dart';
import 'event.dart';

/// Sprint 08: イベント発火優先順位とランダム遭遇の確率判定。
///
/// 役割:
/// 1. 個別イベントの「今この枠で発火すべきもの」を 1 件返す（[resolveIndividual]）。
/// 2. 共通イベントの「今日の日付に発火するもの」を返す（[resolveCommon]）。
/// 3. 節目イベントの「今日が誰と過ごすか選択日か」を返す（[resolveMilestone]）。
/// 4. ランダム遭遇の発火判定（[shouldFireRandom]）と 1 件取得（[pickRandom]）。
///
/// 確率はモック化容易なように [Random] を引数で受ける形にする（DI）。
///
/// 仕様書 §7「ランダム遭遇イベントは 5〜15% の確率で発火」に対応：
/// 既定値として上限の 15% を採用する（spec の幅の中で「やや高め」を取り、
/// テストでは Random をモックして決定論的に検証する）。
class EventResolver {
  const EventResolver();

  /// 個別イベントの優先発火判定。
  ///
  /// 与えられた状態（出会い済キャラの affinityStage、現在日付、現在枠）から
  /// 「解放条件を満たし、まだ消化していない」個別イベントを 1 件返す。
  /// 該当が複数あった場合は宣言順（[IndividualEventCatalog.all]）の先頭を採用。
  ///
  /// [unlockedEventIds] には既に消化済みの id 集合を渡す（同じイベントの再発火防止）。
  GameEvent? resolveIndividual({
    required Map<CharacterId, CharacterState> characterStates,
    required DateTime currentDate,
    required SlotIndex slot,
    required Set<String> unlockedEventIds,
  }) {
    for (final ev in IndividualEventCatalog.all) {
      if (unlockedEventIds.contains(ev.id)) continue;
      final target = ev.target;
      if (target == null) continue;
      final cs = characterStates[target];
      if (cs == null || !cs.isMet) continue;
      final stageNeeded = ev.requiredAffinityStage ?? 1;
      if (cs.affinityStage < stageNeeded) continue;
      if (ev.requiredMonth != null && currentDate.month < ev.requiredMonth!) {
        continue;
      }
      if (ev.preferredSlot != null &&
          slot.index != ev.preferredSlot) {
        continue;
      }
      return ev;
    }
    return null;
  }

  /// 告白前夜イベントの優先発火判定。
  ///
  /// 個別イベントよりさらに高い優先度で発火する。発火条件は
  /// 「対象キャラが出会い済 + 表面好感度 ≥ 75 + 真の好感度 ≥ 15 + 未消化」。
  /// 該当が複数あった場合は宣言順（[ConfessionEveCatalog.all]）の先頭を採用。
  ///
  /// [unlockedEventIds] には対象キャラ自身の `unlockedEventIds` を渡す
  /// （他キャラの解放状況は無関係なので呼び出し側で絞っても良い）。
  GameEvent? resolveConfessionEve({
    required Map<CharacterId, CharacterState> characterStates,
    required Set<String> unlockedEventIds,
  }) {
    for (final ev in ConfessionEveCatalog.all) {
      if (unlockedEventIds.contains(ev.id)) continue;
      final target = ev.target;
      if (target == null) continue;
      final cs = characterStates[target];
      if (cs == null || !cs.isMet) continue;
      if (cs.affinity < ConfessionEveCatalog.kConfessionEveAffinityFloor) {
        continue;
      }
      if (cs.trueAffinity <
          ConfessionEveCatalog.kConfessionEveTrueAffinityFloor) {
        continue;
      }
      return ev;
    }
    return null;
  }

  /// 共通イベントの発火判定（年は無視し、month/day のみで照合）。
  ///
  /// `CommonEventCatalog.all` には節目イベントも含まれているため、
  /// ここでは category=common のみを対象にする（節目は [resolveMilestone] が拾う）。
  GameEvent? resolveCommon({
    required DateTime currentDate,
    required Set<String> unlockedEventIds,
  }) {
    for (final ev in CommonEventCatalog.all) {
      if (ev.category != EventCategory.common) continue;
      if (unlockedEventIds.contains(ev.id)) continue;
      final d = ev.fireDate;
      if (d == null) continue;
      if (d.month == currentDate.month && d.day == currentDate.day) {
        return ev;
      }
    }
    return null;
  }

  /// 節目イベント（クリスマス等）の発火判定。
  GameEvent? resolveMilestone({
    required DateTime currentDate,
    required Set<String> unlockedEventIds,
  }) {
    for (final ev in CommonEventCatalog.milestones) {
      if (unlockedEventIds.contains(ev.id)) continue;
      final d = ev.fireDate;
      if (d == null) continue;
      if (d.month == currentDate.month && d.day == currentDate.day) {
        return ev;
      }
    }
    return null;
  }

  /// 出勤枠（朝枠）でのランダム遭遇を発火するか。
  ///
  /// spec §7: 5〜15% の確率。Sprint 08 では上限 15% を採用。
  /// テストでは [Random] をモックして決定論的に検証する。
  bool shouldFireRandom(Random rng, {required DateTime currentDate, required SlotIndex slot}) {
    if (slot != SlotIndex.morning) return false;
    if (!isWeekday(currentDate)) return false;
    final roll = rng.nextInt(100); // 0..99
    return roll < kRandomEncounterPercentMax;
  }

  /// ランダム遭遇を 1 件抽選する。
  ///
  /// `Random.nextInt` で配列のインデックスを引く。
  GameEvent pickRandom(Random rng) {
    final list = RandomEventCatalog.all;
    final idx = rng.nextInt(list.length);
    return list[idx];
  }
}

/// ランダム遭遇の発火確率の最小・最大（％）。spec §7 由来。
///
/// 設計判断: Sprint 08 では「上限 15%」を採用してプレイ感を確保する。
/// 将来的に動的バランスが必要になったら [kRandomEncounterPercentMin] を
/// 使った可変式に置換する。
const int kRandomEncounterPercentMin = 5;
const int kRandomEncounterPercentMax = 15;
