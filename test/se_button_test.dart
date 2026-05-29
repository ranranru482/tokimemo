import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokimemo/models/actions.dart';
import 'package:tokimemo/models/audio_keys.dart';
import 'package:tokimemo/screens/settings_screen.dart';
import 'package:tokimemo/screens/title_screen.dart';
import 'package:tokimemo/services/audio_service.dart';
import 'package:tokimemo/widgets/action_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('タイトル「はじめから」タップで se.confirm が記録される', (tester) async {
    final settings = await createTestSettings();
    final audio = LoggingAudioService();
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const TitleScreen(),
        settings: settings,
        audio: audio,
      ),
    );
    // 初期入場で bgm.title もリクエストされている前提（受入基準1の補完）
    final initialBgmKeys = audio.history
        .where((c) => c.kind == AudioCallKind.bgm)
        .map((c) => c.key)
        .toList();
    expect(initialBgmKeys, contains(AudioKeys.bgmTitle));

    await tester.tap(find.byKey(const ValueKey('title.startButton')));
    await tester.pump();
    final seKeys = audio.history
        .where((c) => c.kind == AudioCallKind.se)
        .map((c) => c.key)
        .toList();
    expect(seKeys, contains(AudioKeys.seConfirm));
  });

  testWidgets('設定画面の戻るボタンで se.cancel が記録される', (tester) async {
    final settings = await createTestSettings();
    final audio = LoggingAudioService();
    await tester.pumpWidget(
      wrapWithAppScope(
        child: const SettingsScreen(),
        settings: settings,
        audio: audio,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('settings.backButton')));
    await tester.pump();
    final seKeys = audio.history
        .where((c) => c.kind == AudioCallKind.se)
        .map((c) => c.key)
        .toList();
    expect(seKeys, contains(AudioKeys.seCancel));
  });

  testWidgets('行動シートで決定すると se.confirm が記録される', (tester) async {
    final settings = await createTestSettings();
    final audio = LoggingAudioService();
    await tester.pumpWidget(
      wrapWithAppScope(
        settings: settings,
        audio: audio,
        child: const _ActionSheetHost(),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('host.openSheet')));
    await tester.pumpAndSettle();
    // 読書 (kHomeActionList の先頭) を選択
    await tester.tap(
      find.byKey(ValueKey('actionSheet.action.${ActionKind.read.name}')),
    );
    await tester.pumpAndSettle();

    final seKeys = audio.history
        .where((c) => c.kind == AudioCallKind.se)
        .map((c) => c.key)
        .toList();
    expect(seKeys, contains(AudioKeys.seConfirm));
  });
}

/// テスト専用のホスト Widget。シートを開く Button を提供する。
class _ActionSheetHost extends StatelessWidget {
  const _ActionSheetHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const ValueKey('host.openSheet'),
          onPressed: () => showActionSheet(
            context,
            slotLabel: '朝',
            actions: kHomeActionList,
          ),
          child: const Text('open'),
        ),
      ),
    );
  }
}
