// Hotfix 2026-05-18: Flutter 標準 counter テンプレが残っていたため、
// 本プロジェクトに合わせて削除しスモークテストのみ残す。
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smoke: 1 + 1 == 2', () {
    expect(1 + 1, 2);
  });
}
