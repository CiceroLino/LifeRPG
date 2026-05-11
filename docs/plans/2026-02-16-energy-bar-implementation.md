# Energy Bar Dual Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add manual and automatic HP/energy modes with schedule-based drain/charge behavior and minute-level UI updates.

**Architecture:** Energy mode and schedule are persisted on `player`. Manual mode reads/writes `current_energy`; automatic mode computes visible HP and color from wake/sleep windows at render time and repaints every minute. Settings becomes the configuration entry point for mode and schedule. Mission completion does not currently spend HP.

**Tech Stack:** Flutter, Provider, sqflite, flutter_test.

---

### Task 1: Add pure energy schedule calculation utility

The calculator models the strategy-guide behavior: HP is full at wake time, drains while awake, and recharges while asleep.

**Files:**
- Create: `lib/core/utils/energy_schedule_calculator.dart`
- Test: `test/core/utils/energy_schedule_calculator_test.dart`

**Step 1: Write the failing test**

```dart
test('awake window drains from 100 to 0 linearly', () {
  final result = EnergyScheduleCalculator.compute(
    now: DateTime(2026, 1, 1, 12, 0),
    wakeUpTime: '08:00',
    sleepTime: '20:00',
  );

  expect(result.isAutoConfigured, true);
  expect(result.isCharging, false);
  expect(result.energyPercent, closeTo(50, 0.01));
});
```

**Step 2: Run test to verify it fails**

Run: `fvm flutter test test/core/utils/energy_schedule_calculator_test.dart`
Expected: FAIL because calculator does not exist yet.

**Step 3: Write minimal implementation**

```dart
class EnergyComputationResult {
  final bool isAutoConfigured;
  final bool isCharging;
  final double energyPercent;
  const EnergyComputationResult({
    required this.isAutoConfigured,
    required this.isCharging,
    required this.energyPercent,
  });
}

class EnergyScheduleCalculator {
  static EnergyComputationResult compute({
    required DateTime now,
    required String? wakeUpTime,
    required String? sleepTime,
  }) {
    // Parse schedule, map windows, calculate linear % for awake/sleep.
    // Clamp [0, 100]. If invalid config, return isAutoConfigured=false.
  }
}
```

**Step 4: Run test to verify it passes**

Run: `fvm flutter test test/core/utils/energy_schedule_calculator_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/core/utils/energy_schedule_calculator.dart test/core/utils/energy_schedule_calculator_test.dart
git commit -m "feat: add automatic energy schedule calculator"
```

### Task 2: Extend player provider/repository APIs for mode/schedule/manual energy

**Files:**
- Modify: `lib/data/repositories/player_repository.dart`
- Modify: `lib/providers/player_provider.dart`
- Test: `test/providers/player_provider_energy_test.dart`

**Step 1: Write the failing test**

```dart
test('setManualEnergy clamps value and reloads player', () async {
  // Arrange fake repository and provider
  // Act provider.setManualEnergy(150)
  // Assert persisted value is 100 and load called
});
```

**Step 2: Run test to verify it fails**

Run: `fvm flutter test test/providers/player_provider_energy_test.dart`
Expected: FAIL because new APIs are missing.

**Step 3: Write minimal implementation**

```dart
Future<void> setEnergyMode(String mode) async { ... }
Future<void> setEnergySchedule({required String wakeUpTime, required String sleepTime}) async { ... }
Future<void> setManualEnergy(int value) async { ... }
```

Repository exposes helper methods or uses `get+update` pattern with `copyWith`.

**Step 4: Run test to verify it passes**

Run: `fvm flutter test test/providers/player_provider_energy_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/data/repositories/player_repository.dart lib/providers/player_provider.dart test/providers/player_provider_energy_test.dart
git commit -m "feat: add player energy mode and schedule actions"
```

### Task 3: Add energy mode configuration UI in settings

**Files:**
- Modify: `lib/ui/screens/settings/settings_screen.dart`
- Test: `test/ui/screens/settings/settings_energy_mode_test.dart`

**Step 1: Write the failing test**

```dart
testWidgets('shows wake/sleep pickers only in auto mode', (tester) async {
  // pump settings with fake player provider in manual mode
  // switch to auto
  // expect wake/sleep controls visible
});
```

**Step 2: Run test to verify it fails**

Run: `fvm flutter test test/ui/screens/settings/settings_energy_mode_test.dart`
Expected: FAIL because controls do not exist.

**Step 3: Write minimal implementation**

```dart
// Add section with segmented or radio toggle for manual/automatic.
// Add TimeOfDay pickers for wake/sleep when automatic.
// Validate wake != sleep.
// Persist through PlayerProvider methods.
```

**Step 4: Run test to verify it passes**

Run: `fvm flutter test test/ui/screens/settings/settings_energy_mode_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/ui/screens/settings/settings_screen.dart test/ui/screens/settings/settings_energy_mode_test.dart
git commit -m "feat: add energy mode and schedule settings"
```

### Task 4: Make header energy bar mode-aware and enforce interaction rules

**Files:**
- Modify: `lib/ui/widgets/player/player_stats_header.dart`
- Modify: `lib/ui/screens/main_screen.dart`
- Test: `test/ui/widgets/player/player_stats_header_energy_test.dart`

**Step 1: Write the failing test**

```dart
testWidgets('auto mode disables manual bar interaction', (tester) async {
  // pump header in auto mode with callback
  // tap bar
  // callback not called
});
```

**Step 2: Run test to verify it fails**

Run: `fvm flutter test test/ui/widgets/player/player_stats_header_energy_test.dart`
Expected: FAIL because bar behavior is not mode-aware.

**Step 3: Write minimal implementation**

```dart
// Use EnergyScheduleCalculator in auto mode.
// Derive progress/color based on charge/discharge phase.
// Use callback only when player.energyMode == 'manual'.
// MainScreen: 1-minute timer to repaint when auto mode is active.
```

**Step 4: Run test to verify it passes**

Run: `fvm flutter test test/ui/widgets/player/player_stats_header_energy_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/ui/widgets/player/player_stats_header.dart lib/ui/screens/main_screen.dart test/ui/widgets/player/player_stats_header_energy_test.dart
git commit -m "feat: support automatic charging and draining energy bar"
```

### Task 5: End-to-end verification and documentation sync

**Files:**
- Modify: `README.md`

**Step 1: Write/adjust failing expectation test if docs claim old behavior**

```text
N/A for docs-only, verify app behavior through existing tests.
```

**Step 2: Run targeted tests**

Run:
- `fvm flutter test test/core/utils/energy_schedule_calculator_test.dart`
- `fvm flutter test test/providers/player_provider_energy_test.dart`
- `fvm flutter test test/ui/screens/settings/settings_energy_mode_test.dart`
- `fvm flutter test test/ui/widgets/player/player_stats_header_energy_test.dart`

Expected: all PASS.

**Step 3: Run broader regression slice**

Run:
- `fvm flutter test test/ui/screens/settings/settings_screen_test.dart`
- `fvm flutter test test/ui/screens/main_screen_mission_actions_test.dart`

Expected: PASS.

**Step 4: Update README energy section**

```markdown
- Manual mode: user-adjustable energy.
- Automatic mode: schedule-based drain and charge.
```

**Step 5: Commit**

```bash
git add README.md
git commit -m "docs: document manual and automatic energy bar behavior"
```
