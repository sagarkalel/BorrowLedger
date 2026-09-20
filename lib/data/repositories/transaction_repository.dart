import 'dart:developer';
import 'dart:math' as math;

import 'package:borrow_ledger/core/constants/app_constants.dart';
import 'package:borrow_ledger/core/utils/split_settlement_calculator.dart';
import 'package:borrow_ledger/data/models/contact_activity_item.dart';
import 'package:borrow_ledger/data/models/contact_settlement_model.dart';
import 'package:borrow_ledger/data/models/split_model.dart';
import 'package:borrow_ledger/core/utils/transaction_sort_option.dart';
import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:borrow_ledger/data/repositories/split_transaction_sync_helper.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../database/database_helper.dart';

class ContactSettlementBalances {
  final double directNet;
  final double splitNet;

  const ContactSettlementBalances({this.directNet = 0, this.splitNet = 0});
}

class ContactSettlementResult {
  final int? settlementId;
  final double directSettled;
  final double splitSettled;
  final double cashAmount;
  final double offsetAmount;

  const ContactSettlementResult({
    this.settlementId,
    this.directSettled = 0,
    this.splitSettled = 0,
    this.cashAmount = 0,
    this.offsetAmount = 0,
  });
}

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _splitHistoryDescriptionPrefix = 'Split history: ';
  static const List<String> _hiddenContactSettlementSourceTypes = [
    AppConstants.sourceTypeContactSettlement,
    AppConstants.sourceTypeContactSettlementOffset,
    AppConstants.sourceTypeContactSettlementLegacy,
    AppConstants.sourceTypeContactSettlementOffsetLegacy,
  ];

  String get _visibleUserTransactionCondition =>
      '(t.source_type IS NULL OR t.source_type NOT IN (?, ?, ?, ?))';

  void _addHiddenSettlementArgs(List<dynamic> args) {
    args.addAll(_hiddenContactSettlementSourceTypes);
  }

  /* =======================
     WRITE OPERATIONS
  ======================== */

  Future<int> createTransaction(TransactionModel transaction) async {
    log(
      'TransactionRepository: Creating ${transaction.category} transaction - ${transaction.type}',
    );
    return _dbHelper.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    log('TransactionRepository: Updating transaction ID: ${transaction.id}');
    return _dbHelper.update(
      'transactions',
      transaction.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    log('TransactionRepository: Deleting transaction ID: $id');
    return _dbHelper.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<ContactSettlementResult> settleContactBalance({
    required int contactId,
    required bool settleFull,
    required double amount,
    required String paymentDescription,
    required String offsetDescription,
    DateTime? date,
  }) async {
    return _dbHelper.transaction((txn) async {
      final balances = await _getContactSettlementBalancesInTransaction(
        txn,
        contactId,
      );
      final directNet = balances.directNet;
      final splitNet = balances.splitNet;
      final net = directNet + splitNet;
      final effectiveDate = date ?? DateTime.now();

      if (directNet.abs() <= SplitSettlementCalculator.tolerance &&
          splitNet.abs() <= SplitSettlementCalculator.tolerance) {
        return const ContactSettlementResult();
      }

      final isFullSettlement =
          settleFull ||
          (net.abs() > SplitSettlementCalculator.tolerance &&
              (amount - net.abs()).abs() <=
                  SplitSettlementCalculator.tolerance);

      if (isFullSettlement ||
          net.abs() <= SplitSettlementCalculator.tolerance) {
        return _settleContactBalanceFullyInTransaction(
          txn,
          contactId: contactId,
          directNet: directNet,
          splitNet: splitNet,
          paymentDescription: paymentDescription,
          offsetDescription: offsetDescription,
          date: effectiveDate,
        );
      }

      if (amount <= SplitSettlementCalculator.tolerance ||
          amount - net.abs() > SplitSettlementCalculator.tolerance) {
        throw ArgumentError(
          'Settlement amount must be within the net balance.',
        );
      }

      return _settleContactBalancePartiallyInTransaction(
        txn,
        contactId: contactId,
        directNet: directNet,
        splitNet: splitNet,
        amount: amount,
        paymentDescription: paymentDescription,
        date: effectiveDate,
      );
    });
  }

  /* =======================
     READ OPERATIONS
  ======================== */

  // Get all transactions with pagination
  Future<List<TransactionModel>> getAllTransactions({
    int? limit,
    int? offset,
    TransactionSortOption sortOption =
        TransactionSortOption.transactionDateDesc,
  }) async {
    final args = <dynamic>[];
    _addHiddenSettlementArgs(args);
    final sql = StringBuffer('''
      SELECT t.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      WHERE $_visibleUserTransactionCondition
      ORDER BY ${sortOption.orderBy()}
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final maps = await _dbHelper.rawQuery(sql.toString(), args);
    return maps.map(TransactionModel.fromMap).toList();
  }

  // Get transactions by type with pagination
  Future<List<TransactionModel>> getTransactionsByType(
    String type, {
    int? limit,
    int? offset,
    TransactionSortOption sortOption =
        TransactionSortOption.transactionDateDesc,
  }) async {
    final args = <dynamic>[];
    _addHiddenSettlementArgs(args);
    args.add(type);
    final sql = StringBuffer('''
      SELECT t.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      WHERE $_visibleUserTransactionCondition AND t.type = ?
      ORDER BY ${sortOption.orderBy()}
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final maps = await _dbHelper.rawQuery(sql.toString(), args);
    return maps.map(TransactionModel.fromMap).toList();
  }

  // Get transactions by category (cash or udhari)
  Future<List<TransactionModel>> getTransactionsByCategory(
    String category, {
    int? limit,
    int? offset,
    TransactionSortOption sortOption =
        TransactionSortOption.transactionDateDesc,
  }) async {
    log('TransactionRepository: Fetching $category transactions');
    final args = <dynamic>[];
    _addHiddenSettlementArgs(args);
    args.add(category);
    final sql = StringBuffer('''
      SELECT t.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      WHERE $_visibleUserTransactionCondition AND t.transaction_category = ?
      ORDER BY ${sortOption.orderBy()}
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final maps = await _dbHelper.rawQuery(sql.toString(), args);
    return maps.map(TransactionModel.fromMap).toList();
  }

  // Get transactions by category (cash or udhari)
  Future<List<TransactionModel>> getTransactionsByCategoryAndType(
    String category,
    String type, {
    int? limit,
    int? offset,
    TransactionSortOption sortOption =
        TransactionSortOption.transactionDateDesc,
  }) async {
    log('TransactionRepository: Fetching $category transactions');
    final args = <dynamic>[];
    _addHiddenSettlementArgs(args);
    args.addAll([category, type]);
    final sql = StringBuffer('''
      SELECT t.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      WHERE $_visibleUserTransactionCondition
        AND t.transaction_category = ?
        AND t.type = ?
      ORDER BY ${sortOption.orderBy()}
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final maps = await _dbHelper.rawQuery(sql.toString(), args);
    return maps.map(TransactionModel.fromMap).toList();
  }

  // Get transactions by contact with pagination
  Future<List<TransactionModel>> getTransactionsByContact(
    int contactId, {
    int? limit,
    int? offset,
    String? category, // Optional category filter
    TransactionSortOption sortOption =
        TransactionSortOption.transactionDateDesc,
  }) async {
    final whereConditions = ['t.contact_id = ?'];
    final whereArgs = <dynamic>[contactId];

    if (category != null) {
      whereConditions.add('t.transaction_category = ?');
      whereArgs.add(category);
    }

    final sql = StringBuffer('''
      SELECT t.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      WHERE ${whereConditions.join(' AND ')}
      ORDER BY ${sortOption.orderBy()}
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final maps = await _dbHelper.rawQuery(sql.toString(), whereArgs);
    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> getContactActivity(
    int contactId, {
    int? limit,
    int? offset,
    String? category,
    TransactionSortOption sortOption =
        TransactionSortOption.transactionDateDesc,
  }) async {
    final args = <dynamic>[];
    final sql = _buildContactActivitySql(
      contactId: contactId,
      category: category,
      args: args,
    );

    final pagedSql = StringBuffer('''
      SELECT *
      FROM ($sql) activity
      ORDER BY ${sortOption.orderBy(alias: '')}
    ''');

    if (limit != null) {
      pagedSql.write(' LIMIT ?');
      args.add(limit);
      if (offset != null) {
        pagedSql.write(' OFFSET ?');
        args.add(offset);
      }
    }

    final maps = await _dbHelper.rawQuery(pagedSql.toString(), args);
    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<List<ContactActivityItem>> getContactActivityItems(
    int contactId, {
    int? limit,
    int? offset,
    String? category,
    TransactionSortOption sortOption =
        TransactionSortOption.transactionDateDesc,
  }) async {
    final transactions = await getContactActivity(
      contactId,
      category: category,
      sortOption: sortOption,
    );
    final items = transactions
        .map(ContactActivityItem.transaction)
        .toList(growable: true);

    if (category == null) {
      final settlements = await _getContactSettlements(contactId);
      items.addAll(settlements.map(ContactActivityItem.settlement));
    }

    _sortContactActivityItems(items, sortOption);
    final start = offset ?? 0;
    if (start >= items.length) return const [];
    final end = limit == null
        ? items.length
        : math.min(items.length, start + limit);
    return items.sublist(start, end);
  }

  Future<List<TransactionModel>> getContactActivityByDateRange(
    int contactId,
    DateTime start,
    DateTime end, {
    String? category,
    int? limit,
    int? offset,
    TransactionSortOption sortOption =
        TransactionSortOption.transactionDateDesc,
  }) async {
    final args = <dynamic>[];
    final sql = _buildContactActivitySql(
      contactId: contactId,
      category: category,
      args: args,
    );

    final rangeSql = StringBuffer('''
      SELECT *
      FROM ($sql) activity
      WHERE date BETWEEN ? AND ?
      ORDER BY ${sortOption.orderBy(alias: '')}
    ''');
    args.add(start.toIso8601String());
    args.add(end.toIso8601String());

    if (limit != null) {
      rangeSql.write(' LIMIT ?');
      args.add(limit);
      if (offset != null) {
        rangeSql.write(' OFFSET ?');
        args.add(offset);
      }
    }

    final maps = await _dbHelper.rawQuery(rangeSql.toString(), args);
    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<List<ContactActivityItem>> getContactActivityItemsByDateRange(
    int contactId,
    DateTime start,
    DateTime end, {
    String? category,
    int? limit,
    int? offset,
    TransactionSortOption sortOption =
        TransactionSortOption.transactionDateDesc,
  }) async {
    final transactions = await getContactActivityByDateRange(
      contactId,
      start,
      end,
      category: category,
      sortOption: sortOption,
    );
    final items = transactions
        .map(ContactActivityItem.transaction)
        .toList(growable: true);

    if (category == null) {
      final settlements = await _getContactSettlements(
        contactId,
        start: start,
        end: end,
      );
      items.addAll(settlements.map(ContactActivityItem.settlement));
    }

    _sortContactActivityItems(items, sortOption);
    final startIndex = offset ?? 0;
    if (startIndex >= items.length) return const [];
    final endIndex = limit == null
        ? items.length
        : math.min(items.length, startIndex + limit);
    return items.sublist(startIndex, endIndex);
  }

  Future<int> getContactActivityCount(int contactId, {String? category}) async {
    final args = <dynamic>[];
    final sql = _buildContactActivitySql(
      contactId: contactId,
      category: category,
      args: args,
    );
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) AS count FROM ($sql) activity',
      args,
    );
    final transactionCount = (result.first['count'] as int?) ?? 0;
    if (category != null) return transactionCount;

    final settlementCount = await _dbHelper.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM contact_settlements
      WHERE contact_id = ?
      ''',
      [contactId],
    );
    return transactionCount + ((settlementCount.first['count'] as int?) ?? 0);
  }

  Future<List<ContactSettlementModel>> _getContactSettlements(
    int contactId, {
    DateTime? start,
    DateTime? end,
  }) async {
    final where = <String>['cs.contact_id = ?'];
    final args = <dynamic>[contactId];
    if (start != null && end != null) {
      where.add('cs.date BETWEEN ? AND ?');
      args.add(start.toIso8601String());
      args.add(end.toIso8601String());
    }

    final rows = await _dbHelper.rawQuery('''
      SELECT cs.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM contact_settlements cs
      LEFT JOIN contacts c ON c.id = cs.contact_id
      WHERE ${where.join(' AND ')}
      ''', args);
    return rows.map(ContactSettlementModel.fromMap).toList();
  }

  Future<List<ContactSettlementModel>> _getLedgerSettlements({
    String? type,
    String? searchQuery,
    DateTime? start,
    DateTime? end,
  }) async {
    final where = <String>[];
    final args = <dynamic>[];

    if (type == AppConstants.typeBorrow) {
      where.add('cs.direction = ?');
      args.add(AppConstants.typeLend);
    } else if (type == AppConstants.typeLend) {
      where.add('cs.direction = ?');
      args.add(AppConstants.typeBorrow);
    }

    if (start != null && end != null) {
      where.add('cs.date BETWEEN ? AND ?');
      args.addAll([start.toIso8601String(), end.toIso8601String()]);
    }

    final search = searchQuery?.trim();
    if (search != null && search.isNotEmpty) {
      final searchTerm = '%$search%';
      where.add(
        '(LOWER(c.name) LIKE LOWER(?) OR LOWER(?) LIKE LOWER(?) OR LOWER(cs.note) LIKE LOWER(?))',
      );
      args.addAll([searchTerm, 'settlement', searchTerm, searchTerm]);
    }

    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await _dbHelper.rawQuery('''
      SELECT cs.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM contact_settlements cs
      LEFT JOIN contacts c ON c.id = cs.contact_id
      $whereSql
      ''', args);
    return rows.map(ContactSettlementModel.fromMap).toList();
  }

  void _sortContactActivityItems(
    List<ContactActivityItem> items,
    TransactionSortOption sortOption,
  ) {
    int compareDate(DateTime a, DateTime b) => a.compareTo(b);
    int compareId(ContactActivityItem a, ContactActivityItem b) {
      final aId = a.transaction?.id ?? a.settlement?.id ?? 0;
      final bId = b.transaction?.id ?? b.settlement?.id ?? 0;
      return aId.compareTo(bId);
    }

    items.sort((a, b) {
      final result = switch (sortOption) {
        TransactionSortOption.transactionDateDesc => -compareDate(
          a.date,
          b.date,
        ),
        TransactionSortOption.transactionDateAsc => compareDate(a.date, b.date),
        TransactionSortOption.createdDateDesc => -compareDate(
          a.createdAt,
          b.createdAt,
        ),
        TransactionSortOption.createdDateAsc => compareDate(
          a.createdAt,
          b.createdAt,
        ),
      };
      if (result != 0) return result;

      final createdResult = switch (sortOption) {
        TransactionSortOption.transactionDateDesc => -compareDate(
          a.createdAt,
          b.createdAt,
        ),
        TransactionSortOption.transactionDateAsc => compareDate(
          a.createdAt,
          b.createdAt,
        ),
        TransactionSortOption.createdDateDesc => 0,
        TransactionSortOption.createdDateAsc => 0,
      };
      if (createdResult != 0) return createdResult;

      final idResult = compareId(a, b);
      return switch (sortOption) {
        TransactionSortOption.transactionDateDesc ||
        TransactionSortOption.createdDateDesc => -idResult,
        TransactionSortOption.transactionDateAsc ||
        TransactionSortOption.createdDateAsc => idResult,
      };
    });
  }

  Future<List<TransactionModel>> getLedgerActivity({
    String? category,
    String? type,
    String? searchQuery,
    int? limit,
    int? offset,
    TransactionSortOption sortOption =
        TransactionSortOption.transactionDateDesc,
  }) async {
    final args = <dynamic>[];
    final sql = _buildLedgerActivitySql(
      category: category,
      type: type,
      searchQuery: searchQuery,
      args: args,
    );

    final pagedSql = StringBuffer('''
      SELECT *
      FROM ($sql) activity
      ORDER BY ${sortOption.orderBy(alias: '')}
    ''');

    if (limit != null) {
      pagedSql.write(' LIMIT ?');
      args.add(limit);
      if (offset != null) {
        pagedSql.write(' OFFSET ?');
        args.add(offset);
      }
    }

    final maps = await _dbHelper.rawQuery(pagedSql.toString(), args);
    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<List<ContactActivityItem>> getLedgerActivityItems({
    String? category,
    String? type,
    String? searchQuery,
    int? limit,
    int? offset,
    TransactionSortOption sortOption =
        TransactionSortOption.transactionDateDesc,
  }) async {
    final transactions = await getLedgerActivity(
      category: category,
      type: type,
      searchQuery: searchQuery,
      sortOption: sortOption,
    );
    final items = transactions
        .map(ContactActivityItem.transaction)
        .toList(growable: true);

    if (category == null || category == 'cash_udhari') {
      final settlements = await _getLedgerSettlements(
        type: type,
        searchQuery: searchQuery,
      );
      items.addAll(settlements.map(ContactActivityItem.settlement));
    }

    _sortContactActivityItems(items, sortOption);
    final start = offset ?? 0;
    if (start >= items.length) return const [];
    final end = limit == null
        ? items.length
        : math.min(items.length, start + limit);
    return items.sublist(start, end);
  }

  Future<List<TransactionModel>> getLedgerActivityByDateRange(
    DateTime start,
    DateTime end, {
    String? category,
    String? type,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    final args = <dynamic>[];
    final sql = _buildLedgerActivitySql(
      category: category,
      type: type,
      searchQuery: searchQuery,
      args: args,
    );

    final rangeSql = StringBuffer('''
      SELECT *
      FROM ($sql) activity
      WHERE date BETWEEN ? AND ?
      ORDER BY datetime(date) DESC, datetime(COALESCE(updated_at, created_at, date)) DESC, id DESC
    ''');
    args.add(start.toIso8601String());
    args.add(end.toIso8601String());

    if (limit != null) {
      rangeSql.write(' LIMIT ?');
      args.add(limit);
      if (offset != null) {
        rangeSql.write(' OFFSET ?');
        args.add(offset);
      }
    }

    final maps = await _dbHelper.rawQuery(rangeSql.toString(), args);
    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<List<ContactActivityItem>> getLedgerActivityItemsByDateRange(
    DateTime start,
    DateTime end, {
    String? category,
    String? type,
    String? searchQuery,
    int? limit,
    int? offset,
    TransactionSortOption sortOption =
        TransactionSortOption.transactionDateDesc,
  }) async {
    final transactions = await getLedgerActivityByDateRange(
      start,
      end,
      category: category,
      type: type,
      searchQuery: searchQuery,
    );
    final items = transactions
        .map(ContactActivityItem.transaction)
        .toList(growable: true);

    if (category == null || category == 'cash_udhari') {
      final settlements = await _getLedgerSettlements(
        type: type,
        searchQuery: searchQuery,
        start: start,
        end: end,
      );
      items.addAll(settlements.map(ContactActivityItem.settlement));
    }

    _sortContactActivityItems(items, sortOption);
    final startIndex = offset ?? 0;
    if (startIndex >= items.length) return const [];
    final endIndex = limit == null
        ? items.length
        : math.min(items.length, startIndex + limit);
    return items.sublist(startIndex, endIndex);
  }

  Future<int> getLedgerActivityCount({
    String? category,
    String? type,
    String? searchQuery,
  }) async {
    final args = <dynamic>[];
    final sql = _buildLedgerActivitySql(
      category: category,
      type: type,
      searchQuery: searchQuery,
      args: args,
    );
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) AS count FROM ($sql) activity',
      args,
    );
    final transactionCount = (result.first['count'] as int?) ?? 0;
    if (category != null && category != 'cash_udhari') {
      return transactionCount;
    }

    final settlements = await _getLedgerSettlements(
      type: type,
      searchQuery: searchQuery,
    );
    return transactionCount + settlements.length;
  }

  Future<int> getLedgerActivityItemCount({
    String? category,
    String? type,
    String? searchQuery,
  }) {
    return getLedgerActivityCount(
      category: category,
      type: type,
      searchQuery: searchQuery,
    );
  }

  Future<double> getLedgerOpeningBalanceBefore(
    DateTime before, {
    String? category,
    String? type,
    String? searchQuery,
  }) async {
    final normalizedCategory = category == 'cash_udhari' ? null : category;
    final search = searchQuery?.trim();
    final whereConditions = <String>['t.date < ?'];
    final args = <dynamic>[before.toIso8601String()];

    if (normalizedCategory != null) {
      whereConditions.add('t.transaction_category = ?');
      args.add(normalizedCategory);
    }

    if (type != null) {
      whereConditions.add('t.type = ?');
      args.add(type);
    }

    if (search != null && search.isNotEmpty) {
      final searchTerm = '%$search%';
      whereConditions.add(
        '(LOWER(t.description) LIKE LOWER(?) OR LOWER(c.name) LIKE LOWER(?) OR LOWER(t.item_name) LIKE LOWER(?) OR LOWER(t.transaction_category) LIKE LOWER(?))',
      );
      args.addAll([searchTerm, searchTerm, searchTerm, searchTerm]);
    }

    final result = await _dbHelper.rawQuery(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN t.type = ? THEN t.amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN t.type = ? THEN t.amount ELSE 0 END), 0) AS opening_balance
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      WHERE ${whereConditions.join(' AND ')}
      ''',
      [AppConstants.typeLend, AppConstants.typeBorrow, ...args],
    );

    return (result.first['opening_balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getContactOpeningBalanceBefore(
    int contactId,
    DateTime before, {
    String? category,
  }) async {
    final whereConditions = <String>['contact_id = ?', 'date < ?'];
    final args = <dynamic>[contactId, before.toIso8601String()];

    if (category != null) {
      whereConditions.add('transaction_category = ?');
      args.add(category);
    }

    final result = await _dbHelper.rawQuery(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = ? THEN amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN type = ? THEN amount ELSE 0 END), 0) AS opening_balance
      FROM transactions
      WHERE ${whereConditions.join(' AND ')}
      ''',
      [AppConstants.typeLend, AppConstants.typeBorrow, ...args],
    );

    return (result.first['opening_balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, dynamic>> getContactActivityStats(int contactId) async {
    final result = await _dbHelper.rawQuery(
      '''
      WITH direct AS (
        SELECT
          COUNT(id) AS total_transactions,
          COALESCE(SUM(CASE WHEN type = ? THEN amount ELSE 0 END), 0) AS total_lent,
          COALESCE(SUM(CASE WHEN type = ? THEN amount ELSE 0 END), 0) AS total_borrowed,
          COUNT(CASE WHEN transaction_category = ? THEN 1 END) AS cash_count,
          COUNT(CASE WHEN transaction_category = ? THEN 1 END) AS udhari_count,
          COUNT(CASE WHEN transaction_category = ? THEN 1 END) AS shared_spend_count,
          COUNT(CASE WHEN transaction_category = ? THEN 1 END) AS split_transaction_count,
          COALESCE(SUM(CASE WHEN transaction_category = ? AND type = ? THEN amount ELSE 0 END), 0) AS split_lent,
          COALESCE(SUM(CASE WHEN transaction_category = ? AND type = ? THEN amount ELSE 0 END), 0) AS split_borrowed
        FROM transactions
        WHERE contact_id = ?
      ),
      split_history AS (
        SELECT COUNT(se.id) AS split_history_count
        FROM split_expenses se
        INNER JOIN split_participants sp ON se.id = sp.split_id
        WHERE sp.contact_id = ?
          AND NOT EXISTS (
            SELECT 1
            FROM transactions t
            WHERE t.contact_id = sp.contact_id
              AND t.transaction_category = ?
              AND t.source_type = ?
              AND t.source_id = se.id
          )
      )
      SELECT
        COALESCE(direct.total_transactions, 0) + COALESCE(split_history.split_history_count, 0) AS total_transactions,
        COALESCE(direct.total_lent, 0) AS total_lent,
        COALESCE(direct.total_borrowed, 0) AS total_borrowed,
        COALESCE(direct.cash_count, 0) AS cash_count,
        COALESCE(direct.udhari_count, 0) AS udhari_count,
        COALESCE(direct.shared_spend_count, 0) AS shared_spend_count,
        COALESCE(direct.split_transaction_count, 0) + COALESCE(split_history.split_history_count, 0) AS split_count,
        COALESCE(direct.split_lent, 0) AS split_lent,
        COALESCE(direct.split_borrowed, 0) AS split_borrowed
      FROM direct, split_history
      ''',
      [
        AppConstants.typeLend,
        AppConstants.typeBorrow,
        AppConstants.categoryCash,
        AppConstants.categoryUdhari,
        AppConstants.categorySharedSpend,
        AppConstants.categorySplit,
        AppConstants.categorySplit,
        AppConstants.typeLend,
        AppConstants.categorySplit,
        AppConstants.typeBorrow,
        contactId,
        contactId,
        AppConstants.categorySplit,
        AppConstants.sourceTypeSplit,
      ],
    );

    final row = result.first;
    final hiddenSettlementResult = await _dbHelper.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM transactions
      WHERE contact_id = ?
        AND source_type IN (?, ?, ?, ?)
      ''',
      [
        contactId,
        AppConstants.sourceTypeContactSettlement,
        AppConstants.sourceTypeContactSettlementOffset,
        AppConstants.sourceTypeContactSettlementLegacy,
        AppConstants.sourceTypeContactSettlementOffsetLegacy,
      ],
    );
    final settlementEventResult = await _dbHelper.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM contact_settlements
      WHERE contact_id = ?
      ''',
      [contactId],
    );
    final hiddenSettlementCount =
        (hiddenSettlementResult.first['count'] as int?) ?? 0;
    final settlementEventCount =
        (settlementEventResult.first['count'] as int?) ?? 0;
    final totalLent = (row['total_lent'] as num?)?.toDouble() ?? 0.0;
    final totalBorrowed = (row['total_borrowed'] as num?)?.toDouble() ?? 0.0;
    final splitLent = (row['split_lent'] as num?)?.toDouble() ?? 0.0;
    final splitBorrowed = (row['split_borrowed'] as num?)?.toDouble() ?? 0.0;

    return {
      'total_transactions':
          ((row['total_transactions'] as int?) ?? 0) -
          hiddenSettlementCount +
          settlementEventCount,
      'total_lent': totalLent,
      'total_borrowed': totalBorrowed,
      'net_balance': totalLent - totalBorrowed,
      'normal_net_balance':
          (totalLent - splitLent) - (totalBorrowed - splitBorrowed),
      'split_net_balance': splitLent - splitBorrowed,
      'cash_count': math.max(
        0,
        ((row['cash_count'] as int?) ?? 0) - hiddenSettlementCount,
      ),
      'udhari_count': (row['udhari_count'] as int?) ?? 0,
      'shared_spend_count': (row['shared_spend_count'] as int?) ?? 0,
      'split_count': (row['split_count'] as int?) ?? 0,
      'split_lent': splitLent,
      'split_borrowed': splitBorrowed,
    };
  }

  String _buildContactActivitySql({
    required int contactId,
    required String? category,
    required List<dynamic> args,
  }) {
    final includeSplitHistory =
        category == null || category == AppConstants.categorySplit;
    final directConditions = <String>[
      't.contact_id = ?',
      '''
      (
        t.source_type IS NULL OR t.source_type NOT IN (?, ?, ?, ?)
      )
      ''',
    ];
    args.addAll([
      contactId,
      AppConstants.sourceTypeContactSettlement,
      AppConstants.sourceTypeContactSettlementOffset,
      AppConstants.sourceTypeContactSettlementLegacy,
      AppConstants.sourceTypeContactSettlementOffsetLegacy,
    ]);

    if (category != null) {
      directConditions.add('t.transaction_category = ?');
      args.add(category);
    }

    final directSql =
        '''
      SELECT
        t.id AS id,
        t.type AS type,
        t.transaction_category AS transaction_category,
        t.contact_id AS contact_id,
        t.amount AS amount,
        t.description AS description,
        t.date AS date,
        t.created_at AS created_at,
        t.updated_at AS updated_at,
        t.item_name AS item_name,
        t.quantity AS quantity,
        t.expected_date AS expected_date,
        t.paid_amount AS paid_amount,
        t.is_settlement AS is_settlement,
        t.source_type AS source_type,
        t.source_id AS source_id,
        t.shared_total_amount AS shared_total_amount,
        t.shared_user_share AS shared_user_share,
        t.shared_contact_share AS shared_contact_share,
        t.shared_paid_by_user AS shared_paid_by_user,
        c.name AS contact_name,
        c.phone AS contact_phone,
        c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      WHERE ${directConditions.join(' AND ')}
    ''';

    if (!includeSplitHistory) return directSql;

    args.add(AppConstants.typeLend);
    args.add(AppConstants.typeBorrow);
    args.add(AppConstants.categorySplit);
    args.add(_splitHistoryDescriptionPrefix);
    args.add(AppConstants.sourceTypeSplit);
    args.add(contactId);
    args.add(AppConstants.categorySplit);
    args.add(AppConstants.sourceTypeSplit);

    final splitHistorySql = '''
      SELECT
        -se.id AS id,
        CASE
          WHEN (sp.share_amount - sp.expense_paid) >= 0 THEN ?
          ELSE ?
        END AS type,
        ? AS transaction_category,
        sp.contact_id AS contact_id,
        CASE
          WHEN ABS(sp.share_amount - sp.expense_paid) >= 0.01 THEN ABS(sp.share_amount - sp.expense_paid)
          ELSE sp.share_amount
        END AS amount,
        ? || se.title AS description,
        se.date AS date,
        se.created_at AS created_at,
        se.updated_at AS updated_at,
        NULL AS item_name,
        NULL AS quantity,
        NULL AS expected_date,
        NULL AS paid_amount,
        1 AS is_settlement,
        ? AS source_type,
        se.id AS source_id,
        NULL AS shared_total_amount,
        NULL AS shared_user_share,
        NULL AS shared_contact_share,
        NULL AS shared_paid_by_user,
        c.name AS contact_name,
        c.phone AS contact_phone,
        c.avatar AS contact_avatar
      FROM split_expenses se
      INNER JOIN split_participants sp ON se.id = sp.split_id
      LEFT JOIN contacts c ON sp.contact_id = c.id
      WHERE sp.contact_id = ?
        AND NOT EXISTS (
          SELECT 1
          FROM transactions t
          WHERE t.contact_id = sp.contact_id
            AND t.transaction_category = ?
            AND t.source_type = ?
            AND t.source_id = se.id
        )
    ''';

    return '$directSql UNION ALL $splitHistorySql';
  }

  String _buildLedgerActivitySql({
    required String? category,
    required String? type,
    required String? searchQuery,
    required List<dynamic> args,
  }) {
    final normalizedCategory = category == 'cash_udhari' ? null : category;
    final includeSplitHistory =
        normalizedCategory == null ||
        normalizedCategory == AppConstants.categorySplit;
    final search = searchQuery?.trim();
    final directConditions = <String>[_visibleUserTransactionCondition];
    _addHiddenSettlementArgs(args);

    if (normalizedCategory != null) {
      directConditions.add('t.transaction_category = ?');
      args.add(normalizedCategory);
    }

    if (type != null) {
      directConditions.add('t.type = ?');
      args.add(type);
    }

    if (search != null && search.isNotEmpty) {
      final searchTerm = '%$search%';
      directConditions.add(
        '(LOWER(t.description) LIKE LOWER(?) OR LOWER(c.name) LIKE LOWER(?) OR LOWER(t.item_name) LIKE LOWER(?) OR LOWER(t.transaction_category) LIKE LOWER(?))',
      );
      args.addAll([searchTerm, searchTerm, searchTerm, searchTerm]);
    }

    final directWhere = directConditions.isEmpty
        ? ''
        : 'WHERE ${directConditions.join(' AND ')}';
    final directSql =
        '''
      SELECT
        t.id AS id,
        t.type AS type,
        t.transaction_category AS transaction_category,
        t.contact_id AS contact_id,
        t.amount AS amount,
        t.description AS description,
        t.date AS date,
        t.created_at AS created_at,
        t.updated_at AS updated_at,
        t.item_name AS item_name,
        t.quantity AS quantity,
        t.expected_date AS expected_date,
        t.paid_amount AS paid_amount,
        t.is_settlement AS is_settlement,
        t.source_type AS source_type,
        t.source_id AS source_id,
        t.shared_total_amount AS shared_total_amount,
        t.shared_user_share AS shared_user_share,
        t.shared_contact_share AS shared_contact_share,
        t.shared_paid_by_user AS shared_paid_by_user,
        c.name AS contact_name,
        c.phone AS contact_phone,
        c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      $directWhere
    ''';

    if (!includeSplitHistory) return directSql;

    args.add(AppConstants.typeLend);
    args.add(AppConstants.typeBorrow);
    args.add(AppConstants.categorySplit);
    args.add(_splitHistoryDescriptionPrefix);
    args.add(AppConstants.sourceTypeSplit);

    final splitConditions = <String>[
      '''
      NOT EXISTS (
        SELECT 1
        FROM transactions t
        WHERE t.transaction_category = ?
          AND t.source_type = ?
          AND t.source_id = se.id
      )
      ''',
    ];
    args.add(AppConstants.categorySplit);
    args.add(AppConstants.sourceTypeSplit);

    if (type == AppConstants.typeLend) {
      splitConditions.add('(sp.share_amount - sp.expense_paid) >= 0');
    } else if (type == AppConstants.typeBorrow) {
      splitConditions.add('(sp.share_amount - sp.expense_paid) < 0');
    }

    if (search != null && search.isNotEmpty) {
      final searchTerm = '%$search%';
      splitConditions.add(
        '(LOWER(se.title) LIKE LOWER(?) OR LOWER(c.name) LIKE LOWER(?) OR LOWER(?) LIKE LOWER(?))',
      );
      args.addAll([
        searchTerm,
        searchTerm,
        AppConstants.categorySplit,
        searchTerm,
      ]);
    }

    final splitHistorySql =
        '''
      SELECT
        (-(se.id * 1000000 + sp.id)) AS id,
        CASE
          WHEN (sp.share_amount - sp.expense_paid) >= 0 THEN ?
          ELSE ?
        END AS type,
        ? AS transaction_category,
        sp.contact_id AS contact_id,
        CASE
          WHEN ABS(sp.share_amount - sp.expense_paid) >= 0.01 THEN ABS(sp.share_amount - sp.expense_paid)
          ELSE sp.share_amount
        END AS amount,
        ? || se.title AS description,
        se.date AS date,
        se.created_at AS created_at,
        se.updated_at AS updated_at,
        NULL AS item_name,
        NULL AS quantity,
        NULL AS expected_date,
        NULL AS paid_amount,
        1 AS is_settlement,
        ? AS source_type,
        se.id AS source_id,
        NULL AS shared_total_amount,
        NULL AS shared_user_share,
        NULL AS shared_contact_share,
        NULL AS shared_paid_by_user,
        c.name AS contact_name,
        c.phone AS contact_phone,
        c.avatar AS contact_avatar
      FROM split_expenses se
      INNER JOIN split_participants sp ON se.id = sp.split_id
      LEFT JOIN contacts c ON sp.contact_id = c.id
      WHERE ${splitConditions.join(' AND ')}
    ''';

    return '$directSql UNION ALL $splitHistorySql';
  }

  // Search transactions (uses description + contact name + item name indexes)
  Future<List<TransactionModel>> searchTransactions(
    String query, {
    String? category,
    String? type,
    int? limit,
    int? offset,
    TransactionSortOption sortOption =
        TransactionSortOption.transactionDateDesc,
  }) async {
    if (query.trim().isEmpty) return [];
    final whereConditions = <String>[_visibleUserTransactionCondition];
    final whereArgs = <dynamic>[];
    _addHiddenSettlementArgs(whereArgs);
    final searchTerm = '%${query.trim()}%';

    whereConditions.add(
      '(LOWER(t.description) LIKE LOWER(?) OR LOWER(c.name) LIKE LOWER(?) OR LOWER(t.item_name) LIKE LOWER(?))',
    );
    whereArgs.addAll([searchTerm, searchTerm, searchTerm]);

    if (category != null) {
      whereConditions.add('t.transaction_category = ?');
      whereArgs.add(category);
    }
    if (type != null) {
      whereConditions.add('t.type = ?');
      whereArgs.add(type);
    }

    final where = whereConditions.isEmpty ? '' : whereConditions.join(' AND ');

    final sql = StringBuffer('''
      SELECT t.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      WHERE $where
      ORDER BY ${sortOption.orderBy()}
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final maps = await _dbHelper.rawQuery(sql.toString(), whereArgs);

    return maps.map(TransactionModel.fromMap).toList();
  }

  // Get transaction by ID
  Future<TransactionModel?> getTransactionById(int id) async {
    final maps = await _dbHelper.rawQuery(
      '''
      SELECT t.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      WHERE t.id = ?
      LIMIT 1
      ''',
      [id],
    );

    return maps.isEmpty ? null : TransactionModel.fromMap(maps.first);
  }

  // Get transactions by date range with pagination
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end, {
    int? limit,
    int? offset,
  }) async {
    final sql = StringBuffer('''
      SELECT t.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      WHERE t.date BETWEEN ? AND ?
      ORDER BY t.date DESC, t.id DESC
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final maps = await _dbHelper.rawQuery(sql.toString(), [
      start.toIso8601String(),
      end.toIso8601String(),
    ]);

    return maps.map(TransactionModel.fromMap).toList();
  }

  /* =======================
     DASHBOARD & STATISTICS
  ======================== */

  // Dashboard summary (overall totals)
  Future<Map<String, double>> getDashboardSummary() async {
    log('TransactionRepository: Fetching dashboard summary');

    // First, get the existing overall stats
    final result = await _dbHelper.rawQuery('''
    SELECT 
      COALESCE(SUM(CASE WHEN type = 'lend' THEN amount ELSE 0 END), 0) AS total_lent,
      COALESCE(SUM(CASE WHEN type = 'borrow' THEN amount ELSE 0 END), 0) AS total_borrowed,
      
      -- Cash breakdown
      COALESCE(SUM(CASE WHEN type = 'lend' AND transaction_category = 'cash' THEN amount ELSE 0 END), 0) AS cash_lent,
      COALESCE(SUM(CASE WHEN type = 'borrow' AND transaction_category = 'cash' THEN amount ELSE 0 END), 0) AS cash_borrowed,
      
      -- Udhari breakdown
      COALESCE(SUM(CASE WHEN type = 'lend' AND transaction_category = 'udhari' THEN amount ELSE 0 END), 0) AS udhari_given,
      COALESCE(SUM(CASE WHEN type = 'borrow' AND transaction_category = 'udhari' THEN amount ELSE 0 END), 0) AS udhari_taken
    FROM transactions
  ''');

    // Second, calculate per-contact net balances and sum them up
    final balanceResult = await _dbHelper.rawQuery('''
    SELECT 
      COALESCE(SUM(CASE WHEN net_balance > 0 THEN net_balance ELSE 0 END), 0) AS total_receivable,
      COALESCE(SUM(CASE WHEN net_balance < 0 THEN ABS(net_balance) ELSE 0 END), 0) AS total_payable
    FROM (
      SELECT 
        contact_id,
        (SUM(CASE WHEN type = 'lend' THEN amount ELSE 0 END) - 
         SUM(CASE WHEN type = 'borrow' THEN amount ELSE 0 END)) AS net_balance
      FROM transactions
      GROUP BY contact_id
    )
  ''');

    final totalLent = (result.first['total_lent'] as num?)?.toDouble() ?? 0.0;
    final totalBorrowed =
        (result.first['total_borrowed'] as num?)?.toDouble() ?? 0.0;
    final cashLent = (result.first['cash_lent'] as num?)?.toDouble() ?? 0.0;
    final cashBorrowed =
        (result.first['cash_borrowed'] as num?)?.toDouble() ?? 0.0;
    final udhariGiven =
        (result.first['udhari_given'] as num?)?.toDouble() ?? 0.0;
    final udhariTaken =
        (result.first['udhari_taken'] as num?)?.toDouble() ?? 0.0;
    final totalReceivable =
        (balanceResult.first['total_receivable'] as num?)?.toDouble() ?? 0.0;
    final totalPayable =
        (balanceResult.first['total_payable'] as num?)?.toDouble() ?? 0.0;

    log(
      'TransactionRepository: Summary - Total Lent: ₹$totalLent, Total Borrowed: ₹$totalBorrowed, Receivable: ₹$totalReceivable, Payable: ₹$totalPayable',
    );

    return {
      'total_lent': totalLent,
      'total_borrowed': totalBorrowed,
      'net_balance': totalLent - totalBorrowed,
      'cash_lent': cashLent,
      'cash_borrowed': cashBorrowed,
      'cash_net': cashLent - cashBorrowed,
      'udhari_given': udhariGiven,
      'udhari_taken': udhariTaken,
      'udhari_net': udhariGiven - udhariTaken,
      'total_receivable': totalReceivable,
      'total_payable': totalPayable,
    };
  }

  /// Get contact-wise summary with search and balance filter support (IMPROVED)
  Future<List<Map<String, dynamic>>> getContactWiseSummary({
    int? limit,
    int? offset,
    String? searchQuery,
    String? balanceFilter, // 'all', 'settled', 'pending'
  }) async {
    log('TransactionRepository: Fetching contact-wise summary with filters');

    final sql = StringBuffer('''
      WITH transaction_summary AS (
        SELECT
          contact_id,
          COUNT(id) AS total_transactions,
          COALESCE(SUM(CASE WHEN type = 'lend' THEN amount ELSE 0 END), 0) AS total_lent,
          COALESCE(SUM(CASE WHEN type = 'borrow' THEN amount ELSE 0 END), 0) AS total_borrowed,
          COUNT(CASE WHEN transaction_category = 'cash' THEN 1 END) AS cash_count,
          COALESCE(SUM(CASE WHEN transaction_category = 'cash' AND type = 'lend' THEN amount ELSE 0 END), 0) AS cash_lent,
          COALESCE(SUM(CASE WHEN transaction_category = 'cash' AND type = 'borrow' THEN amount ELSE 0 END), 0) AS cash_borrowed,
          COUNT(CASE WHEN transaction_category = 'udhari' THEN 1 END) AS udhari_count,
          COALESCE(SUM(CASE WHEN transaction_category = 'udhari' AND type = 'lend' THEN amount ELSE 0 END), 0) AS udhari_given,
          COALESCE(SUM(CASE WHEN transaction_category = 'udhari' AND type = 'borrow' THEN amount ELSE 0 END), 0) AS udhari_taken,
          COUNT(CASE WHEN transaction_category = 'shared_spend' THEN 1 END) AS shared_spend_count,
          COUNT(CASE WHEN transaction_category = 'split' THEN 1 END) AS split_transaction_count,
          COALESCE(SUM(CASE WHEN transaction_category = 'split' AND type = 'lend' THEN amount ELSE 0 END), 0) AS split_lent,
          COALESCE(SUM(CASE WHEN transaction_category = 'split' AND type = 'borrow' THEN amount ELSE 0 END), 0) AS split_borrowed,
          MAX(COALESCE(updated_at, created_at, date)) AS last_transaction_date
        FROM transactions
        GROUP BY contact_id
      ),
      split_history AS (
        SELECT
          sp.contact_id,
          COUNT(sp.id) AS split_history_count,
          MAX(COALESCE(se.updated_at, se.created_at, se.date)) AS last_split_date
        FROM split_participants sp
        INNER JOIN split_expenses se ON se.id = sp.split_id
        GROUP BY sp.contact_id
      )
      SELECT
        c.id AS contact_id,
        c.name AS contact_name,
        c.phone AS contact_phone,
        c.avatar AS contact_avatar,
        COALESCE(ts.total_transactions, 0) + COALESCE(sh.split_history_count, 0) AS total_transactions,
        COALESCE(ts.total_lent, 0) AS total_lent,
        COALESCE(ts.total_borrowed, 0) AS total_borrowed,
        COALESCE(ts.cash_count, 0) AS cash_count,
        COALESCE(ts.cash_lent, 0) AS cash_lent,
        COALESCE(ts.cash_borrowed, 0) AS cash_borrowed,
        COALESCE(ts.udhari_count, 0) AS udhari_count,
        COALESCE(ts.udhari_given, 0) AS udhari_given,
        COALESCE(ts.udhari_taken, 0) AS udhari_taken,
        COALESCE(ts.shared_spend_count, 0) AS shared_spend_count,
        COALESCE(ts.split_transaction_count, 0) + COALESCE(sh.split_history_count, 0) AS split_count,
        COALESCE(ts.split_lent, 0) AS split_lent,
        COALESCE(ts.split_borrowed, 0) AS split_borrowed,
        CASE
          WHEN ts.last_transaction_date IS NULL THEN sh.last_split_date
          WHEN sh.last_split_date IS NULL THEN ts.last_transaction_date
          WHEN ts.last_transaction_date >= sh.last_split_date THEN ts.last_transaction_date
          ELSE sh.last_split_date
        END AS last_transaction_date
      FROM contacts c
      LEFT JOIN transaction_summary ts ON ts.contact_id = c.id
      LEFT JOIN split_history sh ON sh.contact_id = c.id
    ''');

    final whereConditions = <String>[];
    final args = <dynamic>[];

    // Apply search filter
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereConditions.add('(LOWER(c.name) LIKE LOWER(?) OR c.phone LIKE ?)');
      final searchTerm = '%${searchQuery.trim()}%';
      args.add(searchTerm);
      args.add(searchTerm);
    }

    final activityCondition =
        '(COALESCE(ts.total_transactions, 0) + COALESCE(sh.split_history_count, 0)) > 0';
    final netExpression =
        '(COALESCE(ts.total_lent, 0) - COALESCE(ts.total_borrowed, 0))';

    if (balanceFilter == 'settled') {
      whereConditions.add(activityCondition);
      whereConditions.add('ABS($netExpression) <= 0.01');
    } else if (balanceFilter == 'pending') {
      whereConditions.add('ABS($netExpression) > 0.01');
    } else {
      whereConditions.add(activityCondition);
    }

    if (whereConditions.isNotEmpty) {
      sql.write(' WHERE ${whereConditions.join(' AND ')}');
    }

    sql.write(
      ' ORDER BY last_transaction_date IS NULL, last_transaction_date DESC',
    );

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final result = await _dbHelper.rawQuery(sql.toString(), args);
    log(
      'TransactionRepository: Found ${result.length} contacts (search: "$searchQuery", balance: $balanceFilter)',
    );
    return result;
  }

  /// Get contact count with filters (for pagination)
  Future<int> getContactSummaryCount({
    String? searchQuery,
    String? balanceFilter,
  }) async {
    log('TransactionRepository: Getting contact count with filters');

    final sql = StringBuffer('''
      WITH transaction_summary AS (
        SELECT
          contact_id,
          COUNT(id) AS total_transactions,
          COALESCE(SUM(CASE WHEN type = 'lend' THEN amount ELSE 0 END), 0) AS total_lent,
          COALESCE(SUM(CASE WHEN type = 'borrow' THEN amount ELSE 0 END), 0) AS total_borrowed
        FROM transactions
        GROUP BY contact_id
      ),
      split_history AS (
        SELECT
          sp.contact_id,
          COUNT(sp.id) AS split_history_count
        FROM split_participants sp
        INNER JOIN split_expenses se ON se.id = sp.split_id
        GROUP BY sp.contact_id
      )
      SELECT COUNT(*) as count
      FROM contacts c
      LEFT JOIN transaction_summary ts ON ts.contact_id = c.id
      LEFT JOIN split_history sh ON sh.contact_id = c.id
    ''');

    final whereConditions = <String>[];
    final args = <dynamic>[];

    // Apply search filter
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereConditions.add(
        '(LOWER(c.name) LIKE LOWER(?) OR LOWER(c.phone) LIKE LOWER(?))',
      );
      final searchTerm = '%${searchQuery.trim()}%';
      args.add(searchTerm);
      args.add(searchTerm);
    }

    final activityCondition =
        '(COALESCE(ts.total_transactions, 0) + COALESCE(sh.split_history_count, 0)) > 0';
    final netExpression =
        '(COALESCE(ts.total_lent, 0) - COALESCE(ts.total_borrowed, 0))';

    if (balanceFilter == 'settled') {
      whereConditions.add(activityCondition);
      whereConditions.add('ABS($netExpression) <= 0.01');
    } else if (balanceFilter == 'pending') {
      whereConditions.add('ABS($netExpression) > 0.01');
    } else {
      whereConditions.add(activityCondition);
    }

    if (whereConditions.isNotEmpty) {
      sql.write(' WHERE ${whereConditions.join(' AND ')}');
    }

    final countResult = await _dbHelper.rawQuery(sql.toString(), args);

    return (countResult.first['count'] as int?) ?? 0;
  }

  // Get monthly stats (indexes on date + type help here)
  Future<List<Map<String, dynamic>>> getMonthlyStats(int year) async {
    return _dbHelper.rawQuery(
      '''
      SELECT 
        strftime('%m', date) AS month,
        type,
        transaction_category,
        SUM(amount) AS total,
        COUNT(*) AS count
      FROM transactions
      WHERE strftime('%Y', date) = ?
      GROUP BY month, type, transaction_category
      ORDER BY month
      ''',
      [year.toString()],
    );
  }

  // Get transaction count (for pagination)
  Future<int> getTransactionCount({
    String? type,
    String? category,
    int? contactId,
    String? searchQuery,
  }) async {
    final whereConditions = <String>[_visibleUserTransactionCondition];
    final whereArgs = <dynamic>[];
    _addHiddenSettlementArgs(whereArgs);

    if (type != null) {
      whereConditions.add('t.type = ?');
      whereArgs.add(type);
    }

    if (category != null) {
      whereConditions.add('t.transaction_category = ?');
      whereArgs.add(category);
    }

    if (contactId != null) {
      whereConditions.add('t.contact_id = ?');
      whereArgs.add(contactId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final searchTerm = '%${searchQuery.trim()}%';
      whereConditions.add(
        '(LOWER(t.description) LIKE LOWER(?) OR LOWER(c.name) LIKE LOWER(?) OR LOWER(t.item_name) LIKE LOWER(?))',
      );
      whereArgs.addAll([searchTerm, searchTerm, searchTerm]);
    }

    final where = whereConditions.isEmpty
        ? ''
        : 'WHERE ${whereConditions.join(' AND ')}';

    final result = await _dbHelper.rawQuery('''
      SELECT COUNT(*) as count
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      $where
      ''', whereArgs);

    return (result.first['count'] as int?) ?? 0;
  }

  // Get recent transactions for dashboard
  Future<List<TransactionModel>> getRecentTransactions({int limit = 10}) async {
    return getAllTransactions(limit: limit);
  }

  /* =======================
     OVERDUE & STATUS TRACKING
  ======================== */

  // Get overdue transactions
  Future<List<TransactionModel>> getOverdueTransactions({
    int? limit,
    int? offset,
  }) async {
    log('TransactionRepository: Fetching overdue transactions');
    final today = DateTime.now().toIso8601String().split('T')[0];

    final sql = StringBuffer('''
      SELECT t.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      WHERE t.status = 'pending' 
        AND t.expected_date IS NOT NULL 
        AND t.expected_date < ?
      ORDER BY t.expected_date ASC
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final maps = await _dbHelper.rawQuery(sql.toString(), [today]);
    return maps.map(TransactionModel.fromMap).toList();
  }

  // Get transactions due soon (within next N days)
  Future<List<TransactionModel>> getTransactionsDueSoon({
    int daysAhead = 7,
    int? limit,
    int? offset,
  }) async {
    log(
      'TransactionRepository: Fetching transactions due in next $daysAhead days',
    );
    final today = DateTime.now();
    final futureDate = today.add(Duration(days: daysAhead));

    final sql = StringBuffer('''
      SELECT t.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      WHERE t.status = 'pending' 
        AND t.expected_date IS NOT NULL 
        AND t.expected_date BETWEEN ? AND ?
      ORDER BY t.expected_date ASC
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final maps = await _dbHelper.rawQuery(sql.toString(), [
      today.toIso8601String(),
      futureDate.toIso8601String(),
    ]);

    return maps.map(TransactionModel.fromMap).toList();
  }

  // Mark transaction as paid/settled
  Future<int> markTransactionAsPaid(int transactionId) async {
    log('TransactionRepository: Marking transaction $transactionId as paid');
    return _dbHelper.update(
      'transactions',
      {
        'status': 'paid',
        'paid_amount': 0, // Will be set from amount in UI
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // Update partial payment
  Future<int> updatePartialPayment(int transactionId, double paidAmount) async {
    log(
      'TransactionRepository: Updating partial payment for transaction $transactionId',
    );

    // Get current transaction to calculate status
    final transaction = await getTransactionById(transactionId);
    if (transaction == null) return 0;

    final totalPaid = (transaction.paidAmount ?? 0) + paidAmount;
    final status = totalPaid >= transaction.amount ? 'paid' : 'partial';

    return _dbHelper.update(
      'transactions',
      {
        'paid_amount': totalPaid,
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<ContactSettlementBalances> _getContactSettlementBalancesInTransaction(
    sqflite.Transaction txn,
    int contactId,
  ) async {
    final result = await txn.rawQuery(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN transaction_category != ? AND type = ? THEN amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN transaction_category != ? AND type = ? THEN amount ELSE 0 END), 0) AS direct_net,
        COALESCE(SUM(CASE WHEN transaction_category = ? AND type = ? THEN amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN transaction_category = ? AND type = ? THEN amount ELSE 0 END), 0) AS split_net
      FROM transactions
      WHERE contact_id = ?
      ''',
      [
        AppConstants.categorySplit,
        AppConstants.typeLend,
        AppConstants.categorySplit,
        AppConstants.typeBorrow,
        AppConstants.categorySplit,
        AppConstants.typeLend,
        AppConstants.categorySplit,
        AppConstants.typeBorrow,
        contactId,
      ],
    );

    final row = result.first;
    return ContactSettlementBalances(
      directNet: (row['direct_net'] as num?)?.toDouble() ?? 0,
      splitNet: (row['split_net'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<int> _insertContactSettlementInTransaction(
    sqflite.Transaction txn, {
    required int contactId,
    required double netAmount,
    required int netSign,
    required double directCleared,
    required double splitCleared,
    required double offsetAmount,
    required bool isPartial,
    required DateTime date,
  }) async {
    final now = DateTime.now();
    final direction = netSign > 0
        ? AppConstants.typeLend
        : netSign < 0
        ? AppConstants.typeBorrow
        : AppConstants.statusSettled;

    return txn.insert(
      'contact_settlements',
      ContactSettlementModel(
        contactId: contactId,
        netAmount: netAmount,
        direction: direction,
        directCleared: directCleared,
        splitCleared: splitCleared,
        offsetAmount: offsetAmount,
        isPartial: isPartial,
        date: date,
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );
  }

  Future<void> _updateContactSettlementAmountsInTransaction(
    sqflite.Transaction txn, {
    required int settlementId,
    required double directCleared,
    required double splitCleared,
  }) async {
    await txn.update(
      'contact_settlements',
      {
        'direct_cleared': directCleared,
        'split_cleared': splitCleared,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [settlementId],
    );
  }

  Future<void> _insertContactSettlementEffectInTransaction(
    sqflite.Transaction txn, {
    required int settlementId,
    required ContactSettlementEffectType effectType,
    required double amount,
    required int balanceSign,
    int? transactionId,
    int? splitId,
    int? splitParticipantId,
  }) async {
    if (amount <= SplitSettlementCalculator.tolerance) return;

    await txn.insert(
      'contact_settlement_effects',
      ContactSettlementEffectModel(
        settlementId: settlementId,
        effectType: effectType,
        amount: amount,
        direction: balanceSign > 0
            ? AppConstants.typeLend
            : AppConstants.typeBorrow,
        transactionId: transactionId,
        splitId: splitId,
        splitParticipantId: splitParticipantId,
      ).toMap(),
    );
  }

  Future<ContactSettlementResult> _settleContactBalanceFullyInTransaction(
    sqflite.Transaction txn, {
    required int contactId,
    required double directNet,
    required double splitNet,
    required String paymentDescription,
    required String offsetDescription,
    required DateTime date,
  }) async {
    final directSign = _amountSign(directNet);
    final splitSign = _amountSign(splitNet);
    final hasOffset =
        directSign != 0 && splitSign != 0 && directSign != splitSign;
    final offsetAmount = hasOffset
        ? math.min(directNet.abs(), splitNet.abs())
        : 0.0;
    final directCashAmount = directNet.abs() - offsetAmount;
    final net = directNet + splitNet;
    final settlementId = await _insertContactSettlementInTransaction(
      txn,
      contactId: contactId,
      netAmount: net.abs(),
      netSign: _amountSign(net),
      directCleared: directNet.abs(),
      splitCleared: splitNet.abs(),
      offsetAmount: offsetAmount,
      isPartial: false,
      date: date,
    );

    if (directCashAmount > SplitSettlementCalculator.tolerance) {
      final transactionId = await _insertDirectSettlementInTransaction(
        txn,
        contactId: contactId,
        amount: directCashAmount,
        balanceSign: directSign,
        description: paymentDescription,
        sourceType: AppConstants.sourceTypeContactSettlement,
        sourceId: settlementId,
        date: date,
      );
      await _insertContactSettlementEffectInTransaction(
        txn,
        settlementId: settlementId,
        effectType: ContactSettlementEffectType.directCash,
        amount: directCashAmount,
        balanceSign: directSign,
        transactionId: transactionId,
      );
    }

    if (offsetAmount > SplitSettlementCalculator.tolerance) {
      final transactionId = await _insertDirectSettlementInTransaction(
        txn,
        contactId: contactId,
        amount: offsetAmount,
        balanceSign: directSign,
        description: offsetDescription,
        sourceType: AppConstants.sourceTypeContactSettlementOffset,
        sourceId: settlementId,
        date: date,
      );
      await _insertContactSettlementEffectInTransaction(
        txn,
        settlementId: settlementId,
        effectType: ContactSettlementEffectType.directOffset,
        amount: offsetAmount,
        balanceSign: directSign,
        transactionId: transactionId,
      );
    }

    final splitSettled = await _settleContactSplitsInTransaction(
      txn,
      settlementId: settlementId,
      contactId: contactId,
      balanceSign: splitSign,
      amount: splitNet.abs(),
    );
    await _updateContactSettlementAmountsInTransaction(
      txn,
      settlementId: settlementId,
      directCleared: directCashAmount + offsetAmount,
      splitCleared: splitSettled,
    );

    return ContactSettlementResult(
      settlementId: settlementId,
      directSettled: directCashAmount + offsetAmount,
      splitSettled: splitSettled,
      cashAmount: (directNet + splitNet).abs(),
      offsetAmount: offsetAmount,
    );
  }

  Future<ContactSettlementResult> _settleContactBalancePartiallyInTransaction(
    sqflite.Transaction txn, {
    required int contactId,
    required double directNet,
    required double splitNet,
    required double amount,
    required String paymentDescription,
    required DateTime date,
  }) async {
    final netSign = _amountSign(directNet + splitNet);
    var remaining = amount;
    var directSettled = 0.0;
    var splitSettled = 0.0;
    final directPlan = _amountSign(directNet) == netSign
        ? math.min(directNet.abs(), remaining)
        : 0.0;
    final splitPlan =
        math.max(0.0, remaining - directPlan) *
        (_amountSign(splitNet) == netSign ? 1 : 0);
    final settlementId = await _insertContactSettlementInTransaction(
      txn,
      contactId: contactId,
      netAmount: amount,
      netSign: netSign,
      directCleared: directPlan,
      splitCleared: splitPlan,
      offsetAmount: 0,
      isPartial: true,
      date: date,
    );

    if (_amountSign(directNet) == netSign) {
      directSettled = math.min(directNet.abs(), remaining);
      if (directSettled > SplitSettlementCalculator.tolerance) {
        final transactionId = await _insertDirectSettlementInTransaction(
          txn,
          contactId: contactId,
          amount: directSettled,
          balanceSign: netSign,
          description: paymentDescription,
          sourceType: AppConstants.sourceTypeContactSettlement,
          sourceId: settlementId,
          date: date,
        );
        await _insertContactSettlementEffectInTransaction(
          txn,
          settlementId: settlementId,
          effectType: ContactSettlementEffectType.directCash,
          amount: directSettled,
          balanceSign: netSign,
          transactionId: transactionId,
        );
        remaining -= directSettled;
      }
    }

    if (remaining > SplitSettlementCalculator.tolerance &&
        _amountSign(splitNet) == netSign) {
      splitSettled = await _settleContactSplitsInTransaction(
        txn,
        settlementId: settlementId,
        contactId: contactId,
        balanceSign: netSign,
        amount: remaining,
      );
    }
    await _updateContactSettlementAmountsInTransaction(
      txn,
      settlementId: settlementId,
      directCleared: directSettled,
      splitCleared: splitSettled,
    );

    return ContactSettlementResult(
      settlementId: settlementId,
      directSettled: directSettled,
      splitSettled: splitSettled,
      cashAmount: amount,
    );
  }

  Future<int?> _insertDirectSettlementInTransaction(
    sqflite.Transaction txn, {
    required int contactId,
    required double amount,
    required int balanceSign,
    required String description,
    required String sourceType,
    required int sourceId,
    required DateTime date,
  }) async {
    if (amount <= SplitSettlementCalculator.tolerance || balanceSign == 0) {
      return null;
    }

    return txn.insert(
      'transactions',
      TransactionModel(
        type: balanceSign > 0 ? AppConstants.typeBorrow : AppConstants.typeLend,
        category: AppConstants.categoryCash,
        contactId: contactId,
        amount: amount,
        description: description,
        isSettlement: true,
        sourceType: sourceType,
        sourceId: sourceId,
        date: date,
      ).toMap(),
    );
  }

  Future<double> _settleContactSplitsInTransaction(
    sqflite.Transaction txn, {
    required int settlementId,
    required int contactId,
    required int balanceSign,
    required double amount,
  }) async {
    if (amount <= SplitSettlementCalculator.tolerance || balanceSign == 0) {
      return 0;
    }

    final targetType = balanceSign > 0
        ? AppConstants.typeLend
        : AppConstants.typeBorrow;
    final splitRows = await txn.rawQuery(
      '''
      SELECT source_id AS split_id, MIN(date) AS first_date
      FROM transactions
      WHERE contact_id = ?
        AND transaction_category = ?
        AND source_type = ?
        AND type = ?
      GROUP BY source_id
      ORDER BY datetime(first_date) ASC, source_id ASC
      ''',
      [
        contactId,
        AppConstants.categorySplit,
        AppConstants.sourceTypeSplit,
        targetType,
      ],
    );

    var remaining = amount;
    var settled = 0.0;
    final affectedSplitIds = <int>{};

    for (final row in splitRows) {
      if (remaining <= SplitSettlementCalculator.tolerance) break;
      final splitId = row['split_id'] as int?;
      if (splitId == null) continue;

      final split =
          await SplitTransactionSyncHelper.getSplitWithParticipantsInTransaction(
            txn,
            splitId,
          );
      if (split == null) continue;
      final participants =
          split.participants ?? const <SplitParticipantModel>[];
      final routeEntries = SplitSettlementCalculator.calculateRouteEntries(
        split,
        participants,
      );

      for (final entry in routeEntries) {
        if (remaining <= SplitSettlementCalculator.tolerance) break;
        if (!entry.affectsUser ||
            entry.amount <= SplitSettlementCalculator.tolerance) {
          continue;
        }

        final entryType = entry.userReceives
            ? AppConstants.typeLend
            : AppConstants.typeBorrow;
        if (entryType != targetType) continue;

        final participant = entry.from.isUser
            ? entry.to.participant
            : entry.from.participant;
        if (participant == null || participant.contactId != contactId) {
          continue;
        }

        final amountToApply = math.min(entry.amount, remaining);
        await _applySplitParticipantPaymentInTransaction(
          txn,
          participant,
          amountToApply,
        );
        await _insertContactSettlementEffectInTransaction(
          txn,
          settlementId: settlementId,
          effectType: ContactSettlementEffectType.splitParticipant,
          amount: amountToApply,
          balanceSign: balanceSign,
          splitId: splitId,
          splitParticipantId: participant.id,
        );
        remaining -= amountToApply;
        settled += amountToApply;
        affectedSplitIds.add(splitId);
      }
    }

    for (final splitId in affectedSplitIds) {
      await SplitTransactionSyncHelper.syncSplitTransactionsInTransaction(
        txn,
        splitId,
      );
    }

    return settled;
  }

  Future<void> _applySplitParticipantPaymentInTransaction(
    sqflite.Transaction txn,
    SplitParticipantModel participant,
    double amount,
  ) async {
    if (participant.id == null ||
        amount <= SplitSettlementCalculator.tolerance) {
      return;
    }

    final amountToSettle = (participant.shareAmount - participant.expensePaid)
        .abs();
    final newPaid = math.min(amountToSettle, participant.paid + amount);
    final isFullyPaid =
        (newPaid - amountToSettle).abs() <
            SplitSettlementCalculator.tolerance ||
        newPaid >= amountToSettle;

    await txn.update(
      'split_participants',
      {
        'paid': newPaid,
        'status': isFullyPaid
            ? AppConstants.statusPaid
            : AppConstants.statusPending,
      },
      where: 'id = ?',
      whereArgs: [participant.id],
    );
  }

  int _amountSign(double amount) {
    if (amount > SplitSettlementCalculator.tolerance) return 1;
    if (amount < -SplitSettlementCalculator.tolerance) return -1;
    return 0;
  }
}
