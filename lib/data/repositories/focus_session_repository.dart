import '../database/data_operations.dart';
import '../database/database_helper.dart';
import '../models/focus_session.dart';
import 'package:sqflite/sqflite.dart';

class FocusSessionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(
    FocusSession session, {
    DatabaseExecutor? executor,
    String? sessionKey,
  }) => DataOperations.instance.run(() async {
    final db = executor ?? await _dbHelper.database;
    return db.insert('focus_sessions', {
      ...session.toMap(),
      'session_key': sessionKey,
    });
  }, readOnly: false);

  Future<List<FocusSession>> getRecent({int limit = 20}) =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        final maps = await db.query(
          'focus_sessions',
          orderBy: 'completed_at DESC',
          limit: limit,
        );
        return maps.map(FocusSession.fromMap).toList();
      }, readOnly: true);
}
