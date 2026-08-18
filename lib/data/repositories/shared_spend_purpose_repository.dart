import 'dart:developer';

import '../database/database_helper.dart';
import '../models/shared_spend_purpose_model.dart';

class SharedSpendPurposeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> ensureTable() async {
    await _dbHelper.ensureSharedSpendPurposeTable();
  }

  Future<int> recordPurposeUsage(String purpose) async {
    if (purpose.trim().isEmpty) return 0;

    await ensureTable();
    final trimmedPurpose = purpose.trim();
    log(
      'SharedSpendPurposeRepository: Recording usage for purpose: $trimmedPurpose',
    );

    final existing = await getPurposeByName(trimmedPurpose);
    if (existing != null) {
      final updated = existing.copyWith(
        usageCount: existing.usageCount + 1,
        updatedAt: DateTime.now(),
      );
      await _dbHelper.update(
        'shared_spend_purposes',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return existing.id!;
    }

    final newPurpose = SharedSpendPurposeModel(purpose: trimmedPurpose);
    return _dbHelper.insert('shared_spend_purposes', newPurpose.toMap());
  }

  Future<SharedSpendPurposeModel?> getPurposeByName(String purpose) async {
    if (purpose.trim().isEmpty) return null;

    await ensureTable();
    final maps = await _dbHelper.query(
      'shared_spend_purposes',
      where: 'LOWER(purpose) = LOWER(?)',
      whereArgs: [purpose.trim()],
      limit: 1,
    );

    return maps.isEmpty ? null : SharedSpendPurposeModel.fromMap(maps.first);
  }

  Future<List<SharedSpendPurposeModel>> getTopPurposes({int limit = 10}) async {
    await ensureTable();
    final maps = await _dbHelper.query(
      'shared_spend_purposes',
      orderBy: 'usage_count DESC, updated_at DESC',
      limit: limit,
    );

    return maps.map(SharedSpendPurposeModel.fromMap).toList();
  }

  Future<List<SharedSpendPurposeModel>> searchPurposes(
    String query, {
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return getTopPurposes(limit: limit);

    await ensureTable();
    final maps = await _dbHelper.query(
      'shared_spend_purposes',
      where: 'LOWER(purpose) LIKE LOWER(?)',
      whereArgs: ['%${query.trim()}%'],
      orderBy: 'usage_count DESC, updated_at DESC',
      limit: limit,
    );

    return maps.map(SharedSpendPurposeModel.fromMap).toList();
  }
}
