class RewardRedemption {
  final int? id;
  final int? rewardId;
  final int? inventoryItemId;
  final String rewardNameSnapshot;
  final String rewardDescriptionSnapshot;
  final String? rewardIconSnapshot;
  final int pricePaidRp;
  final DateTime redeemedAt;

  RewardRedemption({
    this.id,
    this.rewardId,
    this.inventoryItemId,
    required this.rewardNameSnapshot,
    this.rewardDescriptionSnapshot = '',
    this.rewardIconSnapshot,
    required this.pricePaidRp,
    DateTime? redeemedAt,
  }) : redeemedAt = redeemedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reward_id': rewardId,
      'inventory_item_id': inventoryItemId,
      'reward_name_snapshot': rewardNameSnapshot,
      'reward_description_snapshot': rewardDescriptionSnapshot,
      'reward_icon_snapshot': rewardIconSnapshot,
      'price_paid_rp': pricePaidRp,
      'redeemed_at': redeemedAt.toIso8601String(),
    };
  }

  factory RewardRedemption.fromMap(Map<String, dynamic> map) {
    return RewardRedemption(
      id: map['id'] as int?,
      rewardId: map['reward_id'] as int?,
      inventoryItemId: map['inventory_item_id'] as int?,
      rewardNameSnapshot: map['reward_name_snapshot'] as String,
      rewardDescriptionSnapshot:
          map['reward_description_snapshot'] as String? ?? '',
      rewardIconSnapshot: map['reward_icon_snapshot'] as String?,
      pricePaidRp: map['price_paid_rp'] as int? ?? 0,
      redeemedAt: DateTime.parse(map['redeemed_at'] as String),
    );
  }
}
