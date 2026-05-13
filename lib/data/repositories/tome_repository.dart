import '../database/database_helper.dart';
import '../models/tome.dart';

class TomeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertTome(Tome tome) async {
    final db = await _dbHelper.database;
    return db.insert('tomes', tome.toMap());
  }

  Future<List<Tome>> getActiveTomes() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tomes',
      where: 'is_active = 1',
      orderBy: 'updated_at DESC',
    );
    return maps.map(Tome.fromMap).toList();
  }

  Future<Tome?> getTomeById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('tomes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Tome.fromMap(maps.first);
  }

  Future<int> updateTome(Tome tome) async {
    final db = await _dbHelper.database;
    return db.update(
      'tomes',
      tome.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [tome.id],
    );
  }

  Future<int> archiveTome(int id) async {
    final db = await _dbHelper.database;
    return db.update(
      'tomes',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markOpened(int id) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'tomes',
      {'last_opened_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
