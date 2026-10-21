import '../database/data_operations.dart';
import '../database/database_helper.dart';
import '../models/mission_completion_event.dart';
import '../models/mission_reward_drop.dart';

class MissionCompletionHistoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<MissionCompletionEvent>> getAll() =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        final eventMaps = await db.query(
          'mission_completion_events',
          orderBy: 'completed_at DESC',
        );
        if (eventMaps.isEmpty) return const [];
        final rewardMaps = await db.query('mission_completion_skill_rewards');
        final rewardsByEvent = <int, List<MissionCompletionSkillReward>>{};
        for (final map in rewardMaps) {
          final reward = MissionCompletionSkillReward.fromMap(map);
          rewardsByEvent.putIfAbsent(reward.eventId, () => []).add(reward);
        }
        final dropMaps = await db.query('mission_completion_reward_drops');
        final dropsByEvent = <int, List<MissionCompletionRewardDrop>>{};
        for (final map in dropMaps) {
          final drop = MissionCompletionRewardDrop.fromMap(map);
          dropsByEvent.putIfAbsent(drop.eventId, () => []).add(drop);
        }
        return eventMaps.map((map) {
          final event = MissionCompletionEvent.fromMap(map);
          return event.copyWith(
            skillRewards: rewardsByEvent[event.id] ?? const [],
            rewardDrops: dropsByEvent[event.id] ?? const [],
          );
        }).toList();
      }, readOnly: true);

  Future<List<MissionCompletionEvent>> getByMissionId(int missionId) =>
      DataOperations.instance.run(() async {
        final all = await getAll();
        return all.where((event) => event.missionId == missionId).toList();
      }, readOnly: true);
}
