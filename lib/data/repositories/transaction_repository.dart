import 'dart:developer';

import 'package:borrow_ledger/core/constants/app_constants.dart';
import 'package:borrow_ledger/data/models/transaction_model.dart';

import '../database/database_helper.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _activityOrder =
      'datetime(COALESCE(t.updated_at, t.created_at, t.date)) DESC, t.id DESC';
  static const String _splitHistoryDescriptionPrefix = 'Split history: ';

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

  /* =======================
     READ OPERATIONS
  ======================== */

  // Get all transactions with pagination
  Future<List<TransactionModel>> getAllTransactions({
    int? limit,
    int? offset,
  }) async {
    final sql = StringBuffer('''
      SELECT t.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      ORDER BY $_activityOrder
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final maps = await _dbHelper.rawQuery(sql.toString());
    return maps.map(TransactionModel.fromMap).toList();
  }

  // Get transactions by type with pagination
  Future<List<TransactionModel>> getTransactionsByType(
    String type, {
    int? limit,
    int? offset,
  }) async {
    final sql = StringBuffer('''
      SELECT t.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      WHERE t.type = ?
      ORDER BY $_activityOrder
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final maps = await _dbHelper.rawQuery(sql.toString(), [type]);
    return maps.map(TransactionModel.fromMap).toList();
  }

  // Get transactions by category (cash or udhari)
  Future<List<TransactionModel>> getTransactionsByCategory(
    String category, {
    int? limit,
    int? offset,
  }) async {
    log('TransactionRepository: Fetching $category transactions');
    final sql = StringBuffer('''
      SELECT t.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      WHERE t.transaction_category = ?
      ORDER BY $_activityOrder
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final maps = await _dbHelper.rawQuery(sql.toString(), [category]);
    return maps.map(TransactionModel.fromMap).toList();
  }

  // Get transactions by category (cash or udhari)
  Future<List<TransactionModel>> getTransactionsByCategoryAndType(
    String category,
    String type, {
    int? limit,
    int? offset,
  }) async {
    log('TransactionRepository: Fetching $category transactions');
    final sql = StringBuffer('''
      SELECT t.*, c.name AS contact_name, c.phone AS contact_phone, c.avatar AS contact_avatar
      FROM transactions t
      LEFT JOIN contacts c ON t.contact_id = c.id
      WHERE t.transaction_category = ? AND t.type = ?
      ORDER BY $_activityOrder
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final maps = await _dbHelper.rawQuery(sql.toString(), [category, type]);
    return maps.map(TransactionModel.fromMap).toList();
  }

  // Get transactions by contact with pagination
  Future<List<TransactionModel>> getTransactionsByContact(
    int contactId, {
    int? limit,
    int? offset,
    String? category, // Optional category filter
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
      ORDER BY $_activityOrder
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
      ORDER BY datetime(COALESCE(updated_at, created_at, date)) DESC, id DESC
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

  Future<List<TransactionModel>> getContactActivityByDateRange(
    int contactId,
    DateTime start,
    DateTime end, {
    String? category,
    int? limit,
    int? offset,
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
    return (result.first['count'] as int?) ?? 0;
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
    final totalLent = (row['total_lent'] as num?)?.toDouble() ?? 0.0;
    final totalBorrowed = (row['total_borrowed'] as num?)?.toDouble() ?? 0.0;
    final splitLent = (row['split_lent'] as num?)?.toDouble() ?? 0.0;
    final splitBorrowed = (row['split_borrowed'] as num?)?.toDouble() ?? 0.0;

    return {
      'total_transactions': (row['total_transactions'] as int?) ?? 0,
      'total_lent': totalLent,
      'total_borrowed': totalBorrowed,
      'net_balance': totalLent - totalBorrowed,
      'normal_net_balance':
          (totalLent - splitLent) - (totalBorrowed - splitBorrowed),
      'split_net_balance': splitLent - splitBorrowed,
      'cash_count': (row['cash_count'] as int?) ?? 0,
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
    final directConditions = <String>['t.contact_id = ?'];
    args.add(contactId);

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

  // Search transactions (uses description + contact name + item name indexes)
  Future<List<TransactionModel>> searchTransactions(
    String query, {
    String? category,
    String? type,
    int? limit,
    int? offset,
  }) async {
    if (query.trim().isEmpty) return [];
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];
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
      ORDER BY $_activityOrder
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
  }) async {
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (type != null) {
      whereConditions.add('t.type = ?');
      whereArgs.add(type);
    }

    if (category != null) {
      whereConditions.add('t.transaction_category = ?');
      whereArgs.add(category);
    }

    if (contactId != null) {
      whereConditions.add('contact_id = ?');
      whereArgs.add(contactId);
    }

    final where = whereConditions.isEmpty
        ? ''
        : 'WHERE ${whereConditions.join(' AND ')}';

    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM transactions t $where',
      whereArgs,
    );

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
}
