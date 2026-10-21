import 'dart:async';
import 'package:liferpg/data/repositories/notebook_repository.dart';
import '../support/test_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/models/note.dart';
import 'package:liferpg/data/models/notebook.dart';
import 'package:liferpg/providers/notebook_provider.dart';

class DelayedNotebookRepository extends NotebookRepository {
  final a = Completer<List<Note>>();
  final b = Completer<List<Note>>();
  @override
  Future<List<Note>> getNotesForNotebook(int id) =>
      id == 1 ? a.future : b.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NotebookProvider provider;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await resetTestDatabase();
    provider = NotebookProvider();
  });

  test('late response cannot replace current notebook notes', () async {
    final repo = DelayedNotebookRepository();
    final subject = NotebookProvider(repo: repo);
    final a = subject.loadNotes(1);
    final b = subject.loadNotes(2);
    repo.b.complete([Note(notebookId: 2, title: 'B')]);
    await b;
    repo.a.complete([Note(notebookId: 1, title: 'A')]);
    await a;
    expect(subject.selectedNotebookId, 2);
    expect(subject.notes.single.notebookId, 2);
    subject.dispose();
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
