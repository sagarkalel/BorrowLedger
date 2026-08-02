import 'dart:developer';

import '../database/database_helper.dart';
import '../models/udhari_quantity_model.dart';

class UdhariQuantityRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> recordQuantityUsage(String quantity) async {
    if (quantity.trim().isEmpty) return 0;

    final trimmedQuantity = quantity.trim();
    log(
      'UdhariQuantityRepository: Recording usage for quantity: $trimmedQuantity',
    );

    try {
      final existing = await getQuantityByText(trimmedQuantity);

      if (existing != null) {
        final updated = existing.copyWith(
          usageCount: existing.usageCount + 1,
          updatedAt: DateTime.now(),
        );
        await _dbHelper.update(
          'udhari_quantities',
          updated.toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        return existing.id!;
      }

      final newQuantity = UdhariQuantityModel(quantity: trimmedQuantity);
      return _dbHelper.insert('udhari_quantities', newQuantity.toMap());
    } catch (e) {
      log('UdhariQuantityRepository: Error recording quantity usage - $e');
      rethrow;
    }
  }

  Future<UdhariQuantityModel?> getQuantityByText(String quantity) async {
    if (quantity.trim().isEmpty) return null;

    final maps = await _dbHelper.query(
      'udhari_quantities',
      where: 'LOWER(quantity) = LOWER(?)',
      whereArgs: [quantity.trim()],
      limit: 1,
    );

    return maps.isEmpty ? null : UdhariQuantityModel.fromMap(maps.first);
  }

  Future<List<UdhariQuantityModel>> getTopQuantities({int limit = 10}) async {
    final maps = await _dbHelper.query(
      'udhari_quantities',
      orderBy: 'usage_count DESC, updated_at DESC',
      limit: limit,
    );

    return maps.map(UdhariQuantityModel.fromMap).toList();
  }

  Future<List<UdhariQuantityModel>> searchQuantities(
    String query, {
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return getTopQuantities(limit: limit);

    final maps = await _dbHelper.query(
      'udhari_quantities',
      where: 'LOWER(quantity) LIKE LOWER(?)',
      whereArgs: ['%${query.trim()}%'],
      orderBy: 'usage_count DESC, updated_at DESC',
      limit: limit,
    );

    return maps.map(UdhariQuantityModel.fromMap).toList();
  }

  Future<void> clearAllQuantities() async {
    await _dbHelper.delete('udhari_quantities');
  }
}
