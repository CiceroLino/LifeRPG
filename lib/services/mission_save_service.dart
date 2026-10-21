import '../data/database/database_helper.dart';
import '../data/database/data_operations.dart';
import '../data/models/mission.dart';
import '../data/models/mission_reward_drop.dart';
import '../data/repositories/mission_repository.dart';
import '../data/repositories/mission_reward_drop_repository.dart';

class MissionSaveService {
  MissionSaveService({required this.missions, required this.drops});
  final MissionRepository missions;
  final MissionRewardDropRepository drops;

  Future<int> save(
    Mission mission, {
    required bool create,
    List<MissionRewardDrop>? rewardDrops,
  }) => DataOperations.instance.run(() async {
    final db = await DatabaseHelper().database;
    return db.transaction((txn) async {
      final int id;
      if (create) {
        id = await missions.insert(mission, executor: txn);
      } else {
        id = mission.id!;
        if (await missions.update(mission, executor: txn) != 1) {
          throw StateError('Mission is unavailable.');
        }
      }
      await missions.linkSkills(id, mission.skillIds, executor: txn);
      if (rewardDrops != null) {
        await drops.replaceForMission(id, rewardDrops, executor: txn);
      }
      return id;
    });
  });
}
