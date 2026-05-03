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
  @override
  List<Mission> get missions => const [];

  @override
  Future<void> loadMissions() async {}

  @override
  Future<void> addMission(Mission mission) async {}
}

void main() {
  testWidgets('creates and auto-selects new skill from mission form', (
    tester,
  ) async {
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

    await tester.tap(find.textContaining('Nova skill'));
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
}
