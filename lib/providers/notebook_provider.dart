import '../data/database/data_operations.dart';
import 'package:flutter/foundation.dart';

import '../data/models/note.dart';
import '../data/models/notebook.dart';
import '../data/repositories/notebook_repository.dart';

class NotebookProvider extends ChangeNotifier {
  NotebookProvider({NotebookRepository? repo})
    : _repo = repo ?? NotebookRepository();
  final NotebookRepository _repo;

  List<Notebook> _notebooks = [];
  List<Note> _notes = [];
  Map<int, int> _noteCountsByNotebook = {};
  bool _isLoading = false;
  String _searchQuery = '';
  int? _selectedNotebookId;
  int _notesRequest = 0;

  List<Notebook> get notebooks => _notebooks;
  List<Note> get notes => _notes;
  Map<int, int> get noteCountsByNotebook => _noteCountsByNotebook;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int? get selectedNotebookId => _selectedNotebookId;

  void clearSelection() {
    _notesRequest++;
    _selectedNotebookId = null;
    _notes = [];
    notifyListeners();
  }

  List<Notebook> get filteredNotebooks {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _notebooks;
    return _notebooks
        .where(
          (notebook) =>
              notebook.name.toLowerCase().contains(query) ||
              notebook.description.toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> loadNotebooks() => DataOperations.instance.run(() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notebooks = await _repo.getActiveNotebooks();
      _noteCountsByNotebook = await _repo.getNoteCountsByNotebook();
    } catch (e) {
      debugPrint('Error loading notebooks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }, readOnly: true);

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  Future<int?> addNotebook(Notebook notebook) =>
      DataOperations.instance.run(() async {
        try {
          final id = await _repo.insertNotebook(notebook);
          await loadNotebooks();
          return id;
        } catch (e) {
          debugPrint('Error adding notebook: $e');
          return null;
        }
      }, readOnly: false);

  Future<void> updateNotebook(Notebook notebook) =>
      DataOperations.instance.run(() async {
        try {
          await _repo.updateNotebook(notebook);
          await loadNotebooks();
        } catch (e) {
          debugPrint('Error updating notebook: $e');
        }
      }, readOnly: false);

  Future<void> archiveNotebook(int id) => DataOperations.instance.run(() async {
    try {
      await _repo.archiveNotebook(id);
      await loadNotebooks();
    } catch (e) {
      debugPrint('Error archiving notebook: $e');
    }
  }, readOnly: false);

  Future<void> loadNotes(int notebookId) =>
      DataOperations.instance.run(() async {
        final request = ++_notesRequest;
        _selectedNotebookId = notebookId;
        _notes = [];
        notifyListeners();
        final notes = await _repo.getNotesForNotebook(notebookId);
        if (request != _notesRequest) return;
        _notes = notes;
        notifyListeners();
      }, readOnly: true);

  Future<int?> addNote(Note note) => DataOperations.instance.run(() async {
    try {
      final id = await _repo.insertNote(note);
      await loadNotes(note.notebookId);
      await loadNotebooks();
      return id;
    } catch (e) {
      debugPrint('Error adding note: $e');
      return null;
    }
  }, readOnly: false);

  Future<void> updateNote(Note note) => DataOperations.instance.run(() async {
    try {
      await _repo.updateNote(note);
      await loadNotes(note.notebookId);
      await loadNotebooks();
    } catch (e) {
      debugPrint('Error updating note: $e');
    }
  }, readOnly: false);

  Future<void> deleteNote(int id) => DataOperations.instance.run(() async {
    try {
      await _repo.deleteNote(id);
      final notebookId = _selectedNotebookId;
      if (notebookId != null) {
        await loadNotes(notebookId);
      }
      await loadNotebooks();
    } catch (e) {
      debugPrint('Error deleting note: $e');
    }
  }, readOnly: false);
}
