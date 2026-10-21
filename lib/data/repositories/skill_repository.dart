import '../database/data_operations.dart';
import '../database/database_helper.dart';
import '../models/skill.dart';

class SkillRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Skill skill) => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    return await db.insert('skills', skill.toMap());
  }, readOnly: false);

  Future<List<Skill>> getAll() => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    final maps = await db.query('skills', where: 'is_active = 1');
    return List.generate(maps.length, (i) => Skill.fromMap(maps[i]));
  }, readOnly: true);

  Future<Skill?> getById(int id) => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    final maps = await db.query('skills', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Skill.fromMap(maps.first);
  }, readOnly: true);

  Future<int> update(Skill skill) => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    return await db.update(
      'skills',
      skill.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [skill.id],
    );
  }, readOnly: false);

  Future<int> delete(int id) => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    return await db.update(
      'skills',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }, readOnly: false);

  Future<void> addXP(int skillId, int xp) =>
      DataOperations.instance.run(() async {
        final skill = await getById(skillId);
        if (skill == null) return;
        int newXP = skill.currentXP + xp;
        int newLevel = skill.level;
        while (newXP >= newLevel * 100) {
          newXP -= newLevel * 100;
          newLevel++;
        }
        await update(skill.copyWith(currentXP: newXP, level: newLevel));
      }, readOnly: false);
}
