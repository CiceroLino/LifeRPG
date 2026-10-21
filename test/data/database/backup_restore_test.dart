import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/data/repositories/mission_repository.dart';
import 'package:liferpg/services/mission_completion_service.dart';
import '../../support/test_database.dart';

void main() {
  setUp(resetTestDatabase);

  test('own backup restores a child whose id precedes its parent', () async {
    final repo = MissionRepository();
    final child = await repo.insert(Mission(title: 'First task'));
    final parent = await repo.insert(Mission(title: 'Later project'));
    await repo.update(
      (await repo.getById(child))!.copyWith(parentMissionId: parent),
    );
    final backup = await DatabaseHelper().getAllDataForBackup();
    await resetTestDatabase();
    await DatabaseHelper().restoreData(backup);
    expect((await repo.getById(child))!.parentMissionId, parent);
    expect((await repo.getAll()).length, 2);
    final db = await DatabaseHelper().database;
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });

  test('cyclic mission hierarchy is rejected without replacing data', () async {
    final id = await MissionRepository().insert(Mission(title: 'Keep'));
    final raw =
        jsonDecode(jsonEncode(await DatabaseHelper().getAllDataForBackup()))
            as Map<String, dynamic>;
    (raw['missions'] as List).first['parent_mission_id'] = id;
    await expectLater(DatabaseHelper().restoreData(raw), throwsFormatException);
    expect((await MissionRepository().getById(id))!.parentMissionId, isNull);
  });

  test(
    'backup sees a complete state while rewards are being granted',
    () async {
      final id = await MissionRepository().insert(
        Mission(
          title: 'Repeat',
          xpReward: 1,
          rewardPoints: 1,
          isRecurring: true,
          recurrenceType: 'continuous',
        ),
      );
      final writer = () async {
        for (var i = 0; i < 25; i++) {
          await MissionCompletionService().completeMission(id);
        }
      }();
      final snapshots = <Map<String, dynamic>>[];
      for (var i = 0; i < 12; i++) {
        snapshots.add(await DatabaseHelper().getAllDataForBackup());
      }
      await writer;
      for (final data in snapshots) {
        final events = data['mission_completion_events'] as List;
        expect((data['player'] as Map)['total_xp'], events.length);
        expect((data['player'] as Map)['reward_points'], events.length);
      }
    },
  );
}
