import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:liferpg/providers/mission_provider.dart';
import 'package:liferpg/providers/player_provider.dart';
import 'package:liferpg/providers/settings_provider.dart';
import 'package:liferpg/providers/skill_provider.dart';
import 'package:liferpg/ui/screens/settings/settings_screen.dart';

class FakeMissionProvider extends MissionProvider {
  int loadMissionsCalls = 0;

  @override
  Future<void> loadMissions() async {
    loadMissionsCalls++;
  }
}

class FakeSkillProvider extends SkillProvider {
  int loadSkillsCalls = 0;

  @override
  Future<void> loadSkills() async {
    loadSkillsCalls++;
  }
}

class FakePlayerProvider extends PlayerProvider {
  int loadPlayerCalls = 0;

  @override
  Future<void> loadPlayer() async {
    loadPlayerCalls++;
  }
}

class FakeSettingsProvider extends SettingsProvider {
  int factoryResetCalls = 0;

  @override
  bool get isLoading => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> factoryReset() async {
    factoryResetCalls++;
  }
}

void main() {
  testWidgets('factory reset recarrega providers de dados', (tester) async {
    final settings = FakeSettingsProvider();
    final mission = FakeMissionProvider();
    final skill = FakeSkillProvider();
    final player = FakePlayerProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<MissionProvider>.value(value: mission),
          ChangeNotifierProvider<SkillProvider>.value(value: skill),
          ChangeNotifierProvider<PlayerProvider>.value(value: player),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Factory Reset / Wipe All'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Factory Reset / Wipe All'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'WIPE ALL DATA'));
    await tester.pumpAndSettle();

    expect(settings.factoryResetCalls, 1);
    expect(player.loadPlayerCalls, 1);
    expect(mission.loadMissionsCalls, 1);
    expect(skill.loadSkillsCalls, 1);
  });
}
