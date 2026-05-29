import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/widgets/typewriter_text.dart';

void main() {
  group('TypewriterText.msPerCharFor', () {
    test('textSpeed 0.0 → 50ms/char', () {
      expect(TypewriterText.msPerCharFor(0.0), 50);
    });
    test('textSpeed 0.5 → 25ms/char', () {
      expect(TypewriterText.msPerCharFor(0.5), 25);
    });
    test('textSpeed 1.0 → 0ms/char', () {
      expect(TypewriterText.msPerCharFor(1.0), 0);
    });
    test('範囲外でも clamp される', () {
      expect(TypewriterText.msPerCharFor(-1.0), 50);
      expect(TypewriterText.msPerCharFor(2.0), 0);
    });
  });

  testWidgets('1 文字ずつ表示される', (tester) async {
    var completed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TypewriterText(
          text: 'こんにちは',
          textSpeed: 0.0, // 50ms/char
          onComplete: () => completed = true,
        ),
      ),
    ));
    // 初期フレームでは 0 文字表示。
    expect(find.text(''), findsOneWidget);
    expect(completed, isFalse);

    // 50ms 後に 1 文字目。
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('こ'), findsOneWidget);

    // さらに 50ms × 4 で全文表示。
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('こんにちは'), findsOneWidget);
    expect(completed, isTrue);
  });

  testWidgets('タップで全文を即時表示する', (tester) async {
    var completed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TypewriterText(
          text: 'こんにちは',
          textSpeed: 0.0,
          onComplete: () => completed = true,
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 50)); // 1 文字目
    expect(find.text('こ'), findsOneWidget);

    // タップで全文。
    await tester.tap(find.byKey(const ValueKey('typewriter.tapArea')));
    await tester.pump();
    expect(find.text('こんにちは'), findsOneWidget);
    expect(completed, isTrue);
  });

  testWidgets('textSpeed 1.0 では瞬時に全文表示', (tester) async {
    var completed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TypewriterText(
          text: 'すぐに表示される',
          textSpeed: 1.0,
          onComplete: () => completed = true,
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('すぐに表示される'), findsOneWidget);
    expect(completed, isTrue);
  });

  testWidgets('空文字でも即 onComplete', (tester) async {
    var completed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TypewriterText(
          text: '',
          textSpeed: 0.0,
          onComplete: () => completed = true,
        ),
      ),
    ));
    await tester.pump();
    expect(completed, isTrue);
  });

  testWidgets('text 変更で頭からやり直し', (tester) async {
    Widget build(String text) => MaterialApp(
          home: Scaffold(
            body: TypewriterText(
              text: text,
              textSpeed: 0.0,
            ),
          ),
        );
    await tester.pumpWidget(build('AAA'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('AAA'), findsOneWidget);

    await tester.pumpWidget(build('BBB'));
    await tester.pump();
    // 新規 text は 0 文字スタート。
    expect(find.text(''), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('BBB'), findsOneWidget);
  });
}
