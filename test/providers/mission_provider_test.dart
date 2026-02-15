import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/providers/mission_provider.dart';

Mission _mission({
  required int id,
  required String title,
  String description = '',
  int difficulty = 1,
  int urgency = 1,
  int rewardPoints = 0,
  DateTime? createdAt,
  List<int> skillIds = const [],
}) {
  return Mission(
    id: id,
    title: title,
    description: description,
    difficulty: difficulty,
    urgency: urgency,
    rewardPoints: rewardPoints,
    createdAt: createdAt ?? DateTime(2026, 1, id),
    skillIds: skillIds,
  );
}

void main() {
  late MissionProvider provider;

  setUp(() {
    provider = MissionProvider();
    provider.setMissionsForTesting([
      _mission(
        id: 1,
        title: 'Study Flutter',
        description: 'Build widgets',
        difficulty: 2,
        urgency: 3,
        rewardPoints: 20,
        skillIds: const [1, 2],
      ),
      _mission(
        id: 2,
        title: 'Morning Workout',
        description: 'Cardio and strength',
        difficulty: 5,
        urgency: 5,
        rewardPoints: 40,
        skillIds: const [3],
      ),
      _mission(
        id: 3,
        title: 'Read Book',
        description: 'Programming principles',
        difficulty: 1,
        urgency: 1,
        rewardPoints: 10,
        skillIds: const [1],
      ),
    ]);
  });

  test('filters missions by search query in title or description', () {
    provider.setSearchQuery('build');

    final titles = provider.filteredMissions.map((m) => m.title).toList();
    expect(titles, contains('Study Flutter'));
    expect(titles, isNot(contains('Morning Workout')));
    expect(titles, isNot(contains('Read Book')));
  });

  test('filters missions by selected skills', () {
    provider.setSkillFilters({3});

    final titles = provider.filteredMissions.map((m) => m.title).toList();
    expect(titles, ['Morning Workout']);
  });

  test('combines search and skills filters', () {
    provider.setSearchQuery('read');
    provider.setSkillFilters({1});

    final titles = provider.filteredMissions.map((m) => m.title).toList();
    expect(titles, ['Read Book']);
  });

  test('sorts missions by reward descending', () {
    provider.setSortMode(MissionSortMode.rewardDesc);

    final ids = provider.filteredMissions.map((m) => m.id).toList();
    expect(ids, [2, 1, 3]);
  });
}
