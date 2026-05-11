import '../database/database_helper.dart';
import '../models/focus_session.dart';

class FocusSessionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(FocusSession session) async {
    final db = await _dbHelper.database;
    return db.insert('focus_sessions', session.toMap());
  }

  Future<List<FocusSession>> getRecent({int limit = 20}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'focus_sessions',
      orderBy: 'completed_at DESC',
      limit: limit,
    );
    return maps.map(FocusSession.fromMap).toList();
  }
}
