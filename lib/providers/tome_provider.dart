import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import '../data/models/tome.dart';
import '../data/repositories/tome_repository.dart';
import '../services/local_media_import_service.dart';

class TomeProvider extends ChangeNotifier {
  TomeProvider({TomeRepository? repo, LocalMediaImportService? mediaImporter})
    : _repo = repo ?? TomeRepository(),
      _mediaImporter = mediaImporter ?? createLocalMediaImportService();

  final TomeRepository _repo;
  final LocalMediaImportService _mediaImporter;

  List<Tome> _tomes = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Tome> get tomes => _tomes;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  List<Tome> get filteredTomes {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _tomes;
    return _tomes
        .where(
          (tome) =>
              tome.title.toLowerCase().contains(query) ||
              tome.author.toLowerCase().contains(query) ||
              tome.description.toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> loadTomes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tomes = await _repo.getActiveTomes();
    } catch (e) {
      debugPrint('Error loading tomes: $e');
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

  Future<int?> addTome(Tome tome) async {
    try {
      final id = await _repo.insertTome(tome);
      await loadTomes();
      return id;
    } catch (e) {
      debugPrint('Error adding tome: $e');
      return null;
    }
  }

  Future<int?> importTome(PlatformFile file) async {
    try {
      final imported = await _mediaImporter.importPlatformFile(
        file,
        library: LocalMediaLibrary.tomes,
        allowedExtensions: const ['pdf'],
      );
      return addTome(Tome(title: imported.title, filePath: imported.path));
    } catch (e) {
      debugPrint('Error importing tome: $e');
      return null;
    }
  }

  Future<void> updateTome(Tome tome) async {
    try {
      await _repo.updateTome(tome);
      await loadTomes();
    } catch (e) {
      debugPrint('Error updating tome: $e');
    }
  }

  Future<void> archiveTome(int id) async {
    try {
      await _repo.archiveTome(id);
      await loadTomes();
    } catch (e) {
      debugPrint('Error archiving tome: $e');
    }
  }

  Future<void> markOpened(int id) async {
    try {
      await _repo.markOpened(id);
      await loadTomes();
    } catch (e) {
      debugPrint('Error marking tome opened: $e');
    }
  }

  Future<void> updateReadingProgress(
    int id, {
    required int currentPage,
    int? totalPages,
  }) async {
    try {
      final tome = await _repo.getTomeById(id);
      if (tome == null) return;
      final safeCurrentPage = currentPage < 0 ? 0 : currentPage;
      final safeTotalPages = totalPages != null && totalPages > 0
          ? totalPages
          : tome.totalPages;
      await _repo.updateTome(
        tome.copyWith(
          currentPage: safeCurrentPage,
          totalPages: safeTotalPages,
          clearTotalPages: safeTotalPages == null,
        ),
      );
      await loadTomes();
    } catch (e) {
      debugPrint('Error updating tome reading progress: $e');
    }
  }
}
