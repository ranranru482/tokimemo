import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/data/common_events.dart';
import 'package:tokimemo/models/event.dart';
import 'package:tokimemo/models/event_resolver.dart';

void main() {
  group('CommonEventCatalog', () {
    test('共通イベントは 7 本以上ある', () {
      expect(CommonEventCatalog.all.length, greaterThanOrEqualTo(7));
    });

    test('全 ID がユニーク', () {
      final ids = CommonEventCatalog.all.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('健康診断（6/15）が含まれている', () {
      final hits = CommonEventCatalog.all.where((e) => e.id == 'common.health_check.jun').toList();
      expect(hits, hasLength(1));
      final hc = hits.single;
      expect(hc.fireDate?.month, 6);
      expect(hc.fireDate?.day, 15);
      expect(hc.category, EventCategory.common);
    });

    test('節目イベント (milestones) は少なくとも 1 本（クリスマス）', () {
      expect(CommonEventCatalog.milestones, isNotEmpty);
      final hasChristmas =
          CommonEventCatalog.milestones.any((e) => e.id == 'common.christmas.dec');
      expect(hasChristmas, isTrue);
    });
  });

  group('EventResolver.resolveCommon', () {
    test('6/15 で健康診断が発火する', () {
      const r = EventResolver();
      final ev = r.resolveCommon(
        currentDate: DateTime(2026, 6, 15),
        unlockedEventIds: <String>{},
      );
      expect(ev, isNotNull);
      expect(ev!.id, 'common.health_check.jun');
    });

    test('6/14 では発火しない', () {
      const r = EventResolver();
      final ev = r.resolveCommon(
        currentDate: DateTime(2026, 6, 14),
        unlockedEventIds: <String>{},
      );
      expect(ev, isNull);
    });

    test('同じ id が unlocked に入っていれば発火しない', () {
      const r = EventResolver();
      final ev = r.resolveCommon(
        currentDate: DateTime(2026, 6, 15),
        unlockedEventIds: <String>{'common.health_check.jun'},
      );
      expect(ev, isNull);
    });

    test('12/24 のクリスマスは milestones として resolveMilestone から返る', () {
      const r = EventResolver();
      final m = r.resolveMilestone(
        currentDate: DateTime(2026, 12, 24),
        unlockedEventIds: <String>{},
      );
      expect(m, isNotNull);
      expect(m!.id, 'common.christmas.dec');
      expect(m.category, EventCategory.milestone);
    });
  });
}
