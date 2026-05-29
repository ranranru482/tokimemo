import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/cg_state.dart';

void main() {
  group('CgLibrary', () {
    test('初期状態は空', () {
      final lib = CgLibrary();
      expect(lib.unlockedCount, 0);
      expect(lib.has('cg.example'), isFalse);
    });

    test('unlock すると has が true、unlockedCount が増える', () {
      final lib = CgLibrary();
      var notified = 0;
      lib.addListener(() => notified++);
      lib.unlock('cg.example');
      expect(lib.has('cg.example'), isTrue);
      expect(lib.unlockedCount, 1);
      expect(notified, 1);
    });

    test('同じ key の unlock は冪等（listener 通知も追加で起きない）', () {
      final lib = CgLibrary();
      lib.unlock('cg.a');
      var notified = 0;
      lib.addListener(() => notified++);
      lib.unlock('cg.a');
      expect(notified, 0, reason: '冪等なら通知を増やさない');
      expect(lib.unlockedCount, 1);
    });

    test('clear すると空に戻る', () {
      final lib = CgLibrary();
      lib.unlock('cg.a');
      lib.unlock('cg.b');
      expect(lib.unlockedCount, 2);
      lib.clear();
      expect(lib.unlockedCount, 0);
    });

    test('snapshot / restoreFrom で往復できる', () {
      final lib = CgLibrary();
      lib.unlock('cg.a');
      lib.unlock('cg.b');
      final snap = lib.snapshot();
      final other = CgLibrary();
      other.restoreFrom(snap);
      expect(other.has('cg.a'), isTrue);
      expect(other.has('cg.b'), isTrue);
      expect(other.unlockedCount, 2);
    });

    test('空 key の unlock は無視される', () {
      final lib = CgLibrary();
      lib.unlock('');
      expect(lib.unlockedCount, 0);
    });
  });
}
