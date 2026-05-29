import 'package:flutter/material.dart';

import '../app.dart';
import '../data/endings.dart';
import '../models/ending.dart';
import '../services/scene_bgm_router.dart';
import '../widgets/cg_view.dart';
import '../widgets/page_transitions.dart';
import '../widgets/typewriter_text.dart';

/// Sprint 09: エンディング再生画面。
///
/// 1 本の ED 本文を順に表示する。表示形式:
/// - 上部に CG プレースホルダ（[CgView]）
/// - 中央〜下部に本文を 1 行ずつ表示し、タップで次の行へ進める
/// - 最終行を超えると「クレジット」表示に切り替わり、画面下に「タイトルへ」が出る
///
/// 注意: Sprint 09 ではタイプライター演出は実装しない（Sprint 10 範囲）。
/// 1 タップで 1 行を全文表示するシンプルな構成にする。
class EndingScreen extends StatefulWidget {
  const EndingScreen({super.key, required this.kind, this.onComplete});

  final EndingKind kind;

  /// 「タイトルへ」ボタンが押された時のコールバック。
  /// 通常はタイトル画面まで戻す処理を渡す。
  final VoidCallback? onComplete;

  /// このエンディングを再生して図鑑にも記録するヘルパ。
  ///
  /// 戻り値の Future は「タイトルへ」ボタンが押されたときに解決する。
  /// 図鑑への記録は呼び出し側の責務（HomeScreen 側で archive.recordAchievement を呼ぶ）。
  static Future<void> show(BuildContext context,
      {required EndingKind kind, VoidCallback? onComplete}) {
    return Navigator.of(context).push<void>(
      fadeRoute<void>(
        (_) => EndingScreen(kind: kind, onComplete: onComplete),
        duration: const Duration(milliseconds: 400),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<EndingScreen> createState() => _EndingScreenState();
}

class _EndingScreenState extends State<EndingScreen> {
  late final EndingBody _body;
  int _lineIndex = 0;
  bool _showingCredit = false;
  bool _bgmRequested = false;

  @override
  void initState() {
    super.initState();
    _body = EndingBodyCatalog.bodyOf(widget.kind);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bgmRequested) return;
    _bgmRequested = true;
    // Sprint 11: エンディング進入で bgm.ending にクロスフェード。
    try {
      final audio = AppScope.of(context).audio;
      SceneBgmRouter.enterWithService(audio, BgmScene.ending);
    } catch (e) {
      debugPrint('[EndingScreen] AudioService unavailable: $e');
    }
  }

  void _next() {
    if (_showingCredit) return;
    setState(() {
      if (_lineIndex < _body.lines.length - 1) {
        _lineIndex += 1;
      } else {
        _showingCredit = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColor = _themeColorFor(theme, widget.kind);
    return Scaffold(
      key: ValueKey('endingScreen.${widget.kind.id}.root'),
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _body.title,
                key: ValueKey('endingScreen.${widget.kind.id}.title'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _body.subtitle,
                key: ValueKey('endingScreen.${widget.kind.id}.subtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 3,
                child: CgView(
                  cgKey: widget.kind.cgKey,
                  title: widget.kind.displayName,
                  themeColor: themeColor,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 4,
                child: GestureDetector(
                  key: ValueKey('endingScreen.${widget.kind.id}.tapArea'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _next,
                  child: SingleChildScrollView(
                    child: _showingCredit
                        ? _CreditBlock(
                            credit: _body.credit,
                            kindId: widget.kind.id,
                          )
                        : _LineBlock(
                            line: _body.lines[_lineIndex],
                            lineIndex: _lineIndex,
                            totalLines: _body.lines.length,
                            kindId: widget.kind.id,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_showingCredit)
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key:
                        ValueKey('endingScreen.${widget.kind.id}.toTitle'),
                    onPressed: () {
                      widget.onComplete?.call();
                      Navigator.of(context).maybePop();
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('タイトルへ'),
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: ValueKey('endingScreen.${widget.kind.id}.next'),
                    onPressed: _next,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('次へ'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _themeColorFor(ThemeData theme, EndingKind kind) {
    // 個別 ED は対象キャラのテーマ色、それ以外はアプリのシード色。
    final target = kind.target;
    if (target == null) return theme.colorScheme.primary;
    // キャラのテーマ色は CharacterRepository に持たせているが、循環参照を
    // 避けるためここでは AppScope 経由で取得しない（プレースホルダ色のみ）。
    // ed のサムネは EndingArchiveScreen 側でキャラ色を当てるため、本 Screen は
    // 主色で問題ない。
    return theme.colorScheme.primary;
  }
}

class _LineBlock extends StatelessWidget {
  const _LineBlock({
    required this.line,
    required this.lineIndex,
    required this.totalLines,
    required this.kindId,
  });

  final String line;
  final int lineIndex;
  final int totalLines;
  final String kindId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sprint 10: 設定の textSpeed と連動。AppScope が無いテスト用に try/catch。
    double textSpeed;
    try {
      textSpeed = AppScope.of(context).settings.textSpeed;
    } catch (e) {
      debugPrint('[EndingScreen] textSpeed fallback (AppScope unavailable): $e');
      textSpeed = 0.5;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${lineIndex + 1} / $totalLines',
            key: ValueKey('endingScreen.$kindId.progress'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          TypewriterText(
            key: ValueKey('endingScreen.$kindId.line.$lineIndex'),
            text: line,
            textSpeed: textSpeed,
            textStyle: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _CreditBlock extends StatelessWidget {
  const _CreditBlock({required this.credit, required this.kindId});

  final String credit;
  final String kindId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          credit,
          key: ValueKey('endingScreen.$kindId.credit'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// テスト/UI 補助: タイトル画面まで戻すためのコールバックを生成する。
VoidCallback popUntilTitle(BuildContext context) {
  final navigator = Navigator.of(context);
  return () {
    // タイトル画面（root）まで戻す。
    navigator.popUntil((route) => route.isFirst);
  };
}

/// AppScope 経由で EndingArchive に記録するヘルパ。
Future<void> recordEndingAchievement(BuildContext context, EndingKind kind,
    {DateTime? at}) async {
  final scope = AppScope.of(context);
  final arc = scope.endingArchive;
  if (arc == null) return; // テストでアーカイブ未注入のときはスキップ
  await arc.recordAchievement(kind, at ?? DateTime.now());
}
