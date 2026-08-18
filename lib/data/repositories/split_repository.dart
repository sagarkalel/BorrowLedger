import 'package:borrow_ledger/core/constants/app_constants.dart';
import 'package:borrow_ledger/core/utils/split_settlement_calculator.dart';
import 'package:borrow_ledger/data/models/split_model.dart';
import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../database/database_helper.dart';

class SplitRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Future<void>? _syncAllFuture;
  static const String _activityOrder =
      'updated_at DESC, created_at DESC, id DESC';

  // Helper method to compare doubles with tolerance for floating-point precision
  bool _isAmountFullyPaid(double paid, double shareAmount) {
    const tolerance = 0.01; // 1 cent tolerance
    return (paid - shareAmount).abs() < tolerance || paid >= shareAmount;
  }

  // Create a new split expense
  Future<int> createSplitExpense(SplitExpenseModel split) async {
    return await _dbHelper.insert('split_expenses', split.toMap());
  }

  Future<int> createSplitWithParticipants(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants,
  ) {
    return _dbHelper.transaction((txn) async {
      final splitId = await txn.insert('split_expenses', split.toMap());

      for (final participant in participants) {
        await txn.insert(
          'split_participants',
          participant.copyWith(splitId: splitId).toMap(),
        );
      }

      await _syncSplitTransactionsInTransaction(txn, splitId);
      return splitId;
    });
  }

  // Create split participants
  Future<void> createParticipants(
    List<SplitParticipantModel> participants,
  ) async {
    for (var participant in participants) {
      await _dbHelper.insert('split_participants', participant.toMap());
    }
  }

  Future<void> syncSplitTransactions(int splitId) async {
    await _dbHelper.transaction((txn) async {
      await _syncSplitTransactionsInTransaction(txn, splitId);
    });
  }

  Future<void> _syncSplitTransactionsInTransaction(
    sqflite.Transaction txn,
    int splitId,
  ) async {
    final split = await _getSplitByIdInTransaction(txn, splitId);
    if (split == null) return;

    await _deleteGeneratedTransactionsInTransaction(txn, splitId);

    if (split.status == AppConstants.statusSettled) return;

    final participants = split.participants ?? [];
    if (participants.isEmpty) return;

    final routeEntries = SplitSettlementCalculator.calculateRouteEntries(
      split,
      participants,
    );

    for (final entry in routeEntries) {
      if (!entry.affectsUser ||
          entry.amount <= SplitSettlementCalculator.tolerance) {
        continue;
      }

      final contactParticipant = entry.from.isUser
          ? entry.to.participant
          : entry.from.participant;
      if (contactParticipant == null) continue;

      await _createGeneratedTransactionInTransaction(
        txn,
        split: split,
        participant: contactParticipant,
        type: entry.userReceives
            ? AppConstants.typeLend
            : AppConstants.typeBorrow,
        amount: entry.amount,
      );
    }

    await _checkAndUpdateSplitStatusInTransaction(txn, splitId);
  }

  Future<void> _createGeneratedTransactionInTransaction(
    sqflite.Transaction txn, {
    required SplitExpenseModel split,
    required SplitParticipantModel participant,
    required String type,
    required double amount,
  }) async {
    if (amount < 0.01) return;

    await txn.insert(
      'transactions',
      TransactionModel(
        type: type,
        category: AppConstants.categorySplit,
        contactId: participant.contactId,
        amount: amount,
        description: 'Split: ${split.title}',
        date: split.date,
        createdAt: split.createdAt,
        updatedAt: split.updatedAt,
        sourceType: AppConstants.sourceTypeSplit,
        sourceId: split.id,
      ).toMap(),
    );
  }

  Future<void> syncAllSplitTransactions() async {
    final activeSync = _syncAllFuture;
    if (activeSync != null) return activeSync;

    final future = () async {
      final rows = await _dbHelper.query('split_expenses');
      for (final row in rows) {
        final splitId = row['id'] as int?;
        if (splitId != null) {
          await syncSplitTransactions(splitId);
        }
      }
    }();

    _syncAllFuture = future.whenComplete(() => _syncAllFuture = null);
    return _syncAllFuture!;
  }

  Future<void> _deleteGeneratedTransactionsInTransaction(
    sqflite.Transaction txn,
    int splitId,
  ) async {
    await txn.delete(
      'transactions',
      where: 'source_type = ? AND source_id = ?',
      whereArgs: [AppConstants.sourceTypeSplit, splitId],
    );
  }

  Future<SplitExpenseModel?> _getSplitByIdInTransaction(
    sqflite.Transaction txn,
    int id,
  ) async {
    final maps = await txn.query(
      'split_expenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final split = SplitExpenseModel.fromMap(maps.first);
    final participants = await _getParticipantsBySplitIdInTransaction(txn, id);

    return split.copyWith(participants: participants);
  }

  Future<List<SplitParticipantModel>> _getParticipantsBySplitIdInTransaction(
    sqflite.Transaction txn,
    int splitId,
  ) async {
    final maps = await txn.rawQuery(
      '''
      SELECT sp.*, c.name as contact_name
      FROM split_participants sp
      LEFT JOIN contacts c ON sp.contact_id = c.id
      WHERE sp.split_id = ?
      ORDER BY sp.status ASC, c.name ASC
    ''',
      [splitId],
    );

    return maps.map((map) => SplitParticipantModel.fromMap(map)).toList();
  }

  // Get all split expenses with participants (with pagination)
  Future<List<SplitExpenseModel>> getAllSplits({
    int limit = 20,
    int offset = 0,
  }) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'split_expenses',
      orderBy: _activityOrder,
      limit: limit,
      offset: offset,
    );

    List<SplitExpenseModel> splits = [];
    for (var map in maps) {
      final split = SplitExpenseModel.fromMap(map);
      final participants = await getParticipantsBySplitId(split.id!);
      splits.add(split.copyWith(participants: participants));
    }

    return splits;
  }

  // Get split by ID with participants
  Future<SplitExpenseModel?> getSplitById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'split_expenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final split = SplitExpenseModel.fromMap(maps.first);
    final participants = await getParticipantsBySplitId(id);

    return split.copyWith(participants: participants);
  }

  // Get participants for a split
  Future<List<SplitParticipantModel>> getParticipantsBySplitId(
    int splitId,
  ) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery(
      '''
      SELECT sp.*, c.name as contact_name
      FROM split_participants sp
      LEFT JOIN contacts c ON sp.contact_id = c.id
      WHERE sp.split_id = ?
      ORDER BY sp.status ASC, c.name ASC
    ''',
      [splitId],
    );

    return maps.map((map) => SplitParticipantModel.fromMap(map)).toList();
  }

  // Get splits by status (with pagination)
  Future<List<SplitExpenseModel>> getSplitsByStatus(
    String status, {
    int limit = 20,
    int offset = 0,
  }) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'split_expenses',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: _activityOrder,
      limit: limit,
      offset: offset,
    );

    List<SplitExpenseModel> splits = [];
    for (var map in maps) {
      final split = SplitExpenseModel.fromMap(map);
      final participants = await getParticipantsBySplitId(split.id!);
      splits.add(split.copyWith(participants: participants));
    }

    return splits;
  }

  // Search splits (with pagination)
  Future<List<SplitExpenseModel>> searchSplits(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'split_expenses',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%${query.trim()}%', '%${query.trim()}%'],
      orderBy: _activityOrder,
      limit: limit,
      offset: offset,
    );

    List<SplitExpenseModel> splits = [];
    for (var map in maps) {
      final split = SplitExpenseModel.fromMap(map);
      final participants = await getParticipantsBySplitId(split.id!);
      splits.add(split.copyWith(participants: participants));
    }

    return splits;
  }

  // Get split count (with optional status filter)
  Future<int> getSplitCount({String? status}) async {
    String query = 'SELECT COUNT(*) as count FROM split_expenses';
    List<dynamic> args = [];

    if (status != null) {
      query += ' WHERE status = ?';
      args.add(status);
    }

    final result = await _dbHelper.rawQuery(query, args);
    return (result.first['count'] as int?) ?? 0;
  }

  // Update split expense
  Future<int> updateSplitExpense(SplitExpenseModel split) async {
    return await _dbHelper.update(
      'split_expenses',
      split.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [split.id],
    );
  }

  Future<void> updateSplitWithParticipants(
    SplitExpenseModel split, [
    List<SplitParticipantModel>? participants,
  ]) async {
    final splitId = split.id;
    if (splitId == null) return;

    await _dbHelper.transaction((txn) async {
      await txn.update(
        'split_expenses',
        split.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [splitId],
      );

      if (participants != null) {
        await txn.delete(
          'split_participants',
          where: 'split_id = ?',
          whereArgs: [splitId],
        );

        for (final participant in participants) {
          await txn.insert(
            'split_participants',
            participant.copyWith(splitId: splitId).toMap(),
          );
        }
      }

      await _syncSplitTransactionsInTransaction(txn, splitId);
    });
  }

  // Update participant
  Future<int> updateParticipant(SplitParticipantModel participant) async {
    return await _dbHelper.update(
      'split_participants',
      participant.toMap(),
      where: 'id = ?',
      whereArgs: [participant.id],
    );
  }

  // Mark participant as paid - WITH FLOATING POINT PRECISION FIX
  Future<void> markParticipantAsPaid(int participantId, double amount) async {
    await _dbHelper.transaction((txn) async {
      final maps = await txn.query(
        'split_participants',
        where: 'id = ?',
        whereArgs: [participantId],
      );
      if (maps.isEmpty) return;

      final participant = SplitParticipantModel.fromMap(maps.first);
      final amountToSettle = (participant.shareAmount - participant.expensePaid)
          .abs();
      final isFullyPaid = _isAmountFullyPaid(amount, amountToSettle);

      await txn.update(
        'split_participants',
        {'paid': amount, 'status': isFullyPaid ? 'paid' : 'pending'},
        where: 'id = ?',
        whereArgs: [participantId],
      );

      await _syncSplitTransactionsInTransaction(txn, participant.splitId);
    });
  }

  // Get participant by ID
  Future<SplitParticipantModel?> getParticipantById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'split_participants',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return SplitParticipantModel.fromMap(maps.first);
  }

  Future<void> _checkAndUpdateSplitStatusInTransaction(
    sqflite.Transaction txn,
    int splitId,
  ) async {
    final pendingTransactions = await txn.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM transactions
      WHERE source_type = ?
        AND source_id = ?
        AND transaction_category = ?
    ''',
      [AppConstants.sourceTypeSplit, splitId, AppConstants.categorySplit],
    );
    final pendingCount = pendingTransactions.first['count'] as int? ?? 0;
    final participantDebtResult = await txn.rawQuery(
      '''
      SELECT COALESCE(SUM(
        CASE
          WHEN share_amount > expense_paid + paid
          THEN share_amount - expense_paid - paid
          ELSE 0
        END
      ), 0) as pending_participant_debt
      FROM split_participants
      WHERE split_id = ?
    ''',
      [splitId],
    );
    final pendingParticipantDebt =
        (participantDebtResult.first['pending_participant_debt'] as num?)
            ?.toDouble() ??
        0.0;
    const tolerance = 0.01;
    final allPaid = pendingCount == 0 && pendingParticipantDebt <= tolerance;

    if (allPaid) {
      await txn.update(
        'split_expenses',
        {'status': 'settled', 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [splitId],
      );
    } else {
      // If not all paid, ensure status is 'pending'
      await txn.update(
        'split_expenses',
        {'status': 'pending', 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [splitId],
      );
    }
  }

  // Settle entire split - marks all participants as fully paid**
  Future<void> settleSplit(int splitId) async {
    await _dbHelper.transaction((txn) async {
      final participants = await _getParticipantsBySplitIdInTransaction(
        txn,
        splitId,
      );

      // Mark each participant as fully settled in whichever direction applies.
      for (var participant in participants) {
        final amountToSettle =
            (participant.shareAmount - participant.expensePaid).abs();
        await txn.update(
          'split_participants',
          {'paid': amountToSettle, 'status': 'paid'},
          where: 'id = ?',
          whereArgs: [participant.id],
        );
      }

      // Update split status to settled
      await txn.update(
        'split_expenses',
        {'status': 'settled', 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [splitId],
      );
      await _deleteGeneratedTransactionsInTransaction(txn, splitId);
    });
  }

  // Delete split expense (cascade deletes participants)
  Future<int> deleteSplit(int id) async {
    return _dbHelper.transaction((txn) async {
      await _deleteGeneratedTransactionsInTransaction(txn, id);

      // First delete all participants
      await txn.delete(
        'split_participants',
        where: 'split_id = ?',
        whereArgs: [id],
      );

      // Then delete the split
      return txn.delete('split_expenses', where: 'id = ?', whereArgs: [id]);
    });
  }

  // Get splits by date range
  Future<List<SplitExpenseModel>> getSplitsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 20,
    int offset = 0,
  }) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'split_expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    List<SplitExpenseModel> splits = [];
    for (var map in maps) {
      final split = SplitExpenseModel.fromMap(map);
      final participants = await getParticipantsBySplitId(split.id!);
      splits.add(split.copyWith(participants: participants));
    }

    return splits;
  }

  // Get summary
  Future<Map<String, double>> getSplitSummary() async {
    final expenseResult = await _dbHelper.rawQuery('''
    SELECT 
      SUM(CASE WHEN status != 'settled' THEN paid_by_user ELSE 0 END) as total_paid_by_user,
      SUM(CASE WHEN status != 'settled' THEN (total_amount - paid_by_user) ELSE 0 END) as total_owed
    FROM split_expenses
  ''');

    final linkedTransactionResult = await _dbHelper.rawQuery(
      '''
    SELECT 
      COALESCE(SUM(CASE WHEN type = 'lend' THEN amount ELSE 0 END), 0) as total_receivable,
      COALESCE(SUM(CASE WHEN type = 'borrow' THEN amount ELSE 0 END), 0) as total_payable
    FROM transactions
    WHERE source_type = ?
      AND transaction_category = ?
  ''',
      [AppConstants.sourceTypeSplit, AppConstants.categorySplit],
    );

    final fallbackParticipantResult = await _dbHelper.rawQuery('''
    SELECT 
      COALESCE(SUM(MAX(sp.share_amount - sp.expense_paid - sp.paid, 0)), 0) as total_receivable
    FROM split_expenses se
    INNER JOIN split_participants sp ON se.id = sp.split_id
    WHERE se.status != 'settled'
  ''');

    final totalPaidByUser =
        (expenseResult.first['total_paid_by_user'] as num?)?.toDouble() ?? 0.0;
    final totalOwed =
        (expenseResult.first['total_owed'] as num?)?.toDouble() ?? 0.0;
    var totalReceivable =
        (linkedTransactionResult.first['total_receivable'] as num?)
            ?.toDouble() ??
        0.0;
    final totalPayable =
        (linkedTransactionResult.first['total_payable'] as num?)?.toDouble() ??
        0.0;

    if (totalReceivable == 0 && totalPayable == 0) {
      totalReceivable =
          (fallbackParticipantResult.first['total_receivable'] as num?)
              ?.toDouble() ??
          0.0;
    }

    return {
      'total_paid_by_user': totalPaidByUser,
      'total_owed': totalOwed,
      'total_receivable': totalReceivable,
      'total_payable': totalPayable,
    };
  }

  // Get pending amount from a specific contact
  Future<double> getPendingAmountFromContact(int contactId) async {
    final result = await _dbHelper.rawQuery(
      '''
	      SELECT SUM(MAX(share_amount - expense_paid - paid, 0)) as pending
	      FROM split_participants
      WHERE contact_id = ? AND status != 'paid'
    ''',
      [contactId],
    );

    return (result.first['pending'] as num?)?.toDouble() ?? 0.0;
  }

  // Get splits where contact is a participant
  Future<List<SplitExpenseModel>> getSplitsByContact(
    int contactId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery(
      '''
      SELECT DISTINCT se.*
      FROM split_expenses se
      INNER JOIN split_participants sp ON se.id = sp.split_id
      WHERE sp.contact_id = ?
      ORDER BY se.updated_at DESC, se.created_at DESC, se.id DESC
      LIMIT ? OFFSET ?
    ''',
      [contactId, limit, offset],
    );

    List<SplitExpenseModel> splits = [];
    for (var map in maps) {
      final split = SplitExpenseModel.fromMap(map);
      final participants = await getParticipantsBySplitId(split.id!);
      splits.add(split.copyWith(participants: participants));
    }

    return splits;
  }

  // Bulk update participants for a split
  Future<void> updateSplitParticipants(
    int splitId,
    List<SplitParticipantModel> participants,
  ) async {
    await _dbHelper.transaction((txn) async {
      // Delete existing participants
      await txn.delete(
        'split_participants',
        where: 'split_id = ?',
        whereArgs: [splitId],
      );

      // Insert new participants
      for (var participant in participants) {
        await txn.insert(
          'split_participants',
          participant.copyWith(splitId: splitId).toMap(),
        );
      }

      await _syncSplitTransactionsInTransaction(txn, splitId);
    });
  }

  // Get recent splits
  Future<List<SplitExpenseModel>> getRecentSplits({int limit = 5}) async {
    return await getAllSplits(limit: limit, offset: 0);
  }

  // Get splits statistics
  Future<Map<String, dynamic>> getSplitStatistics() async {
    final result = await _dbHelper.rawQuery('''
      SELECT 
        COUNT(*) as total_splits,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_splits,
        COUNT(CASE WHEN status = 'settled' THEN 1 END) as settled_splits,
        SUM(total_amount) as total_amount,
        AVG(total_amount) as avg_amount
      FROM split_expenses
    ''');

    return {
      'total_splits': (result.first['total_splits'] as int?) ?? 0,
      'pending_splits': (result.first['pending_splits'] as int?) ?? 0,
      'settled_splits': (result.first['settled_splits'] as int?) ?? 0,
      'total_amount': (result.first['total_amount'] as num?)?.toDouble() ?? 0.0,
      'avg_amount': (result.first['avg_amount'] as num?)?.toDouble() ?? 0.0,
    };
  }
}
