import '../database/data_operations.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/mission.dart';

class MissionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Mission mission, {DatabaseExecutor? executor}) =>
      DataOperations.instance.run(() async {
        final db = executor ?? await _dbHelper.database;
        return await db.insert('missions', mission.toMap());
      }, readOnly: false);

  Future<List<Mission>> getAll() => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    final maps = await db.query('missions', orderBy: 'created_at DESC');
    final missions = List.generate(
      maps.length,
      (i) => Mission.fromMap(maps[i]),
    );
    return _withSkillIds(db, missions);
  }, readOnly: true);

  Future<List<Mission>> getByStatus(String status) =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        final maps = await db.query(
          'missions',
          where: 'status = ?',
          whereArgs: [status],
          orderBy: 'created_at DESC',
        );
        final missions = List.generate(
          maps.length,
          (i) => Mission.fromMap(maps[i]),
        );
        return _withSkillIds(db, missions);
      }, readOnly: true);

  Future<Mission?> getById(int id) => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    final maps = await db.query('missions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Mission.fromMap(maps.first);
  }, readOnly: true);

  Future<Mission> getWithSkills(int missionId) =>
      DataOperations.instance.run(() async {
        final mission = await getById(missionId);
        if (mission == null) throw Exception('Mission not found');
        final db = await _dbHelper.database;
        final skillMaps = await db.rawQuery(
          '''
      SELECT skill_id FROM mission_skills WHERE mission_id = ?
    ''',
          [missionId],
        );
        final skillIds = skillMaps.map((m) => m['skill_id'] as int).toList();
        return mission.copyWith(skillIds: skillIds);
      }, readOnly: true);

  Future<List<Mission>> _withSkillIds(
    Database db,
    List<Mission> missions,
  ) async {
    if (missions.isEmpty) return missions;

    final skillMaps = await db.query('mission_skills');
    final skillsByMission = <int, List<int>>{};
    for (final row in skillMaps) {
      final missionId = row['mission_id'] as int?;
      final skillId = row['skill_id'] as int?;
      if (missionId == null || skillId == null) continue;
      skillsByMission.putIfAbsent(missionId, () => <int>[]).add(skillId);
    }

    return missions
        .map(
          (mission) => mission.copyWith(
            skillIds: skillsByMission[mission.id] ?? const [],
          ),
        )
        .toList();
  }

  Future<int> update(Mission mission, {DatabaseExecutor? executor}) =>
      DataOperations.instance.run(() async {
        final db = executor ?? await _dbHelper.database;
        return await db.update(
          'missions',
          mission.copyWith(updatedAt: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [mission.id],
        );
      }, readOnly: false);

  Future<void> complete(int id) => DataOperations.instance.run(() async {
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
  }, readOnly: false);

  Future<int> delete(int id) => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    return await db.delete('missions', where: 'id = ?', whereArgs: [id]);
  }, readOnly: false);

  Future<void> linkSkills(
    int missionId,
    List<int> skillIds, {
    DatabaseExecutor? executor,
  }) => DataOperations.instance.run(() async {
    final db = executor ?? await _dbHelper.database;
    await db.delete(
      'mission_skills',
      where: 'mission_id = ?',
      whereArgs: [missionId],
    );
    for (final skillId in skillIds) {
      await db.insert('mission_skills', {
        'mission_id': missionId,
        'skill_id': skillId,
      });
    }
  }, readOnly: false);

  Future<int> countByStatus(String status) =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM missions WHERE status = ?',
          [status],
        );
        return Sqflite.firstIntValue(result) ?? 0;
      }, readOnly: false);
}
