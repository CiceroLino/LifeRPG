import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/note.dart';
import 'package:liferpg/data/models/notebook.dart';
import 'package:liferpg/providers/notebook_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NotebookProvider provider;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
    provider = NotebookProvider();
  });

  test('loads notebooks and filters by search query', () async {
    await provider.addNotebook(
      Notebook(name: 'Field Journal', description: 'Routes and maps'),
    );
    await provider.addNotebook(
      Notebook(name: 'Recipes', description: 'Kitchen notes'),
    );

    provider.setSearchQuery('field');

    expect(provider.filteredNotebooks, hasLength(1));
    expect(provider.filteredNotebooks.single.name, 'Field Journal');
  });

  test('creates, updates, and deletes notes for selected notebook', () async {
    final notebookId = await provider.addNotebook(
      Notebook(name: 'Quest Notes'),
    );
    await provider.loadNotes(notebookId!);

    final noteId = await provider.addNote(
      Note(notebookId: notebookId, title: 'Plan', body: 'Start early.'),
    );
    expect(provider.notes, hasLength(1));
    expect(provider.notes.single.title, 'Plan');

    await provider.updateNote(
      provider.notes.single.copyWith(title: 'Updated plan'),
    );
    expect(provider.notes.single.title, 'Updated plan');

    await provider.deleteNote(noteId!);
    expect(provider.notes, isEmpty);
  });
}
