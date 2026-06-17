import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/player.dart';
import 'package:liferpg/data/repositories/player_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayerRepository players;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
    players = PlayerRepository();
  });

  test('resetCharacterStats restores visible profile and progression defaults', () async {
    final current = await players.get();
    await players.update(
      current.copyWith(
        name: 'Cicero',
        title: 'Archmage',
        description: 'Custom profile',
        totalXP: 1200,
        level: 5,
        rewardPoints: 90,
        avatarPath: '/tmp/avatar.png',
        currentEnergy: 12,
        energyMode: 'auto',
        wakeUpTime: '06:30',
        sleepTime: '23:45',
      ),
    );

    await DatabaseHelper().resetCharacterStats();

    final reset = await players.get();
    expect(
      reset,
      isA<Player>()
          .having((player) => player.name, 'name', 'Player')
          .having((player) => player.title, 'title', 'Adventurer')
          .having((player) => player.description, 'description', '')
          .having((player) => player.totalXP, 'totalXP', 0)
          .having((player) => player.level, 'level', 1)
          .having((player) => player.rewardPoints, 'rewardPoints', 0)
          .having((player) => player.avatarPath, 'avatarPath', isNull)
          .having((player) => player.currentEnergy, 'currentEnergy', 100)
          .having((player) => player.energyMode, 'energyMode', 'manual')
          .having((player) => player.wakeUpTime, 'wakeUpTime', isNull)
          .having((player) => player.sleepTime, 'sleepTime', isNull),
    );
  });
}
