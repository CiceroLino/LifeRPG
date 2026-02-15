# Missions Search Sort Skill Filter Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement search, sorting, and skills filtering for missions from existing app bar actions.

**Architecture:** Keep all mission list presentation state in `MissionProvider` and expose a single computed list for screens. `MainScreen` handles UI affordances and forwards user intent to provider setters.

**Tech Stack:** Flutter, Provider, flutter_test.

---

### Task 1: Add mission view-state model and provider filtering pipeline

**Files:**
- Modify: `lib/providers/mission_provider.dart`
- Test: `test/providers/mission_provider_test.dart`

**Step 1: Write failing tests**
- Add tests for `filteredMissions` search, skill filter, combined filters, and sort behavior.

**Step 2: Run tests to verify failure**
- Run: `fvm flutter test test/providers/mission_provider_test.dart`
- Expected: FAIL for missing `filteredMissions` and filter/sort state methods.

**Step 3: Implement minimal provider state + derivation**
- Add `MissionSortMode` enum.
- Add `searchQuery`, `selectedSkillIds`, `sortMode` state.
- Add setter methods and `filteredMissions` getter.

**Step 4: Re-run tests to verify pass**
- Run same command.
- Expected: PASS.

### Task 2: Wire mission list screen to filtered missions

**Files:**
- Modify: `lib/ui/screens/missions/missions_list_screen.dart`
- Test: `test/ui/screens/missions/missions_list_screen_test.dart`

**Step 1: Write failing widget test**
- Assert mission list renders from filtered provider output.

**Step 2: Run test to verify failure**
- Run: `fvm flutter test test/ui/screens/missions/missions_list_screen_test.dart`
- Expected: FAIL because screen uses raw `missions`.

**Step 3: Implement minimal change**
- Replace `provider.missions` with `provider.filteredMissions`.

**Step 4: Re-run test**
- Run same command.
- Expected: PASS.

### Task 3: Implement MainScreen app bar actions (search/sort/skills filter)

**Files:**
- Modify: `lib/ui/screens/main_screen.dart`
- Modify: `lib/ui/widgets/common/liferpg_app_bar.dart` (only if callback payload mapping requires updates)
- Modify: `lib/providers/skill_provider.dart` (if utility helper needed)
- Test: `test/ui/screens/main_screen_mission_actions_test.dart`

**Step 1: Write failing widget tests**
- Search action updates provider query.
- Sort action updates provider sort mode.
- Skills filter action toggles selected skills.

**Step 2: Run tests to verify failure**
- Run: `fvm flutter test test/ui/screens/main_screen_mission_actions_test.dart`

**Step 3: Implement minimal UI logic**
- Add a search delegate/dialog for mission query.
- Map sort menu values to provider enum.
- Add skills multi-select bottom sheet and apply selected ids.

**Step 4: Re-run tests**
- Run same command.

### Task 4: Verification and cleanup

**Files:**
- Modify: `README.md` (optional, if behavior docs updated)

**Step 1: Run formatter**
- `fvm dart format lib/providers/mission_provider.dart lib/ui/screens/missions/missions_list_screen.dart lib/ui/screens/main_screen.dart test/providers/mission_provider_test.dart test/ui/screens/missions/missions_list_screen_test.dart test/ui/screens/main_screen_mission_actions_test.dart`

**Step 2: Run targeted suite**
- `fvm flutter test test/providers/mission_provider_test.dart test/ui/screens/missions/missions_list_screen_test.dart test/ui/screens/main_screen_mission_actions_test.dart test/ui/widgets/mission/mission_card_test.dart test/ui/screens/missions/mission_form_screen_test.dart test/widget_test.dart`

**Step 3: Commit**
- `git add lib/providers/mission_provider.dart lib/ui/screens/missions/missions_list_screen.dart lib/ui/screens/main_screen.dart test/providers/mission_provider_test.dart test/ui/screens/missions/missions_list_screen_test.dart test/ui/screens/main_screen_mission_actions_test.dart docs/plans/2026-02-15-missions-search-sort-skill-filter-design.md docs/plans/2026-02-15-missions-search-sort-skill-filter-implementation.md`
- `git commit -m "feat(missions): add search sorting and skill filters"`

