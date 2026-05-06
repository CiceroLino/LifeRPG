class InventoryItem {
  final int? id;
  final int? rewardId;
  final String name;
  final String description;
  final String? icon;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItem({
    this.id,
    this.rewardId,
    required this.name,
    this.description = '',
    this.icon,
    this.quantity = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reward_id': rewardId,
      'name': name,
      'description': description,
      'icon': icon,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as int?,
      rewardId: map['reward_id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      icon: map['icon'] as String?,
      quantity: map['quantity'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  InventoryItem copyWith({
    int? id,
    int? rewardId,
    String? name,
    String? description,
    String? icon,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      rewardId: rewardId ?? this.rewardId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
