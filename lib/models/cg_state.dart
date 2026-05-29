import 'package:flutter/foundation.dart';

/// Sprint 08: 解放済み CG の状態を管理する ChangeNotifier。
///
/// `GameState` に統合され、イベント完了時に [unlock] が呼ばれる。
/// メモリーアルバム画面 ([AlbumScreen]) が `AnimatedBuilder` で購読する。
///
/// セーブ/ロードは Sprint 09 で対応する：
/// 現状は [snapshot] / [restoreFrom] のスナップショット API のみ提供して、
/// `GameState.resetToStart` 時のクリアに使う。
class CgLibrary extends ChangeNotifier {
  CgLibrary({Set<String>? initial})
      : _unlocked = <String>{...?initial};

  final Set<String> _unlocked;

  /// CG を解放する。既に解放済みなら何もしない（[notifyListeners] も呼ばない）。
  void unlock(String cgKey) {
    if (cgKey.isEmpty) return;
    if (_unlocked.add(cgKey)) {
      notifyListeners();
    }
  }

  /// 指定 CG が解放済みか。
  bool has(String cgKey) => _unlocked.contains(cgKey);

  /// 解放済 CG のスナップショット（読み取り専用）。
  Set<String> get unlockedKeys => Set<String>.unmodifiable(_unlocked);

  /// 解放済 CG 数。
  int get unlockedCount => _unlocked.length;

  /// 全クリア（タイトル「はじめから」用）。
  void clear() {
    if (_unlocked.isEmpty) return;
    _unlocked.clear();
    notifyListeners();
  }

  /// セーブ用スナップショット。
  List<String> snapshot() => _unlocked.toList(growable: false);

  /// ロード用復元。既存内容はクリアしてから注入する。
  void restoreFrom(Iterable<String> keys) {
    _unlocked
      ..clear()
      ..addAll(keys);
    notifyListeners();
  }
}
