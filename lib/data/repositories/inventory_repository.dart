import '../database/database_helper.dart';
import '../models/inventory_item.dart';

class InventoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<InventoryItem>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('inventory_items', orderBy: 'updated_at DESC');
    return maps.map(InventoryItem.fromMap).toList();
  }

  Future<InventoryItem?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'inventory_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return InventoryItem.fromMap(maps.first);
  }

  Future<void> consumeItem(int id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final maps = await txn.query(
        'inventory_items',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) {
        throw InventoryItemNotFoundException();
      }

      final item = InventoryItem.fromMap(maps.first);
      if (item.quantity <= 1) {
        await txn.delete('inventory_items', where: 'id = ?', whereArgs: [id]);
      } else {
        await txn.update(
          'inventory_items',
          {
            'quantity': item.quantity - 1,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }
}

class InventoryItemNotFoundException implements Exception {}
