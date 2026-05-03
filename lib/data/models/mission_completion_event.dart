class MissionCompletionEvent {
  final int? id;
  final int missionId;
  final String missionTitleSnapshot;
  final int xpGranted;
  final int rewardPointsGranted;
  final DateTime completedAt;
  final String? recurrenceType;
  final int resultingStreak;
  final List<MissionCompletionSkillReward> skillRewards;

  MissionCompletionEvent({
    this.id,
    required this.missionId,
    required this.missionTitleSnapshot,
    required this.xpGranted,
    required this.rewardPointsGranted,
    required this.completedAt,
    this.recurrenceType,
    required this.resultingStreak,
    this.skillRewards = const [],
  });

  factory MissionCompletionEvent.fromMap(Map<String, dynamic> map) {
    return MissionCompletionEvent(
      id: map['id'] as int?,
      missionId: map['mission_id'] as int,
      missionTitleSnapshot: map['mission_title_snapshot'] as String,
      xpGranted: map['xp_granted'] as int? ?? 0,
      rewardPointsGranted: map['reward_points_granted'] as int? ?? 0,
      completedAt: DateTime.parse(map['completed_at'] as String),
      recurrenceType: map['recurrence_type'] as String?,
      resultingStreak: map['resulting_streak'] as int? ?? 0,
    );
  }

  MissionCompletionEvent copyWith({
    int? id,
    List<MissionCompletionSkillReward>? skillRewards,
  }) {
    return MissionCompletionEvent(
      id: id ?? this.id,
      missionId: missionId,
      missionTitleSnapshot: missionTitleSnapshot,
      xpGranted: xpGranted,
      rewardPointsGranted: rewardPointsGranted,
      completedAt: completedAt,
      recurrenceType: recurrenceType,
      resultingStreak: resultingStreak,
      skillRewards: skillRewards ?? this.skillRewards,
    );
  }
}

class MissionCompletionSkillReward {
  final int? id;
  final int eventId;
  final int skillId;
  final String skillNameSnapshot;
  final int xpGranted;

  MissionCompletionSkillReward({
    this.id,
    required this.eventId,
    required this.skillId,
    required this.skillNameSnapshot,
    required this.xpGranted,
  });

  factory MissionCompletionSkillReward.fromMap(Map<String, dynamic> map) {
    return MissionCompletionSkillReward(
      id: map['id'] as int?,
      eventId: map['event_id'] as int,
      skillId: map['skill_id'] as int,
      skillNameSnapshot: map['skill_name_snapshot'] as String,
      xpGranted: map['xp_granted'] as int? ?? 0,
    );
  }
}
