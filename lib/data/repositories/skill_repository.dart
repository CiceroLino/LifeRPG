import '../database/database_helper.dart';
import '../models/skill.dart';

class SkillRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Skill skill) async {
    final db = await _dbHelper.database;
    return await db.insert('skills', skill.toMap());
  }

  Future<List<Skill>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('skills', where: 'is_active = 1');
    return List.generate(maps.length, (i) => Skill.fromMap(maps[i]));
  }

  Future<Skill?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('skills', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Skill.fromMap(maps.first);
  }

  Future<int> update(Skill skill) async {
    final db = await _dbHelper.database;
    return await db.update(
      'skills',
      skill.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [skill.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'skills',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addXP(int skillId, int xp) async {
    final skill = await getById(skillId);
    if (skill == null) return;

    int newXP = skill.currentXP + xp;
    int newLevel = skill.level;

    while (newXP >= newLevel * 100) {
      newXP -= newLevel * 100;
      newLevel++;
    }

    await update(skill.copyWith(currentXP: newXP, level: newLevel));
  }
}
