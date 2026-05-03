import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/data/repositories/mission_completion_history_repository.dart';
import 'package:liferpg/data/repositories/mission_repository.dart';
import 'package:liferpg/data/repositories/player_repository.dart';
import 'package:liferpg/data/repositories/skill_repository.dart';
import 'package:liferpg/services/mission_completion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MissionRepository missions;
  late PlayerRepository players;
  late SkillRepository skills;
  late MissionCompletionHistoryRepository history;
  late MissionCompletionService service;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
    missions = MissionRepository();
    players = PlayerRepository();
    skills = SkillRepository();
    history = MissionCompletionHistoryRepository();
    service = MissionCompletionService();
  });

  Future<int> insertMission(Mission mission) async {
    final id = await missions.insert(mission);
    if (mission.skillIds.isNotEmpty) {
      await missions.linkSkills(id, mission.skillIds);
    }
    return id;
  }

  test(
    'normal mission grants rewards once, rewards skills, and completes',
    () async {
      final missionId = await insertMission(
        Mission(
          title: 'Study',
          xpReward: 45,
          rewardPoints: 12,
          skillIds: const [1, 2],
        ),
      );

      final result = await service.completeMission(missionId);

      expect(result.status, MissionCompletionStatus.completed);
      expect(result.xpGranted, 45);
      expect(result.rewardPointsGranted, 12);
      expect(result.skillRewards.map((r) => r.xpGranted), [23, 23]);

      final mission = await missions.getWithSkills(missionId);
      expect(mission.status, 'completed');
      expect(mission.completedAt, isNotNull);

      final player = await players.get();
      expect(player.totalXP, 45);
      expect(player.rewardPoints, 12);

      expect((await skills.getById(1))!.currentXP, 23);
      expect((await skills.getById(2))!.currentXP, 23);

      final events = await history.getAll();
      expect(events, hasLength(1));
      expect(events.single.missionTitleSnapshot, 'Study');
      expect(events.single.skillRewards, hasLength(2));
    },
  );

  test('normal mission cannot grant rewards twice', () async {
    final missionId = await insertMission(
      Mission(title: 'One shot', xpReward: 30, rewardPoints: 7),
    );

    await service.completeMission(missionId);
    final second = await service.completeMission(missionId);

    expect(second.status, MissionCompletionStatus.duplicateBlocked);
    expect(second.xpGranted, 0);
    expect(second.rewardPointsGranted, 0);
    expect((await players.get()).totalXP, 30);
    expect(await history.getAll(), hasLength(1));
  });

  test(
    'recurring mission stays active, advances due date, and blocks early repeat',
    () async {
      final missionId = await insertMission(
        Mission(
          title: 'Daily review',
          xpReward: 20,
          rewardPoints: 4,
          isRecurring: true,
          recurrenceType: 'daily',
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );

      final first = await service.completeMission(missionId);
      final afterFirst = await missions.getWithSkills(missionId);
      final second = await service.completeMission(missionId);

      expect(first.status, MissionCompletionStatus.recurringAdvanced);
      expect(afterFirst.status, 'active');
      expect(afterFirst.completedAt, isNull);
      expect(afterFirst.lastCompletedAt, isNotNull);
      expect(afterFirst.streak, 1);
      expect(afterFirst.dueDate, isNotNull);
      expect(afterFirst.dueDate!.isAfter(DateTime.now()), isTrue);

      expect(second.status, MissionCompletionStatus.duplicateBlocked);
      expect((await players.get()).totalXP, 20);
      expect(await history.getAll(), hasLength(1));
    },
  );

  test(
    'continuous recurring mission records completion without advancing due date',
    () async {
      final dueDate = DateTime(2026, 1, 1);
      final missionId = await insertMission(
        Mission(
          title: 'Hydrate',
          xpReward: 5,
          isRecurring: true,
          recurrenceType: 'continuous',
          dueDate: dueDate,
        ),
      );

      final result = await service.completeMission(missionId);
      final mission = await missions.getWithSkills(missionId);

      expect(result.status, MissionCompletionStatus.recurringCompleted);
      expect(mission.status, 'active');
      expect(mission.dueDate, dueDate);
      expect(mission.streak, 1);
    },
  );

  test('backup and restore preserve mission completion history', () async {
    final missionId = await insertMission(
      Mission(title: 'Backup me', xpReward: 10, skillIds: const [1]),
    );

    await service.completeMission(missionId);

    final backup = await DatabaseHelper().getAllDataForBackup();
    expect(backup['mission_completion_events'], hasLength(1));
    expect(backup['mission_completion_skill_rewards'], hasLength(1));

    await DatabaseHelper().restoreData(backup);

    final events = await history.getAll();
    expect(events, hasLength(1));
    expect(events.single.missionTitleSnapshot, 'Backup me');
    expect(events.single.skillRewards.single.skillId, 1);
  });
}
