import '../database/data_operations.dart';
import '../database/database_helper.dart';
import '../models/note.dart';
import '../models/notebook.dart';

class NotebookRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertNotebook(Notebook notebook) =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        return db.insert('notebooks', notebook.toMap());
      }, readOnly: false);

  Future<List<Notebook>> getActiveNotebooks() =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        final maps = await db.query(
          'notebooks',
          where: 'is_active = 1',
          orderBy: 'updated_at DESC',
        );
        return maps.map(Notebook.fromMap).toList();
      }, readOnly: true);

  Future<Notebook?> getNotebookById(int id) =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        final maps = await db.query(
          'notebooks',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (maps.isEmpty) return null;
        return Notebook.fromMap(maps.first);
      }, readOnly: true);

  Future<int> updateNotebook(Notebook notebook) =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        return db.update(
          'notebooks',
          notebook.copyWith(updatedAt: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [notebook.id],
        );
      }, readOnly: false);

  Future<int> archiveNotebook(int id) => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    return db.update(
      'notebooks',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }, readOnly: false);

  Future<int> insertNote(Note note) => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('notes', note.toMap());
    await db.update(
      'notebooks',
      {'updated_at': now},
      where: 'id = ?',
      whereArgs: [note.notebookId],
    );
    return id;
  }, readOnly: false);

  Future<List<Note>> getNotesForNotebook(int notebookId) =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        final maps = await db.query(
          'notes',
          where: 'notebook_id = ?',
          whereArgs: [notebookId],
          orderBy: 'updated_at DESC',
        );
        return maps.map(Note.fromMap).toList();
      }, readOnly: true);

  Future<Note?> getNoteById(int id) => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    final maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }, readOnly: true);

  Future<int> updateNote(Note note) => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final result = await db.update(
      'notes',
      note.copyWith(updatedAt: now).toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
    await db.update(
      'notebooks',
      {'updated_at': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [note.notebookId],
    );
    return result;
  }, readOnly: false);

  Future<int> deleteNote(int id) => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }, readOnly: false);

  Future<Map<int, int>> getNoteCountsByNotebook() =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        final rows = await db.rawQuery('''
      SELECT notebook_id, COUNT(*) AS count
      FROM notes
      GROUP BY notebook_id
    ''');
        return {
          for (final row in rows)
            row['notebook_id'] as int: row['count'] as int,
        };
      }, readOnly: true);
}
