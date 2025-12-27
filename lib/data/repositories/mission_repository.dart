import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/mission.dart';

class MissionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Mission mission) async {
    final db = await _dbHelper.database;
    return await db.insert('missions', mission.toMap());
  }

  Future<List<Mission>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('missions', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => Mission.fromMap(maps[i]));
  }

  Future<List<Mission>> getByStatus(String status) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'missions',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Mission.fromMap(maps[i]));
  }

  Future<Mission?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'missions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Mission.fromMap(maps.first);
  }

  Future<Mission> getWithSkills(int missionId) async {
    final mission = await getById(missionId);
    if (mission == null) throw Exception('Mission not found');

    final db = await _dbHelper.database;
    final skillMaps = await db.rawQuery('''
      SELECT skill_id FROM mission_skills WHERE mission_id = ?
    ''', [missionId]);

    final skillIds = skillMaps.map((m) => m['skill_id'] as int).toList();
    return mission.copyWith(skillIds: skillIds);
  }

  Future<int> update(Mission mission) async {
    final db = await _dbHelper.database;
    return await db.update(
      'missions',
      mission.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [mission.id],
    );
  }

  Future<void> complete(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      'missions',
      {
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('missions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> linkSkills(int missionId, List<int> skillIds) async {
    final db = await _dbHelper.database;

    await db.delete('mission_skills', where: 'mission_id = ?', whereArgs: [missionId]);

    for (final skillId in skillIds) {
      await db.insert('mission_skills', {
        'mission_id': missionId,
        'skill_id': skillId,
      });
    }
  }

  Future<int> countByStatus(String status) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM missions WHERE status = ?',
      [status],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}