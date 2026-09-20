import 'package:borrow_ledger/core/constants/app_constants.dart';
import 'package:borrow_ledger/core/utils/split_settlement_calculator.dart';
import 'package:borrow_ledger/data/models/split_model.dart';
import 'package:borrow_ledger/data/repositories/split_transaction_sync_helper.dart';
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
    return _dbHelper.transaction((txn) async {
      final splitToSave = _splitWithTotalsFromBills(split, split.bills);
      final splitId = await txn.insert('split_expenses', splitToSave.toMap());
      await _replaceBillsInTransaction(
        txn,
        splitId,
        _billsForSplit(
          splitToSave.copyWith(id: splitId),
          const [],
          split.bills,
        ),
      );
      return splitId;
    });
  }

  Future<int> createSplitWithParticipants(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants, [
    List<SplitBillModel>? bills,
  ]) {
    return _dbHelper.transaction((txn) async {
      final explicitBills = bills ?? split.bills;
      final splitToSave = _splitWithTotalsFromBills(split, explicitBills);
      final participantsToSave = explicitBills == null
          ? participants
          : _participantsWithExpensePaidFromBills(participants, explicitBills);
      final splitId = await txn.insert('split_expenses', splitToSave.toMap());

      for (final participant in participantsToSave) {
        await txn.insert(
          'split_participants',
          participant.copyWith(splitId: splitId).toMap(),
        );
      }

      await _replaceBillsInTransaction(
        txn,
        splitId,
        _billsForSplit(
          splitToSave.copyWith(id: splitId),
          participantsToSave,
          explicitBills,
        ),
      );

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
    int splitId, {
    bool refreshPendingActivity = true,
  }) async {
    await SplitTransactionSyncHelper.syncSplitTransactionsInTransaction(
      txn,
      splitId,
      refreshPendingActivity: refreshPendingActivity,
    );
  }

  Future<void> syncAllSplitTransactions() async {
    final activeSync = _syncAllFuture;
    if (activeSync != null) return activeSync;

    final future = () async {
      final rows = await _dbHelper.rawQuery(
        '''
        SELECT se.id
        FROM split_expenses se
        LEFT JOIN (
          SELECT
            source_id,
            COUNT(*) AS generated_count,
            MAX(updated_at) AS last_generated_update
          FROM transactions
          WHERE source_type = ?
            AND transaction_category = ?
          GROUP BY source_id
        ) gt ON gt.source_id = se.id
        WHERE (
          se.status = ?
          AND COALESCE(gt.generated_count, 0) > 0
        ) OR (
          se.status != ?
          AND (
            se.generated_synced_at IS NULL
            OR datetime(se.generated_synced_at) < datetime(se.updated_at)
            OR (
              COALESCE(gt.generated_count, 0) > 0
              AND datetime(gt.last_generated_update) < datetime(se.updated_at)
            )
          )
        )
        ''',
        [
          AppConstants.sourceTypeSplit,
          AppConstants.categorySplit,
          AppConstants.statusSettled,
          AppConstants.statusSettled,
        ],
      );
      if (rows.isEmpty) return;

      await _dbHelper.transaction((txn) async {
        for (final row in rows) {
          final splitId = row['id'] as int?;
          if (splitId != null) {
            await _syncSplitTransactionsInTransaction(
              txn,
              splitId,
              refreshPendingActivity: false,
            );
          }
        }
      });
    }();

    _syncAllFuture = future.whenComplete(() => _syncAllFuture = null);
    return _syncAllFuture!;
  }

  Future<void> _deleteGeneratedTransactionsInTransaction(
    sqflite.Transaction txn,
    int splitId,
  ) async {
    await SplitTransactionSyncHelper.deleteGeneratedTransactionsInTransaction(
      txn,
      splitId,
    );
  }

  Future<SplitExpenseModel?> _getSplitByIdInTransaction(
    sqflite.Transaction txn,
    int id,
  ) async {
    return SplitTransactionSyncHelper.getSplitWithParticipantsInTransaction(
      txn,
      id,
    );
  }

  Future<List<SplitParticipantModel>> _getParticipantsBySplitIdInTransaction(
    sqflite.Transaction txn,
    int splitId,
  ) async {
    final maps = await txn.rawQuery(
      '''
      SELECT sp.*, c.name as contact_name, c.avatar as contact_avatar
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
    final maps = await _dbHelper.query(
      'split_expenses',
      orderBy: _activityOrder,
      limit: limit,
      offset: offset,
    );

    return _splitsWithDetails(maps);
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
    final bills = await getBillsBySplitId(id);

    return split.copyWith(participants: participants, bills: bills);
  }

  // Get participants for a split
  Future<List<SplitParticipantModel>> getParticipantsBySplitId(
    int splitId,
  ) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery(
      '''
      SELECT sp.*, c.name as contact_name, c.avatar as contact_avatar
      FROM split_participants sp
      LEFT JOIN contacts c ON sp.contact_id = c.id
      WHERE sp.split_id = ?
      ORDER BY sp.status ASC, c.name ASC
    ''',
      [splitId],
    );

    return maps.map((map) => SplitParticipantModel.fromMap(map)).toList();
  }

  Future<List<SplitBillModel>> getBillsBySplitId(int splitId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery(
      '''
      SELECT sb.*, c.name as paid_by_contact_name, c.avatar as paid_by_contact_avatar
      FROM split_bills sb
      LEFT JOIN contacts c ON sb.paid_by_contact_id = c.id
      WHERE sb.split_id = ?
      ORDER BY sb.date ASC, sb.id ASC
    ''',
      [splitId],
    );

    return maps.map((map) => SplitBillModel.fromMap(map)).toList();
  }

  // Get splits by status (with pagination)
  Future<List<SplitExpenseModel>> getSplitsByStatus(
    String status, {
    int limit = 20,
    int offset = 0,
  }) async {
    final maps = await _dbHelper.query(
      'split_expenses',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: _activityOrder,
      limit: limit,
      offset: offset,
    );

    return _splitsWithDetails(maps);
  }

  // Search splits (with pagination)
  Future<List<SplitExpenseModel>> searchSplits(
    String query, {
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final whereParts = <String>['(title LIKE ? OR description LIKE ?)'];
    final args = <dynamic>['%${query.trim()}%', '%${query.trim()}%'];

    if (status != null) {
      whereParts.add('status = ?');
      args.add(status);
    }

    final maps = await _dbHelper.query(
      'split_expenses',
      where: whereParts.join(' AND '),
      whereArgs: args,
      orderBy: _activityOrder,
      limit: limit,
      offset: offset,
    );

    return _splitsWithDetails(maps);
  }

  // Get split count (with optional filters)
  Future<int> getSplitCount({String? status, String? searchQuery}) async {
    String query = 'SELECT COUNT(*) as count FROM split_expenses';
    final whereParts = <String>[];
    final args = <dynamic>[];

    if (status != null) {
      whereParts.add('status = ?');
      args.add(status);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereParts.add('(title LIKE ? OR description LIKE ?)');
      final searchTerm = '%${searchQuery.trim()}%';
      args.addAll([searchTerm, searchTerm]);
    }

    if (whereParts.isNotEmpty) {
      query += ' WHERE ${whereParts.join(' AND ')}';
    }

    final result = await _dbHelper.rawQuery(query, args);
    return (result.first['count'] as int?) ?? 0;
  }

  Future<List<SplitExpenseModel>> _splitsWithDetails(
    List<Map<String, dynamic>> maps,
  ) async {
    if (maps.isEmpty) return [];

    final splits = maps.map(SplitExpenseModel.fromMap).toList();
    final splitIds = splits
        .map((split) => split.id)
        .whereType<int>()
        .toList(growable: false);
    final participantsBySplitId = await _getParticipantsBySplitIds(splitIds);
    final billsBySplitId = await _getBillsBySplitIds(splitIds);

    return splits
        .map(
          (split) => split.copyWith(
            participants: participantsBySplitId[split.id] ?? const [],
            bills: billsBySplitId[split.id] ?? const [],
          ),
        )
        .toList(growable: false);
  }

  Future<Map<int, List<SplitParticipantModel>>> _getParticipantsBySplitIds(
    List<int> splitIds,
  ) async {
    if (splitIds.isEmpty) return {};

    final placeholders = List.filled(splitIds.length, '?').join(', ');
    final maps = await _dbHelper.rawQuery('''
      SELECT sp.*, c.name as contact_name, c.avatar as contact_avatar
      FROM split_participants sp
      LEFT JOIN contacts c ON sp.contact_id = c.id
      WHERE sp.split_id IN ($placeholders)
      ORDER BY sp.split_id ASC, sp.status ASC, c.name ASC
    ''', splitIds);

    final grouped = <int, List<SplitParticipantModel>>{};
    for (final map in maps) {
      final participant = SplitParticipantModel.fromMap(map);
      grouped.putIfAbsent(participant.splitId, () => []).add(participant);
    }

    return grouped;
  }

  Future<Map<int, List<SplitBillModel>>> _getBillsBySplitIds(
    List<int> splitIds,
  ) async {
    if (splitIds.isEmpty) return {};

    final placeholders = List.filled(splitIds.length, '?').join(', ');
    final maps = await _dbHelper.rawQuery('''
      SELECT sb.*, c.name as paid_by_contact_name, c.avatar as paid_by_contact_avatar
      FROM split_bills sb
      LEFT JOIN contacts c ON sb.paid_by_contact_id = c.id
      WHERE sb.split_id IN ($placeholders)
      ORDER BY sb.split_id ASC, sb.date ASC, sb.id ASC
    ''', splitIds);

    final grouped = <int, List<SplitBillModel>>{};
    for (final map in maps) {
      final bill = SplitBillModel.fromMap(map);
      grouped.putIfAbsent(bill.splitId, () => []).add(bill);
    }

    return grouped;
  }

  SplitExpenseModel _splitWithTotalsFromBills(
    SplitExpenseModel split,
    List<SplitBillModel>? bills,
  ) {
    if (bills == null || bills.isEmpty) return split;

    final totalAmount = bills.fold<double>(0, (sum, bill) => sum + bill.amount);
    final paidByUser = bills.fold<double>(
      0,
      (sum, bill) => bill.paidByUser ? sum + bill.amount : sum,
    );

    return split.copyWith(totalAmount: totalAmount, paidByUser: paidByUser);
  }

  List<SplitParticipantModel> _participantsWithExpensePaidFromBills(
    List<SplitParticipantModel> participants,
    List<SplitBillModel> bills,
  ) {
    final paidByContactId = <int, double>{};
    for (final bill in bills) {
      final contactId = bill.paidByContactId;
      if (bill.paidByUser || contactId == null) continue;

      paidByContactId.update(
        contactId,
        (amount) => amount + bill.amount,
        ifAbsent: () => bill.amount,
      );
    }

    return participants
        .map(
          (participant) => participant.copyWith(
            expensePaid: paidByContactId[participant.contactId] ?? 0,
          ),
        )
        .toList(growable: false);
  }

  List<SplitBillModel> _billsForSplit(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants, [
    List<SplitBillModel>? explicitBills,
  ]) {
    if (explicitBills != null && explicitBills.isNotEmpty) {
      return explicitBills
          .map(
            (bill) => bill.copyWith(
              splitId: split.id ?? bill.splitId,
              title: bill.title.trim().isEmpty ? split.title : bill.title,
              date: bill.date,
            ),
          )
          .toList(growable: false);
    }

    return _fallbackBillsForSplit(split, participants);
  }

  List<SplitBillModel> _fallbackBillsForSplit(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants,
  ) {
    final splitId = split.id ?? 0;
    final bills = <SplitBillModel>[];

    if (split.paidByUser > SplitSettlementCalculator.tolerance) {
      bills.add(
        SplitBillModel(
          splitId: splitId,
          title: split.title,
          amount: split.paidByUser,
          paidByUser: true,
          date: split.date,
          note: split.description,
          createdAt: split.createdAt,
          updatedAt: split.updatedAt,
        ),
      );
    }

    for (final participant in participants) {
      if (participant.expensePaid <= SplitSettlementCalculator.tolerance) {
        continue;
      }

      bills.add(
        SplitBillModel(
          splitId: splitId,
          title: split.title,
          amount: participant.expensePaid,
          paidByUser: false,
          paidByContactId: participant.contactId,
          date: split.date,
          note: split.description,
          createdAt: split.createdAt,
          updatedAt: split.updatedAt,
          paidByContactName: participant.contactName,
          paidByContactAvatar: participant.contactAvatar,
        ),
      );
    }

    if (bills.isEmpty &&
        split.totalAmount > SplitSettlementCalculator.tolerance) {
      bills.add(
        SplitBillModel(
          splitId: splitId,
          title: split.title,
          amount: split.totalAmount,
          paidByUser: true,
          date: split.date,
          note: split.description,
          createdAt: split.createdAt,
          updatedAt: split.updatedAt,
        ),
      );
    }

    return bills;
  }

  Future<void> _replaceBillsInTransaction(
    sqflite.Transaction txn,
    int splitId,
    List<SplitBillModel> bills,
  ) async {
    await txn.delete(
      'split_bills',
      where: 'split_id = ?',
      whereArgs: [splitId],
    );

    for (final bill in bills) {
      await txn.insert('split_bills', bill.copyWith(splitId: splitId).toMap());
    }
  }

  // Update split expense
  Future<int> updateSplitExpense(SplitExpenseModel split) async {
    final splitId = split.id;
    if (splitId == null) return 0;

    return _dbHelper.transaction((txn) async {
      final participants = await _getParticipantsBySplitIdInTransaction(
        txn,
        splitId,
      );
      final participantsToSave = split.bills == null
          ? participants
          : _participantsWithExpensePaidFromBills(participants, split.bills!);
      final splitToSave = _splitWithTotalsFromBills(split, split.bills);
      final updatedAt = DateTime.now();
      final result = await txn.update(
        'split_expenses',
        splitToSave.copyWith(updatedAt: updatedAt).toMap(),
        where: 'id = ?',
        whereArgs: [splitId],
      );

      await _replaceBillsInTransaction(
        txn,
        splitId,
        _billsForSplit(
          splitToSave.copyWith(id: splitId, updatedAt: updatedAt),
          participantsToSave,
          split.bills,
        ),
      );
      if (split.bills != null) {
        for (final participant in participantsToSave) {
          final amountToSettle =
              (participant.shareAmount - participant.expensePaid).abs();
          final isSettled =
              amountToSettle <= SplitSettlementCalculator.tolerance ||
              participant.paid >= amountToSettle;
          await txn.update(
            'split_participants',
            {
              'expense_paid': participant.expensePaid,
              'status': isSettled
                  ? AppConstants.statusPaid
                  : AppConstants.statusPending,
            },
            where: 'id = ?',
            whereArgs: [participant.id],
          );
        }
      }
      await _syncSplitTransactionsInTransaction(txn, splitId);

      return result;
    });
  }

  Future<void> updateSplitWithParticipants(
    SplitExpenseModel split, [
    List<SplitParticipantModel>? participants,
    List<SplitBillModel>? bills,
  ]) async {
    final splitId = split.id;
    if (splitId == null) return;

    await _dbHelper.transaction((txn) async {
      final existingParticipants = participants == null
          ? await _getParticipantsBySplitIdInTransaction(txn, splitId)
          : null;
      final participantsSource = participants ?? existingParticipants ?? [];
      final explicitBills = bills ?? split.bills;
      final splitToSave = _splitWithTotalsFromBills(split, explicitBills);
      final participantsToSave = explicitBills == null
          ? participantsSource
          : _participantsWithExpensePaidFromBills(
              participantsSource,
              explicitBills,
            );

      final updatedAt = DateTime.now();
      await txn.update(
        'split_expenses',
        splitToSave.copyWith(updatedAt: updatedAt).toMap(),
        where: 'id = ?',
        whereArgs: [splitId],
      );

      if (participants != null) {
        await txn.delete(
          'split_participants',
          where: 'split_id = ?',
          whereArgs: [splitId],
        );

        for (final participant in participantsToSave) {
          await txn.insert(
            'split_participants',
            participant.copyWith(splitId: splitId).toMap(),
          );
        }
      }

      await _replaceBillsInTransaction(
        txn,
        splitId,
        _billsForSplit(
          splitToSave.copyWith(id: splitId, updatedAt: updatedAt),
          participantsToSave,
          explicitBills,
        ),
      );

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

      await txn.delete('split_bills', where: 'split_id = ?', whereArgs: [id]);

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
    final maps = await _dbHelper.query(
      'split_expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    return _splitsWithDetails(maps);
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
    final maps = await _dbHelper.rawQuery(
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

    return _splitsWithDetails(maps);
  }

  // Bulk update participants for a split
  Future<void> updateSplitParticipants(
    int splitId,
    List<SplitParticipantModel> participants,
  ) async {
    await _dbHelper.transaction((txn) async {
      final split = await _getSplitByIdInTransaction(txn, splitId);
      if (split == null) return;

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

      await _replaceBillsInTransaction(
        txn,
        splitId,
        _fallbackBillsForSplit(split, participants),
      );

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
