# LifeRPG Project Guide

This guide is for humans and coding agents working on LifeRPG. Read it before changing project behavior so you do not need to rediscover the rules from the codebase.

If this guide conflicts with code, treat the code as the current truth and update this file as part of the change.

## Product Model

LifeRPG is a Flutter app that turns real-life tasks into RPG progression.

- Missions are tasks.
- Completing missions grants player XP and Reward Points.
- Skills receive XP when linked missions are completed.
- Rewards are shop items bought with Reward Points.
- Purchased rewards become inventory items.
- Energy is displayed as HP and can be manual or schedule-based.

The app is local-first. Data lives in SQLite through `sqflite`/`sqflite_common_ffi`; settings live in `SharedPreferences`; import/export works through platform-specific backup services.

## Architecture

The app follows a simple layered structure:

- `lib/ui`: screens and widgets. UI should compose providers and render state.
- `lib/providers`: `ChangeNotifier` state and application-facing operations.
- `lib/services`: transactional business workflows that touch multiple tables.
- `lib/data/repositories`: database access for one aggregate or persistence area.
- `lib/data/models`: immutable-ish data models with `toMap`, `fromMap`, `copyWith`.
- `lib/data/database/database_helper.dart`: schema, migrations, backup/restore, reset helpers.
- `lib/core/utils`: pure calculators and business helpers.
- `lib/core/theme/app_theme.dart`: design tokens and Material theme.

Important ownership rule: do not duplicate business calculations in UI. Reuse utilities such as `XPCalculator`, `RewardPointAdvisor`, and `EnergyScheduleCalculator`.

## Runtime Setup

`lib/main.dart`:

- Calls `configureDatabasePlatform()` before `runApp`.
- Registers providers with `MultiProvider`.
- Eagerly loads player, rewards, inventory, missions, skills, and settings.
- Forces `ThemeMode.dark`.
- Supports locales `en`, `pt`, and `es`.

Primary providers:

- `PlayerProvider`
- `MissionProvider`
- `SkillProvider`
- `RewardProvider`
- `InventoryProvider`
- `SettingsProvider`

## Database

Database file: `liferpg.db`.

Current schema version: `6`.

Core tables:

- `player`: singleton player row, enforced with `id INTEGER PRIMARY KEY CHECK (id = 1)`.
- `skills`: skill progression.
- `missions`: mission/task records.
- `mission_skills`: many-to-many join between missions and skills.
- `mission_completion_events`: history snapshots for mission completions.
- `mission_completion_skill_rewards`: per-skill XP history snapshots.
- `rewards`: shop reward definitions.
- `inventory_items`: owned reward items.
- `reward_redemptions`: purchase history snapshots.

Migration notes:

- Version 5 migrated mission `difficulty`, `urgency`, and `fear` from the old 1-5 scale to the current 0-100 percent scale by multiplying values 1-5 by 20.
- Version 6 added rewards, inventory, and redemption history.
- Foreign keys are enabled in `onConfigure`.

Backup/restore:

- `DatabaseHelper.getAllDataForBackup()` exports all core tables with `version` and `timestamp`.
- `DatabaseHelper.restoreData()` clears existing data and inserts the supplied backup payload inside a transaction.
- Restore assumes backup rows match the current schema.

## Player Rules

Model: `lib/data/models/player.dart`.

Defaults:

- `id`: `1`
- `name`: `Player`
- `title`: `Adventurer`
- `totalXP`: `0`
- `level`: `1`
- `rewardPoints`: `0`
- `currentEnergy`: `100`
- `energyMode`: `manual`
- `themeMode`: `light`, although the app currently runs dark mode.

`PlayerProvider` exposes current XP, level, XP needed for next level, XP inside current level, and progress to next level.

Manual energy:

- Only valid in `energyMode == 'manual'`.
- `setManualEnergy` clamps values to `0..100`.

Auto energy:

- `energyMode` must be `auto`.
- `wakeUpTime` and `sleepTime` must be parseable `HH:mm` strings.
- The visible energy value is computed in `PlayerStatsHeader` using `EnergyScheduleCalculator`.

## XP And Levels

Owner: `lib/core/utils/xp_calculator.dart`.

Level curve:

- XP required for the next level is `currentLevel * 100`.
- Level starts at `1`.
- Total XP is cumulative.
- XP inside the current level is `totalXP - XP required by previous levels`.

Examples:

- Level 1 needs 100 XP to reach level 2.
- Level 2 needs 200 more XP.
- Level 3 needs 300 more XP.

Mission XP formula:

```text
xp = difficulty * urgency * (1 + fear / 100)
```

Rules:

- `difficulty`, `urgency`, and `fear` are clamped to `0..100`.
- If `difficulty == 0` or `urgency == 0`, XP is `0`.
- `fear` is a multiplier, not a blocker.
- Result is rounded to the nearest integer.

Mission attribute bands:

- `0..25`: Low
- `26..50`: Medium
- `51..75`: High
- `76..100`: Extreme

Use `XPCalculator.attributeGuideLabel` for the human-readable strategy labels shown next to sliders.

## Mission Rules

Model: `lib/data/models/mission.dart`.

Important fields:

- `status`: currently `active`, `completed`, or `archived`.
- `difficulty`, `urgency`, `fear`: percent scale `0..100`.
- `energyRequired`: database constrained to `1..5`, but it is not currently consumed by completion logic.
- `xpReward`: stored XP amount granted on completion.
- `rewardPoints`: stored RP amount granted on completion.
- `dueDate`: used by filters and recurrence advancement.
- `isRecurring`, `recurrenceType`, `recurrenceInterval`: recurrence metadata. `recurrenceInterval` exists but is not currently used by completion logic.
- `lastCompletedAt`, `streak`: recurrence tracking.
- `parentMissionId`: subtasks; cascade deleted with parent mission.
- `skillIds`: loaded through `mission_skills`, not stored in the `missions` table.

Mission creation:

- The form defaults to difficulty 50, urgency 50, fear 30.
- XP is previewed with `XPCalculator.calculateMissionXP`.
- Duration input is clamped to `0..60` minutes.
- Recurrence values from UI: `once`, `continuous`, `daily`, `weekly`, `monthly`, `yearly`.
- `once` is saved as `isRecurring = false` and `recurrenceType = null`.
- Any other recurrence is saved as `isRecurring = true` and `recurrenceType` set to that value.
- A mission may be created as already completed; this sets `status = completed` and `completedAt = now`, but does not grant completion rewards through `MissionCompletionService`.

Skill linking:

- Use `MissionRepository.linkSkills`.
- Updating links deletes existing rows for the mission and inserts the supplied list.
- Be careful when updating a mission with an empty `skillIds` list: `MissionProvider.updateMission` currently only relinks when the list is non-empty, so clearing all links may require repository-level handling.

## Mission Completion Rules

Owner: `lib/services/mission_completion_service.dart`.

Always complete missions through `MissionProvider.completeMission` or `MissionProvider.updateMissionStatus(id, 'completed')`. Do not call `MissionRepository.complete` for user-facing completion flows because it only flips mission status and bypasses XP/RP/history/skill rewards.

Completion is transactional:

1. Load mission and linked skill IDs.
2. Block duplicate completions when applicable.
3. Insert `mission_completion_events`.
4. Grant skill XP and insert `mission_completion_skill_rewards`.
5. Grant player XP/RP and recalculate player level.
6. Update mission status or recurrence state.

Duplicate rules:

- Non-recurring mission: blocked if already `completed`.
- Recurring mission with `recurrenceType == 'continuous'`: never duplicate-blocked.
- Other recurring mission: blocked when `dueDate != null && dueDate.isAfter(now)`.

Rewards granted:

- Player receives exactly `mission.xpReward` and `mission.rewardPoints`.
- Player level is recalculated from total XP.
- Linked skills split mission XP evenly with `(xpReward / skillIds.length).round()`.
- Skill XP uses a per-skill level track: while `currentXP >= level * 100`, subtract `level * 100` and increment level.

Mission status after completion:

- Non-recurring mission becomes `completed`, `completedAt = now`.
- Recurring mission remains `active`, sets `lastCompletedAt = now`, increments `streak`, clears `completedAt`, and advances `dueDate`.
- Continuous recurring mission keeps the same `dueDate`.
- Daily/weekly/monthly/yearly recurrence advances from the old due date until it is after `now`.
- Unknown recurrence types behave like daily.

Completion result statuses:

- `completed`: non-recurring mission completed.
- `recurringAdvanced`: recurring mission advanced to a future due date.
- `recurringCompleted`: continuous recurring mission completed.
- `duplicateBlocked`: no rewards granted.

## Mission Filtering And Sorting

Owner: `lib/providers/mission_provider.dart`.

Default state:

- Sort: `recent`.
- Filter: `all`.
- Completed missions hidden unless `showCompleted == true`.

Filters:

- `plan`: active missions without `dueDate`.
- `all`: all missions except hidden completed.
- `next`: active missions with `dueDate >= now`.
- `today`: active missions due from today at 00:00 until tomorrow at 00:00.
- `tomorrow`: active missions due from tomorrow at 00:00 until the following day.
- `overdue`: active missions with `dueDate` before today at 00:00.

Search:

- Trims the query.
- Matches lowercase title or description.

Skill filter:

- A mission matches when any linked skill ID is in the selected set.

Sorts:

- `recent`: newest `createdAt` first.
- `oldest`: oldest `createdAt` first.
- `difficultyDesc`: highest difficulty first.
- `priorityDesc`: compares `(urgency * 100) + (fear * 10) + difficulty`.
- `rewardDesc`: highest Reward Points first.

## Reward Points

Owner: `lib/core/utils/reward_point_advisor.dart`.

Recommended RP for missions:

- Standalone daily mission: `1`.
- Child mission that is daily or weekly: `1`.
- Standalone by XP:
  - `<= 100`: 5 RP
  - `<= 1,000`: 10 RP
  - `<= 10,000`: 25 RP
  - `<= 100,000`: 50 RP
  - `<= 1,000,000`: 75 RP
  - `> 1,000,000`: 100 RP
- Child mission by XP:
  - `<= 1,000`: 5 RP
  - `<= 10,000`: 10 RP
  - `<= 100,000`: 25 RP
  - `<= 1,000,000`: 50 RP
  - `> 1,000,000`: 75 RP

Negative XP is treated as `0` for recommendation.

## Rewards, Shop, And Inventory

Models:

- `Reward`
- `InventoryItem`
- `RewardRedemption`

Repository: `lib/data/repositories/reward_repository.dart`.

Reward fields:

- `priceRp` must be non-negative in the database.
- `isUnlimitedStock` controls stock behavior.
- `stockRemaining` is stored as null for unlimited rewards.
- `isActive` archives rewards instead of deleting them from purchase history.

Purchase flow is transactional:

1. Require active reward.
2. If finite stock, require stock remaining > 0.
3. Require player RP >= price.
4. Subtract player RP.
5. Decrement finite stock.
6. Create or increment an inventory item keyed by `reward_id`.
7. Insert redemption snapshot.

Provider-facing errors:

- Insufficient RP: `RP insuficiente para comprar esta recompensa.`
- Out of stock: `Recompensa sem estoque disponível.`
- Unavailable reward: `Recompensa indisponível.`

Inventory:

- `InventoryRepository.consumeItem` deletes the item when quantity is `1`.
- Otherwise it decrements quantity and updates `updated_at`.
- Inventory items are sorted by `updated_at DESC`.

## Energy Rules

Owner: `lib/core/utils/energy_schedule_calculator.dart`.

Manual mode:

- Stored value is `player.currentEnergy`.
- UI allows tap/drag on the energy bar to set `0..100`.

Auto mode:

- Requires valid `wakeUpTime` and `sleepTime`.
- If either time is invalid or the awake duration is zero, result is not configured and energy is `0`.
- During awake time, energy drains linearly from 100 to 0.
- During sleep time, energy charges linearly from 0 to 100.
- Schedules may cross midnight.
- `MainScreen` refreshes auto energy display every minute while player energy mode is auto.

UI label:

- Manual mode shows `manual`.
- Auto mode without configured times shows `set schedule`.
- Configured auto mode shows time left until sleep or wake.

## Settings And Reset

Owner: `lib/providers/settings_provider.dart`.

SharedPreferences keys:

- `language`
- `sound_effects_enabled`
- `notification_sounds_enabled`
- `notifications_enabled`
- `start_week_on_monday`
- `use_24_hour_format`
- `show_xp_bar`

Defaults:

- Language: `en`
- Sound effects: false
- Notification sounds: true
- Notifications: true
- Start week on Monday: false
- 24-hour format: false
- Show XP bar: true

Reset behavior:

- `resetCharacter()` resets player XP, level, RP, energy, energy mode, wake/sleep times.
- `factoryReset()` deletes user data from reward, inventory, completion history, mission, skill, and player tables; then reinserts the default player and default skills; then clears preferences and reloads defaults.

Default skills:

- Inteligência, blue `#2196F3`
- Força, red `#F44336`
- Saúde, green `#4CAF50`
- Social, orange `#FF9800`
- Criatividade, purple `#9C27B0`

The database currently stores the Portuguese names with accents. Keep user-facing defaults localized intentionally if you change them.

## Navigation And Screens

`MainScreen` owns top-level navigation with an `IndexedStack`.

Drawer order:

1. Missions
2. Map
3. Rewards
4. Inventory
5. Skills
6. Statistics
7. Profile
8. Shop
9. Settings
10. Help

`PlayerStatsHeader` is hidden for Skills, Settings, and Help. It shows tabs only on Missions.

Mission tabs map to filters:

1. PLAN -> `MissionFilterMode.plan`
2. ALL -> `MissionFilterMode.all`
3. NEXT -> `MissionFilterMode.next`
4. OVERDUE -> `MissionFilterMode.overdue`
5. TODAY -> `MissionFilterMode.today`
6. TOMORROW -> `MissionFilterMode.tomorrow`

App bar actions are contextual:

- Missions: stats toggle, search, add mission, show completed, sort, skill filter.
- Profile: stats toggle, edit, reset avatar, share profile.
- Statistics: stats toggle, calendar, export data, clear history.

Workspace switching currently only changes in-memory UI state and shows a snackbar. It is not a persisted data partition.

## Design System

Owner: `lib/core/theme/app_theme.dart`.

The app intentionally uses a dense dark RPG dashboard style:

- Dark background, compact controls, functional surfaces.
- Icons and small labels are preferred over explanatory blocks.
- Cards should be compact and information-dense.
- Avoid marketing-page layouts, oversized hero sections, and decorative gradients.

Core colors:

- `background`: `#212121`
- `surface`: `#303030`
- `primary`: `#03A9F4`
- `accentRed`: `#F44336`
- `accentAmber`: `#FFC107`
- `textPrimary`: `#F5F5F5`
- `textSecondary`: `#BDBDBD`
- `border`: `#424242`
- `successGreen`: `#4CAF50`

Theme:

- Material 3.
- Roboto via `google_fonts`.
- Dark scaffold background.
- Compact visual density.
- Cards use `surface`, border `border`, elevation 2, and radius 12.
- Inputs are filled with `surface`, border radius 10, and primary focus border.
- FAB uses primary blue on dark foreground.

Common UI patterns:

- Use `AppTheme` constants instead of ad hoc colors.
- Use `LifeRPGAppBar` for top-level app bar behavior.
- Use `AppDrawer` for main navigation.
- Use `PlayerStatsHeader` for player, XP, RP, and energy summary.
- Use SVG assets from `assets/game-icons.net.svg/...` for RPG-themed icons.
- Use `normalizeMissionIconAsset` when rendering saved mission icons.
- Keep text short and scannable. Many current strings are English even in Portuguese app areas; preserve existing style unless localizing intentionally.

Mission card visual rules:

- Priority strip color:
  - urgency >= 76: red
  - difficulty >= 76: orange
  - fear >= 76: primary blue
  - urgency >= 51: amber
  - otherwise text secondary
- Mission icon box is 50x50 with radius 8.
- Expanded card exposes status dropdown and edit button.
- Reward Points are shown with a gem icon and amber text.

Player header visual rules:

- Avatar is 60x60 with radius 8 and border.
- Level is large gold text.
- XP and HP bars are stacked, 20px high.
- HP is red in manual/draining state; auto charging interpolates red to cyan.
- Mission tabs are uppercase labels in a compact `TabBar`.

## Localization And Text

The app has generated localization scaffolding, but many visible strings are currently hardcoded in English or Portuguese.

When adding user-facing text:

- Follow the local style of the file you are editing.
- If touching a localized screen, prefer using `AppLocalizations`.
- Avoid broad localization refactors unless requested.

## Platform Notes

Database platform setup lives in `lib/core/platform/database_platform*.dart`.

Avatar and backup behavior use platform-specific implementations:

- Avatar image/storage helpers in `lib/core/platform/custom_avatar_storage*.dart` and `lib/ui/widgets/common/avatar_image*.dart`.
- Backup service implementations in `lib/services/backup_service*.dart`.

Web support includes SQLite wasm assets in `web/`.

## Testing Expectations

Run focused tests for the area you change, then broader tests when risk is high.

Useful commands:

```bash
flutter analyze
flutter test
flutter test test/core/utils/mission_strategy_calculator_test.dart
flutter test test/core/utils/energy_schedule_calculator_test.dart
flutter test test/services/mission_completion_service_test.dart
flutter test test/data/repositories/reward_inventory_repository_test.dart
flutter test test/providers/mission_provider_test.dart
```

Add or update tests when changing:

- XP or level formulas.
- Mission completion rewards, recurrence, duplicate blocking, or history.
- Mission filtering/sorting.
- Reward purchase, stock, inventory, or redemption history.
- Energy schedule math or UI energy interactions.
- Database migrations, backup, restore, reset, or factory reset.
- Provider behavior that affects visible state or error messages.

Existing focused test files:

- `test/core/utils/mission_strategy_calculator_test.dart`
- `test/core/utils/energy_schedule_calculator_test.dart`
- `test/services/mission_completion_service_test.dart`
- `test/data/database/mission_attribute_migration_test.dart`
- `test/data/repositories/reward_inventory_repository_test.dart`
- `test/providers/mission_provider_test.dart`
- `test/providers/reward_inventory_provider_test.dart`
- UI/widget tests under `test/ui/...`

## Known Sharp Edges

- `MissionRepository.complete` bypasses reward and history logic. Avoid it for user-facing completion.
- `MissionProvider.updateMission` does not clear mission skills when `skillIds` is empty.
- Creating a mission with `Mission Complete` checked does not grant XP/RP. It only stores completed status.
- `recurrenceInterval` exists but completion logic ignores it.
- `energyRequired` exists but mission completion does not consume energy.
- `themeMode` exists on `Player`, but `MaterialApp` currently forces dark theme.
- Workspace selection is UI-only and does not isolate data.
- `RewardRepository.purchaseReward` assumes the player row exists.
- Backup restore inserts raw rows and assumes compatible schema.
- Some docs/README descriptions may still refer to older 1-5 mission attributes. Current code uses 0-100 for difficulty, urgency, and fear.

## How To Extend Safely

When adding a new rule:

1. Put pure math in `lib/core/utils`.
2. Put transactional multi-table workflows in `lib/services`.
3. Keep database access in repositories.
4. Expose state and errors through providers.
5. Keep UI widgets thin and reusable.
6. Add focused tests beside the existing test area.
7. Update this guide when the behavior becomes part of the project contract.

When adding a new screen:

1. Add screen under `lib/ui/screens/<area>/`.
2. Reuse `AppTheme`, app bar/drawer patterns, and compact dark styling.
3. Add provider or repository APIs only if existing ones do not already cover the workflow.
4. Add widget tests for user-visible interactions.

When adding a new dependency or using a library API:

1. Use `ctx7` first for current docs.
2. Prefer existing dependencies before adding new packages.
3. Update `pubspec.yaml`, run `flutter pub get`, and commit `pubspec.lock` changes.
