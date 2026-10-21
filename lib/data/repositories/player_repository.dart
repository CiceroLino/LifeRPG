import '../database/data_operations.dart';
import '../database/database_helper.dart';
import '../models/player.dart';
import '../../core/utils/xp_calculator.dart';
import 'package:sqflite/sqflite.dart';

class PlayerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Player> get() => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    return db.transaction(_get);
  }, readOnly: true);

  Future<Player> _get(DatabaseExecutor db) async {
    final maps = await db.query('player', where: 'id = 1');
    if (maps.isEmpty) {
      final now = DateTime.now().toIso8601String();
      await db.insert('player', {
        'id': 1,
        'name': 'Player',
        'title': 'Adventurer',
        'description': '',
        'total_xp': 0,
        'level': 1,
        'reward_points': 0,
        'current_energy': 100,
        'theme_mode': 'light',
        'created_at': now,
        'updated_at': now,
      });
      return Player();
    }
    final player = Player.fromMap(maps.first);

    final calculatedLevel = XPCalculator.calculateLevel(player.totalXP);
    if (calculatedLevel != player.level) {
      final updated = player.copyWith(level: calculatedLevel);
      await db.update('player', {'level': calculatedLevel}, where: 'id = 1');
      return updated;
    }

    return player;
  }

  Future<int> update(Player player) => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    return await db.update(
      'player',
      player.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = 1',
    );
  }, readOnly: false);

  Future<void> updateProfile(Player player) => _patch({
    'name': player.name,
    'title': player.title,
    'description': player.description,
    'avatar_path': player.avatarPath,
  });

  Future<void> updateEnergy({
    int? value,
    String? mode,
    String? wakeUpTime,
    String? sleepTime,
  }) => _patch({
    if (value != null) 'current_energy': value.clamp(0, 100),
    'energy_mode': ?mode,
    'wake_up_time': ?wakeUpTime,
    'sleep_time': ?sleepTime,
  });

  Future<void> _patch(Map<String, Object?> fields) =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        final changed = await db.update('player', {
          ...fields,
          'updated_at': DateTime.now().toIso8601String(),
        }, where: 'id = 1');
        if (changed != 1) throw StateError('Player is unavailable.');
      }, readOnly: false);

  Future<void> addXP(int xp, {DatabaseExecutor? executor}) =>
      DataOperations.instance.run(() async {
        Future<void> apply(DatabaseExecutor txn) async {
          final player = await _get(txn);
          final total = player.totalXP + xp;
          if (total < 0) throw ArgumentError.value(xp, 'xp');
          await txn.update('player', {
            'total_xp': total,
            'level': XPCalculator.calculateLevel(total),
            'updated_at': DateTime.now().toIso8601String(),
          }, where: 'id = 1');
        }

        if (executor != null) return apply(executor);
        final db = await _dbHelper.database;
        await db.transaction(apply);
      }, readOnly: false);

  Future<void> addRewardPoints(int points, {DatabaseExecutor? executor}) =>
      DataOperations.instance.run(() async {
        Future<void> apply(DatabaseExecutor txn) async {
          final player = await _get(txn);
          final balance = player.rewardPoints + points;
          if (balance < 0) throw ArgumentError.value(points, 'points');
          await txn.update('player', {
            'reward_points': balance,
            'updated_at': DateTime.now().toIso8601String(),
          }, where: 'id = 1');
        }

        if (executor != null) return apply(executor);
        final db = await _dbHelper.database;
        await db.transaction(apply);
      }, readOnly: false);
}
