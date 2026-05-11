import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/data/repositories/mission_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
  });

  test('new missions persist location and reminder fields', () async {
    final id = await MissionRepository().insert(
      Mission(
        title: 'Buy groceries',
        locationName: 'Market',
        latitude: -9.6498,
        longitude: -35.7089,
        reminderAt: DateTime(2026, 5, 11, 17, 30),
        recurrenceDays: const [1, 3, 5],
      ),
    );

    final mission = await MissionRepository().getById(id);

    expect(mission!.locationName, 'Market');
    expect(mission.latitude, -9.6498);
    expect(mission.longitude, -35.7089);
    expect(mission.reminderAt, DateTime(2026, 5, 11, 17, 30));
    expect(mission.recurrenceDays, [1, 3, 5]);
  });

  test(
    'backup and restore preserve v7 mission fields and drop tables',
    () async {
      await MissionRepository().insert(
        Mission(
          title: 'Library',
          locationName: 'Central Library',
          latitude: -9.65,
          longitude: -35.7,
          reminderAt: DateTime(2026, 5, 11, 9),
        ),
      );

      final backup = await DatabaseHelper().getAllDataForBackup();

      expect(backup['missions'].single['location_name'], 'Central Library');
      expect(backup['mission_reward_drops'], isA<List<dynamic>>());
      expect(backup['mission_completion_reward_drops'], isA<List<dynamic>>());

      await DatabaseHelper().restoreData(backup);
      expect(
        (await MissionRepository().getAll()).single.locationName,
        'Central Library',
      );
    },
  );
}
