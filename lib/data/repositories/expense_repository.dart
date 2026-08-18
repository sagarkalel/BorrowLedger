import 'package:borrow_ledger/data/models/expense_model.dart';

import '../database/database_helper.dart';

class ExpenseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _activityOrder =
      'updated_at DESC, created_at DESC, id DESC';

  // Create a new expense
  Future<int> createExpense(ExpenseModel expense) async {
    return await _dbHelper.insert('expenses', expense.toMap());
  }

  // Get all expenses
  Future<List<ExpenseModel>> getAllExpenses({int? limit, int? offset}) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'expenses',
      orderBy: _activityOrder,
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  // Get expenses by category
  Future<List<ExpenseModel>> getExpensesByCategory(
    String category, {
    int? limit,
    int? offset,
  }) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'expenses',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: _activityOrder,
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  // Get expense by ID
  Future<ExpenseModel?> getExpenseById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ExpenseModel.fromMap(maps.first);
  }

  // Search expenses
  Future<List<ExpenseModel>> searchExpenses(
    String query, {
    int? limit,
    int? offset,
  }) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'expenses',
      where: 'description LIKE ? OR category LIKE ?',
      whereArgs: ['%${query.trim()}%', '%${query.trim()}%'],
      orderBy: _activityOrder,
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  Future<int> getExpenseCount({String? category, String? searchQuery}) async {
    final whereParts = <String>[];
    final args = <dynamic>[];

    if (category != null && category.trim().isNotEmpty) {
      whereParts.add('category = ?');
      args.add(category);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereParts.add('(description LIKE ? OR category LIKE ?)');
      final searchTerm = '%${searchQuery.trim()}%';
      args.addAll([searchTerm, searchTerm]);
    }

    final where = whereParts.isEmpty ? '' : 'WHERE ${whereParts.join(' AND ')}';
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM expenses $where',
      args,
    );

    return (result.first['count'] as int?) ?? 0;
  }

  // Update expense
  Future<int> updateExpense(ExpenseModel expense) async {
    return await _dbHelper.update(
      'expenses',
      expense.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // Delete expense
  Future<int> deleteExpense(int id) async {
    return await _dbHelper.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Get expenses by date range
  Future<List<ExpenseModel>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  // Get total expenses
  Future<double> getTotalExpenses() async {
    final result = await _dbHelper.rawQuery('''
      SELECT SUM(amount) as total FROM expenses
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get expenses by month
  Future<List<ExpenseModel>> getExpensesByMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1).subtract(Duration(days: 1));
    return await getExpensesByDateRange(startDate, endDate);
  }

  // Get category-wise summary
  Future<List<Map<String, dynamic>>> getCategorySummary() async {
    return await _dbHelper.rawQuery('''
      SELECT 
        category,
        SUM(amount) as total,
        COUNT(*) as count
      FROM expenses
      GROUP BY category
      ORDER BY total DESC
    ''');
  }

  // Get monthly category breakdown
  Future<List<Map<String, dynamic>>> getMonthlyCategoryBreakdown(
    int year,
    int month,
  ) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1).subtract(Duration(days: 1));

    return await _dbHelper.rawQuery(
      '''
      SELECT 
        category,
        SUM(amount) as total,
        COUNT(*) as count
      FROM expenses
      WHERE date BETWEEN ? AND ?
      GROUP BY category
      ORDER BY total DESC
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
  }

  // Get recent expenses (limit to n items)
  Future<List<ExpenseModel>> getRecentExpenses(int limit) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'expenses',
      orderBy: _activityOrder,
      limit: limit,
    );
    return maps.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  // Get yearly total
  Future<double> getYearlyTotal(int year) async {
    final result = await _dbHelper.rawQuery(
      '''
      SELECT SUM(amount) as total 
      FROM expenses
      WHERE strftime('%Y', date) = ?
    ''',
      [year.toString()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get monthly totals for a year
  Future<List<Map<String, dynamic>>> getMonthlyTotals(int year) async {
    return await _dbHelper.rawQuery(
      '''
      SELECT 
        strftime('%m', date) as month,
        SUM(amount) as total,
        COUNT(*) as count
      FROM expenses
      WHERE strftime('%Y', date) = ?
      GROUP BY month
      ORDER BY month
    ''',
      [year.toString()],
    );
  }
}
