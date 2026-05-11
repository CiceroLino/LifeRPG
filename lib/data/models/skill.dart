class Skill {
  final int? id;
  final String name;
  final String description;
  final int currentXP;
  final int level;
  final String color;
  final String? icon;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Skill({
    this.id,
    required this.name,
    this.description = '',
    this.currentXP = 0,
    this.level = 1,
    this.color = '#2196F3',
    this.icon,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'current_xp': currentXP,
      'level': level,
      'color': color,
      'icon': icon,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      currentXP: map['current_xp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      color: map['color'] as String? ?? '#2196F3',
      icon: map['icon'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Skill.fromJson(Map<String, dynamic> json) => Skill.fromMap(json);

  Skill copyWith({
    int? id,
    String? name,
    String? description,
    int? currentXP,
    int? level,
    String? color,
    String? icon,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      currentXP: currentXP ?? this.currentXP,
      level: level ?? this.level,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
