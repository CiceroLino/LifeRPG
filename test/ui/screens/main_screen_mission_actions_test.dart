import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/data/models/player.dart';
import 'package:liferpg/data/models/skill.dart';
import 'package:liferpg/providers/mission_provider.dart';
import 'package:liferpg/providers/inventory_provider.dart';
import 'package:liferpg/providers/player_provider.dart';
import 'package:liferpg/providers/pomodoro_provider.dart';
import 'package:liferpg/providers/reward_provider.dart';
import 'package:liferpg/providers/settings_provider.dart';
import 'package:liferpg/providers/skill_provider.dart';
import 'package:liferpg/ui/screens/main_screen.dart';
import 'package:liferpg/ui/widgets/common/liferpg_app_bar.dart';

class FakeMissionProvider extends MissionProvider {
  MissionSortMode? lastSortMode;
  MissionFilterMode? lastFilterMode;
  String? lastQuery;
  Set<int> lastSkillFilters = {};

  @override
  bool get isLoading => false;

  @override
  List<Mission> get filteredMissions => const [];

  @override
  List<Mission> get missions => const [];

  @override
  Future<void> loadMissions() async {}

  @override
  void setSortMode(MissionSortMode mode) {
    lastSortMode = mode;
  }

  @override
  void setFilterMode(MissionFilterMode mode) {
    lastFilterMode = mode;
  }

  @override
  void setSearchQuery(String query) {
    lastQuery = query;
  }

  @override
  void setSkillFilters(Set<int> skillIds) {
    lastSkillFilters = skillIds;
  }
}

class FakeSkillProvider extends SkillProvider {
  @override
  bool get isLoading => false;

  @override
  List<Skill> get skills => [
    Skill(id: 11, name: 'Programming'),
    Skill(id: 22, name: 'Fitness'),
  ];

  @override
  Future<void> loadSkills() async {}
}

class FakePlayerProvider extends PlayerProvider {
  @override
  Player? get player => Player();

  @override
  Future<void> loadPlayer() async {}
}

class FakeSettingsProvider extends SettingsProvider {
  @override
  Future<void> initialize() async {}
}

class FakeRewardProvider extends RewardProvider {
  @override
  Future<void> loadRewards() async {}
}

class FakeInventoryProvider extends InventoryProvider {
  @override
  Future<void> loadItems() async {}
}

void main() {
  Future<void> pumpMain(
    WidgetTester tester,
    FakeMissionProvider missionProvider,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MissionProvider>.value(value: missionProvider),
          ChangeNotifierProvider<SkillProvider>.value(
            value: FakeSkillProvider(),
          ),
          ChangeNotifierProvider<PlayerProvider>.value(
            value: FakePlayerProvider(),
          ),
          ChangeNotifierProvider<PomodoroProvider>.value(
            value: PomodoroProvider(),
          ),
          ChangeNotifierProvider<RewardProvider>.value(
            value: FakeRewardProvider(),
          ),
          ChangeNotifierProvider<InventoryProvider>.value(
            value: FakeInventoryProvider(),
          ),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: FakeSettingsProvider(),
          ),
        ],
        child: const MaterialApp(home: MainScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('search action updates mission query', (tester) async {
    final missionProvider = FakeMissionProvider();
    await pumpMain(tester, missionProvider);

    await tester.tap(find.byKey(const Key('mission-search-toggle')));
    await tester.pump();
    expect(find.byKey(const Key('mission-search-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('mission-search-field')),
      'flutter',
    );
    await tester.pump();

    expect(missionProvider.lastQuery, 'flutter');
  });

  testWidgets('sort action maps to provider sort mode', (tester) async {
    final missionProvider = FakeMissionProvider();
    await pumpMain(tester, missionProvider);

    final appBar = tester.widget<LifeRPGAppBar>(find.byType(LifeRPGAppBar));
    appBar.onSortChanged?.call('difficulty');
    await tester.pump();

    expect(missionProvider.lastSortMode, MissionSortMode.difficultyDesc);
  });

  testWidgets('mission header tabs map to provider filters', (tester) async {
    final missionProvider = FakeMissionProvider();
    await pumpMain(tester, missionProvider);

    expect(find.text('Completed/History'), findsNothing);

    await tester.tap(find.text('TODAY'));
    await tester.pump();
    expect(missionProvider.lastFilterMode, MissionFilterMode.today);

    await tester.tap(find.text('TOMORROW'));
    await tester.pump();
    expect(missionProvider.lastFilterMode, MissionFilterMode.tomorrow);
  });

  testWidgets('navigation dropdown exposes Pomodoro option', (tester) async {
    final missionProvider = FakeMissionProvider();
    await pumpMain(tester, missionProvider);

    await tester.tap(find.text('LifeRPG'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pomodoro'), findsOneWidget);
  });
}
