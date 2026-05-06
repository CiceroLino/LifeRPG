import 'package:flutter/foundation.dart';

import '../data/models/inventory_item.dart';
import '../data/repositories/inventory_repository.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _inventoryRepo = InventoryRepository();

  List<InventoryItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _inventoryRepo.getAll();
    } catch (e) {
      _error = 'Erro ao carregar inventário: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> consumeItem(int id) async {
    try {
      _error = null;
      await _inventoryRepo.consumeItem(id);
      await loadItems();
    } catch (e) {
      _error = 'Erro ao usar item: $e';
      notifyListeners();
    }
  }
}
