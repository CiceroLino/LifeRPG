class MissionRewardDrop {
  final int? id;
  final int missionId;
  final int rewardId;
  final int chancePercent;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  MissionRewardDrop({
    this.id,
    required this.missionId,
    required this.rewardId,
    required int chancePercent,
    required int quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : chancePercent = chancePercent.clamp(0, 100),
       quantity = quantity < 1 ? 1 : quantity,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mission_id': missionId,
      'reward_id': rewardId,
      'chance_percent': chancePercent,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MissionRewardDrop.fromMap(Map<String, dynamic> map) {
    return MissionRewardDrop(
      id: map['id'] as int?,
      missionId: map['mission_id'] as int,
      rewardId: map['reward_id'] as int,
      chancePercent: map['chance_percent'] as int? ?? 0,
      quantity: map['quantity'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  MissionRewardDrop copyWith({
    int? id,
    int? missionId,
    int? rewardId,
    int? chancePercent,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MissionRewardDrop(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      rewardId: rewardId ?? this.rewardId,
      chancePercent: chancePercent ?? this.chancePercent,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MissionCompletionRewardDrop {
  final int? id;
  final int eventId;
  final int rewardId;
  final int? inventoryItemId;
  final String rewardNameSnapshot;
  final int quantity;
  final int chancePercent;
  final bool wasAwarded;

  MissionCompletionRewardDrop({
    this.id,
    required this.eventId,
    required this.rewardId,
    this.inventoryItemId,
    required this.rewardNameSnapshot,
    required this.quantity,
    required this.chancePercent,
    required this.wasAwarded,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'reward_id': rewardId,
      'inventory_item_id': inventoryItemId,
      'reward_name_snapshot': rewardNameSnapshot,
      'quantity': quantity,
      'chance_percent': chancePercent,
      'was_awarded': wasAwarded ? 1 : 0,
    };
  }

  factory MissionCompletionRewardDrop.fromMap(Map<String, dynamic> map) {
    return MissionCompletionRewardDrop(
      id: map['id'] as int?,
      eventId: map['event_id'] as int,
      rewardId: map['reward_id'] as int,
      inventoryItemId: map['inventory_item_id'] as int?,
      rewardNameSnapshot: map['reward_name_snapshot'] as String,
      quantity: map['quantity'] as int? ?? 1,
      chancePercent: map['chance_percent'] as int? ?? 0,
      wasAwarded: (map['was_awarded'] as int? ?? 0) == 1,
    );
  }
}
