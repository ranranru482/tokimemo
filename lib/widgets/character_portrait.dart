import 'package:flutter/material.dart';

import '../models/character.dart';

/// キャラの立ち絵を描画するプレースホルダ Widget。
///
/// 実イラスト導入前の仮描画として、以下の構成で「それっぽい」見た目を作る：
/// - 円形 Container（キャラ固有の `themeColor`）
/// - 中央にキャラ名のイニシャル（1文字）
/// - 右下に表情アイコン（Icons.sentiment_*）を重ねる
///
/// 将来拡張ポイント:
/// 実イラストに置き換える場合は [Character] に `assetPathFor(Expression)` のような
/// メソッドを追加し、本 Widget で `Image.asset(character.assetPathFor(expression))`
/// に切り替えるだけで差し替え可能な構造にしてある。
/// 表情 enum はそのままアセットファイル名のサフィックスに使える命名
/// （`normal / smile / troubled`）。
class CharacterPortrait extends StatelessWidget {
  const CharacterPortrait({
    super.key,
    required this.character,
    this.expression = Expression.normal,
    this.size = 96,
    this.isSilhouette = false,
  });

  /// 表示するキャラ。
  final Character character;

  /// 表情差分。
  ///
  /// `DialogueModal` から会話進行に合わせて切り替える。
  final Expression expression;

  /// 円形領域の直径（論理ピクセル）。
  ///
  /// カード用には small (≈56)、詳細画面では large (≈160) のように使い分ける。
  final double size;

  /// true の場合「？？？」シルエット表示にする。
  ///
  /// 未会いキャラのキャラ一覧カードで使う想定。背景色を一段暗くし、
  /// イニシャルを「?」に置換、表情アイコンも非表示にする。
  final bool isSilhouette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isSilhouette
        ? theme.colorScheme.onSurface.withValues(alpha: 0.18)
        : character.themeColor;
    final fg = isSilhouette
        ? theme.colorScheme.surface
        : Colors.white;
    final initialChar = isSilhouette ? '?' : character.initial;

    // Sprint 10: 表情切替時に AnimatedSwitcher でクロスフェード（200ms）。
    // 既存テストは `findsAtLeast(1)` を使う想定。transition 中は新旧 2 つの
    // expression キーが同時にツリーに存在し得る。
    final body = SizedBox(
      // 表情/シルエットが変わるたびにキーを変えることで、AnimatedSwitcher が
      // 新旧の widget を別々に扱える。
      key: ValueKey(
        'characterPortrait.${character.id.name}.'
        '${isSilhouette ? 'silhouette' : expression.name}',
      ),
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initialChar,
                style: TextStyle(
                  fontSize: size * 0.45,
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (!isSilhouette)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                key: ValueKey(
                  'characterPortrait.${character.id.name}.expression.${expression.name}',
                ),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Icon(
                  _expressionIcon(expression),
                  size: size * 0.22,
                  color: character.themeColor,
                ),
              ),
            ),
        ],
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: body,
      ),
    );
  }

  /// 表情 enum → Material アイコンの単純マッピング。
  /// 実イラスト導入後はこのメソッドは不要になる（または使われ続ける）。
  static IconData _expressionIcon(Expression expression) {
    switch (expression) {
      case Expression.normal:
        return Icons.sentiment_neutral;
      case Expression.smile:
        return Icons.sentiment_very_satisfied;
      case Expression.troubled:
        return Icons.sentiment_dissatisfied;
    }
  }
}
