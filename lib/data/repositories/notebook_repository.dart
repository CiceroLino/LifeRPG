import '../database/database_helper.dart';
import '../models/note.dart';
import '../models/notebook.dart';

class NotebookRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertNotebook(Notebook notebook) async {
    final db = await _dbHelper.database;
    return db.insert('notebooks', notebook.toMap());
  }

  Future<List<Notebook>> getActiveNotebooks() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notebooks',
      where: 'is_active = 1',
      orderBy: 'updated_at DESC',
    );
    return maps.map(Notebook.fromMap).toList();
  }

  Future<Notebook?> getNotebookById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('notebooks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Notebook.fromMap(maps.first);
  }

  Future<int> updateNotebook(Notebook notebook) async {
    final db = await _dbHelper.database;
    return db.update(
      'notebooks',
      notebook.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [notebook.id],
    );
  }

  Future<int> archiveNotebook(int id) async {
    final db = await _dbHelper.database;
    return db.update(
      'notebooks',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertNote(Note note) async {
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
  }

  Future<List<Note>> getNotesForNotebook(int notebookId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notes',
      where: 'notebook_id = ?',
      whereArgs: [notebookId],
      orderBy: 'updated_at DESC',
    );
    return maps.map(Note.fromMap).toList();
  }

  Future<Note?> getNoteById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  Future<int> updateNote(Note note) async {
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
  }

  Future<int> deleteNote(int id) async {
    final db = await _dbHelper.database;
    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<int, int>> getNoteCountsByNotebook() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT notebook_id, COUNT(*) AS count
      FROM notes
      GROUP BY notebook_id
    ''');
    return {
      for (final row in rows) row['notebook_id'] as int: row['count'] as int,
    };
  }
}
