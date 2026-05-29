import 'package:flutter/material.dart';

import '../models/actions.dart';

/// Sprint 10: ホーム画面の背景に置く時間帯 + 季節グラデーション。
///
/// 仕様書 Sprint 10「季節背景の昼夜変化」「ホーム画面の背景が時間帯（朝・
/// 日中・夕方・夜）で変化する」に対応。
///
/// 設計:
/// - 依存パッケージ追加禁止のため、`AnimatedContainer` + `LinearGradient` で実装。
/// - 季節は `currentDate.month` から算出（3-5:春 / 6-8:夏 / 9-11:秋 / 12-2:冬）。
/// - 時間帯は `progressSlot`（現在進行中のスロット）で決定。
///   - morning → 朝 / midday → 日中 / evening → 夕方 / night → 夜
///   - null（テスト等）の場合は morning 相当を採用。
/// - グラデーション色の決定は [resolvePalette] 純粋関数。テストはこれを直接叩く。
///
/// 配置:
/// HomeScreen の Stack の最下層に置く。`Positioned.fill` でラップする想定。
class ScenicBackground extends StatelessWidget {
  const ScenicBackground({
    super.key,
    required this.currentDate,
    this.progressSlot,
    this.transition = const Duration(milliseconds: 500),
  });

  /// ゲーム内の現在日付。
  final DateTime currentDate;

  /// 進行中のスロット（null なら朝相当）。
  ///
  /// HomeScreen から「次に未実行となっている SlotIndex」を渡す想定。
  /// 全枠 done の場合は night を渡せば「日が暮れた」表現に近づく。
  final SlotIndex? progressSlot;

  /// 季節/時間帯切替時のクロスフェード時間。
  final Duration transition;

  @override
  Widget build(BuildContext context) {
    final palette = resolvePalette(currentDate, progressSlot);
    return AnimatedContainer(
      key: ValueKey('scenicBackground.${palette.season.name}.${palette.timeOfDay.name}'),
      duration: transition,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            palette.topColor,
            palette.midColor,
            palette.bottomColor,
          ],
        ),
      ),
    );
  }

  /// 月 + スロットからパレットを純粋関数で算出する（テスト対象）。
  static ScenicPalette resolvePalette(DateTime date, SlotIndex? slot) {
    final season = _seasonOf(date.month);
    final tod = _timeOfDayOf(slot);
    return ScenicPalette(
      season: season,
      timeOfDay: tod,
      topColor: _topColorFor(tod, season),
      midColor: _midColorFor(tod, season),
      bottomColor: _bottomColorFor(tod, season),
    );
  }
}

/// 季節の区分。
enum Season {
  spring(label: '春'),
  summer(label: '夏'),
  autumn(label: '秋'),
  winter(label: '冬');

  const Season({required this.label});
  final String label;
}

/// 時間帯の区分。
enum DayPhase {
  morning(label: '朝'),
  noon(label: '日中'),
  evening(label: '夕方'),
  night(label: '夜');

  const DayPhase({required this.label});
  final String label;
}

/// 季節 × 時間帯のパレット。
class ScenicPalette {
  const ScenicPalette({
    required this.season,
    required this.timeOfDay,
    required this.topColor,
    required this.midColor,
    required this.bottomColor,
  });

  final Season season;
  final DayPhase timeOfDay;
  final Color topColor;
  final Color midColor;
  final Color bottomColor;
}

Season _seasonOf(int month) {
  if (month >= 3 && month <= 5) return Season.spring;
  if (month >= 6 && month <= 8) return Season.summer;
  if (month >= 9 && month <= 11) return Season.autumn;
  return Season.winter;
}

DayPhase _timeOfDayOf(SlotIndex? slot) {
  switch (slot) {
    case SlotIndex.morning:
    case null:
      return DayPhase.morning;
    case SlotIndex.midday:
      return DayPhase.noon;
    case SlotIndex.evening:
      return DayPhase.evening;
    case SlotIndex.night:
      return DayPhase.night;
  }
}

// ===========================================================================
// 季節 × 時間帯の配色テーブル
// ===========================================================================
//
// すべて手動で選定した HSV ベースの大人びた配色。
// 季節アクセントは midColor で表現し、時間帯の支配色は topColor / bottomColor。
//
// 春（3-5月）: 桜色アクセント
// 夏（6-8月）: 緑/青アクセント
// 秋（9-11月）: 朱/茶アクセント
// 冬（12-2月）: 銀/紺アクセント

Color _topColorFor(DayPhase tod, Season season) {
  switch (tod) {
    case DayPhase.morning:
      return const Color(0xFFFFD9B0); // 薄い橙
    case DayPhase.noon:
      return const Color(0xFFB0DCFF); // 明るい水色
    case DayPhase.evening:
      return const Color(0xFFFFB07A); // 橙
    case DayPhase.night:
      return const Color(0xFF1B2440); // 紺
  }
}

Color _midColorFor(DayPhase tod, Season season) {
  // 季節アクセントを中央に置く。
  switch (season) {
    case Season.spring:
      return const Color(0xFFFFC1D8); // 桜色
    case Season.summer:
      return const Color(0xFFA8D8C8); // 若葉/水色寄りの緑
    case Season.autumn:
      return const Color(0xFFD89B6A); // 朱/茶
    case Season.winter:
      return const Color(0xFFC6CFE0); // 銀
  }
}

Color _bottomColorFor(DayPhase tod, Season season) {
  switch (tod) {
    case DayPhase.morning:
      return const Color(0xFFB0D8F0); // 薄い水色
    case DayPhase.noon:
      return const Color(0xFFF4F8FB); // 白
    case DayPhase.evening:
      return const Color(0xFF6A4980); // 紫
    case DayPhase.night:
      return const Color(0xFF050811); // 黒寄り
  }
}
