import 'package:sqflite/sqflite.dart';

import '../core/utils/xp_calculator.dart';
import '../data/database/database_helper.dart';
import '../data/models/mission.dart';

enum MissionCompletionStatus {
  completed,
  recurringAdvanced,
  recurringCompleted,
  duplicateBlocked,
}

class MissionCompletionResult {
  final Mission mission;
  final MissionCompletionStatus status;
  final int xpGranted;
  final int rewardPointsGranted;
  final List<MissionSkillRewardResult> skillRewards;

  MissionCompletionResult({
    required this.mission,
    required this.status,
    required this.xpGranted,
    required this.rewardPointsGranted,
    this.skillRewards = const [],
  });

  bool get grantedRewards => xpGranted > 0 || rewardPointsGranted > 0;
}

class MissionSkillRewardResult {
  final int skillId;
  final String skillName;
  final int xpGranted;

  MissionSkillRewardResult({
    required this.skillId,
    required this.skillName,
    required this.xpGranted,
  });
}

class MissionCompletionService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<MissionCompletionResult> completeMission(int missionId) async {
    final db = await _dbHelper.database;
    return db.transaction((txn) async {
      final mission = await _getMission(txn, missionId);
      final skillIds = await _getMissionSkillIds(txn, missionId);
      final missionWithSkills = mission.copyWith(skillIds: skillIds);
      final now = DateTime.now();

      if (_isDuplicateCompletion(missionWithSkills, now)) {
        return MissionCompletionResult(
          mission: missionWithSkills,
          status: MissionCompletionStatus.duplicateBlocked,
          xpGranted: 0,
          rewardPointsGranted: 0,
        );
      }

      final resultingStreak = mission.isRecurring ? mission.streak + 1 : 0;
      final eventId = await txn.insert('mission_completion_events', {
        'mission_id': missionId,
        'mission_title_snapshot': mission.title,
        'xp_granted': mission.xpReward,
        'reward_points_granted': mission.rewardPoints,
        'completed_at': now.toIso8601String(),
        'recurrence_type': mission.recurrenceType,
        'resulting_streak': resultingStreak,
      });

      final skillRewards = await _rewardSkills(
        txn,
        eventId: eventId,
        skillIds: skillIds,
        xpReward: mission.xpReward,
        now: now,
      );

      await _rewardPlayer(
        txn,
        xpReward: mission.xpReward,
        rewardPoints: mission.rewardPoints,
        now: now,
      );

      final updatedMission = await _updateMissionAfterCompletion(
        txn,
        mission,
        now,
        resultingStreak,
      );

      return MissionCompletionResult(
        mission: updatedMission.copyWith(skillIds: skillIds),
        status: _statusFor(updatedMission),
        xpGranted: mission.xpReward,
        rewardPointsGranted: mission.rewardPoints,
        skillRewards: skillRewards,
      );
    });
  }

  bool _isDuplicateCompletion(Mission mission, DateTime now) {
    if (!mission.isRecurring) {
      return mission.status == 'completed';
    }
    if (mission.recurrenceType == 'continuous') {
      return false;
    }
    final dueDate = mission.dueDate;
    return dueDate != null && dueDate.isAfter(now);
  }

  Future<Mission> _getMission(DatabaseExecutor db, int missionId) async {
    final maps = await db.query(
      'missions',
      where: 'id = ?',
      whereArgs: [missionId],
      limit: 1,
    );
    if (maps.isEmpty) {
      throw StateError('Mission $missionId not found');
    }
    return Mission.fromMap(maps.first);
  }

  Future<List<int>> _getMissionSkillIds(
    DatabaseExecutor db,
    int missionId,
  ) async {
    final maps = await db.query(
      'mission_skills',
      columns: ['skill_id'],
      where: 'mission_id = ?',
      whereArgs: [missionId],
    );
    return maps.map((map) => map['skill_id'] as int).toList();
  }

  Future<void> _rewardPlayer(
    DatabaseExecutor db, {
    required int xpReward,
    required int rewardPoints,
    required DateTime now,
  }) async {
    final maps = await db.query('player', where: 'id = 1', limit: 1);
    if (maps.isEmpty) return;
    final currentXP = maps.first['total_xp'] as int? ?? 0;
    final currentRewardPoints = maps.first['reward_points'] as int? ?? 0;
    final totalXP = currentXP + xpReward;

    await db.update('player', {
      'total_xp': totalXP,
      'level': XPCalculator.calculateLevel(totalXP),
      'reward_points': currentRewardPoints + rewardPoints,
      'updated_at': now.toIso8601String(),
    }, where: 'id = 1');
  }

  Future<List<MissionSkillRewardResult>> _rewardSkills(
    DatabaseExecutor db, {
    required int eventId,
    required List<int> skillIds,
    required int xpReward,
    required DateTime now,
  }) async {
    if (skillIds.isEmpty) return const [];
    final xpPerSkill = (xpReward / skillIds.length).round();
    final rewards = <MissionSkillRewardResult>[];

    for (final skillId in skillIds) {
      final maps = await db.query(
        'skills',
        where: 'id = ?',
        whereArgs: [skillId],
        limit: 1,
      );
      if (maps.isEmpty) continue;

      final skill = maps.first;
      final skillName = skill['name'] as String;
      var newXP = (skill['current_xp'] as int? ?? 0) + xpPerSkill;
      var newLevel = skill['level'] as int? ?? 1;

      while (newXP >= newLevel * 100) {
        newXP -= newLevel * 100;
        newLevel++;
      }

      await db.update(
        'skills',
        {
          'current_xp': newXP,
          'level': newLevel,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [skillId],
      );

      await db.insert('mission_completion_skill_rewards', {
        'event_id': eventId,
        'skill_id': skillId,
        'skill_name_snapshot': skillName,
        'xp_granted': xpPerSkill,
      });

      rewards.add(
        MissionSkillRewardResult(
          skillId: skillId,
          skillName: skillName,
          xpGranted: xpPerSkill,
        ),
      );
    }

    return rewards;
  }

  Future<Mission> _updateMissionAfterCompletion(
    DatabaseExecutor db,
    Mission mission,
    DateTime now,
    int resultingStreak,
  ) async {
    if (!mission.isRecurring) {
      await db.update(
        'missions',
        {
          'status': 'completed',
          'completed_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [mission.id],
      );
      return mission.copyWith(
        status: 'completed',
        completedAt: now,
        updatedAt: now,
      );
    }

    final nextDueDate = _nextDueDate(mission, now);
    await db.update(
      'missions',
      {
        'status': 'active',
        'last_completed_at': now.toIso8601String(),
        'streak': resultingStreak,
        'due_date': nextDueDate?.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'completed_at': null,
      },
      where: 'id = ?',
      whereArgs: [mission.id],
    );

    return mission.copyWith(
      status: 'active',
      dueDate: nextDueDate,
      lastCompletedAt: now,
      streak: resultingStreak,
      updatedAt: now,
    );
  }

  DateTime? _nextDueDate(Mission mission, DateTime now) {
    if (mission.recurrenceType == 'continuous') {
      return mission.dueDate;
    }

    DateTime? dueDate = mission.dueDate ?? now;
    var guard = 0;
    while (!dueDate!.isAfter(now) && guard < 1000) {
      dueDate = _addRecurrenceInterval(dueDate, mission.recurrenceType);
      guard++;
    }
    return dueDate;
  }

  DateTime _addRecurrenceInterval(DateTime date, String? recurrenceType) {
    switch (recurrenceType) {
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(
          date.year,
          date.month + 1,
          date.day,
          date.hour,
          date.minute,
          date.second,
          date.millisecond,
          date.microsecond,
        );
      case 'yearly':
        return DateTime(
          date.year + 1,
          date.month,
          date.day,
          date.hour,
          date.minute,
          date.second,
          date.millisecond,
          date.microsecond,
        );
      case 'daily':
      default:
        return date.add(const Duration(days: 1));
    }
  }

  MissionCompletionStatus _statusFor(Mission mission) {
    if (!mission.isRecurring) return MissionCompletionStatus.completed;
    if (mission.recurrenceType == 'continuous') {
      return MissionCompletionStatus.recurringCompleted;
    }
    return MissionCompletionStatus.recurringAdvanced;
  }
}
