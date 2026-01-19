import 'dart:developer';

import '../database/database_helper.dart';
import '../models/udhari_item_model.dart';

class UdhariItemRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /* =======================
     WRITE OPERATIONS
  ======================== */

  /// Add or update item usage count
  Future<int> recordItemUsage(String itemName) async {
    if (itemName.trim().isEmpty) return 0;

    final trimmedName = itemName.trim();
    log('UdhariItemRepository: Recording usage for item: $trimmedName');

    try {
      // Check if item already exists
      final existing = await getItemByName(trimmedName);

      if (existing != null) {
        // Update usage count
        final updated = existing.copyWith(
          usageCount: existing.usageCount + 1,
          updatedAt: DateTime.now(),
        );
        await _dbHelper.update(
          'udhari_items',
          updated.toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        log(
          'UdhariItemRepository: Updated usage count to ${updated.usageCount}',
        );
        return existing.id!;
      } else {
        // Create new item
        final newItem = UdhariItemModel(itemName: trimmedName);
        final id = await _dbHelper.insert('udhari_items', newItem.toMap());
        log('UdhariItemRepository: Created new item with id: $id');
        return id;
      }
    } catch (e) {
      log('UdhariItemRepository: Error recording item usage - $e');
      rethrow;
    }
  }

  /// Delete an item suggestion
  Future<int> deleteItem(int id) async {
    log('UdhariItemRepository: Deleting item ID: $id');
    return _dbHelper.delete('udhari_items', where: 'id = ?', whereArgs: [id]);
  }

  /// Clear all items (for reset/testing)
  Future<void> clearAllItems() async {
    log('UdhariItemRepository: Clearing all items');
    await _dbHelper.delete('udhari_items');
  }

  /* =======================
     READ OPERATIONS
  ======================== */

  /// Get item by exact name (case-insensitive)
  Future<UdhariItemModel?> getItemByName(String itemName) async {
    if (itemName.trim().isEmpty) return null;

    final maps = await _dbHelper.query(
      'udhari_items',
      where: 'LOWER(item_name) = LOWER(?)',
      whereArgs: [itemName.trim()],
      limit: 1,
    );

    return maps.isEmpty ? null : UdhariItemModel.fromMap(maps.first);
  }

  /// Get top items ordered by usage count
  Future<List<UdhariItemModel>> getTopItems({int limit = 10}) async {
    log('UdhariItemRepository: Fetching top $limit items');

    final maps = await _dbHelper.query(
      'udhari_items',
      orderBy: 'usage_count DESC, updated_at DESC',
      limit: limit,
    );

    return maps.map(UdhariItemModel.fromMap).toList();
  }

  /// Search items by name (for autocomplete)
  Future<List<UdhariItemModel>> searchItems(
    String query, {
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return getTopItems(limit: limit);

    log('UdhariItemRepository: Searching items with query: "$query"');

    final maps = await _dbHelper.query(
      'udhari_items',
      where: 'LOWER(item_name) LIKE LOWER(?)',
      whereArgs: ['%${query.trim()}%'],
      orderBy: 'usage_count DESC, updated_at DESC',
      limit: limit,
    );

    return maps.map(UdhariItemModel.fromMap).toList();
  }

  /// Get all items
  Future<List<UdhariItemModel>> getAllItems() async {
    log('UdhariItemRepository: Fetching all items');

    final maps = await _dbHelper.query(
      'udhari_items',
      orderBy: 'usage_count DESC, item_name ASC',
    );

    return maps.map(UdhariItemModel.fromMap).toList();
  }

  /// Get item count
  Future<int> getItemCount() async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM udhari_items',
    );

    return (result.first['count'] as int?) ?? 0;
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final totalCount = await getItemCount();

    final totalUsageResult = await _dbHelper.rawQuery(
      'SELECT SUM(usage_count) as total_usage FROM udhari_items',
    );

    final totalUsage = (totalUsageResult.first['total_usage'] as int?) ?? 0;

    return {'total_items': totalCount, 'total_usage': totalUsage};
  }
}
