class Mission {
  final int? id;
  final String title;
  final String description;
  final int difficulty;
  final int urgency;
  final int fear;
  final int energyRequired;
  final int xpReward;
  final int rewardPoints;
  final String status; // 'active', 'completed', 'archived'
  final DateTime? dueDate;
  final int? estimatedDuration;
  final bool isRecurring;
  final String? recurrenceType;
  final int? recurrenceInterval;
  final DateTime? lastCompletedAt;
  final int streak;
  final int? parentMissionId;
  final int orderIndex;
  final String? icon;
  final String? emoji;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final DateTime? reminderAt;
  final List<int> recurrenceDays;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final List<int> skillIds;

  Mission({
    this.id,
    required this.title,
    this.description = '',
    this.difficulty = 10,
    this.urgency = 10,
    this.fear = 10,
    this.energyRequired = 1,
    this.xpReward = 10,
    this.rewardPoints = 5,
    this.status = 'active',
    this.dueDate,
    this.estimatedDuration,
    this.isRecurring = false,
    this.recurrenceType,
    this.recurrenceInterval,
    this.lastCompletedAt,
    this.streak = 0,
    this.parentMissionId,
    this.orderIndex = 0,
    this.icon,
    this.emoji,
    this.locationName,
    this.latitude,
    this.longitude,
    this.reminderAt,
    this.recurrenceDays = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.completedAt,
    this.skillIds = const [],
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'urgency': urgency,
      'fear': fear,
      'energy_required': energyRequired,
      'xp_reward': xpReward,
      'reward_points': rewardPoints,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
      'estimated_duration': estimatedDuration,
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_type': recurrenceType,
      'recurrence_interval': recurrenceInterval,
      'last_completed_at': lastCompletedAt?.toIso8601String(),
      'streak': streak,
      'parent_mission_id': parentMissionId,
      'order_index': orderIndex,
      'icon': icon,
      'emoji': emoji,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'reminder_at': reminderAt?.toIso8601String(),
      'recurrence_days': recurrenceDays.isEmpty
          ? null
          : recurrenceDays.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory Mission.fromMap(Map<String, dynamic> map) {
    return Mission(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      difficulty: map['difficulty'] as int? ?? 1,
      urgency: map['urgency'] as int? ?? 1,
      fear: map['fear'] as int? ?? 1,
      energyRequired: map['energy_required'] as int? ?? 1,
      xpReward: map['xp_reward'] as int? ?? 10,
      rewardPoints: map['reward_points'] as int? ?? 5,
      status: map['status'] as String? ?? 'active',
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      estimatedDuration: map['estimated_duration'] as int?,
      isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
      recurrenceType: map['recurrence_type'] as String?,
      recurrenceInterval: map['recurrence_interval'] as int?,
      lastCompletedAt: map['last_completed_at'] != null
          ? DateTime.parse(map['last_completed_at'] as String)
          : null,
      streak: map['streak'] as int? ?? 0,
      parentMissionId: map['parent_mission_id'] as int?,
      orderIndex: map['order_index'] as int? ?? 0,
      icon: map['icon'] as String?,
      emoji: map['emoji'] as String?,
      locationName: map['location_name'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      reminderAt: map['reminder_at'] != null
          ? DateTime.parse(map['reminder_at'] as String)
          : null,
      recurrenceDays: _parseRecurrenceDays(map['recurrence_days'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = toMap();
    json['skill_ids'] = skillIds;
    return json;
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    final mission = Mission.fromMap(json);
    final skillIdsList = json['skill_ids'] as List<dynamic>?;
    return mission.copyWith(
      skillIds: skillIdsList?.map((e) => e as int).toList() ?? [],
    );
  }

  Mission copyWith({
    int? id,
    String? title,
    String? description,
    int? difficulty,
    int? urgency,
    int? fear,
    int? energyRequired,
    int? xpReward,
    int? rewardPoints,
    String? status,
    DateTime? dueDate,
    int? estimatedDuration,
    bool? isRecurring,
    String? recurrenceType,
    int? recurrenceInterval,
    DateTime? lastCompletedAt,
    int? streak,
    int? parentMissionId,
    int? orderIndex,
    String? icon,
    String? emoji,
    String? locationName,
    double? latitude,
    double? longitude,
    DateTime? reminderAt,
    List<int>? recurrenceDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    List<int>? skillIds,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      urgency: urgency ?? this.urgency,
      fear: fear ?? this.fear,
      energyRequired: energyRequired ?? this.energyRequired,
      xpReward: xpReward ?? this.xpReward,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      streak: streak ?? this.streak,
      parentMissionId: parentMissionId ?? this.parentMissionId,
      orderIndex: orderIndex ?? this.orderIndex,
      icon: icon ?? this.icon,
      emoji: emoji ?? this.emoji,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      reminderAt: reminderAt ?? this.reminderAt,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      skillIds: skillIds ?? this.skillIds,
    );
  }

  static List<int> _parseRecurrenceDays(String? value) {
    if (value == null || value.trim().isEmpty) return const [];
    return value
        .split(',')
        .map((part) => int.tryParse(part.trim()))
        .whereType<int>()
        .where((day) => day >= 1 && day <= 7)
        .toList(growable: false);
  }
}
