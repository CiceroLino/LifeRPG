import 'package:flutter/foundation.dart';

import '../data/models/tome.dart';
import '../data/repositories/tome_repository.dart';

class TomeProvider extends ChangeNotifier {
  final TomeRepository _repo = TomeRepository();

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
}
