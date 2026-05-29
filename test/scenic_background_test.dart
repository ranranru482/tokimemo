import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/widgets/scenic_background.dart';

void main() {
  group('resolvePalette: 季節判定', () {
    test('4 月は春', () {
      final p = ScenicBackground.resolvePalette(
        DateTime(2026, 4, 10),
        SlotIndex.morning,
      );
      expect(p.season, Season.spring);
    });
    test('7 月は夏', () {
      final p = ScenicBackground.resolvePalette(
        DateTime(2026, 7, 10),
        SlotIndex.morning,
      );
      expect(p.season, Season.summer);
    });
    test('10 月は秋', () {
      final p = ScenicBackground.resolvePalette(
        DateTime(2026, 10, 10),
        SlotIndex.morning,
      );
      expect(p.season, Season.autumn);
    });
    test('1 月は冬', () {
      final p = ScenicBackground.resolvePalette(
        DateTime(2027, 1, 10),
        SlotIndex.morning,
      );
      expect(p.season, Season.winter);
    });
  });

  group('resolvePalette: 時間帯判定', () {
    test('morning → 朝', () {
      final p = ScenicBackground.resolvePalette(
        DateTime(2026, 4, 1),
        SlotIndex.morning,
      );
      expect(p.timeOfDay, DayPhase.morning);
    });
    test('midday → 日中', () {
      final p = ScenicBackground.resolvePalette(
        DateTime(2026, 4, 1),
        SlotIndex.midday,
      );
      expect(p.timeOfDay, DayPhase.noon);
    });
    test('evening → 夕方', () {
      final p = ScenicBackground.resolvePalette(
        DateTime(2026, 4, 1),
        SlotIndex.evening,
      );
      expect(p.timeOfDay, DayPhase.evening);
    });
    test('night → 夜', () {
      final p = ScenicBackground.resolvePalette(
        DateTime(2026, 4, 1),
        SlotIndex.night,
      );
      expect(p.timeOfDay, DayPhase.night);
    });
    test('null → 朝', () {
      final p = ScenicBackground.resolvePalette(DateTime(2026, 4, 1), null);
      expect(p.timeOfDay, DayPhase.morning);
    });
  });

  test('朝と夜で支配色（topColor）が違う', () {
    final morning = ScenicBackground.resolvePalette(
      DateTime(2026, 7, 1),
      SlotIndex.morning,
    );
    final night = ScenicBackground.resolvePalette(
      DateTime(2026, 7, 1),
      SlotIndex.night,
    );
    expect(morning.topColor, isNot(night.topColor));
  });

  test('春と冬で季節色（midColor）が違う', () {
    final spring = ScenicBackground.resolvePalette(
      DateTime(2026, 4, 1),
      SlotIndex.morning,
    );
    final winter = ScenicBackground.resolvePalette(
      DateTime(2027, 1, 1),
      SlotIndex.morning,
    );
    expect(spring.midColor, isNot(winter.midColor));
  });

  testWidgets('ScenicBackground は時間帯ごとのキーで識別できる', (tester) async {
    Widget build(SlotIndex slot) => MaterialApp(
          home: Scaffold(
            body: ScenicBackground(
              currentDate: DateTime(2026, 4, 1),
              progressSlot: slot,
              transition: Duration.zero,
            ),
          ),
        );

    await tester.pumpWidget(build(SlotIndex.morning));
    expect(
      find.byKey(const ValueKey('scenicBackground.spring.morning')),
      findsOneWidget,
    );

    await tester.pumpWidget(build(SlotIndex.night));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('scenicBackground.spring.night')),
      findsOneWidget,
    );
  });
}
