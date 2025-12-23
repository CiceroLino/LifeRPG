class Player {
  final int id;
  final String name;
  final int totalXP;
  final int level;
  final int rewardPoints;
  final String? avatarPath;
  final int currentEnergy;
  final String themeMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Player({
    this.id = 1,
    this.name = 'Player',
    this.totalXP = 0,
    this.level = 1,
    this.rewardPoints = 0,
    this.avatarPath,
    this.currentEnergy = 5,
    this.themeMode = 'light',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'total_xp': totalXP,
      'level': level,
      'reward_points': rewardPoints,
      'avatar_path': avatarPath,
      'current_energy': currentEnergy,
      'theme_mode': themeMode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as int? ?? 1,
      name: map['name'] as String? ?? 'Player',
      totalXP: map['total_xp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      rewardPoints: map['reward_points'] as int? ?? 0,
      avatarPath: map['avatar_path'] as String?,
      currentEnergy: map['current_energy'] as int? ?? 5,
      themeMode: map['theme_mode'] as String? ?? 'light',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Player copyWith({
    int? id,
    String? name,
    int? totalXP,
    int? level,
    int? rewardPoints,
    String? avatarPath,
    int? currentEnergy,
    String? themeMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      avatarPath: avatarPath ?? this.avatarPath,
      currentEnergy: currentEnergy ?? this.currentEnergy,
      themeMode: themeMode ?? this.themeMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}