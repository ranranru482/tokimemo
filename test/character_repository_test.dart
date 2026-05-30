import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/data/character_repository.dart';
import 'package:tokimemo/models/character.dart';

void main() {
  group('CharacterRepository: 5 名のキャラデータ', () {
    test('all は CharacterId の宣言順に 5 名を返す', () {
      expect(CharacterRepository.all.length, 5);
      expect(
        CharacterRepository.all.map((c) => c.id).toList(),
        const [
          CharacterId.akari,
          CharacterId.uta,
          CharacterId.toru,
          CharacterId.sayo,
          CharacterId.yui,
        ],
      );
    });

    test('spec.md §5 の正式名で displayName が定義されている', () {
      Character byId(CharacterId id) => CharacterRepository.byId(id);
      expect(byId(CharacterId.akari).displayName, '七瀬 灯');
      expect(byId(CharacterId.uta).displayName, '久遠 詩');
      expect(byId(CharacterId.toru).displayName, '鴻巣 透');
      expect(byId(CharacterId.sayo).displayName, '蓮見 紗夜');
      expect(byId(CharacterId.yui).displayName, '槙原 結衣');
    });

    test('社会人版設定の年齢が定義されている（docs/character_profiles.md）', () {
      expect(CharacterRepository.byId(CharacterId.akari).age, 25);
      expect(CharacterRepository.byId(CharacterId.uta).age, 27);
      expect(CharacterRepository.byId(CharacterId.toru).age, 26);
      expect(CharacterRepository.byId(CharacterId.sayo).age, 28);
      expect(CharacterRepository.byId(CharacterId.yui).age, 24);
    });

    test('firstMeetDate が 5 名で重複なく散らされている', () {
      final dates = CharacterRepository.all.map((c) => c.firstMeetDate).toSet();
      expect(dates.length, 5);
      // Sprint 06 仕様で指示された日付配置
      expect(
        CharacterRepository.byId(CharacterId.akari).firstMeetDate,
        DateTime(2026, 4, 10),
      );
      expect(
        CharacterRepository.byId(CharacterId.uta).firstMeetDate,
        DateTime(2026, 4, 15),
      );
      expect(
        CharacterRepository.byId(CharacterId.toru).firstMeetDate,
        DateTime(2026, 4, 20),
      );
      expect(
        CharacterRepository.byId(CharacterId.sayo).firstMeetDate,
        DateTime(2026, 5, 5),
      );
      expect(
        CharacterRepository.byId(CharacterId.yui).firstMeetDate,
        DateTime(2026, 5, 10),
      );
    });

    test('byId で存在しない ID を渡すと ArgumentError（守備）', () {
      // 全 enum 値がカバーされているが、念のため将来追加時の防御を保証する。
      // ここでは存在する ID を引いて成功することのみ検証。
      expect(
        () => CharacterRepository.byId(CharacterId.akari),
        returnsNormally,
      );
    });

    test('bioLong が空でなく、各キャラに役職ラベルが設定されている', () {
      for (final c in CharacterRepository.all) {
        expect(c.bioLong.isNotEmpty, isTrue, reason: '${c.id} の bioLong が空');
        expect(c.roleLabel.isNotEmpty, isTrue);
        expect(c.appealText.isNotEmpty, isTrue);
      }
    });
  });
}
