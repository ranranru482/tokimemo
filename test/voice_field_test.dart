import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/character.dart';
import 'package:tokimemo/models/encounter.dart';
import 'package:tokimemo/models/event.dart';

void main() {
  group('DialogueLine.voiceKey', () {
    test('デフォルトで null', () {
      const line = DialogueLine(Expression.normal, 'こんにちは');
      expect(line.voiceKey, isNull);
    });

    test('voiceKey を指定して構築できる', () {
      const line = DialogueLine(
        Expression.normal,
        'こんにちは',
        voiceKey: 'voice.akari.001',
      );
      expect(line.voiceKey, 'voice.akari.001');
      expect(line.text, 'こんにちは');
      expect(line.expression, Expression.normal);
    });
  });

  group('EventLine.voiceKey', () {
    test('デフォルトで null', () {
      const line = EventLine(text: '社内の廊下に午後の光が差し込む。');
      expect(line.voiceKey, isNull);
    });

    test('voiceKey を指定して構築できる', () {
      const line = EventLine(
        speaker: CharacterId.akari,
        expression: Expression.smile,
        text: '今日も一日お疲れさま。',
        voiceKey: 'voice.akari.evening_001',
      );
      expect(line.voiceKey, 'voice.akari.evening_001');
      expect(line.speaker, CharacterId.akari);
      expect(line.expression, Expression.smile);
    });
  });
}
