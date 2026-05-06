class Reward {
  final int? id;
  final String name;
  final String description;
  final int priceRp;
  final bool isUnlimitedStock;
  final int? stockRemaining;
  final String? icon;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reward({
    this.id,
    required this.name,
    this.description = '',
    required this.priceRp,
    this.isUnlimitedStock = true,
    this.stockRemaining,
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
      'price_rp': priceRp,
      'is_unlimited_stock': isUnlimitedStock ? 1 : 0,
      'stock_remaining': isUnlimitedStock ? null : stockRemaining,
      'icon': icon,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      priceRp: map['price_rp'] as int? ?? 0,
      isUnlimitedStock: (map['is_unlimited_stock'] as int? ?? 1) == 1,
      stockRemaining: map['stock_remaining'] as int?,
      icon: map['icon'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Reward copyWith({
    int? id,
    String? name,
    String? description,
    int? priceRp,
    bool? isUnlimitedStock,
    int? stockRemaining,
    String? icon,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reward(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      priceRp: priceRp ?? this.priceRp,
      isUnlimitedStock: isUnlimitedStock ?? this.isUnlimitedStock,
      stockRemaining: stockRemaining ?? this.stockRemaining,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
