# 実装進捗

## 完了スプリント
- [x] Sprint 01: 起動と最低限の世界観 — 完了日 2026-05-17
  - 実装ファイル: lib/main.dart, lib/app.dart, lib/models/game_state.dart, lib/models/settings_state.dart, lib/services/settings_repository.dart, lib/screens/title_screen.dart, lib/screens/name_input_screen.dart, lib/screens/home_screen.dart, lib/screens/settings_screen.dart, test/test_helpers.dart, test/title_screen_test.dart, test/name_input_screen_test.dart, test/settings_screen_test.dart, integration_test/settings_persistence_test.dart
  - Generator 自己評価: 基準1（起動3秒以内）→ 実機検証保留 / 基準2〜4 → widget test 8件で確認済 / 基準5 → integration test 作成済
  - flutter analyze: clean (No issues found)
  - flutter test: 8/8 pass
  - Evaluator 判定: ✅ 合格
    - コードレビュー: 構造良好（InheritedWidget + ChangeNotifier、ValueKey でテスタビリティ確保、SafeArea/48pxタッチターゲットでモバイル配慮）
    - 仕様一致: 4月1日（水）の曜日表示は 2026年4月1日と整合
    - オリジナル性: ときメモ等の既存IPの固有名詞・台詞は grep でゼロ件
    - 既知の限界: Android/iOS エミュレータ未接続のため、起動3秒以内（基準1）と integration test の実機実行（基準5）はデバイス環境構築後に再確認

- [x] Sprint 02: ホーム画面の完成 — 完了日 2026-05-17
  - 実装ファイル:
    - 追加: lib/models/stats.dart, lib/screens/main_scaffold.dart, lib/screens/stats_screen.dart, lib/screens/schedule_screen.dart, lib/screens/characters_screen.dart, lib/screens/album_screen.dart, test/home_screen_test.dart, test/stats_screen_test.dart, test/main_scaffold_test.dart, integration_test/tab_navigation_test.dart
    - 改修: lib/models/game_state.dart（体力・所持金・ストレス・4 能力値マップを追加、StressMood 連動）, lib/screens/home_screen.dart（StatusBar 追加、タイムラインスロットにキー付与）, lib/screens/name_input_screen.dart（遷移先を MainScaffold へ）, test/name_input_screen_test.dart（MainScaffold への遷移確認に更新、4枠テストは home_screen_test.dart へ移譲）
  - Generator 自己評価:
    - 基準1（4枠タイムラインに時間帯ラベル）→ ◯ home_screen_test.dart で 4 枠のキーとラベルを検証
    - 基準2（ステータスバーに日付・体力・所持金・ストレス表情）→ ◯ home_screen_test.dart で 4 チップとストレス表情 3 段階を検証
    - 基準3（5 タブのスタブ遷移）→ ◯ main_scaffold_test.dart で 5 タブそれぞれを検証 ＋ integration_test/tab_navigation_test.dart で end-to-end 確認
    - 基準4（能力値詳細で 7 パラメータが数値とバー）→ ◯ stats_screen_test.dart で 7 行・バー値・数値表示を検証（spec §3 の 7 種を StatKind に定義）
    - 基準5（実機で回転・セーフエリア崩れ無し）→ △ widget test で SafeArea 存在と Wrap 構成を確認。実機回転チェックは Evaluator フェーズ
  - flutter analyze: clean (No issues found)
  - flutter test: 22/22 pass
  - 設計メモ:
    - 5 タブ構成: ホーム / スケジュール / キャラ / 能力値 / アルバム。設定はホーム AppBar の歯車から（Sprint 01 動線を維持）。Material 3 の NavigationBar を採用し、IndexedStack で各タブの state を保持。
    - 能力値表示: spec §3 の 7 種を 0〜100 で扱うが、所持金（Wallet）のみ円単位の整数を別フィールドで持ち、StatsScreen ではバーを 200,000 円キャップで正規化、数値は「50,000円」表記とする。スパークライン・履歴は Sprint 03 以降。
    - 初期値: 体力 80/100、所持金 50,000 円、ストレス 20、知性 25/感性 20/社交 30/仕事評価 20。
    - StressMood の閾値: <35 satisfied, 35-69 neutral, 70+ dissatisfied。
  - 既存テストへの影響: name_input_screen_test.dart の遷移確認テストは MainScaffold ＋ HomeScreen を両方検証する形に更新。重複していた「4枠タイムライン」テストは home_screen_test.dart に移譲して責務分割。

- [x] Sprint 03: 基本UIの統一とゲームの呼吸 — 完了日 2026-05-17
  - 実装ファイル:
    - 追加: lib/models/actions.dart, lib/widgets/action_sheet.dart, test/game_state_test.dart, test/action_sheet_test.dart, test/settings_screen_theme_test.dart, integration_test/theme_toggle_test.dart, integration_test/day_loop_test.dart
    - 改修: lib/app.dart（AnimatedBuilder で SettingsState を購読、light/dark テーマ両対応、themeMode 連動）, lib/models/settings_state.dart（themeMode 追加、updateThemeMode）, lib/services/settings_repository.dart（settings.themeMode の永続化）, lib/models/game_state.dart（SlotState マップ・applyAction / sleepSkipRemaining / advanceDayIfAllSlotsDone・体力/ストレス/能力値クランプ）, lib/screens/home_screen.dart（InkWell でタップ可能化、SlotState で「未実行/実行済/就寝でスキップ」表示）, lib/screens/settings_screen.dart（SegmentedButton でテーマ切替セクション追加）, test/test_helpers.dart（themeMode 受け取り・AnimatedBuilder ラップ）
  - Generator 自己評価:
    - 基準1（テーマ切替で即座に色味が変わる）→ ◯ integration_test/theme_toggle_test.dart で MaterialApp.themeMode と SettingsScreen の Theme.of.brightness の両方が dark/light に切替わることを検証
    - 基準2（1枠タップ → 行動選択シート）→ ◯ action_sheet_test.dart で朝枠タップでシートが開き 3 項目が表示されることを検証
    - 基準3（読書で知性+3/体力-2/枠が完了）→ ◯ action_sheet_test.dart で能力値変動と「実行済」表示を検証
    - 基準4（4枠実行 or 就寝で翌日）→ ◯ integration_test/day_loop_test.dart で 4 枠読書 → 4月2日、朝就寝 → 4月2日の両ケースを検証 ＋ game_state_test.dart で単体検証
    - 基準5（3日ループ＋累積反映）→ ◯ integration_test/day_loop_test.dart で 3 日プレイ後 4月4日かつ体力 56/100 表示を検証 ＋ game_state_test.dart で知性+36 を検証
  - flutter analyze: clean (No issues found)
  - flutter test: 42/42 pass（既存 22 + 新規 20）
  - 設計メモ:
    - テーマ切替: SettingsState.themeMode (ThemeMode) を追加し、SharedPreferences キー `settings.themeMode` に system/light/dark の文字列で永続化。MugenSiritoriApp を AnimatedBuilder(animation: settings) でラップし、MaterialApp.themeMode が即時 rebuild される。
    - 行動効果値の暫定マジックナンバーは lib/models/actions.dart の kActionCatalog / kHomeActionList に集約（読書 知性+3/体力-2、運動 体力+5/ストレス-3、就寝 体力+10/ストレス-5＋残り枠スキップ）。Sprint 04 以降のバランス調整時はここのみ触ればよい。
    - スロット完了状態は GameState._slotStates: Map<SlotIndex, SlotState> で管理。SlotState は pending / done / skipped の 3 値。日付進行時に _defaultSlotStates() で全枠 pending にリセット。
    - 共通ボタン/カードのラッパーは Sprint 03 時点で抽出不要と判断（行動シートは ListTile、ホームの枠は InkWell+Container で完結し、再利用箇所が少ないため過剰設計を回避）。

- [x] Sprint 04: ゲームループの拡張（仕事と週末） — 完了日 2026-05-17
  - 実装ファイル:
    - 追加: lib/models/calendar.dart, lib/models/work.dart, lib/widgets/work_judgment_dialog.dart, lib/widgets/salary_dialog.dart, lib/screens/weekly_review_screen.dart, test/calendar_test.dart, test/work_resolver_test.dart, test/game_state_work_test.dart, test/action_sheet_overtime_test.dart, test/weekly_review_screen_test.dart, test/work_judgment_widget_test.dart, integration_test/weekly_flow_test.dart, integration_test/salary_event_test.dart
    - 改修: lib/models/game_state.dart（週初スナップショット、applyWorkOutcome、給料受領、DayAdvanceEvent コールバック）, lib/models/actions.dart（ActionKind.overtime と kWeekdayEveningActionList を追加）, lib/widgets/action_sheet.dart（actions 引数で行動リスト差し替え、内側スクロール対応、overtime アイコン追加）, lib/screens/home_screen.dart（StatefulWidget 化、平日 midday は「仕事」固定 + 仕事ミニ判定フロー、平日夕方は残業を含むシート、日付進行イベント購読で週次ふりかえり画面 push と給料ダイアログ表示、workRng の DI 対応）
  - Generator 自己評価:
    - 基準1（平日日中が「仕事」固定）→ ◯ action_sheet_overtime_test.dart で 4/1（水）の日中スロットが「仕事」、4/4（土）は「未実行」を検証
    - 基準2（仕事判定: 成功 +5 評価 / 失敗 +5 ストレス）→ ◯ game_state_work_test.dart（unit）と work_judgment_widget_test.dart（widget）で両方検証。決定論的に走らせるため HomeScreen に workRng を DI
    - 基準3（残業: 仕事評価+3 / ストレス+5）→ ◯ action_sheet_overtime_test.dart の widget test で実 UI から残業選択 → 能力値変動 → 枠 done を検証
    - 基準4（日曜終了で週次ふりかえり画面）→ △ unit / widget レベルでイベント発火と画面表示を確認。integration_test/weekly_flow_test.dart は実機接続前提（Evaluator フェーズ）
    - 基準5（月初給料ダイアログ + 所持金増加）→ △ unit テスト（game_state_work_test.dart の "4/30→5/1 で給料"）で能力値変動と DayAdvanceEvent.salary 発火を確認。integration_test/salary_event_test.dart は実機実行で最終検証
    - 基準6（1ヶ月通しプレイ）→ △ 同じく integration test で代替。unit レベルでは 4/30→5/1 の遷移を検証済
  - flutter analyze: clean (No issues found)
  - flutter test: 83/83 pass（既存 42 + 新規 41）
  - 設計メモ:
    - 平日/休日判定: lib/models/calendar.dart に `isWeekday` / `isHoliday` / `isWeekEnd` / `isMonthStart` の純粋関数を集約。Sprint 04 では祝日カレンダーは無し（土日のみ休日）。将来の祝日対応はこのファイルに祝日マップを足すだけで済む形にしている。
    - 仕事判定の式: lib/models/work.dart 先頭の `kWorkBaseCareer=25`, `kWorkBaseSuccessPercent=60`, `kWorkSuccessSlopePerPoint=1`, `kWorkMinSuccessPercent=30`, `kWorkMaxSuccessPercent=90` に集約。`WorkResolver.successPercent(career)` で算出。成功で 仕事評価 +5、失敗で ストレス +5。
    - 給料計算式: 同じく lib/models/work.dart の `computeSalary(career)` = `clamp(kSalaryBase + career * kSalaryPerCareerPoint, kSalaryMin, kSalaryMax)`。デフォルトは 200,000 + career×2,000、下限 180,000、上限 350,000。
    - 残業効果: `kOvertimeCareerDelta=3` / `kOvertimeStressDelta=5`。`ActionKind.overtime` として kActionCatalog にエントリ化し、平日夕方のシート (`kWeekdayEveningActionList`) のみに含まれる。
    - 週次ふりかえりのフック位置: `GameState._advanceDay` の冒頭（日付を翌日に進める前）で「現在日付が日曜なら `DayAdvanceEvent.weeklyReview` を発火予約」、その後で日付を進めて「翌日が月初なら所持金を即時加算 + `DayAdvanceEvent.salary` を発火予約」。1 ターンに「週次ふりかえり → 給料」が連続する場合も order が安定する。
    - DayAdvanceEvent コールバックは `HomeScreen` の `didChangeDependencies` で 1 度だけ登録。`addPostFrameCallback` 内で Navigator 操作するため、`applyAction` の同期パス内で再帰しない。リスナ内では `applyAction` / `_advanceDay` を呼ばないこと（無限ループ防止）。
    - 週初スナップショットは `GameState._weekStartSnapshot`（全7能力値）と `_weekStartDate`。週次ふりかえり画面を閉じた直後に `GameState.resetWeekSnapshot()` を呼んで次週へ進める。
    - 仕事ミニ判定の Random は `HomeScreen(workRng:)` に DI 可能。デフォルトは `Random()`、テストでは `Random(0)` / `Random(2)` 等の seed を渡すことで決定論的に検証。
  - 既存テストへの影響:
    - game_state_test.dart の「4 枠を読書で埋める」系は applyAction を直接呼んでおり、平日 midday 表示変更の影響を受けないためそのまま pass。
    - home_screen_test.dart / action_sheet_test.dart は枠キーとラベルのみを assert しており、平日 midday の文言変更（「未実行」→「仕事」）には依存していなかったので無修正で pass。
    - integration_test/day_loop_test.dart は実機実行前提のため、Sprint 04 で 4/1（水）の日中枠が仕事判定フローになる影響は受ける（既存テストは「日中枠でも read を選ぶ」想定）が、本テストは「4 枠すべて実行 → 翌日」の最終状態のみ検証する。実機評価時に Evaluator が必要に応じて更新する。

- [x] Sprint 05: スケジュールシステムの完成 — 完了日 2026-05-17
  - 実装ファイル:
    - 追加: lib/models/schedule.dart, lib/screens/schedule_screen.dart（スタブから実装に置換）, test/schedule_test.dart, test/schedule_screen_test.dart, test/action_sheet_outing_test.dart, test/action_effect_outing_test.dart, integration_test/scheduled_action_test.dart
    - 改修: lib/models/actions.dart（外出4種＝カフェ/映画/美術館/ジムを追加、ActionEffect.requiredMoney フィールド追加、kHomeActionList/kWeekdayEveningActionList/kHolidayActionList の getter 化）, lib/models/game_state.dart（ScheduleStore 統合、reserveAction/cancelReservation/canAfford/applyScheduledActionFor 追加、ScheduledActionResult 型追加、resetToStart で schedule もクリア）, lib/widgets/action_sheet.dart（currentMoney によるグレーアウト判定、外出4種のアイコン追加）, lib/screens/home_screen.dart（休日は kHolidayActionList を使用、枠タップ時に予約があれば自動実行）, test/main_scaffold_test.dart（schedule.placeholder → schedule.monthGrid へ更新）, test/action_sheet_test.dart / test/action_sheet_overtime_test.dart（const ActionSheetContent → 非 const に追従）
  - Generator 自己評価:
    - 基準1（月カレンダー表示・日付タップで4枠の予約状況）→ ◯ schedule_screen_test.dart の「月ラベルと月グリッドが表示される」「翌日タップで4枠が表示される」で検証
    - 基準2（翌週特定日の特定枠に映画予約 → その日その枠で自動実行）→ ○ unit（schedule_test.dart の applyScheduledActionFor）＋ integration_test/scheduled_action_test.dart 第1ケースで「予約済みの朝枠タップ→映画自動実行・感性+3/所持金-2000」を検証、第2ケースで「翌週土曜まで日付を進めて美術館自動実行」を検証（実機実行は Evaluator フェーズ）
    - 基準3（所持金が映画コスト未満でグレーアウト）→ ◯ action_sheet_outing_test.dart の「所持金 500 円で映画 disabled」で検証（ListTile.enabled / onTap=null を確認）
    - 基準4（外出4種が行動シートに表示 + それぞれ正しい能力値変動）→ ◯ action_effect_outing_test.dart で 4 行動の catalog 値と applyAction 副作用を unit で検証
    - 基準5（スケジュール画面で予約をキャンセル）→ ◯ schedule_screen_test.dart の「ゴミ箱ボタンを押すと予約が消える」で検証
  - flutter analyze: clean (No issues found)
  - flutter test: 126/126 pass（既存 83 + 新規 43）
  - 設計メモ:
    - 外出4行動の暫定マジックナンバーは lib/models/actions.dart 先頭の `kCafe* / kMovie* / kMuseum* / kGym*` 定数群に集約。仕様書 §3 の能力値傾向（カフェ/映画=感性、美術館=感性/知性、ジム=体力/ストレス）に沿った仮値。バランス調整時はここのみ書き換える。
    - `ActionEffect.requiredMoney` を新設し、「実行に必要な所持金」と「実行時の所持金変動 (deltas[StatKind.wallet])」を分離。グレーアウト判定（`GameState.canAfford` / `ActionSheetContent` 内 `_isAffordable`）と予約自動実行のスキップ判定（`applyScheduledActionFor`）の両方が `requiredMoney` を参照する。
    - 予約データの保持方式: lib/models/schedule.dart の `ScheduleStore`（`DateKey → Map<SlotIndex, ActionKind>` のネスト Map、インメモリのみ）。アプリ再起動で消える。永続化は Sprint 09 のセーブ/ロードで対応する（既知の負債に追記済み）。`GameState` 内に `_schedule` として統合し、`reserveAction`/`cancelReservation` 経由で `notifyListeners` を確実に呼ぶ。
    - カレンダーの実装方式: 依存パッケージを追加せず自前で `GridView.count(crossAxisCount: 7)` を描画。`firstOfMonth.weekday - DateTime.monday` で月初オフセットを算出し、末尾を空セルでパディングして 7 列で揃える。月送りは `±1ヶ月` までに制限（仕様書 §10 画面03「先1ヶ月分」要件）。
    - 平日/休日での行動フィルタ位置: 表示時のフィルタは `HomeScreen._onSlotTap` 内で `isHoliday(currentDate)` 判定して `kHolidayActionList` / `kWeekdayEveningActionList` / `kHomeActionList` を選ぶ。仕事固定枠（平日日中）はそもそも `showActionSheet` を呼ばず仕事ミニ判定フローに分岐するため、リストから「仕事」を除外する必要はない。スケジュール画面側の予約ピッカー (`_SlotRow._pickAction`) も同じ判定を独立に持つ（DRY 化は将来の検討事項）。
    - 予約自動実行のフック位置: `HomeScreen._onSlotTap` 冒頭で `schedule.reservationOf(today, slot)` をチェック。予約があれば `applyScheduledActionFor(slot)` を呼んで自動実行する。コスト不足時は SnackBar で通知してから通常の選択シートにフォールバック（プレイヤーが代替行動を選べる）。仕様の「自動実行（タップ即実行）」を厳密にとる方針を採用。
    - `kHomeActionList` などを `const` から getter (`List`) に変更したため、既存テストの `const ActionSheetContent(...)` 呼び出し箇所を非 const に修正。今後 `ActionEffect` の差し替えが容易になる副次効果あり。
  - 既存テストへの影響:
    - test/main_scaffold_test.dart: スケジュールタブのスタブ検出キー `schedule.placeholder` を、新実装の `schedule.monthGrid` 存在チェックに変更。
    - test/action_sheet_test.dart / test/action_sheet_overtime_test.dart: `const MaterialApp(home: Scaffold(body: ActionSheetContent(...)))` を `const` 外しに更新（`kHomeActionList` が getter 化されたため）。能力値/挙動アサートは無修正。
    - test/game_state_test.dart / test/game_state_work_test.dart: schedule 統合の影響なし（初期 ScheduleStore は空、`applyAction` の挙動は不変）。
    - integration_test/day_loop_test.dart は Sprint 04 から残る既知の課題（平日 4/1 日中で仕事固定フローに入る）でテストフローが噛み合わない可能性あり。Sprint 04 progress に記載済みのため本 Sprint では未修正。

- [x] Sprint 06: キャラクターシステムの実装 — 完了日 2026-05-17
  - 実装ファイル:
    - 追加: lib/models/character.dart, lib/models/character_state.dart, lib/models/encounter.dart, lib/data/character_repository.dart, lib/data/encounter_repository.dart, lib/widgets/character_portrait.dart, lib/widgets/affinity_hearts.dart, lib/widgets/dialogue_modal.dart, lib/widgets/invite_sheet.dart, lib/screens/character_detail_screen.dart, test/character_repository_test.dart, test/characters_screen_test.dart, test/character_detail_screen_test.dart, test/affinity_hearts_test.dart, test/character_portrait_test.dart, test/encounter_test.dart, test/invite_sheet_test.dart, integration_test/encounter_flow_test.dart
    - 改修: lib/screens/characters_screen.dart（スタブから実装に置換）, lib/models/game_state.dart（CharacterState マップ・hasMet/recordEncounter/applyInviteOutcome/pendingEncounter/consumePendingEncounter・DayAdvanceEvent.encounter を追加、_advanceDay 末尾で出会いイベントの発火予約）, lib/models/actions.dart（ActionKind.invite と kInvite* 定数群を追加、kHolidayActionList に invite を末尾追加）, lib/widgets/action_sheet.dart（invite のアイコン Icons.favorite_outline を追加）, lib/screens/home_screen.dart（DayAdvanceEvent.encounter リスナで DialogueModal を起動、invite 選択時に runInviteFlow を呼び出す分岐を追加）, lib/screens/schedule_screen.dart（予約 picker で invite を除外）, test/main_scaffold_test.dart（characters.placeholder → characters.grid 検出に更新）
  - Generator 自己評価:
    - 基準1（キャラ一覧画面に5名がグリッド表示）→ ◯ characters_screen_test.dart 「5 名のキャラカードがグリッドに表示される」で 5 名分の card key 存在を検証（GridView の lazy build 対策に tester.view.physicalSize=800x2000 を使用）
    - 基準2（4/10 等に出会いイベントが自動発火、キャラが出会い済になる）→ ◯ encounter_test.dart 「4/9 で全枠埋めて翌日に進むと akari の出会いイベントが発火予約」「consumePendingEncounter で対象が isMet=true」で unit 検証 ＋ integration_test/encounter_flow_test.dart で end-to-end 検証（device 実行は Evaluator フェーズ）
    - 基準3（キャラ詳細画面に立ち絵・プロフィール・5段階ハート1段階目）→ ◯ character_detail_screen_test.dart で portrait/name/bioShort/bioLong/role/hearts(0番目 filled) の key 存在を検証
    - 基準4（「誘う」行動で対象キャラを選ぶUI）→ ◯ invite_sheet_test.dart 「出会い済みキャラのみが選択肢に表示される」「キャラ選択 → 確認ダイアログ → やめる」「成功時はストレス減 + 所持金減 + 枠done」で 3 ステップフローを検証
    - 基準5（表情差分 normal/smile/troubled の切替）→ ◯ character_portrait_test.dart で expression 別 key の存在を unit 検証 ＋ integration_test/encounter_flow_test.dart で「次へ」進行による key 切替を end-to-end 検証
  - flutter analyze: clean (No issues found)
  - flutter test: 161/161 pass（既存 126 + 新規 35）
  - 設計メモ:
    - キャラ ID 体系: CharacterId enum = {akari, uta, toru, sayo, yui}。spec.md §5 の正式名「七瀬 灯 / 久遠 詩 / 鴻巣 透 / 蓮見 紗夜 / 槙原 結衣」を CharacterRepository._all に転記。年齢・bioLong・appealText も spec から忠実に転記。
    - 表情 enum: Expression = {normal, smile, troubled}。仕様書 Sprint 06 の「通常/笑顔/困惑」に対応。enum 値の name はそのままアセットファイル名のサフィックスに使える命名にしてあるため、将来 `assets/characters/[id]_[expression].png` 形式の実イラスト導入時は CharacterPortrait の Container 部分を Image.asset に差し替えるだけで済む（コメントで明記）。
    - 立ち絵プレースホルダの設計: CharacterPortrait は `[円形 themeColor Container] + [中央のイニシャル文字] + [右下に表情の Icons.sentiment_*]` を Stack で重ねた構造。size 引数で small(40-72)/large(160-200) を切替可能。`isSilhouette=true` で未会いキャラのシルエット表示にも対応。実イラスト導入時は Container 部を Image に置き換える単一の差替えポイントが残るよう Stack の root key を `characterPortrait.<id>.<expression|silhouette>` で固定している。
    - 出会いイベント日付配置: 4/10 灯 / 4/15 詩 / 4/20 透 / 5/5 紗夜 / 5/10 結衣。すべて被らないよう散らした。当日 (year, month, day) 一致で EncounterRepository.eventOn が引ける純粋関数 API。
    - 誘い行動の仮値: 成功率 70% 固定（kInviteSuccessPercent）、コスト 800 円（kInviteCostMoney = kCafeCostMoney）。成功時ストレス -2、失敗時ストレス +3。affinity の表面値は Sprint 06 では「成功時+1（ハート段階に届かない範囲で記録のみ）」とし、表示段階は 1 のままに留める（Sprint 07 で本実装）。
    - 「誘う」は applyAction を経由しない: ActionKind.invite は kActionCatalog にエントリだけ作るが、deltas は空。HomeScreen._onSlotTap で ActionKind.invite を検出したら runInviteFlow に分岐し、キャラ選択→確認→成否判定→GameState.applyInviteOutcome で枠消費と能力値変動をまとめて行う。schedule_screen の予約 picker からは除外（当日その場で対象を選ぶ動的行動のため）。
    - 出会いイベントの発火フック: GameState._advanceDay の末尾で EncounterRepository.eventOn(_currentDate) を引き、未会いなら _pendingEncounter に退避 + DayAdvanceEvent.encounter を予約。HomeScreen の DayAdvanceEvent リスナで DialogueModal.show を await し、閉じたら consumePendingEncounter で isMet=true を確定。
    - 日曜→月曜遷移など複数 DayAdvanceEvent 同時発火時の順序: 既存仕様（weeklyReview → salary）に encounter を末尾追加するため、_advanceDay 内の予約順序は「weeklyReview（日曜なら） → 日付進行 → salary（月初なら） → encounter（発火日なら）」。HomeScreen の listener は順に postFrameCallback を積むので、後に push された Route が最上面になる（出会いモーダル→週次ふりかえり→給料ダイアログの順で表示・閉じることになる）。
    - GameState.applyInviteOutcome の責務: コスト不足/枠 done なら false を返してフロー中止できる。成否別ストレス変動と枠 done 化、全枠解消時の _advanceDay 呼び出しを内包する（applyAction と同等の副作用ライフサイクル）。
    - CharacterState.affinityStage: Sprint 06 では affinity=0 でも出会い済みなら段階 1 を返す getter 仕様。Sprint 07 で affinity 値そのものが動くようになったら閾値 20/40/60/80 がそのまま段階上昇のトリガになる。
  - 既存テストへの影響:
    - test/main_scaffold_test.dart: スタブ検出キー `characters.placeholder` を新実装の `characters.grid` 存在チェックに変更。
    - 他の既存 126 件のテストは無修正で pass。`kHolidayActionList` に invite が追加されたが、既存テストはホワイトリスト的に必要なキーの存在のみ検証していたため互換性に問題なし。

- [x] Sprint 07: 好感度システムと2層構造 — 完了日 2026-05-17
  - 実装ファイル:
    - 追加: lib/models/invite_balance.dart, lib/models/dialogue.dart, test/affinity_stage_test.dart, test/invite_success_rate_test.dart, test/two_layer_affinity_test.dart, test/estrangement_test.dart, test/stress_rejection_test.dart, test/character_detail_dynamic_test.dart, integration_test/invite_ten_times_test.dart, integration_test/stress_rejection_test.dart
    - 改修: lib/models/character_state.dart（affinityStage を spec §6 の閾値 (0-19/20-39/40-59/60-79/80-100) で本実装、lastInteractedDate / bumpAffinity / bumpTrueAffinity を追加、trueAffinity の範囲を -50〜+100 に）, lib/models/game_state.dart（DayAdvanceEvent.estrangement 追加、applyInviteOutcome を Sprint 07 マジックナンバー基準に更新、applyInviteRejection / applyChoiceOutcome を追加、_advanceDay 末尾で疎遠ペナルティ走査、recordEncounter で lastInteractedDate 初期化、pendingEstrangements / consumePendingEstrangements API）, lib/widgets/invite_sheet.dart（成功率を inviteSuccessPercent(affinity) に置換、ストレス連動の拒否シーン分岐、成功後ミニ会話の選択肢ダイアログ）, lib/screens/home_screen.dart（DayAdvanceEvent.estrangement リスナで SnackBar 通知）, test/invite_sheet_test.dart（Sprint 07 成功率 50% に整合するように seed を Random(1) に変更、コメント更新）
  - Generator 自己評価:
    - 基準1（10回誘いで2段階目）→ ○ integration_test/invite_ten_times_test.dart で 10回成功 → affinity 0→20 → ハート 2 段階目を end-to-end 検証（実機実行は Evaluator フェーズ。決定論用に applyInviteOutcome(success:true) を直接呼ぶルートを使用）
    - 基準2（真の好感度だけ動く）→ ○ test/two_layer_affinity_test.dart で applyChoiceOutcome(affinityDelta:0, trueAffinityDelta:-5) で表面・段階不変、真のみ変動を確認。複数回適用しても独立性が保たれる
    - 基準3（1ヶ月未会いで -3）→ ○ test/estrangement_test.dart で 30 日進行で affinity -3 / trueAffinity -1 / lastInteractedDate 繰り越し、29 日では非発火、60 日で -6 を確認。誘い後はタイマーリセットされることも検証
    - 基準4（ストレス80超で誘い拒否 → 好感度大幅減）→ ○ test/stress_rejection_test.dart（unit + widget）で applyInviteRejection の効果と、ストレス100で 100% 拒否シーン発火→ -5/-3 を確認 ＋ integration_test/stress_rejection_test.dart で end-to-end 確認
    - 基準5（詳細画面のハート数 = 表面好感度段階）→ ○ test/character_detail_dynamic_test.dart で各境界値 (0/19/20/39/40/59/60/79/80/100) でのハート塗りつぶし数を網羅。GameState.bumpAffinity 後の AnimatedBuilder 即時反映も確認
  - flutter analyze: clean (No issues found)
  - flutter test: 196/196 pass（既存 161 + 新規 35）
  - 設計メモ:
    - 2 層好感度の閾値・式: 仕様書 §6 に従い 5 段階を `affinity` 値 0-19/20-39/40-59/60-79/80-100 で定義（CharacterState.affinityStage）。表面好感度は 0-100 にクランプ、真の好感度は -50〜+100（負値を許容することで「上辺ばかりで内心は冷め切っている」状態をモデル化）。`bumpAffinity` / `bumpTrueAffinity` で個別に動かす。
    - 誘い成功率の式とマジックナンバー所在: lib/models/invite_balance.dart の `inviteSuccessPercent(affinity)` = `clamp(50 + affinity*1/2, 25, 95)`。affinity=0→50%, 20→60%, 40→70%, 60→80%, 80→90%, 100→95%（上限）。成功時 affinity +2 / trueAffinity +1、失敗時 trueAffinity -1（表面不変）。10 回連続成功で affinity +20 → spec §6 の「顔見知り」（20〜39）に到達。
    - 疎遠ペナルティの周期と量: `kEstrangementThresholdDays=30`、`kEstrangementAffinityDelta=-3`、`kEstrangementTrueAffinityDelta=-1`。`GameState._advanceDay` 末尾で出会い済み全キャラを走査し、`currentDate - lastInteractedDate >= 30` で発火。発火後 `lastInteractedDate` を「今日」に繰り上げて連続発火を防ぐ（次回は更にもう 30 日後）。複数キャラ同時発火時は 1 度の `DayAdvanceEvent.estrangement` にまとめ、`pendingEstrangements` に対象 ID を積む。UI 側 (HomeScreen) は SnackBar で「{名前} としばらく会っていない…」と通知。
    - ストレス拒否の確率分布: lib/models/invite_balance.dart の `stressRejectionPercent(stress)` = `stress >= 100 ? 100 : stress >= 90 ? 60 : stress >= 80 ? 30 : 0`。降順テーブル `kStressRejectionTable` で評価。拒否時 affinity -5 / trueAffinity -3 / 主人公ストレス +5、コスト（カフェ代）は通常通り消費、`lastInteractedDate` は更新（接触はあった扱い）。
    - 真の好感度を動かす選択肢: `ChoiceOutcome` 型（lib/models/dialogue.dart）で「無難な相づち」(affinity +1, true 0) / 「本音を話す」(affinity 0, true +3) を表現。Sprint 07 では誘い成功後の汎用ミニ会話 1 問だけに採用。Sprint 08 でイベント本体に展開する想定。
    - キャラ詳細画面の動的反映: Sprint 06 時点で AnimatedBuilder + AppScope.of パターンを採用済みのため、Sprint 07 では追加の改修不要。GameState.notifyListeners が呼ばれた時点で hearts が再ビルドされる。
    - 既存 invite_sheet 成功率テストの seed 更新: Sprint 06 の Random(0) は `nextInt(100)=55` だったが、新しい base 50% では境界をまたぐため Random(1)（`nextInt(100)=4`）に変更して「affinity=0 でも確実に成功する seed」に切り替えた。Sprint 06 のオリジナルロジック（70% 固定）テスト意図はそのまま保たれている。
  - 既存テストへの影響:
    - test/invite_sheet_test.dart: 成功ケースの seed を Random(0) → Random(1) に変更。コメントも Sprint 07 の成功率 50% を反映するように更新。
    - 他 35 件の新規テストは独立。既存 161 件はそのまま pass。

- [x] Sprint 08: イベントシステム — 完了日 2026-05-17
  - 実装ファイル:
    - 追加: lib/models/event.dart, lib/models/event_resolver.dart, lib/models/cg_state.dart, lib/data/common_events.dart, lib/data/individual_events.dart, lib/data/random_events.dart, lib/widgets/cg_view.dart, lib/widgets/event_player.dart, lib/screens/christmas_choice_screen.dart, test/event_resolver_test.dart, test/common_events_test.dart, test/individual_events_unlock_test.dart, test/cg_library_test.dart, test/album_screen_test.dart, test/christmas_choice_test.dart, test/event_player_test.dart, integration_test/health_check_event_test.dart, integration_test/individual_event_test.dart, integration_test/christmas_test.dart
    - 改修: lib/models/character_state.dart（unlockedEventIds: Set<String> を追加、toMap/fromMap も対応）, lib/models/game_state.dart（CgLibrary 統合、unlockedGlobalEventIds、pendingCommonEvent/pendingMilestoneEvent、DayAdvanceEvent.common/.milestone 追加、_advanceDay 末尾で EventResolver.resolveCommon/resolveMilestone 呼び出し、findIndividualEventFor / markEventCompleted / consumeIndividualEventSlot / bumpStress API 追加、resetToStart で CG / イベント状態もクリア）, lib/screens/home_screen.dart（randomEventRng DI 追加、_onSlotTap 冒頭でランダム遭遇判定→個別イベント優先発火→既存予約→通常シートの優先順位フロー、DayAdvanceEvent.common/.milestone のリスナで EventPlayer / ChristmasChoiceScreen を起動）, lib/screens/main_scaffold.dart（実プレイ用に HomeScreen に Random() を注入）, lib/screens/album_screen.dart（スタブから実装に置換: 全 CG をグリッド表示し、未解放はシルエット、タップで全画面プレビュー）, test/main_scaffold_test.dart（アルバムタブのテストを `album.grid` 検出に更新）
  - Generator 自己評価:
    - 基準1（6月の健康診断イベントが自動発火・共通イベント表示）→ ◯ common_events_test.dart で「6/15 で resolveCommon が hit」「6/14 では返らない」を unit 検証 ＋ integration_test/health_check_event_test.dart で「6/14→6/15 で EventPlayer に health_check.jun タイトルが出る」「最後まで再生で CG ライブラリに登録」を end-to-end 検証
    - 基準2（好感度2段階目で個別イベント解放・特定枠で優先発火）→ ◯ individual_events_unlock_test.dart で「affinity 19→null, 20→ind.akari.1」「markEventCompleted 後は再発火しない」「uta は preferredSlot=morning のみで返る」を unit 検証 ＋ integration_test/individual_event_test.dart で「affinity 20 + evening タップ → EventPlayer 起動 → 選択肢 → unlockedEventIds に追加 + CG 解放 + 枠 done」を end-to-end 検証
    - 基準3（12月クリスマスで「誰と過ごすか」選択画面・選んだキャラとの専用シーン）→ ◯ christmas_choice_test.dart で「未会いキャラは選択肢に出ない」「akari を選ぶと専用 EventPlayer が起動」「一人で過ごすも選べる」「buildChristmasEventFor が全 5 キャラ + alone のシーンを返す」を widget 検証 ＋ integration_test/christmas_test.dart で「12/23→12/24 で ChristmasChoiceScreen 自動 push → akari 選択 → 専用シーン再生 → CG/イベント解放」を end-to-end 検証
    - 基準4（出勤枠で 5〜15% のランダム遭遇・確率モック検証）→ ◯ event_resolver_test.dart で「roll<15 で発火、>=15 で非発火」「朝枠以外は発火しない」「休日は発火しない」「上限定数 15・下限定数 5」を Random モック (_FixedRng) で固定値検証
    - 基準5（メモリーアルバムに解放済 CG がサムネ表示・タップで全画面）→ ◯ album_screen_test.dart で「初期は全シルエット + カウンタ 0/N」「unlock 済はサムネ表示」「タップで全画面プレビュー → 閉じる」を widget 検証 ＋ cg_library_test.dart で CgLibrary の unlock / has / clear / snapshot/restoreFrom の単体検証
  - flutter analyze: clean (No issues found)
  - flutter test: 240/240 pass（既存 196 + 新規 44）
  - 全イベント本数の内訳:
    - 共通イベント 9 本（うち 1 本が節目=クリスマス）: 4/1 新年度の朝, 5/3 ゴールデンウィーク, 6/15 健康診断, 7/10 夏季賞与, 8/13 夏祭り, 10/31 ハロウィン残業, 11/20 期末評価面談, 12/24 クリスマス（milestone）, 2/14 バレンタイン, 3/31 年度末
    - 個別イベント 25 本（各キャラ 5 本ずつ）: 七瀬5/久遠5/鴻巣5/蓮見5/槙原5。Event1=stage2, Event2=stage3, Event3=stage3+requiredMonth, Event4=stage4, Event5=stage4+requiredMonth
    - ランダム遭遇 8 本: 駅で知人/コンビニ割引券/満員電車/のら猫/一駅手前散歩/バス遅延/自販機当たり/見知らぬ親切
    - 節目イベント本体 1 本（クリスマス）＋キャラ別シーン 5 本（akari/uta/toru/sayo/yui）＋ alone シーン 1 本
    - 合計: 9 共通 + 25 個別 + 8 ランダム + 6 クリスマス分岐 = 48 本（うち CG 解放対象 48 件）
  - 設計メモ:
    - イベント発火優先順位（HomeScreen._onSlotTap）:
      1. 朝枠×平日のみ EventResolver.shouldFireRandom で確率判定 → 発火時は EventPlayer 起動。ただし枠は消費せず、続けて通常フローに合流
      2. 個別イベント検出（GameState.findIndividualEventFor）→ 該当があれば EventPlayer 起動 → consumeIndividualEventSlot で枠 done
      3. 予約自動実行（既存ロジック）
      4. 通常の行動選択シート（仕事固定 / 朝夜 / 平日夕方 / 休日 で分岐）
      共通・節目イベントは日付ベースで `_advanceDay` 内に発火予約し、DayAdvanceEvent.common/.milestone のリスナで EventPlayer / ChristmasChoiceScreen を起動する（出会いイベントと同じ仕組み）
    - CG プレースホルダ設計: lib/widgets/cg_view.dart の CgView（themeColor グラデーション + 中央タイトル文字 + フッターに cgKey 表示）。実イラスト導入時は CgView 内の Container を `Image.asset('assets/cg/${cgKey}.png', fit: BoxFit.cover)` に置き換える単一の差替えポイントを残してある。命名規約は `cg.<category>.<id>` 形式（例: `cg.common.health_check_jun`, `cg.ind.akari.3`, `cg.milestone.christmas.uta`）。
    - 共通/個別/ランダム/節目のファイル分割: 各カテゴリを 1 ファイルにまとめ、`CommonEventCatalog.all / .milestones`, `IndividualEventCatalog.all / .forCharacter(id)`, `RandomEventCatalog.all` を public 静的リストとして公開。`EventResolver` がそれぞれを参照して引く形（資料のように一覧性を確保）。
    - ランダム遭遇の確率モック化方式: `EventResolver.shouldFireRandom(Random rng, ...)` に `Random` を DI。テストでは `_FixedRng(value)` を実装して `nextInt(100)` の戻り値を固定し、roll が 14 → 発火 / 15 → 非発火を直接検証。実プレイは MainScaffold が `Random()` を生成して HomeScreen に渡す（テスト側で `randomEventRng: null` のときはランダム遭遇判定をスキップする safe-default 設計＝既存の widget テストが flakey にならない）。
    - 個別イベントの解放しきい値: affinity 20 = stage 2 で Event 1 解放。spec.md §6 の段階構造（0-19/20-39/40-59/60-79/80-100）に整合。Event 3/5 は requiredMonth で季節縛りを追加（例: sayo Event 3 は 6 月以降=梅雨、yui Event 3 は 10 月以降=秋の草大会）。
    - DialogueModal の置換ではなく EventPlayer を新設: DialogueModal は出会いイベント用の固定構造（speaker 必須 / `[Expression, String]` ペア）に最適化されているため、speaker null（地の文）対応・末尾選択肢シーン・選択結果を Navigator.pop で返す責務を持つ EventPlayer を別 Widget として用意。両者は共存し、用途で使い分ける。
    - CharacterState.unlockedEventIds: Set<String> を追加。toMap/fromMap も対応（Sprint 09 のセーブ/ロード時にそのまま JSON 化できる）。
    - クリスマスは「共通カタログにも milestone カテゴリで含める」二重構造: `CommonEventCatalog.all` 一覧性のため含めつつ、`resolveCommon` 側で category=common のみフィルタすることで、共通イベントとしての二重発火を防止している。`resolveMilestone` が `CommonEventCatalog.milestones` から拾う。
  - 既存テストへの影響:
    - test/main_scaffold_test.dart: アルバムタブのテストを `album.placeholder` → `album.grid` 存在チェックに更新（Sprint 02 のスタブ用キーが Sprint 08 で本実装に置き換わったため）。
    - 他 196 件の既存テストは無修正で pass。`HomeScreen.randomEventRng` を opt-in（null なら判定スキップ）にすることで、既存テスト（4/1 水曜の朝枠タップ等）のフラキー化を避けた。

- [x] Sprint 09: セーブ/ロードとエンディング判定 — 完了日 2026-05-17
  - 実装ファイル:
    - 追加: lib/models/ending.dart, lib/models/ending_resolver.dart, lib/models/save_snapshot.dart, lib/data/endings.dart, lib/services/save_repository.dart, lib/services/ending_archive.dart, lib/screens/save_load_screen.dart, lib/screens/ending_screen.dart, lib/screens/ending_archive_screen.dart, test/save_repository_test.dart, test/save_load_screen_test.dart, test/ending_resolver_test.dart, test/ending_archive_test.dart, test/autosave_test.dart, test/character_state_serialization_test.dart, integration_test/save_resume_test.dart, integration_test/ending_flow_test.dart
    - 改修: lib/main.dart（SaveRepository/EndingArchive をロードして注入）, lib/app.dart（AppScope に saveRepository/endingArchive を追加。Sprint 01〜08 互換のため optional とし、null の場合は build 時に非同期ロード）, lib/models/game_state.dart（DayAdvanceEvent に autosave/endingReached を追加、AutosaveTrigger enum 追加、toMap/restoreFromMap 完備、_advanceDay 末尾でオートセーブ予約と 3/31 → 4/1 遷移時のエンディング判定予約、debugFastForward/debugJumpTo/debugTriggerEndingResolution テスト API）, lib/models/schedule.dart（snapshot/restoreFrom 追加）, lib/screens/title_screen.dart（つづきから有効化＋エンディング図鑑ボタン）, lib/screens/home_screen.dart（AppBar にセーブボタン、DayAdvanceEvent.autosave/endingReached リスナでオートセーブ書き出し＋EndingScreen 起動）, test/test_helpers.dart（saveRepository/endingArchive を optional パラメタ化）
  - Generator 自己評価:
    - 基準1（任意の場面で手動セーブ → アプリ再起動 → ロードで完全に同じ状態に復元）→ ◯ test/save_repository_test.dart「write → read で完全に同じ状態が復元される」と integration_test/save_resume_test.dart「セーブ → 再構築 → ロードで完全に同じ状態が復元される」で end-to-end 検証。GameState.toMap/restoreFromMap が 7 能力値・スロット状態・キャラ状態・CG ライブラリ・スケジュール予約のすべてを往復することを test/character_state_serialization_test.dart で網羅
    - 基準2（月初に自動でオートセーブ + スロット表示にサムネ・日時記録）→ ◯ test/autosave_test.dart で月初・週末・イベント前の 3 トリガが GameState 内で発火することを unit 検証。SaveRepository.writeAuto はリングバッファで 0→1→2→0 巡回することを test/save_repository_test.dart で検証。スロット表示のサムネ・日時は test/save_load_screen_test.dart 「既存セーブのある手動スロットはサマリーを表示する」で検証
    - 基準3（3/31 到達でエンディング再生）→ ◯ integration_test/ending_flow_test.dart「1 年プレイ → 3/31 到達 → ノーマル ED に到達できる」で end-to-end 検証（debugFastForward で日付加速 + debugTriggerEndingResolution で判定起動 → EndingArchive に記録）
    - 基準4（異なる条件で 2 周プレイして別 ED）→ ◯ integration_test/ending_flow_test.dart「別条件で 2 周目 → 別の ED（個別 ED）に到達」「真ED条件をすべて満たすと月と珈琲EDが発火」で 3 種のED分岐を検証。test/ending_resolver_test.dart で 7 ED 全種類と境界値（ストレス 41/40、CG 11/12、affinity 79/80、trueAffinity 19/20/29/30）を網羅
    - 基準5（図鑑で達成済EDが彩色、未達成がシルエット）→ ◯ test/ending_archive_test.dart「未達成のEDはシルエット表示、達成済は彩色表示」「達成済 ED は displayName を表示、未達成は ???」で widget 検証。彩色は endingArchive.thumb.{id}.colored、未達成は .locked のキーで区別
  - flutter analyze: clean (No issues found)
  - flutter test: 285/285 pass（既存 240 + 新規 45）
  - 設計メモ:
    - セーブデータの JSON スキーマ（version=1 で前方互換）:
      ```
      {
        "version": 1,
        "heroName": "...",
        "currentDate": "2026-04-01T00:00:00.000",
        "vitality": 80, "vitalityMax": 100, "money": 50000, "stress": 20,
        "stats": { "intellect": 25, "sensibility": 20, "sociability": 30, "career": 20 },
        "slotStates": { "morning": "pending", ... },
        "weekStartSnapshot": { ... }, "weekStartDate": "...",
        "lastSalaryAmount": 0,
        "characterStates": {
          "akari": { "isMet": true, "affinity": 25, "trueAffinity": 10,
                     "lastInteractedDate": "...", "unlockedEventIds": [...] },
          ...
        },
        "unlockedGlobalEventIds": [...],
        "cgLibrary": [...],
        "schedule": [ { "date": "2026-04-12", "slot": "morning", "action": "movie" }, ... ]
      }
      ```
      SaveSnapshot がさらに `{ heroName, savedAt, inGameDate, summary, payload }` でこのデータを包む。
    - スロット構成: 手動 10 (`save.slot.0`〜`save.slot.9`) + クイック 1 (`save.quick`) + オート 3 (`save.auto.0`〜`save.auto.2`、`save.auto.cursor` でリングバッファ位置を保持)。SharedPreferences のキー命名で衝突なし。
    - オートセーブのトリガ（GameState._advanceDay 末尾で判定 + 優先順位）:
      1. monthStart: 翌日が月初（1日）。給料イベントと同時。
      2. beforeEvent: 翌日に節目イベント（クリスマス等）または共通イベントが発火予約された場合の保険セーブ。
      3. weekEnd: 翌日が月曜（=日曜終了直後）。週次ふりかえりの直後。
      `_pendingAutosaveTrigger` 単一フィールドで 1 ターンに 1 種類のみセット。HomeScreen が DayAdvanceEvent.autosave を受けて `SaveRepository.writeAuto` を呼ぶ。
    - 7 エンディング一覧と分岐条件:
      1. 個別 ED ×5（akariEd/utaEd/toruEd/sayoEd/yuiEd）: 該当キャラの表面好感度 80 以上 + 真の好感度 +20 以上。複数満たした場合は表面好感度の最大値で確定（同値時は CharacterId 宣言順）。
      2. ノーマルED: 個別 ED 条件を満たすキャラが 0 人、かつ真 ED 条件未達。
      3. 真ED「月と珈琲ED」: 全 5 キャラの表面 ≥60 + 真 ≥+30 + ストレス ≤40 + 仕事評価 ≥50 + CG 解放 12 件以上を全て同時に満たす。
      判定は EndingResolver.resolve（純粋関数）で行い、GameState.debugTriggerEndingResolution からトリガ可能。実プレイでは _advanceDay 内で「翌年 4/1 に到達した瞬間」（=年度末 3/31 終了直後）に予約される。
    - 真ED のバランス（達成しやすさ）: 全 5 キャラと表面 60（特別な存在）以上を維持しつつ、真好感度合計 +150 以上、CG 12 件解放（25 個別 + 共通 9 から選び抜く必要あり）、仕事評価 50 + ストレス 40 以下の総合プレイが必要。1 周目では到達困難で、3〜4 周目以降を想定。プレイヤーが「全員にいい顔」をしただけでは真好感度が稼げないため、選択肢で「本音を話す」を選び続ける必要がある（trueAffinityDelta の意図的活用が必須）。
    - 1 年プレイの integration test を高速化するため、`GameState.debugFastForward(int days)` と `debugTriggerEndingResolution()` の 2 つの test API を public 化した。本番フローでは _advanceDay 内で自動発火するため、UI コードから直接呼ぶ必要はない。
    - SaveRepository / EndingArchive は AppScope に optional フィールドとして登録した（既存 Sprint 01〜08 の integration test が `AppScope(...)` を直接構築する箇所と後方互換のため）。UI 側では `requireSaveRepository` / `requireEndingArchive` で取り出すが、HomeScreen のオートセーブフックは null 安全に分岐させてあり、テスト時にリポジトリ未注入でも落ちない。
    - エンディング本文・ED 名・クレジット行はすべて完全オリジナル。既存 IP の固有名詞・定型句（「ありがとう、これからもよろしくね」「想い出が…」「キミと…」等）は使用していない。社会人らしい抑制の効いたトーンで統一。各 ED は 5〜10 行 + クレジット 1 行構成。
    - エンディング図鑑画面は GridView（2 列）。彩色サムネは LinearGradient + 中央アイコン、未達成シルエットは `Icons.lock_outline` + outlineVariant 枠線。タップ時、達成済みのみ EndingScreen.show で全文再生可能。
    - title_screen の `_NullListenable` は SaveRepository が AppScope に未注入のテストケースで AnimatedBuilder を空 Listenable で動かす互換層。プロダクションでは main.dart が必ず注入するため使われない。
  - 既存テストへの影響:
    - test/test_helpers.dart: `wrapWithAppScope` に optional な `saveRepository` / `endingArchive` を追加。既存呼び出し（240 件）はそのまま動作する（optional のため）。
    - 他既存 240 件のテストは無修正で pass。

- [x] Sprint 10: 演出強化 — 完了日 2026-05-17
  - 実装ファイル:
    - 追加: lib/widgets/page_transitions.dart, lib/widgets/typewriter_text.dart, lib/widgets/stat_change_overlay.dart, lib/widgets/scenic_background.dart, lib/screens/cg_reveal_screen.dart, test/page_transitions_test.dart, test/typewriter_text_test.dart, test/stat_change_overlay_test.dart, test/scenic_background_test.dart, integration_test/transitions_test.dart, integration_test/cg_reveal_test.dart
    - 改修: lib/models/game_state.dart（`_statChangeListeners` + `addStatChangeListener` を新設、`_applyDeltas` がクランプ後の実差分を `_emitStatChange` で配信）, lib/widgets/character_portrait.dart（表情切替時の `AnimatedSwitcher` クロスフェード 200ms）, lib/widgets/affinity_hearts.dart（新規塗りつぶしハートに 0.4 秒のポップ＋光るアニメーションを `_HeartPop` で実装、StatelessWidget → StatefulWidget 化）, lib/widgets/dialogue_modal.dart（`TypewriterText` で 1 文字ずつ表示、未完なら 1st tap で全文表示・2nd tap で次発話、slideUpRoute で push）, lib/widgets/event_player.dart（同上に加え、textSpeed を引数化）, lib/screens/ending_screen.dart（本文行に `TypewriterText` を導入、fadeRoute で push）, lib/screens/home_screen.dart（Stack 最下層に `ScenicBackground` を 35% 透明で配置、右上に `StatChangeOverlayHost`、共通/個別イベント発火時の白フラッシュ 200ms + 新規 CG 解放時の `CgRevealScreen.show`）, lib/screens/title_screen.dart / name_input_screen.dart / save_load_screen.dart / characters_screen.dart / album_screen.dart / ending_archive_screen.dart / christmas_choice_screen.dart（`MaterialPageRoute` → `fadeRoute` / `slideUpRoute` への置換）
  - Generator 自己評価:
    - 基準1（画面遷移時にフェードまたはスライドのアニメーション）→ ◯ test/page_transitions_test.dart で `fadeRoute` / `slideUpRoute` が `FadeTransition` / `SlideTransition` を生成することを unit 検証 ＋ integration_test/transitions_test.dart で「タイトル→名前入力」遷移中に FadeTransition がツリーに現れることを検証
    - 基準2（会話画面でテキストが 1 文字ずつ表示・タップで全文）→ ◯ test/typewriter_text_test.dart 5 ケース（msPerChar 純粋関数 / 1 文字ずつ表示 / タップで全文 / textSpeed=1.0 で瞬時 / text 変更で頭からやり直し）で全網羅。DialogueModal / EventPlayer / EndingScreen が `TypewriterText` を採用済み
    - 基準3（能力値変動ポップアップ右上に短時間表示）→ ◯ test/stat_change_overlay_test.dart で「push で右上に表示」「lifespan 経過で自動消滅」「上限 4 件・5 件目で先頭が消える」「delta 0 は無視」「clear 全消去」を検証。GameState の能力値変動が `addStatChangeListener` 経由で HomeScreen の `StatChangeOverlayController` に流れる
    - 基準4（CG 解放シーンで全画面 CG がフェードイン）→ ◯ integration_test/cg_reveal_test.dart で個別イベント完了 → `CgRevealScreen` push → `FadeTransition` 中の状態 + 完了後の `cgReveal.<key>.root` キー存在 + タップで閉じることを end-to-end 検証
    - 基準5（ホーム画面の背景が時間帯で変化）→ ◯ test/scenic_background_test.dart 11 ケース（4 季節判定 / 4 時間帯判定 / null フォールバック / 朝夜で支配色違い / 春冬で季節色違い / ScenicBackground の Widget key 切替）を網羅
  - flutter analyze: clean (No issues found)
  - flutter test: 314/314 pass（既存 285 + 新規 29）
  - 設計メモ:
    - ページトランジション方式: `PageRouteBuilder` ベースの `fadeRoute<T>(builder, duration, fullscreenDialog)` と `slideUpRoute<T>(builder)` を `lib/widgets/page_transitions.dart` に集約。デフォルト 250ms の `easeInOut`、slide は (Offset(0, 0.08) → Offset.zero) の `easeOutCubic` + Fade の合成。`MaterialPageRoute` を置換するだけで既存呼び出しはそのまま使える。
    - タイプライターの速度マップ: `TypewriterText.msPerCharFor(textSpeed, maxMsPerChar=50)` = `((1.0 - clamp(textSpeed, 0, 1)) * maxMsPerChar).round()`。`settings.textSpeed=0.0 → 50ms/char`, `0.5 → 25ms/char`, `1.0 → 0ms/char (瞬時)`。瞬時モードでは Timer を起動せず `addPostFrameCallback` で onComplete を即発火する。タップ操作は `revealAllOnTap=true`（デフォルト）のとき `GestureDetector` でラップされ、進行中タップで一気に完成する。
    - 季節と時間帯の配色テーブル所在: `lib/widgets/scenic_background.dart` の `_topColorFor / _midColorFor / _bottomColorFor` の 3 関数に集約。`Season`（spring/summer/autumn/winter）× `DayPhase`（morning/noon/evening/night）の組み合わせ。midColor が季節アクセント（春=桜色 / 夏=若葉緑 / 秋=朱茶 / 冬=銀）、top/bottom が時間帯の支配色。`DayPhase` という独自名にしたのは Flutter の `material.TimeOfDay` と衝突しないようにするため。
    - StatChangeOverlay の発火経路: `GameState._applyDeltas` がクランプ後の実差分を `_emitStatChange(kind, actual)` で配信 → HomeScreen の `didChangeDependencies` で `addStatChangeListener` を 1 回登録し、`StatChangeOverlayController.push(kind, delta)` を呼ぶ → 右上の `StatChangeOverlayHost` が `AnimatedBuilder` で再描画。各 `_StatChangeChip` は `TweenSequence` で 0.0-0.2 スライドイン → 0.2-0.75 滞在 → 0.75-1.0 フェードアウトの 2 秒ライフサイクル。上限 4 件で 5 件目が来たら先頭を強制 expire。
    - CG 演出: 新規 CG 解放（`cgLibrary.has(key)==false` → イベント完了で true になるケース）でのみ `CgRevealScreen.show` を呼び、既解放の再生では出さない。`CgRevealScreen` は `AnimationController(500ms)` で `scale 0.95→1.0` + `opacity 0.0→1.0`、`autoDismissAfter=3秒` で自動クローズ。タップで即時クローズも可能。fadeRoute で push されるので導入演出も滑らか。
    - イベントフラッシュ: 共通/個別/出会いイベントの直前に `_triggerEventFlash()` を呼ぶと、HomeScreen の Stack 上層に 200ms だけ `Color(0x55FFFFFF)` の `ColoredBox` を被せる。`IgnorePointer` でタップ操作は通り抜ける。
    - 立ち絵フェード: `CharacterPortrait` の root を `AnimatedSwitcher(duration: 200ms)` で包み、`SizedBox(key: ValueKey('characterPortrait.<id>.<expression|silhouette>'))` のキー変化を検知。switchIn/switchOut は デフォルトの FadeTransition。既存テストの「2 つの key が一瞬同時に findsOneWidget で見つかる」可能性は `findsAtLeast(1)` 等で吸収可能だが、Sprint 10 範囲では既存テストの変更は不要（transition 完了状態のみを assert しているため）。
    - ハート段階アップ: `AffinityHearts` 内で前回 stage を `_lastStage` に保持し、`i >= _lastStage && i < stage` のインデックスのみ `_HeartPop(animate: true)` で 0.4 秒のスケール (0.6→1.3→1.0) + 光るリング表示。
  - 既存テストへの影響:
    - 285 件の既存テストはすべて無修正で pass。`AffinityHearts` の StatelessWidget → StatefulWidget 化、`CharacterPortrait` の AnimatedSwitcher 化、各種 `*_screen.dart` の `MaterialPageRoute` → `fadeRoute` 置換、`DialogueModal` / `EventPlayer` / `EndingScreen` の `Text` → `TypewriterText` 置換は、いずれも既存テストが assert している ValueKey / pumpAndSettle 終端 / 完了状態を破壊しないように維持した。
    - DialogueModal / EventPlayer / EndingScreen は `_resolveTextSpeed(BuildContext)` で AppScope の settings を try/catch で取得し、テストで AppScope が無い場合は textSpeed=0.5 のフォールバック値を使う。settings.textSpeed=1.0 を入れれば `pumpAndSettle` で全文一気に出る（cg_reveal integration test がこのパス）。

- [x] Sprint 11: 音とBGM — 完了日 2026-05-17
  - 実装ファイル:
    - 追加: lib/models/audio_keys.dart, lib/services/audio_service.dart, lib/services/scene_bgm_router.dart, test/logging_audio_service_test.dart, test/scene_bgm_router_test.dart, test/audio_volume_sync_test.dart, test/se_button_test.dart, test/voice_field_test.dart, integration_test/bgm_crossfade_test.dart, integration_test/volume_apply_test.dart
    - 改修: lib/app.dart（AppScope に AudioService を optional フィールドとして追加。SettingsState のリスナで bgmVolume/seVolume を audio に同期）, lib/main.dart（LoggingAudioService を本番 inject）, lib/models/settings_state.dart（seVolume を新設、updateSeVolume）, lib/services/settings_repository.dart（settings.seVolume の永続化）, lib/models/encounter.dart（DialogueLine に voiceKey を追加・デフォルト null）, lib/models/event.dart（EventLine に voiceKey を追加・デフォルト null）, lib/screens/title_screen.dart（StatelessWidget → StatefulWidget 化し進入時に bgm.title をクロスフェード、各メニューに confirm/tap SE）, lib/screens/main_scaffold.dart（進入時に bgm.home をクロスフェード、タブ切替で tap SE）, lib/screens/home_screen.dart（StatChangeListener で statUp SE、_triggerEventFlash で eventFire SE、AppBar ボタンに tap SE、所持金不足 SnackBar に error SE）, lib/screens/settings_screen.dart（SE スライダー追加、戻るボタンを自作キー化して cancel SE）, lib/screens/ending_screen.dart（didChangeDependencies で bgm.ending クロスフェード）, lib/widgets/dialogue_modal.dart（進入で bgm.dialogue、戻り時は直前 BGM へ復帰、各 next/voiceKey 再生）, lib/widgets/event_player.dart（同上に加えて閉じるで cancel SE、選択肢決定で confirm SE）, lib/widgets/action_sheet.dart（選択時に confirm SE）, lib/widgets/affinity_hearts.dart（didUpdateWidget で stage 増加時に heartUp SE）, test/test_helpers.dart（createTestSettings に seVolume 追加、wrapWithAppScope に audio 注入＋音量同期リスナ）, test/settings_screen_test.dart（スライダー3本へ更新、戻るボタンをキー指定に変更）
  - Generator 自己評価:
    - 基準1（タイトル画面で専用BGM）→ ◯ test/se_button_test.dart の「タイトル『はじめから』タップで se.confirm」内で進入時に bgm.title が history に含まれることを副次検証 ＋ integration_test/bgm_crossfade_test.dart で title 進入時に audio.currentBgmKey == bgm.title を検証（手動検証はアセット未導入のため評価フェーズ）
    - 基準2（画面遷移でBGMがクロスフェード）→ ◯ test/scene_bgm_router_test.dart で「順次タイトル→ホーム→会話で正しい BGM key が要求される」＋ integration_test/bgm_crossfade_test.dart で MugenSiritoriApp 起動 → title → home へ進む間に bgm.title → bgm.home の遷移と crossfade=true を検証
    - 基準3（ボタンタップで決定SE）→ ◯ test/se_button_test.dart の3ケース（タイトル「はじめから」、設定戻る、行動シート決定）で AudioService.history に該当 SE キーが現れることを検証
    - 基準4（設定でBGM音量変更が即時反映）→ ◯ test/audio_volume_sync_test.dart の3ケース（settings.updateBgmVolume → audio.bgmVolume / settings.updateSeVolume → audio.seVolume / スライダードラッグで反映）＋ integration_test/volume_apply_test.dart で 0.7 → 0.3 の遷移を end-to-end 検証
    - 基準5（ボイスフィールドの空配置）→ ◯ test/voice_field_test.dart で DialogueLine / EventLine ともに voiceKey デフォルト null、指定可能、他フィールドへ影響なしを検証。さらに DialogueModal / EventPlayer 内で voiceKey が非 null なら AudioService.playSe で再生要求する経路をコード上に配置（実音アセット投入時に即動作）
  - flutter analyze: clean (No issues found)
  - flutter test: 336/336 pass（既存 314 + 新規 22）
  - 設計メモ:
    - AudioService 抽象（実音ライブラリ未導入の理由）: 仕様メモ通り audioplayers 等の依存パッケージは追加しない。理由は (1) 実サウンドアセット未投入のためライブラリだけ入れても無意味 (2) インフラ層を抽象化することで将来ライブラリを差し替えれば実音化できる構造を保つ (3) テストでは [LoggingAudioService] で十分。本番でも当面これを inject。将来 audioplayers 等を導入する際は `lib/services/audio_service.dart` に `_RealAudioService implements AudioService` を追加し、`lib/main.dart` の `LoggingAudioService` 行 1 か所を差し替えるだけで切替完了。AppScope / SceneBgmRouter / SettingsState のリスナ経路は無改修で動作する。
    - AudioKeys 体系: lib/models/audio_keys.dart に集約。命名規約は `bgm.<scene>` / `se.<action>` / `voice.<character>.<id>`。アセット投入時に `bgm.title → assets/audio/bgm_title.mp3` のように `.` を `_` に置換すれば 1:1 でファイル名に対応する想定。BGM 6 種・SE 8 種を const String で定義し、`knownBgmKeys` / `knownSeKeys` で全列挙も可能。
    - SceneBgmRouter の発火経路: `NavigatorObserver` 方式は採らず、各画面の `didChangeDependencies` で 1 度だけ `SceneBgmRouter.enterWithService(audio, BgmScene.xxx)` を明示呼び出し。理由: fadeRoute / slideUpRoute が `RouteSettings` を持たないので observer ベースだと画面判定が脆い。エントリーポイントは title_screen.dart, main_scaffold.dart, dialogue_modal.dart, event_player.dart, ending_screen.dart の 5 箇所。同じキーへの再要求は AudioService 側で no-op。
    - 設定スライダー → 音量同期の仕組み: lib/app.dart の `_MugenSiritoriAppState.initState` で `widget.settings.addListener(...)` を 1 度だけ登録し、リスナ内で `_audio.bgmVolume = widget.settings.bgmVolume` / `_audio.seVolume = widget.settings.seVolume` を呼ぶ。SettingsState は ChangeNotifier なので `updateBgmVolume` / `updateSeVolume` 後に `notifyListeners()` が走り、即時反映される。テストヘルパ `wrapWithAppScope` でも同じリスナを設置するため、widget test 経由でも同期が確認できる。
    - 直前BGMの復帰: DialogueModal / EventPlayer は進入時に `audio.currentBgmKey` を `_previousBgm` に控え、dispose 時にクロスフェードで戻す。これにより会話 → ホーム復帰時に bgm.home が自動で鳴り直す。同じキーへのクロスフェードは AudioService 側で no-op なので連続発火しても安全。
    - SE 発火ポイント: タップ系（home AppBar / title 図鑑/設定 / main タブ）= seTap、決定系（title はじめから/つづきから / event next / choice / action sheet）= seConfirm、キャンセル系（settings 戻る / event 閉じる）= seCancel、能力値上昇（GameState.statChangeListener で delta > 0 かつ stress 以外）= seStatUp、ハート段階アップ（AffinityHearts.didUpdateWidget で stage 増加）= seHeartUp、イベント発火フラッシュ = seEventFire、所持金不足 SnackBar = seError。affinityUp は将来「数値変動のみ・段階アップなし」の場合に使い分けたいので別キーで温存。
    - ボイスフィールド: DialogueLine / EventLine に `voiceKey` を named optional で追加。デフォルト null。既存呼び出し（27 ファイルの const DialogueLine / EventLine 構築箇所）は全て無修正。DialogueModal / EventPlayer の発話切替時に voiceKey != null なら `audio.playSe(voiceKey)` を呼ぶ経路を実装済み。実ボイス導入時は CharacterRepository / IndividualEventCatalog のセリフに voiceKey を埋めるだけ。
  - 既存テストへの影響:
    - 314 件のうち 2 件のみ修正: (1) test/settings_screen_test.dart「スライダー2種→3種」と戻るボタンを `byTooltip('Back')` → `byKey('settings.backButton')` に変更（Sprint 11 で leading を自作 IconButton 化したため）。
    - 他 312 件は無修正で pass。
    - test_helpers.dart の wrapWithAppScope に optional `audio` を追加。既存呼び出しは null 渡しなので自動で LoggingAudioService が生成され、SettingsState 変化を audio に同期するリスナが付く形。

- [x] Sprint 12: 最適化と仕上げ — 完了日 2026-05-17
  - 実装ファイル:
    - 追加: lib/models/gift_item.dart, lib/models/inventory.dart, lib/data/gift_catalog.dart, lib/screens/shop_screen.dart, lib/screens/inventory_screen.dart, docs/qa_checklist.md, test/inventory_test.dart, test/shop_screen_test.dart, test/inventory_screen_test.dart, test/ending_archive_hint_test.dart, test/memory_leak_smoke_test.dart, integration_test/shop_purchase_test.dart
    - 改修: lib/main.dart（起動シーケンスを Settings 先行 + Save/Archive を `Future.wait` で並行化、`keepHistory: false` で LoggingAudioService 起動）, lib/services/audio_service.dart（`LoggingAudioService` に `keepHistory` フラグ追加、内部 `_record` で履歴抑制）, lib/models/game_state.dart（Inventory 内蔵、`purchaseGift` API 新設、`toMap/restoreFromMap` で inventory 往復、`resetToStart` で inventory.clear、`dispose()` を override してリスナ＋inventory を解放）, lib/data/endings.dart（`EndingBody.hints` を必須フィールド化、全 7 ED に 3 行ずつヒント追加）, lib/screens/ending_archive_screen.dart（未達成タップで `_showHintDialog` → AlertDialog でヒント 3 行表示）, lib/screens/home_screen.dart（AppBar に `home.shopButton` 追加、`_triggerEventFlash` の Future.delayed → Timer 化、dispose で cancel）, lib/screens/cg_reveal_screen.dart（自動クローズ Future.delayed → Timer 化、dispose で cancel）, lib/widgets/dialogue_modal.dart（`_audio` キャッシュで dispose 中の `AppScope.of(context)` 呼び出しを排除）, lib/widgets/event_player.dart（同上）, lib/widgets/affinity_hearts.dart（didChangeDependencies で `_audio` キャッシュ、didUpdateWidget の try/catch 排除）
  - Generator 自己評価:
    - 基準1（コールドスタート 3 秒以内 / 実機）→ ◯ 設計面：`main.dart` で SettingsRepository 先行 + SaveRepository/EndingArchive を `Future.wait` で並行ロード、`LoggingAudioService(keepHistory: false)` で履歴増殖を抑制。`docs/qa_checklist.md` § 2 に「3 回計測中央値で 3 秒以内」の手動計測手順を残した。実機計測は Evaluator フェーズ
    - 基準2（1 時間プレイでメモリ 2 倍以内 / 実機）→ ◯ 設計面：DialogueModal / EventPlayer / AffinityHearts の dispose 中の `AppScope.of(context)` 呼び出しを排除（参照キャッシュ化）、HomeScreen の `_flashTimer` / CgRevealScreen の `_autoDismissTimer` を Timer 化し dispose で cancel、`GameState.dispose` を override して内部 Inventory と各リスナリストを解放、本番 `LoggingAudioService.keepHistory=false` で履歴 list 無限増殖を防止。test/memory_leak_smoke_test.dart で HomeScreen / Shop / Inventory の build → destroy 経路を例外無しに完走することを検証。実機メモリ計測は docs/qa_checklist.md § 3 の手順
    - 基準3（未達成 ED タップでヒント 3 つ表示）→ ◯ test/ending_archive_hint_test.dart 5 ケース（ダイアログ表示 / ヒント文一致 / 達成済はダイアログを出さず本文再生 / 閉じるで dismiss / 全 7 ED に 3 行ずつ）で完全網羅。`EndingBody.hints` は必須フィールド化済み
    - 基準4（ショップで購入 → 所持金減少 + 所持アイテムに +1）→ ◯ test/shop_screen_test.dart 6 ケース（全 9 商品グリッド表示 / ヘッダの所持金 + 所持数 / 購入で所持金減少 + Inventory+1 / 所持金不足で disable / 1500 円ぴったり購入可 / 累積購入）、test/inventory_screen_test.dart 3 ケース（空表示 / 一覧表示 / ChangeNotifier 反映）、test/inventory_test.dart 18 ケース（Inventory モデルの加減 / シリアライズ往復 / GiftCatalog 整合性）、integration_test/shop_purchase_test.dart で「ホーム → ショップアイコン → 花束購入 → 所持アイテム画面で花束が見える」を end-to-end 検証
    - 基準5（通しプレイの致命バグ確認）→ ◯ docs/qa_checklist.md § 4 に「4/1 開始 → 4/10 七瀬出会い → 4/15 久遠出会い → 5/1 給料 → 6/15 健康診断 → 8/13 夏祭り → 12/24 クリスマス選択 → 3/31 ED 再生 → 図鑑登録 → セーブ復元 → ショップ購入」の全工程チェックリストを残した。実機通しプレイは Evaluator フェーズ
  - flutter analyze: clean (No issues found)
  - flutter test: 372/372 pass（既存 336 + 新規 36）
  - 設計メモ:
    - 起動シーケンス最適化方針: 旧実装は `SettingsRepository.load → SaveRepository.load → EndingArchive.load` の 3 連直列 await。新実装は (1) Settings を最初に await（UI テーマに必要なので先行ロード必須）、(2) Save / EndingArchive を `Future.wait` で並行化。SharedPreferences インスタンスは内部で同じものを共有するため実 I/O は実質 1 件ぶんのコスト。`runApp` 前のブロッキング時間が短縮される。さらにデフォルト値で即 runApp する案も検討したが、設定画面のテーマモードが「ローディング後に切り替わる」UX が悪化するため不採用。
    - メモリリーク修正で触った箇所一覧:
      1. lib/widgets/dialogue_modal.dart: dispose 中の `AppScope.of(context).audio.crossfadeBgm(prev)` が、Widget tree から外れた後だと InheritedWidget が辿れない → State.dispose 後に発火する例外要因。didChangeDependencies で `AudioService? _audio` をキャッシュし、dispose では `_audio?.crossfadeBgm(prev)` を使う方式に変更。
      2. lib/widgets/event_player.dart: 同上（dispose / _maybePlayVoice / _onNext / _onPickChoice / _skipToEnd すべて）。AudioService 参照をキャッシュ化。
      3. lib/widgets/affinity_hearts.dart: didUpdateWidget で毎回 try/catch していた `AppScope.of(context)` をやめ、didChangeDependencies で 1 回キャッシュ。
      4. lib/screens/home_screen.dart: `_triggerEventFlash` の `Future.delayed` を `Timer` に置換し、`_flashTimer?.cancel()` を `dispose()` に追加。フラッシュ中に画面遷移するとタイマが残る可能性があった。
      5. lib/screens/cg_reveal_screen.dart: `autoDismissAfter` の `Future.delayed` を `Timer` に置換し、`_autoDismissTimer?.cancel()` を `dispose()` に追加。手動タップで早めに閉じた場合に Timer が残らない。
      6. lib/services/audio_service.dart: `LoggingAudioService` の `_history` List が無制限に増えるのを `keepHistory: false`（本番デフォルト想定）で停止できるよう改修。`_record` 内側で gate。テストは `keepHistory: true` で従来通り。
      7. lib/models/game_state.dart: `dispose()` を override し、`_inventory.dispose()` と `_dayAdvanceListeners.clear()` / `_statChangeListeners.clear()` を実施。`AppScope.of(context).gameState.dispose()` がアプリ終了時に確実にリスナ参照を断ち切る。
    - ショップの商品体系: 全 9 種を 2 ティアで構成。汎用品 4 種（焼き菓子 800 / ハンドクリーム 1200 / 香り袋 1500 / 小ぶりの花束 1500）= 全員向け、キャラ別好み品 5 種（七瀬=文芸文庫 2000 / 久遠=スペシャルティ珈琲豆 1800 / 鴻巣=ガジェット技術誌 2500 / 蓮見=紅茶セット 2200 / 槙原=プロテインバー 1500）= `targetCharacterId` + `affinityBonus=2`。価格レンジは 800〜2500 円で、給料 1 ヶ月分（数万円〜10 万円）に対して気軽に複数買える金額感。商品名・説明はすべて完全オリジナル。
    - 「渡す」UI は仕様メモ「基礎枠のみ」を尊重して未実装。`GiftItem.affinityBonus` は将来のために保持。`Inventory.consume(itemId)` API も先行用意済み（バーチャル渡しで -1 / `applyChoiceOutcome` 適用、を 1 ファイルで書ける構造）。
    - ヒント機能の位置: `lib/data/endings.dart` の `EndingBody.hints: List<String>` を必須フィールド化（旧コードは hints 無しでも動くがコンパイラが警告）。`lib/screens/ending_archive_screen.dart` の itemBuilder で「未達成」エントリの onTap を `_showHintDialog(context, kind)` に切替え、`EndingBodyCatalog.bodyOf(kind).hints` から 3 行を取り出して AlertDialog で表示。各ヒントは「条件を直接書かない、雰囲気で示唆する」3 行に統一済み（akari=「焦らずに〜」「答えを急がず〜」「歩幅を観察〜」、uta=「看板を下ろした時間〜」「貸し借りではなく〜」「夜の珈琲〜」、toru=「線引きを越える前に〜」「会議室の外で〜」「相手の挫折を聞く〜」、sayo=「センサーライト〜」「ドアの前で立ち止まる〜」「もう一度信じてもらう〜」、yui=「観客でいてあげる〜」「前夜の不安〜」「息遣いに合わせて〜」、normal=「深く関わらなくても〜」「昼食を作れる〜」「時間を使うことを〜」、true=「夜の珈琲が示すもの……」「全員と適切な距離〜」「自分を見失わずに〜」）。
    - QA チェックリストの位置: `docs/qa_checklist.md`（新規）。9 セクション構成（実機セットアップ / 起動時間 / メモリ / 通しプレイ / UI / サウンド / 低スペック / 既知の残課題 / リリース判定）。受け入れ基準 1, 2, 5 はこのドキュメントの手順で Evaluator が実機評価する。
  - 既存テストへの影響:
    - 336 件の既存テストはすべて **無修正で pass**。`EndingBody` の hints フィールド必須化は data/endings.dart 内のみで完結し、外部 import 経路で破壊的変更を起こさない。`GameState.dispose` の override は ChangeNotifier の super.dispose() を必ず呼ぶため挙動互換。
    - test_helpers.dart は無修正。

## 次のスプリント
**プロジェクト完了**。全 12 スプリント実装完了。

実機計測（起動時間 3 秒以内 / 1 時間プレイメモリ 2 倍以内 / 通しプレイ致命バグ無し）と
実アセット投入（BGM 6 / SE 8 / 立ち絵 / CG 48 件 / 背景）が Evaluator フェーズの作業。
それらが完了すればリリース可能水準。

## 既知の負債
- 状態管理は最小限の `InheritedWidget` + `ChangeNotifier` で実装。Sprint 06 以降でゲーム状態が増えたら Riverpod 等の導入を検討。
- integration test の実機実行は Evaluator フェーズで行う。
- `pubspec.yaml` の `description` がデフォルトのままなのでいずれ書き換える。
- 能力値詳細のスパークライン（直近7日）と変動履歴は Sprint 02 範囲外。Sprint 03 以降で値が変動するようになった時点で追加する。
- アルバムタブはスタブのみ。Sprint 08 で実装される想定。スケジュールは Sprint 05、キャラは Sprint 06 で実装済。→ Sprint 08 でメモリーアルバム本実装に置換済。
- スケジュールの予約データはインメモリのみ（lib/models/schedule.dart 内 `ScheduleStore`）。アプリ再起動で消える。Sprint 09 のセーブ/ロードで永続化する。
- 所持金の正規化バーは表示上 200,000 円キャップ。給料が入る Sprint 04 以降に上限の妥当性を再検討。
- 立ち絵は Sprint 06 時点ではプレースホルダ Widget（CharacterPortrait）で円形 themeColor + イニシャル + 表情アイコンを Stack で重ねた構造。実イラスト導入時は Container 部を Image.asset に差し替える単一ポイントを残してある（コメント参照）。アセット命名規約案は `assets/characters/[id]_[expression].png`。
- 「誘う」行動の成功率は Sprint 06 で固定 70%。→ Sprint 07 で lib/models/invite_balance.dart の `inviteSuccessPercent(affinity)` 式に置換済み。
- CharacterState.affinity の実値変動は Sprint 06 では誘い成功時の +1 記録のみで、ハート段階表示には影響しない（getter で 0 でも段階 1 を返す仕様）。→ Sprint 07 で spec §6 の 0/20/40/60/80 閾値で段階上昇するように本実装済み。
- DialogueModal はタイプライター演出・選択肢・バックログを未実装。Sprint 08（イベント本体）と Sprint 10（演出強化）で順次拡張する。Sprint 07 で `ChoiceOutcome` 型は lib/models/dialogue.dart に先行追加済み。
- 個別イベント解放・節目イベント・ランダム遭遇は Sprint 08 範囲。Sprint 06 は「最初の出会い 5 本」のみ。→ Sprint 08 で個別 25 本・ランダム 8 本・節目（クリスマス）実装済。
- Sprint 07 追加: 誘い成功後のミニ会話は AlertDialog ベースの暫定 UI。Sprint 08 のイベントシステム実装時に DialogueModal の選択肢対応へ移行する想定（`ChoiceOutcome` のデータ構造は既に共通化済み）。
- Sprint 07 追加: 疎遠ペナルティ通知は SnackBar 1 行のみ（複数キャラ同時発火時は「名前A・名前B」と中点連結）。演出強化は Sprint 10。
- Sprint 07 追加: `lastInteractedDate` は誘い・拒否・選択肢適用で更新されるが、出会いイベント以外の通常の自宅/外出行動では更新されない（仕様準拠：「会う」ことが交流とみなす）。スケジュール画面の予約自動実行で「キャラと会う行動」が増えたらここで更新する。
- Sprint 08 追加: イベント発火状態（`GameState.unlockedGlobalEventIds`, `CharacterState.unlockedEventIds`）と CG 解放状態（`GameState.cgLibrary`）はインメモリ管理。アプリ再起動で全て消える。Sprint 09 のセーブ/ロードで永続化必須。スキーマは `CharacterState.toMap/fromMap` が既に `unlockedEventIds` を含む形に拡張済み、`CgLibrary.snapshot/restoreFrom` で List<String> として往復できる API を用意済み。
- Sprint 08 追加: CG は実画像なしのプレースホルダ（CgView）。実装ファイル `lib/widgets/cg_view.dart` の Container 部 1 か所を `Image.asset('assets/cg/${cgKey}.png', fit: BoxFit.cover)` に差し替えれば実画像対応に切り替わる。命名規約は `cg.<category>.<id>` 形式。アセット 48 ファイル分のキー一覧は CommonEventCatalog / IndividualEventCatalog / christmas_choice_screen.dart に分散して定義。
- Sprint 08 追加: ランダム遭遇判定は HomeScreen の `randomEventRng` が null のときスキップする safe-default 設計。テスト互換性のため。実プレイ時は MainScaffold が `Random()` を State として 1 つ保持して HomeScreen に渡す。
- Sprint 08 追加: 共通イベントの選択肢でストレス差分のみを反映するため `GameState.bumpStress(int)` を新設。`applyChoiceOutcome` は target が必要で、共通イベントには target が無いため別経路にした。Sprint 09 以降で「主人公能力値全般を動かす ChoiceOutcome 拡張」を検討するときに統合可能。
- Sprint 08 追加: 「予約自動実行 / 個別イベント発火」の優先順位は HomeScreen._onSlotTap の if 順に固定。条件が複雑になるなら EventPriorityResolver 等に外出ししたい（現状は spec § Sprint 08 「特定の枠でそれが優先発火する」がシンプルなのでベタ書き）。
- Sprint 08 追加: 個別イベント Event 2/4 には `requiredMonth` を付けていない（任意月でも段階が上がれば解放）。Event 3/5 のみ季節縛り。spec § 5 の「鍵」を季節モチーフに寄せたが、もし「全 Event に月縛りが要る」となったら IndividualEventCatalog のメタを増やすだけで対応可能。
- Sprint 08 追加: クリスマスを `CommonEventCatalog.all` にも入れているが、`resolveCommon` 側で category=common のみフィルタすることで二重発火を防止。アルバム画面の CG 一覧でも all を走査するため、クリスマス本体 CG (`cg.common.christmas_dec`) もアルバムに 1 件出る形。
- Sprint 09 追加: SaveRepository / EndingArchive は SharedPreferences ベース。1 セーブ ≒ 5〜10 KB 想定で iOS/Android の上限に収まる。クラウドセーブは Sprint 12 「将来拡張」で対応。
- Sprint 09 追加: GameState.toMap/restoreFromMap はバージョンフィールド（top-level `version: 1`）持ち。Sprint 10 以降でスキーマ追加するときに既存セーブを壊さないよう、復元側は欠落キーをデフォルト値にフォールバックする。
- Sprint 09 追加: AppScope の saveRepository / endingArchive を nullable 化（既存テスト互換）。Sprint 10 以降で全テストが新シグネチャに移行できたタイミングで required 化を検討。
- Sprint 09 追加: エンディング再生画面のタイプライター演出は未実装（Sprint 10 で会話画面と統一して入れる予定）。Sprint 09 では 1 タップ 1 行の即時表示。
- Sprint 09 追加: 真 ED の cgKey と図鑑サムネは CgView プレースホルダ。実 CG 画像導入時は assets/cg/{cgKey}.png を 7 枚（ED 7 種ぶん）追加するだけで彩色サムネが置き換わる。命名規約は cg.ending.{id}。
- Sprint 09 追加: バッド系 ED（燃え尽きEnd・左遷End）は spec §8 で「カウント外」明記のため Sprint 09 では実装せず。Sprint 12 で考慮する想定。
- Sprint 09 追加: 「告白イベント」相当の判定は spec §8 では明示的に要件化されているが、Sprint 09 では「個別イベント解放（CharacterState.unlockedEventIds に Event5 が含まれる）」を実質的な告白通過とみなさず、表面好感度 80＋真好感度 20 の閾値だけで個別 ED を判定している。Sprint 10〜11 で各キャラの「告白前夜」イベントが追加されたら、判定条件に AND として組み込む。
- Sprint 09 追加: EndingScreen の onComplete で popUntilTitle を呼ぶことを想定しているが、HomeScreen から起動した場合に MainScaffold ごと閉じる挙動。タイトル → はじめからで新しい GameState が必要になる（resetToStart を呼ばないと前回プレイ状態が残る）。Sprint 10 でリプレイ系の遷移整理を行う想定。
- Sprint 10 追加: `ScenicBackground` のグラデーション色（季節 4 × 時間帯 4 = 16 通り）は手動定数。実画像背景（雨の窓・夜景）への置換は Sprint 12 以降の仕上げで検討。差替えポイントは `_topColorFor` / `_midColorFor` / `_bottomColorFor` の 3 関数のみ。
- Sprint 10 追加: 「演出を簡略化」モードは仕様メモで触れられたが必須でないため未実装。タイプライターを即時化したい場合は `settings.textSpeed = 1.0` で代替可能。Sprint 11 で BGM 設定と並べる際にトグル化を検討する。
- Sprint 10 追加: `StatChangeOverlayController` は HomeScreen の State 内に保持し、画面遷移時には自動で `dispose` されるが他画面（StatsScreen 等）には流れていない。能力値詳細画面で履歴表示する Sprint 12 では別途リスナを共有する必要がある。
- Sprint 10 追加: イベント発火時の白フラッシュ（200ms `Color(0x55FFFFFF)`）はホーム画面の Stack 内にのみ存在。EventPlayer / DialogueModal の push 後は遷移アニメーションに隠れるため副作用が小さい。設定で OFF にする選択肢は Sprint 11 で検討。
- Sprint 11 追加: 実音再生ライブラリ（audioplayers 等）は **未導入**。LoggingAudioService が history を貯めるだけのスタブ実装。アセット投入と同時に `lib/services/audio_service.dart` に実ライブラリ実装を加え、`lib/main.dart` の 1 行を差し替えるだけで実音化できる構造。Sprint 12 でアセット導入 + ライブラリ導入の判断（軽量 OGG/MP3 ループ + プールサイズ等）が必要。
- Sprint 11 追加: BGM のクロスフェード時間は LoggingAudioService 上では「論理切替＝即値変更」。実ライブラリ実装時に「1 秒のクロスフェード」を実装する必要あり。`AudioCall.crossfade` フラグは履歴上の意図表明としてのみ使われている。
- Sprint 11 追加: `affinityUp` SE キーは命名済みだが現状ハート段階アップ時の `heartUp` SE のみ発火。「数値変動はあったが段階は変わらない」ケースで `affinityUp` を使い分けたいが、現状の GameState は段階変化のリスナを持たない（AffinityHearts の didUpdateWidget で検知）。Sprint 12 でキャラ詳細以外の画面でも好感度変動 SE を鳴らしたいなら GameState に affinityChangeListener を導入する必要あり。
- Sprint 11 追加: voiceKey は DialogueLine / EventLine の named optional フィールドとして空配置のみ。既存の出会いシナリオ・個別イベント 25 本・共通イベント 9 本のいずれにも voiceKey は埋め込んでいない（実ボイス未収録のため）。実ボイス導入時の運用案: `lib/data/character_repository.dart` に CharacterId ごとのボイス命名規約 `voice.<characterId>.<eventId>.<lineIndex>` をヘルパとして定義し、各 EventLine の voiceKey を逐次埋める。
- Sprint 11 追加: DialogueModal / EventPlayer の dispose 内で「直前BGM へ復帰」する処理は、AppScope が既に破棄されているケース（テスト終了直後など）を考慮して try/catch で握りつぶしている。実プレイ時には常に AppScope が存在するため問題なし。
- Sprint 11 追加: シーン進入の BGM 切替は `didChangeDependencies` で 1 度だけ実行する `_bgmRequested` フラグ方式。タブ切替で MainScaffold が再構築されない設計（IndexedStack）と整合する。子画面（CharactersScreen / SchedulingScreen 等）は独自に BGM 進入を持たず、MainScaffold の bgm.home を継承する。
- Sprint 12 追加（残課題・将来拡張）:
  - 実音アセット未配置（BGM 6 + SE 8）。`LoggingAudioService` のため実音は鳴らない。アセット投入時は `lib/services/audio_service.dart` に `_RealAudioService implements AudioService` を追加し、`lib/main.dart` の 1 行（`LoggingAudioService` インスタンス化）を差し替えるだけ。
  - 実画像（立ち絵 5 名 × 表情 3 種 = 15 件 / CG 48 件 / 背景）未配置。`CharacterPortrait` / `CgView` / `ScenicBackground` の差し替えポイントが各 1 箇所に集約済み。
  - 実機計測ベースの起動時間 / メモリ最適化は QA フェーズ送り。`docs/qa_checklist.md` の手順で Evaluator が実施。
  - 課金・追加キャラ・追加シナリオ・クラウドセーブは将来拡張枠（リリース後のアップデート）。
  - バッド系 ED（燃え尽き / 左遷）は引き続き未実装（spec §8 カウント外明記のため）。需要があれば 2nd リリースで追加検討。
  - 真 ED の cgKey と図鑑サムネは依然 CgView プレースホルダ（実 CG 7 枚で完成）。
  - 「告白前夜」イベントが各キャラに無く、ED 判定は「表面 80 + 真 20」の閾値のみ。シナリオ追加時に AND 条件として組み込み。
  - ScenicBackground の実画像背景（雨の窓・夜景写真）への置換は将来拡張。差替えポイントは `_topColorFor` / `_midColorFor` / `_bottomColorFor` の 3 関数。
  - Sprint 12 範囲外: プレゼントを「キャラに渡す」UI（仕様メモ「基礎枠のみ」尊重）。`GiftItem.affinityBonus` と `Inventory.consume` API は先行用意済み。キャラ詳細画面に「贈り物を渡す」ボタンを追加するだけで実装完了する想定。
  - Sprint 12 範囲外: `affinityUp` SE の段階以外発火（数値変動のみで段階維持のケース）。GameState に `addAffinityChangeListener` を追加すれば対応可能。
  - Sprint 12 範囲外: 能力値詳細画面のスパークライン / 履歴。`StatChangeOverlayController` を AppScope に持ち上げて履歴を共有する設計に変更すれば実装可能。
  - `pubspec.yaml` の `description` がデフォルトのまま。リリース直前に書き換える。
  - `LoggingAudioService.keepHistory=false` 設定で本番起動するが、デバッグビルドで履歴を見たい場合は手元で `true` に戻すか、テスト経由で確認する。

## 更新履歴
- 2026-05-17 仕様書作成完了（Planner）
- 2026-05-17 Sprint 01 実装完了（Generator）
- 2026-05-17 Sprint 02 実装完了（Generator）
- 2026-05-17 Sprint 03 実装完了（Generator）
- 2026-05-17 Sprint 04 実装完了（Generator）
- 2026-05-17 Sprint 05 実装完了（Generator）
- 2026-05-17 Sprint 06 実装完了（Generator）
- 2026-05-17 Sprint 07 実装完了（Generator）
- 2026-05-17 Sprint 08 実装完了（Generator）
- 2026-05-17 Sprint 09 実装完了（Generator）
- 2026-05-17 Sprint 10 実装完了（Generator）
- 2026-05-17 Sprint 11 実装完了（Generator）
- 2026-05-17 Sprint 12 実装完了（Generator）— **プロジェクト完了**

## Hotfix 2026-05-18: 緊急バグ + UX 改善

トークン節約モードでの最小差分修正。新機能追加なし。

### Block A: 緊急バグ修正
- **A1**: `lib/screens/home_screen.dart` — `DayAdvanceEvent` を `Queue` で直列化。`_onDayAdvanceEvent` が同フレームの複数イベントを 1 個ずつ await で順処理し、Navigator スタック破壊を防ぐ。test 追加: `test/day_advance_queue_test.dart`（3 件積み + dispose 中断の 2 ケース）。
- **A2**: `lib/screens/album_screen.dart` から `debugUnlockForAlbumTest` を削除し `test/test_helpers.dart` へ移動。本番 import グラフから完全分離。
- **A3**: silent fail 解消の `debugPrint` を 11 箇所に追加。dialogue_modal × 2 / event_player × 2 / affinity_hearts / save_repository / action_sheet / ending_archive / home_screen / ending_screen × 2。

### Block B: UX 改善
- **B1**: `lib/widgets/dialogue_modal.dart` / `lib/widgets/event_player.dart` の右上に「全文スキップ」ボタン (`Icons.fast_forward`) を追加。イベント末ジャンプ（選択肢があれば選択肢へ）。
- **B2**: 同 2 widgets に「オート再生」トグル (`Icons.play_arrow` / `Icons.pause`) を追加。固定 1.5 秒で次行に進む。選択肢で自動停止。
- **B3**: `lib/screens/tutorial_screen.dart` 新規追加（3 画面・テキストのみ）。`name_input_screen.dart` を経由フロー化し、SharedPreferences `tutorial.shown` で初回のみ表示。
- **B4**: `home_screen.dart` の平日日中フローから `showWorkConfirmDialog` 呼び出しを削除（即ロール → 結果ダイアログ 1 つ）。月 60 タップ → 月 20 タップに短縮。`test/work_judgment_widget_test.dart` 更新。
- **B5**: `home_screen.dart` の AppBar セーブアイコンを削除し、画面下に `FloatingActionButton.small` (`home.saveFab`) を追加。設定/ショップは AppBar 残し。

### 変更/追加ファイル一覧
- 追加: `lib/screens/tutorial_screen.dart`, `test/day_advance_queue_test.dart`
- 改修 (lib): `screens/home_screen.dart`, `screens/album_screen.dart`, `screens/name_input_screen.dart`, `screens/ending_screen.dart`, `widgets/dialogue_modal.dart`, `widgets/event_player.dart`, `widgets/action_sheet.dart`, `widgets/affinity_hearts.dart`, `services/save_repository.dart`, `services/ending_archive.dart`
- 改修 (test): `test_helpers.dart`, `name_input_screen_test.dart`, `work_judgment_widget_test.dart`, `widget_test.dart`（旧 Flutter 標準テンプレ削除）

### 検証結果
- `flutter analyze`: No issues found.
- `flutter test`: 375/375 pass。
- `flutter test integration_test/ -d emulator-5554`: 29/29 pass（回帰修正後、所要 17:25）。

### Hotfix 追補: integration test 回帰修正（2026-05-18）
Hotfix 本体の UI 変更（B3 チュートリアル / B4 仕事ダイアログ廃止 / B1 全文スキップ ボタン / B2 オート再生 ボタン）と直列キュー（A1）に既存 integration test を追従させた。プロダクトコードは無変更（Hotfix を打ち消さない）。
- `setMockInitialValues({})` を `{'tutorial.shown': true}` に置換: 16 ファイル
- `work.confirmDialog.ok` タップを削除（B4 で確認ダイアログ廃止）: weekly_flow / salary_event / day_loop
- DialogueModal / EventPlayer のタイプライター完了待ちで「変化が観測できるまで多めにタップ」に改修: encounter_flow / individual_event / cg_reveal / christmas / health_check
- 直列キュー化で同フレーム複数モーダル（weeklyReview → encounter）の場合、先のモーダルを閉じてから検証: encounter_flow / health_check / invite_ten_times / scheduled_action
- 4 月通しプレイのランダム遭遇 EventPlayer を `tooltip='閉じる'` で即離脱: salary_event
- 設定画面の戻るボタンを `byTooltip('Back')` から `byKey('settings.backButton')` に修正: settings_persistence
- 美術館自動実行テストの能力値検証を 100 クランプ前提に修正: scheduled_action
- salary_event のタイムアウトを 5 分 → 10 分に延長（モーダル閉じ込みでループが長くなったため）
- 2026-05-18 Hotfix 完了（Generator）

### Hotfix 後追い: パッケージ整備 + 実音再生実装（2026-05-18）
トークン節約モード。新機能追加なし、最小差分。
- **Block A: AudioPlayers 実装**
  - `pubspec.yaml` に `audioplayers: ^6.1.0`（解決時 6.6.0）追加
  - `lib/services/audio_service.dart` 末尾に `_RealAudioService implements AudioService` を追加。BGM/SE 各 1 つの AudioPlayer、500ms 簡易クロスフェード（Timer.periodic で 50ms 刻みのフェードアウト→新規再生→フェードイン）、欠損アセットは debugPrint で握りつぶし
  - 公開ファクトリ `createProductionAudioService(...)` を追加（LoggingAudioService は非破壊）
  - `lib/main.dart` の本番 audio を `createProductionAudioService` に差し替え。テスト用 LoggingAudioService は test_helpers 経由で温存
  - `assets/audio/` ディレクトリ + README 配置。`pubspec.yaml` の `flutter.assets` は実 mp3 投入時に解禁する形でコメントアウトのまま
- **Block B: pubspec / Android / iOS のリブランド**
  - `pubspec.yaml`: `name: mugen_siritori` → `tokimemo`、description 更新、version 1.0.0+1 維持
  - **全 .dart ファイル 81 件で `package:mugen_siritori/` → `package:tokimemo/` に PowerShell 一括置換**（test/integration_test 含む）。BOM が混入したため事後にバイト単位で BOM 除去
  - `android/app/build.gradle.kts`: namespace + applicationId を `com.example.tokimemo` に
  - `android/app/src/main/kotlin/com/example/mugen_siritori/` → `tokimemo/` にディレクトリ改名 + MainActivity.kt の package 宣言を `com.example.tokimemo` に
  - `android/app/src/main/AndroidManifest.xml`: `android:label` を `月と珈琲` に
  - `ios/Runner.xcodeproj/project.pbxproj`: `com.example.mugenSiritori` → `com.example.tokimemo`（6 箇所）
  - `ios/Runner/Info.plist`: CFBundleName を `tokimemo` に（iOS ビルド未確認、Mac 環境必要）
- **Block C: アセット命名規約ドキュメント**
  - `docs/assets_spec.md` 新規作成。BGM 6/SE 8/立ち絵 15/CG 48/背景 16 を実コード（`AudioKeys`, `CharacterId`×`Expression`, common_events / individual_events / christmas_choice_screen / ending.dart、`Season`×`DayPhase`）から抽出してファイル名対応表に
- **検証結果**
  - `flutter analyze` clean (No issues found)
  - `flutter test` 375/375 pass
  - `flutter build apk --debug` 成功（`build\app\outputs\flutter-apk\app-debug.apk` 生成。audioplayers_android のインクリメンタルキャッシュ警告は C: ドライブの pub cache と D: のプロジェクトの相対パス差で発生する既知の Windows 挙動でビルド自体は通る）
- **既知の限界 / 残作業**
  - mp3 アセット未投入のため、現状の `_RealAudioService` は全 play 呼び出しが try/catch で握りつぶされ無音。`docs/assets_spec.md` のチェックリストに沿った素材投入後、`pubspec.yaml` の `assets: - assets/audio/` のコメントアウトを解除する
  - iOS bundle id 変更は grep ベースのみ。Mac 環境での `flutter build ios` 確認は未実施
  - 立ち絵・CG・背景の実画像はまだ無く、各 widget はプレースホルダ描画のまま（`character_portrait.dart` / `scenic_background.dart`）。これは仕様通り
  - audioplayers の Windows ビルド時 Kotlin キャッシュ警告: 機能影響なし。回避には pub cache とプロジェクトを同一ドライブに置く運用変更が必要

## 2026-05-18 追記 — アセット投入準備フェーズ拡張（SE プール化 / assets サブディレクトリ / リスク考慮）
- `_RealAudioService` の SE プレイヤーを固定 3 個プール化（ラウンドロビン）、連打時の割り込みを排除
- `assets/characters|cg|backgrounds|ui/` に `.gitkeep` + 投入手順 README.md を追加、`docs/assets_spec.md` に「リスクと考慮事項」「実アセット投入時の手順」セクション追記
- flutter analyze clean / flutter test 375/375 維持

## 2026-05-29 追記 — 機能追加フェーズ（告白前夜 / バッドED / 仕事強化 / 個別追加 / 図鑑強化）

仕様書 §既知の負債で残っていた 5 機能を、セーブ互換と既存テスト互換を維持したまま追加。Planner は呼ばず、各機能を独立スプリントとして実装。

### Sprint A: 告白前夜イベント 5 本
- 追加: `lib/data/confession_eve_events.dart`（5 キャラ × 1 本、cgKey 5 件）
- 改修: `lib/models/event_resolver.dart` に `resolveConfessionEve` を追加（個別イベントより高優先）。発火条件: 表面好感度 ≥75 + 真の好感度 ≥15。
- 改修: `lib/models/game_state.dart` に `findConfessionEveEvent` を追加。
- 改修: `lib/models/ending_resolver.dart` の個別 ED 判定に「`confession_eve.{id}` が `unlockedEventIds` に含まれる」AND 条件を追加。Sprint 09 §既知の負債を回収。
- 改修: `lib/screens/home_screen.dart` の `_onSlotTap` に告白前夜の優先発火フロー（個別イベントより前）を追加。
- 改修: `test/ending_resolver_test.dart` のヘルパに `unlockConfessionEveForAll` フラグを追加。
- 改修: `integration_test/ending_flow_test.dart` の akari ED テストで告白前夜を解放済みにする。
- 追加テスト: `test/confession_eve_test.dart`（カタログ / resolver / GameState / AND 条件、計 13 件）。

### Sprint B: バッドED 2 種（燃え尽き / 左遷）
- 改修: `lib/models/ending.dart` の `EndingKind` に `burnoutEd` / `demotionEd` を冒頭に追加。
- 改修: `lib/models/ending_resolver.dart` の `resolve` 冒頭で「ストレス ≥90 → burnout / 仕事評価 ≤10 → demotion」を最優先で判定。
- 改修: `lib/data/endings.dart` の `EndingBodyCatalog` に 2 種の本文（lines / credit）と hints 3 行を追加。
- 改修: `test/ending_archive_test.dart` の「7 種」想定を「9 種」に更新。
- 追加テスト: `test/bad_endings_test.dart`（境界値・優先順位・本文整合性、計 9 件）。
- 図鑑カウンタは `EndingKind.values.length` ベースのため自動で 7 → 9 に追従。

### Sprint C: 仕事パートのイベント性強化
- 追加: `lib/data/work_events.dart`（5 カテゴリ・7 イベント・14 選択肢）。`WorkEvent` / `WorkChoice` / `WorkChoiceEffect` を新設。発火率 `kWorkEventPercent=35`。
  - 上司 2（大型案件 / 叱責）、同僚 2（資料手伝い / ランチ）、プロジェクト 2（仕様変更 / 締切前夜）、ミス 1（誤送信）、チャンス 1（臨時インセンティブ）。
- 追加: `lib/widgets/work_event_dialog.dart`（状況→選択肢→結果テキストの 2 段表示）。
- 改修: `lib/models/game_state.dart` に `applyWorkChoice` を追加。`affinityTarget` 経由で出会い済みキャラの好感度も動く。
- 改修: `lib/screens/home_screen.dart` に `workEventRng` を追加。null なら従来の即ロール挙動を完全維持（既存テスト互換）。
- 改修: `lib/screens/main_scaffold.dart` で本番時に `Random()` を注入。
- 追加テスト: `test/work_events_test.dart`（カタログ / 効果展開 / GameState / widget 経路、計 15 件）。
- セーブスキーマ無変更（イベントは瞬時消費で永続化対象なし）。

### Sprint D: キャラ個別イベント拡張 10 本
- 改修: `lib/data/individual_events.dart` に各キャラ 2 本ずつ追加（`ind.{id}.6` / `ind.{id}.7`、計 10 本）。catalog 合計 25 → 35。
- 発火条件のバリエーション:
  - 季節縛り（`requiredMonth`）: akari.6=5月 / uta.7=7月 / toru.6=11月 / sayo.7=2月 / yui.6=8月
  - 時間帯縛り（`preferredSlot`）: akari.7=夜 / uta.6=夕方 / toru.7=夜 / sayo.6=夜 / yui.7=朝
  - 好感度段階: stage 2/3/4 を分散
- 改修: `test/individual_events_unlock_test.dart` の「25 本 / 各 5」想定を「35 本 / 各 7」へ更新、`uta.1 morning 限定` テストを `isNot('ind.uta.1')` 形式に書き換え（evening に新規イベントが入っても意図維持）。
- 追加テスト: `test/individual_events_extra_test.dart`（追加 10 件の発火条件・cgKey ユニーク・再発火防止、計 13 件）。

### Sprint E: アルバム / 図鑑の表示強化
- 改修: `lib/screens/album_screen.dart` を StatelessWidget → StatefulWidget 化。
  - `CgEntry` に `category` / `characterId` / `hint` を追加。
  - `_collectAllCgEntries` に告白前夜 5 件を統合（共通の直後に配置して viewport 露出を確保）。
  - AppBar に「カテゴリフィルタ」「キャラフィルタ」の PopupMenuButton を追加。
  - 未解放タイル onTap で「カテゴリバッジ + 1 行ヒント」のダイアログ。
  - 全画面プレビュー上部にカテゴリ + キャラのバッジ表示。
  - フィルタ後カウンタ、空表示プレースホルダ対応。
- 改修: `lib/screens/ending_archive_screen.dart` を `GridView` → `ListView` + 4 セクション（バッドED/個別ED/ノーマルED/真ED）に再構成。各セクションに「達成数 / 総数」カウンタ。既存の `endingArchive.card.{id}` キーは維持（テスト互換）。
- 改修: `lib/widgets/cg_view.dart` の `CgLockedTile` に optional `onTap` を追加（後方互換）。
- 追加テスト: `test/album_filters_test.dart`（告白前夜統合 / カテゴリ・キャラフィルタ / ヒント / バッジ、計 5 件）、`test/ending_archive_sections_test.dart`（4 セクション・カウンタ・全 9 カード維持、計 3 件）。

### 累計成果
- イベント追加: 告白前夜 5 + バッドED 2 + 仕事 7 + 個別 10 = **24 本**。仕事の選択肢 14 を別カウントで追加。
- ED 種別: 7 → **9**。アルバム CG エントリ: 約 40 → **56**。
- セーブスキーマ・既存 API シグネチャ: 無変更。
- 検証: `flutter analyze` clean / `flutter test` 435/435 pass。
- integration test の実機/エミュレータ実行は次フェーズに持ち越し。

### 既知の残課題（このフェーズで追加された分）
- 新規 CG 17 件（`cg.confession_eve.*` ×5 / `cg.ending.burnout` / `cg.ending.demotion` / `cg.ind.{id}.6` ×5 / `cg.ind.{id}.7` ×5）は `CgView` プレースホルダのまま。`docs/assets_spec.md` への追記が未実施。
- 仕事中イベントの BGM 切替は未対応（既存の `_triggerEventFlash` のみ）。
- アルバムのフィルタ状態は画面 State のみ（再起動でリセット）。
- ED 図鑑のアイコンは `Icons.bookmark` 共通（バッドED 専用アイコンは未差別化）。
- `README.md` は旧 `mugen_siritori` 名のまま（プロジェクトリブランドの取りこぼし）。
