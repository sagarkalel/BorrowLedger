import 'package:borrow_ledger/core/constants/app_constants.dart';
import 'package:borrow_ledger/core/utils/split_settlement_calculator.dart';
import 'package:borrow_ledger/data/models/split_model.dart';
import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class SplitTransactionSyncHelper {
  static Future<void> syncSplitTransactionsInTransaction(
    sqflite.Transaction txn,
    int splitId, {
    bool refreshPendingActivity = true,
  }) async {
    final split = await getSplitWithParticipantsInTransaction(txn, splitId);
    if (split == null) return;

    await deleteGeneratedTransactionsInTransaction(txn, splitId);

    final participants = split.participants ?? const <SplitParticipantModel>[];
    final syncedAt = refreshPendingActivity ? DateTime.now() : split.updatedAt;

    if (participants.isEmpty || split.status == AppConstants.statusSettled) {
      await _markSplitTransactionsSyncedInTransaction(txn, splitId, syncedAt);
      return;
    }

    final routeEntries = SplitSettlementCalculator.calculateRouteEntries(
      split,
      participants,
    );
    final pendingRouteEntries = routeEntries
        .where((entry) => entry.amount > SplitSettlementCalculator.tolerance)
        .toList();

    for (final entry in pendingRouteEntries) {
      if (!entry.affectsUser) continue;

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
        updatedAt: syncedAt,
      );
    }

    await _updateSplitStatusFromRoutesInTransaction(
      txn,
      splitId,
      currentStatus: split.status,
      hasPendingRoutes: pendingRouteEntries.isNotEmpty,
      updatedAt: syncedAt,
      refreshPendingActivity: refreshPendingActivity,
    );
    await _markSplitTransactionsSyncedInTransaction(txn, splitId, syncedAt);
  }

  static Future<SplitExpenseModel?> getSplitWithParticipantsInTransaction(
    sqflite.Transaction txn,
    int splitId,
  ) async {
    final splitRows = await txn.query(
      'split_expenses',
      where: 'id = ?',
      whereArgs: [splitId],
      limit: 1,
    );
    if (splitRows.isEmpty) return null;

    final participantRows = await txn.rawQuery(
      '''
      SELECT sp.*, c.name AS contact_name, c.avatar AS contact_avatar
      FROM split_participants sp
      LEFT JOIN contacts c ON c.id = sp.contact_id
      WHERE sp.split_id = ?
      ORDER BY sp.id ASC
      ''',
      [splitId],
    );

    final billRows = await txn.rawQuery(
      '''
      SELECT sb.*, c.name AS paid_by_contact_name
      FROM split_bills sb
      LEFT JOIN contacts c ON sb.paid_by_contact_id = c.id
      WHERE sb.split_id = ?
      ORDER BY sb.id ASC
      ''',
      [splitId],
    );

    return SplitExpenseModel.fromMap(splitRows.first).copyWith(
      participants: participantRows.map(SplitParticipantModel.fromMap).toList(),
      bills: billRows.map(SplitBillModel.fromMap).toList(),
    );
  }

  static Future<void> deleteGeneratedTransactionsInTransaction(
    sqflite.Transaction txn,
    int splitId,
  ) async {
    await txn.delete(
      'transactions',
      where: 'source_type = ? AND source_id = ?',
      whereArgs: [AppConstants.sourceTypeSplit, splitId],
    );
  }

  static Future<void> _createGeneratedTransactionInTransaction(
    sqflite.Transaction txn, {
    required SplitExpenseModel split,
    required SplitParticipantModel participant,
    required String type,
    required double amount,
    required DateTime updatedAt,
  }) async {
    if (amount <= SplitSettlementCalculator.tolerance) return;

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
        updatedAt: updatedAt,
        sourceType: AppConstants.sourceTypeSplit,
        sourceId: split.id,
      ).toMap(),
    );
  }

  static Future<void> _markSplitTransactionsSyncedInTransaction(
    sqflite.Transaction txn,
    int splitId,
    DateTime syncedAt,
  ) async {
    await txn.update(
      'split_expenses',
      {'generated_synced_at': syncedAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [splitId],
    );
  }

  static Future<void> _updateSplitStatusFromRoutesInTransaction(
    sqflite.Transaction txn,
    int splitId, {
    required String currentStatus,
    required bool hasPendingRoutes,
    required DateTime updatedAt,
    required bool refreshPendingActivity,
  }) async {
    if (!hasPendingRoutes) {
      await txn.update(
        'split_expenses',
        {
          'status': AppConstants.statusSettled,
          'updated_at': updatedAt.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [splitId],
      );
      return;
    }

    if (currentStatus != AppConstants.statusPending || refreshPendingActivity) {
      await txn.update(
        'split_expenses',
        {
          'status': AppConstants.statusPending,
          'updated_at': updatedAt.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [splitId],
      );
    }
  }
}
