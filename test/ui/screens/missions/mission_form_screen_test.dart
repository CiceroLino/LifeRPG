import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/data/models/skill.dart';
import 'package:liferpg/providers/mission_provider.dart';
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
  Future<void> addMission(Mission mission) async {
    addedMission = mission;
  }
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
        providers: [
          ChangeNotifierProvider<SkillProvider>.value(value: skillProvider),
          ChangeNotifierProvider<MissionProvider>.value(value: missionProvider),
        ],
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

  testWidgets('shows strategy labels and calculated XP preview', (
    tester,
  ) async {
    await _setLargeSurface(tester);
    final skillProvider = FakeSkillProvider();
    final missionProvider = FakeMissionProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SkillProvider>.value(value: skillProvider),
          ChangeNotifierProvider<MissionProvider>.value(value: missionProvider),
        ],
        child: const MaterialApp(home: MissionFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Medium'), findsWidgets);
    expect(find.textContaining('XP calculado'), findsOneWidget);
    expect(find.text('3250 XP'), findsOneWidget);
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
        providers: [
          ChangeNotifierProvider<SkillProvider>.value(value: skillProvider),
          ChangeNotifierProvider<MissionProvider>.value(value: missionProvider),
        ],
        child: const MaterialApp(home: MissionFormScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Write plan');
    await tester.tap(find.byKey(const Key('save-mission-button')).last);
    await tester.pumpAndSettle();

    expect(missionProvider.addedMission, isNotNull);
    expect(missionProvider.addedMission!.difficulty, 50);
    expect(missionProvider.addedMission!.urgency, 50);
    expect(missionProvider.addedMission!.fear, 30);
    expect(missionProvider.addedMission!.xpReward, 3250);
  });
}
