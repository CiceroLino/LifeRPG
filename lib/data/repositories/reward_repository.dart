import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/inventory_item.dart';
import '../models/reward.dart';
import '../models/reward_redemption.dart';

class RewardRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Reward reward) async {
    final db = await _dbHelper.database;
    return db.insert('rewards', reward.toMap());
  }

  Future<List<Reward>> getActive() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'rewards',
      where: 'is_active = 1',
      orderBy: 'created_at DESC',
    );
    return maps.map(Reward.fromMap).toList();
  }

  Future<Reward?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('rewards', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Reward.fromMap(maps.first);
  }

  Future<int> update(Reward reward) async {
    final db = await _dbHelper.database;
    return db.update(
      'rewards',
      reward.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [reward.id],
    );
  }

  Future<int> archive(int id) async {
    final db = await _dbHelper.database;
    return db.update(
      'rewards',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<RewardRedemption>> getRedemptions() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'reward_redemptions',
      orderBy: 'redeemed_at DESC',
    );
    return maps.map(RewardRedemption.fromMap).toList();
  }

  Future<RewardPurchaseResult> purchaseReward(int rewardId) async {
    final db = await _dbHelper.database;
    return db.transaction((txn) async {
      final reward = await _requireActiveReward(txn, rewardId);
      if (!reward.isUnlimitedStock && (reward.stockRemaining ?? 0) <= 0) {
        throw RewardOutOfStockException();
      }

      final playerMaps = await txn.query('player', where: 'id = 1', limit: 1);
      final rewardPoints = playerMaps.first['reward_points'] as int? ?? 0;
      if (rewardPoints < reward.priceRp) {
        throw InsufficientRewardPointsException();
      }

      final now = DateTime.now().toIso8601String();
      await txn.update('player', {
        'reward_points': rewardPoints - reward.priceRp,
        'updated_at': now,
      }, where: 'id = 1');

      if (!reward.isUnlimitedStock) {
        await txn.update(
          'rewards',
          {
            'stock_remaining': (reward.stockRemaining ?? 0) - 1,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [reward.id],
        );
      }

      final inventoryItemId = await _createOrIncrementInventoryItem(
        txn,
        reward,
        now,
      );
      final redemptionId = await txn.insert(
        'reward_redemptions',
        RewardRedemption(
          rewardId: reward.id,
          inventoryItemId: inventoryItemId,
          rewardNameSnapshot: reward.name,
          rewardDescriptionSnapshot: reward.description,
          rewardIconSnapshot: reward.icon,
          pricePaidRp: reward.priceRp,
        ).toMap(),
      );

      return RewardPurchaseResult(
        rewardId: rewardId,
        inventoryItemId: inventoryItemId,
        redemptionId: redemptionId,
      );
    });
  }

  Future<Reward> _requireActiveReward(
    DatabaseExecutor txn,
    int rewardId,
  ) async {
    final maps = await txn.query(
      'rewards',
      where: 'id = ? AND is_active = 1',
      whereArgs: [rewardId],
      limit: 1,
    );
    if (maps.isEmpty) {
      throw RewardUnavailableException();
    }
    return Reward.fromMap(maps.first);
  }

  Future<int> _createOrIncrementInventoryItem(
    DatabaseExecutor txn,
    Reward reward,
    String now,
  ) async {
    final existing = await txn.query(
      'inventory_items',
      where: 'reward_id = ?',
      whereArgs: [reward.id],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final item = InventoryItem.fromMap(existing.first);
      await txn.update(
        'inventory_items',
        {'quantity': item.quantity + 1, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [item.id],
      );
      return item.id!;
    }

    return txn.insert(
      'inventory_items',
      InventoryItem(
        rewardId: reward.id,
        name: reward.name,
        description: reward.description,
        icon: reward.icon,
      ).toMap(),
    );
  }
}

class RewardPurchaseResult {
  final int rewardId;
  final int inventoryItemId;
  final int redemptionId;

  RewardPurchaseResult({
    required this.rewardId,
    required this.inventoryItemId,
    required this.redemptionId,
  });
}

class RewardUnavailableException implements Exception {}

class InsufficientRewardPointsException implements Exception {}

class RewardOutOfStockException implements Exception {}
