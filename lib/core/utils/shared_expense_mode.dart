import '../../data/models/transaction_model.dart';

/// Presentation/storage shape of a two-person `shared_spend` transaction.
///
/// The app intentionally keeps this as a derived value. Existing backups and
/// database rows do not need a new mode column or migration.
enum SharedExpenseMode {
  paidOnBehalf,
  sharedCost,
  legacy,
}

class SharedExpenseModeResolver {
  const SharedExpenseModeResolver._();

  static const double _tolerance = 0.01;

  static SharedExpenseMode forTransaction(TransactionModel transaction) {
    if (!transaction.isSharedSpend) return SharedExpenseMode.legacy;

    final userShare = transaction.sharedUserShare;
    final contactShare = transaction.sharedContactShare;
    if (userShare == null || contactShare == null) {
      return SharedExpenseMode.legacy;
    }

    final userShareIsPositive = userShare > _tolerance;
    final contactShareIsPositive = contactShare > _tolerance;
    if (userShareIsPositive && contactShareIsPositive) {
      return SharedExpenseMode.sharedCost;
    }

    final total = transaction.sharedTotalAmount;
    final totalMatchesAmount =
        total != null && (total - transaction.amount).abs() <= _tolerance;
    final exactlyOneShareIsZero = userShareIsPositive != contactShareIsPositive;
    if (totalMatchesAmount && exactlyOneShareIsZero) {
      return SharedExpenseMode.paidOnBehalf;
    }

    return SharedExpenseMode.legacy;
  }
}

class SharedExpenseAmounts {
  final double? totalAmount;
  final double? userShare;
  final double? contactShare;

  const SharedExpenseAmounts({
    required this.totalAmount,
    required this.userShare,
    required this.contactShare,
  });

  factory SharedExpenseAmounts.paidOnBehalf({
    required double amount,
    required bool paidByUser,
  }) {
    return SharedExpenseAmounts(
      totalAmount: amount,
      userShare: paidByUser ? 0 : amount,
      contactShare: paidByUser ? amount : 0,
    );
  }

  factory SharedExpenseAmounts.sharedCost({
    required double? totalAmount,
    required double counterpartyShare,
    required bool paidByUser,
  }) {
    return SharedExpenseAmounts(
      totalAmount: totalAmount,
      userShare: paidByUser
          ? (totalAmount == null ? null : totalAmount - counterpartyShare)
          : counterpartyShare,
      contactShare: paidByUser
          ? counterpartyShare
          : (totalAmount == null ? null : totalAmount - counterpartyShare),
    );
  }
}
