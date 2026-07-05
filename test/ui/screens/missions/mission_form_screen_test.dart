import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/data/models/mission_reward_drop.dart';
import 'package:liferpg/data/models/skill.dart';
import 'package:liferpg/providers/mission_provider.dart';
import 'package:liferpg/providers/reward_provider.dart';
import 'package:liferpg/providers/settings_provider.dart';
import 'package:liferpg/providers/skill_provider.dart';
import 'package:liferpg/ui/screens/missions/mission_icon_assets.dart';
import 'package:liferpg/ui/screens/missions/mission_form_screen.dart';

class FakeSkillProvider extends SkillProvider {
  final List<Skill> _items = [Skill(id: 1, name: 'Focus')];
  int _nextId = 2;

  @override
  List<Skill> get skills => List.unmodifiable(_items);

  @override
  bool get isLoading => false;

  @override
  Future<void> loadSkills() async {}

  @override
  Future<int?> addSkill(Skill skill) async {
    final id = _nextId++;
    _items.add(skill.copyWith(id: id));
    notifyListeners();
    return id;
  }
}

class FakeMissionProvider extends MissionProvider {
  Mission? addedMission;

  @override
  List<Mission> get missions => const [];

  @override
  Future<void> loadMissions() async {}

  @override
  Future<int?> addMission(
    Mission mission, {
    bool notificationsEnabled = true,
    List<MissionRewardDrop> rewardDrops = const [],
  }) async {
    addedMission = mission;
    return mission.id;
  }
}

class FakeRewardProvider extends RewardProvider {
  @override
  Future<void> loadRewards() async {}
}

List<SingleChildWidget> _providers({
  required SkillProvider skillProvider,
  required MissionProvider missionProvider,
}) {
  return [
    ChangeNotifierProvider<SkillProvider>.value(value: skillProvider),
    ChangeNotifierProvider<MissionProvider>.value(value: missionProvider),
    ChangeNotifierProvider<RewardProvider>.value(value: FakeRewardProvider()),
    ChangeNotifierProvider<SettingsProvider>.value(value: SettingsProvider()),
  ];
}

Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('creates and auto-selects new skill from mission form', (
    tester,
  ) async {
    await _setLargeSurface(tester);
    final skillProvider = FakeSkillProvider();
    final missionProvider = FakeMissionProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: _providers(
          skillProvider: skillProvider,
          missionProvider: missionProvider,
        ),
        child: const MaterialApp(home: MissionFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create-skill-button')).last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('new-skill-name-field')),
      'Programming',
    );
    await tester.enterText(
      find.byKey(const Key('new-skill-description-field')),
      'Learn Flutter development',
    );

    await tester.tap(find.widgetWithText(TextButton, 'Criar'));
    await tester.pumpAndSettle();

    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Programming'),
    );
    expect(chip.selected, isTrue);
  });

  test('mission icon options point at bundled assets', () {
    for (final asset in missionIconOptions) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
      expect(asset, isNot(contains('/lorc/crosshair.svg')));
      expect(asset, isNot(contains('/lorc/overkill.svg')));
      expect(asset, isNot(contains('/delapouite/treasure-map.svg')));
      expect(asset, isNot(contains('/delapouite/barbell.svg')));
    }
  });

  testWidgets('mission icon picker does not tint SVGs into solid squares', (
    tester,
  ) async {
    await _setLargeSurface(tester);
    final skillProvider = FakeSkillProvider();
    final missionProvider = FakeMissionProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: _providers(
          skillProvider: skillProvider,
          missionProvider: missionProvider,
        ),
        child: const MaterialApp(home: MissionFormScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Escolher ícone'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Escolher ícone'));
    await tester.pumpAndSettle();

    final icons = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
    expect(icons, isNotEmpty);
    expect(icons.every((icon) => icon.colorFilter == null), isTrue);
  });

  testWidgets('shows strategy labels and calculated XP preview', (
    tester,
  ) async {
    await _setLargeSurface(tester);
    final skillProvider = FakeSkillProvider();
    final missionProvider = FakeMissionProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: _providers(
          skillProvider: skillProvider,
          missionProvider: missionProvider,
        ),
        child: const MaterialApp(home: MissionFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Medium'), findsWidgets);
    expect(find.textContaining('XP calculado'), findsOneWidget);
    expect(find.text('3250 XP'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Usar 25 RP'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Usar 25 RP'), findsOneWidget);
  });

  testWidgets('saves calculated mission XP from current attributes', (
    tester,
  ) async {
    await _setLargeSurface(tester);
    final skillProvider = FakeSkillProvider();
    final missionProvider = FakeMissionProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: _providers(
          skillProvider: skillProvider,
          missionProvider: missionProvider,
        ),
        child: const MaterialApp(home: MissionFormScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Write plan');
    await tester.scrollUntilVisible(
      find.byKey(const Key('save-mission-button')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('save-mission-button')).last);
    await tester.pumpAndSettle();

    expect(missionProvider.addedMission, isNotNull);
    expect(missionProvider.addedMission!.difficulty, 50);
    expect(missionProvider.addedMission!.urgency, 50);
    expect(missionProvider.addedMission!.fear, 30);
    expect(missionProvider.addedMission!.xpReward, 3250);
  });

  testWidgets('mission template fills and saves preset values', (tester) async {
    await _setLargeSurface(tester);
    final skillProvider = FakeSkillProvider();
    final missionProvider = FakeMissionProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: _providers(
          skillProvider: skillProvider,
          missionProvider: missionProvider,
        ),
        child: const MaterialApp(home: MissionFormScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'Deep work'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('save-mission-button')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('save-mission-button')).last);
    await tester.pumpAndSettle();

    expect(missionProvider.addedMission, isNotNull);
    expect(missionProvider.addedMission!.title, 'Deep work block');
    expect(missionProvider.addedMission!.difficulty, 70);
    expect(missionProvider.addedMission!.urgency, 55);
    expect(missionProvider.addedMission!.fear, 35);
    expect(missionProvider.addedMission!.estimatedDuration, 60);
    expect(missionProvider.addedMission!.notes, contains('Session 1'));
  });
}
