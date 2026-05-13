import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/note.dart';
import 'package:liferpg/data/models/notebook.dart';
import 'package:liferpg/data/repositories/notebook_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NotebookRepository notebooks;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
    notebooks = NotebookRepository();
  });

  test('creates, updates, lists, and archives notebooks', () async {
    final id = await notebooks.insertNotebook(
      Notebook(name: 'Field Journal', description: 'Daily field notes'),
    );

    var stored = await notebooks.getNotebookById(id);
    expect(stored!.name, 'Field Journal');
    expect(stored.description, 'Daily field notes');

    await notebooks.updateNotebook(
      stored.copyWith(name: 'Arcane Journal', description: 'Spell notes'),
    );

    stored = await notebooks.getNotebookById(id);
    expect(stored!.name, 'Arcane Journal');
    expect(stored.description, 'Spell notes');
    expect(await notebooks.getActiveNotebooks(), hasLength(1));

    await notebooks.archiveNotebook(id);
    expect(await notebooks.getActiveNotebooks(), isEmpty);
    expect((await notebooks.getNotebookById(id))!.isActive, isFalse);
  });

  test('manages notes and returns note counts per notebook', () async {
    final notebookId = await notebooks.insertNotebook(
      Notebook(name: 'Quest Notes'),
    );

    final firstNoteId = await notebooks.insertNote(
      Note(
        notebookId: notebookId,
        title: 'Morning route',
        body: 'Cross the bridge before noon.',
      ),
    );
    await notebooks.insertNote(
      Note(
        notebookId: notebookId,
        title: 'Supplies',
        body: 'Buy ink and paper.',
      ),
    );

    var notes = await notebooks.getNotesForNotebook(notebookId);
    expect(notes, hasLength(2));
    expect(notes.first.title, 'Supplies');

    await notebooks.updateNote(
      notes.first.copyWith(title: 'Supply list', body: 'Ink, paper, wax.'),
    );
    expect(
      (await notebooks.getNoteById(notes.first.id!))!.title,
      'Supply list',
    );

    await notebooks.deleteNote(firstNoteId);
    notes = await notebooks.getNotesForNotebook(notebookId);
    expect(notes, hasLength(1));

    final counts = await notebooks.getNoteCountsByNotebook();
    expect(counts[notebookId], 1);
  });

  test('backup and restore preserve notebooks and notes', () async {
    final notebookId = await notebooks.insertNotebook(
      Notebook(name: 'Travel Log'),
    );
    await notebooks.insertNote(
      Note(
        notebookId: notebookId,
        title: 'Day 1',
        body: 'Reached the first town.',
      ),
    );

    final backup = await DatabaseHelper().getAllDataForBackup();
    expect(backup['notebooks'], hasLength(1));
    expect(backup['notes'], hasLength(1));

    await DatabaseHelper().restoreData(backup);

    final restoredNotebooks = await notebooks.getActiveNotebooks();
    expect(restoredNotebooks.single.name, 'Travel Log');
    final restoredNotes = await notebooks.getNotesForNotebook(notebookId);
    expect(restoredNotes.single.body, 'Reached the first town.');
  });
}
