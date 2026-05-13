import 'package:flutter/foundation.dart';

import '../data/models/note.dart';
import '../data/models/notebook.dart';
import '../data/repositories/notebook_repository.dart';

class NotebookProvider extends ChangeNotifier {
  final NotebookRepository _repo = NotebookRepository();

  List<Notebook> _notebooks = [];
  List<Note> _notes = [];
  Map<int, int> _noteCountsByNotebook = {};
  bool _isLoading = false;
  String _searchQuery = '';
  int? _selectedNotebookId;

  List<Notebook> get notebooks => _notebooks;
  List<Note> get notes => _notes;
  Map<int, int> get noteCountsByNotebook => _noteCountsByNotebook;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int? get selectedNotebookId => _selectedNotebookId;

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

  Future<void> loadNotebooks() async {
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
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  Future<int?> addNotebook(Notebook notebook) async {
    try {
      final id = await _repo.insertNotebook(notebook);
      await loadNotebooks();
      return id;
    } catch (e) {
      debugPrint('Error adding notebook: $e');
      return null;
    }
  }

  Future<void> updateNotebook(Notebook notebook) async {
    try {
      await _repo.updateNotebook(notebook);
      await loadNotebooks();
    } catch (e) {
      debugPrint('Error updating notebook: $e');
    }
  }

  Future<void> archiveNotebook(int id) async {
    try {
      await _repo.archiveNotebook(id);
      await loadNotebooks();
    } catch (e) {
      debugPrint('Error archiving notebook: $e');
    }
  }

  Future<void> loadNotes(int notebookId) async {
    _selectedNotebookId = notebookId;
    _notes = await _repo.getNotesForNotebook(notebookId);
    notifyListeners();
  }

  Future<int?> addNote(Note note) async {
    try {
      final id = await _repo.insertNote(note);
      await loadNotes(note.notebookId);
      await loadNotebooks();
      return id;
    } catch (e) {
      debugPrint('Error adding note: $e');
      return null;
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      await _repo.updateNote(note);
      await loadNotes(note.notebookId);
      await loadNotebooks();
    } catch (e) {
      debugPrint('Error updating note: $e');
    }
  }

  Future<void> deleteNote(int id) async {
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
  }
}
