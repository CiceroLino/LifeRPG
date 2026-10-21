import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/data/repositories/mission_repository.dart';
import '../support/test_database.dart';

void main() {
  setUp(resetTestDatabase);
  Future<Map<String, dynamic>> backup() async =>
      jsonDecode(jsonEncode(await DatabaseHelper().getAllDataForBackup()))
          as Map<String, dynamic>;

  test(
    'null and unsupported backup payloads cannot erase existing data',
    () async {
      await MissionRepository().insert(Mission(title: 'Keep me'));
      final before = await backup();
      for (final invalid in [
        {'version': '1.0', 'player': null, 'missions': null, 'skills': null},
        {...before, 'version': 'future', 'formatVersion': 99},
        {...before, 'missions': 'invalid'},
        {
          ...before,
          'player': {...before['player'] as Map, 'total_xp': -1},
        },
      ]) {
        await expectLater(
          DatabaseHelper().restoreData(invalid),
          throwsFormatException,
        );
        final after = await backup();
        expect(after['player'], before['player']);
        expect(after['missions'], before['missions']);
      }
    },
  );

  test(
    'export includes separate format and database schema versions',
    () async {
      final data = await backup();
      expect(data['formatVersion'], 2);
      expect(data['schemaVersion'], greaterThanOrEqualTo(13));
    },
  );

  test('modern low percent values remain unchanged', () async {
    await MissionRepository().insert(
      Mission(title: 'Percent', difficulty: 2, urgency: 3, fear: 5),
    );
    final data = await backup();
    data['formatVersion'] = 2;
    data['schemaVersion'] = 13;
    await DatabaseHelper().restoreData(data);
    final mission = (await MissionRepository().getAll()).single;
    expect([mission.difficulty, mission.urgency, mission.fear], [2, 3, 5]);
  });

  test('known legacy scale migrates without changing modern values', () async {
    await MissionRepository().insert(
      Mission(title: 'Legacy', difficulty: 2, urgency: 3, fear: 5),
    );
    final data = await backup();
    data.remove('formatVersion');
    data['version'] = '1.0';
    data['schemaVersion'] = 4;
    await DatabaseHelper().restoreData(data);
    final mission = (await MissionRepository().getAll()).single;
    expect([mission.difficulty, mission.urgency, mission.fear], [40, 60, 100]);
  });

  test(
    'invalid domain and foreign references are rejected before deletion',
    () async {
      await MissionRepository().insert(Mission(title: 'Keep me'));
      for (final patch in [
        {'difficulty': 101},
        {'xp_reward': -1},
        {'status': 'unknown'},
        {'parent_mission_id': 999},
        {'due_date': 'not-a-date'},
      ]) {
        final data = await backup();
        (data['missions'] as List).first.addAll(patch);
        await expectLater(
          DatabaseHelper().restoreData(data),
          throwsFormatException,
        );
        expect((await MissionRepository().getAll()).single.title, 'Keep me');
      }
    },
  );
}
