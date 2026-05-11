import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/data/models/mission_reward_drop.dart';
import 'package:liferpg/data/models/reward.dart';
import 'package:liferpg/data/repositories/mission_repository.dart';
import 'package:liferpg/data/repositories/mission_reward_drop_repository.dart';
import 'package:liferpg/data/repositories/reward_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MissionRepository missions;
  late RewardRepository rewards;
  late MissionRewardDropRepository drops;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
    missions = MissionRepository();
    rewards = RewardRepository();
    drops = MissionRewardDropRepository();
  });

  test(
    'replaces mission drops and clamps chance and quantity safely',
    () async {
      final missionId = await missions.insert(Mission(title: 'Run'));
      final rewardId = await rewards.insert(
        Reward(name: 'Smoothie', priceRp: 5),
      );

      await drops.replaceForMission(missionId, [
        MissionRewardDrop(
          missionId: missionId,
          rewardId: rewardId,
          chancePercent: 150,
          quantity: 0,
        ),
      ]);

      final stored = await drops.getByMissionId(missionId);

      expect(stored, hasLength(1));
      expect(stored.single.chancePercent, 100);
      expect(stored.single.quantity, 1);
    },
  );
}
