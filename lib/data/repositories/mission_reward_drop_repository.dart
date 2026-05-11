import '../database/database_helper.dart';
import '../models/mission_reward_drop.dart';

class MissionRewardDropRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<MissionRewardDrop>> getByMissionId(int missionId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'mission_reward_drops',
      where: 'mission_id = ?',
      whereArgs: [missionId],
      orderBy: 'id ASC',
    );
    return maps.map(MissionRewardDrop.fromMap).toList();
  }

  Future<void> replaceForMission(
    int missionId,
    List<MissionRewardDrop> drops,
  ) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'mission_reward_drops',
        where: 'mission_id = ?',
        whereArgs: [missionId],
      );
      for (final drop in drops) {
        await txn.insert(
          'mission_reward_drops',
          drop.copyWith(missionId: missionId).toMap(),
        );
      }
    });
  }
}
