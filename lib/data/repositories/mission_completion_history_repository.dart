import '../database/database_helper.dart';
import '../models/mission_completion_event.dart';

class MissionCompletionHistoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<MissionCompletionEvent>> getAll() async {
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

    return eventMaps.map((map) {
      final event = MissionCompletionEvent.fromMap(map);
      return event.copyWith(skillRewards: rewardsByEvent[event.id] ?? const []);
    }).toList();
  }

  Future<List<MissionCompletionEvent>> getByMissionId(int missionId) async {
    final all = await getAll();
    return all.where((event) => event.missionId == missionId).toList();
  }
}
