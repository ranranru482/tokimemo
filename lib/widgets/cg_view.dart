import 'package:flutter/material.dart';

/// Sprint 08: CG（イベント立ち絵 / シーン背景）のプレースホルダ Widget。
///
/// 実画像が無いため、`themeColor` ベースのグラデーション背景に
/// タイトル文字を中央に置く構造で「らしい」見た目を作る。
///
/// 将来の差替えポイント:
/// 実画像導入時は、本 Widget の Container を
/// `Image.asset('assets/cg/${cgKey}.png', fit: BoxFit.cover)` に置き換える。
/// CG カタログ（`assets/cg/{cgKey}.png`）はイベント定義の `cgKey` と
/// 1:1 で対応させる命名規約。
///
/// 設計判断:
/// - サイズ系は呼び出し側で固定（サムネは [CgThumbnail]、全画面は [CgFullView]）。
/// - 未解放表示はシルエットを描画する [CgThumbnail.locked] を別経路で使う。
class CgView extends StatelessWidget {
  const CgView({
    super.key,
    required this.cgKey,
    required this.title,
    required this.themeColor,
    this.caption,
  });

  /// CG の論理キー（`cgKey`）。アセット差替え後の Image.asset パス算出にも使う。
  final String cgKey;

  /// 中央に重ねる短いタイトル文字（例:「冬の朝のカフェ」）。
  final String title;

  /// 背景のグラデーション基底色。通常はイベント対象キャラの themeColor を渡す。
  /// 共通イベントの場合は Theme.colorScheme.primary を渡す想定。
  final Color themeColor;

  /// 全画面表示時に下部に出すキャプション（任意）。
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: ValueKey('cgView.$cgKey'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColor.withValues(alpha: 0.85),
            themeColor.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Center(
              child: Text(
                title,
                key: ValueKey('cgView.$cgKey.title'),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            if (caption != null) ...[
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 8),
              Text(
                caption!,
                key: ValueKey('cgView.$cgKey.caption'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.95),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'CG: $cgKey',
              key: ValueKey('cgView.$cgKey.footer'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 未解放 CG の枠（シルエット + 鍵アイコン）。
///
/// Task #5: [onTap] が指定されていれば InkWell でラップしてタップ可能にする。
/// アルバム画面のヒントダイアログ用に使われる。後方互換のため省略可能。
/// 品質改善フェーズ: [iconOverride] でカテゴリ別のアウトラインアイコンに差替え可能。
class CgLockedTile extends StatelessWidget {
  const CgLockedTile({
    super.key,
    required this.cgKey,
    this.onTap,
    this.iconOverride,
  });

  final String cgKey;
  final VoidCallback? onTap;

  /// カテゴリヒント用のアイコン上書き（null なら `Icons.lock_outline`）。
  final IconData? iconOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = Container(
      key: ValueKey('cgLocked.$cgKey'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Center(
        child: Icon(
          iconOverride ?? Icons.lock_outline,
          color: theme.colorScheme.onSurfaceVariant,
          size: 32,
        ),
      ),
    );
    if (onTap == null) return tile;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: tile,
      ),
    );
  }
}
