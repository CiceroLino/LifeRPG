import '../database/database_helper.dart';
import '../models/player.dart';
import '../../core/utils/xp_calculator.dart';

class PlayerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Player> get() async {
    final db = await _dbHelper.database;
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
        'current_energy': 5,
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
      await update(updated);
      return updated;
    }

    return player;
  }

  Future<int> update(Player player) async {
    final db = await _dbHelper.database;
    return await db.update(
      'player',
      player.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = 1',
    );
  }

  Future<void> addXP(int xp) async {
    final player = await get();
    final newTotalXP = player.totalXP + xp;
    final newLevel = XPCalculator.calculateLevel(newTotalXP);

    await update(player.copyWith(totalXP: newTotalXP, level: newLevel));
  }

  Future<void> addRewardPoints(int points) async {
    final player = await get();
    await update(player.copyWith(rewardPoints: player.rewardPoints + points));
  }
}
