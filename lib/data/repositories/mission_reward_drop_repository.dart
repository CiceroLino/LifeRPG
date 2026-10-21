import 'package:sqflite/sqflite.dart';
import '../database/data_operations.dart';
import '../database/database_helper.dart';
import '../models/mission_reward_drop.dart';

class MissionRewardDropRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<MissionRewardDrop>> getByMissionId(int missionId) =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        final maps = await db.query(
          'mission_reward_drops',
          where: 'mission_id = ?',
          whereArgs: [missionId],
          orderBy: 'id ASC',
        );
        return maps.map(MissionRewardDrop.fromMap).toList();
      }, readOnly: true);

  Future<void> replaceForMission(
    int missionId,
    List<MissionRewardDrop> drops, {
    DatabaseExecutor? executor,
  }) => DataOperations.instance.run(() async {
    Future<void> apply(DatabaseExecutor txn) async {
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
    }

    if (executor != null) return apply(executor);
    final db = await _dbHelper.database;
    await db.transaction(apply);
  }, readOnly: false);
}
