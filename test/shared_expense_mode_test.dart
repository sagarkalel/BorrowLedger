import 'package:borrow_ledger/core/constants/app_constants.dart';
import 'package:borrow_ledger/core/utils/shared_expense_mode.dart';
import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionModel _sharedTransaction({
  required double amount,
  double? total,
  double? userShare,
  double? contactShare,
}) {
  return TransactionModel(
    type: AppConstants.typeBorrow,
    category: AppConstants.categorySharedSpend,
    contactId: 1,
    amount: amount,
    date: DateTime(2026, 1, 1),
    sharedTotalAmount: total,
    sharedUserShare: userShare,
    sharedContactShare: contactShare,
    sharedPaidByUser: false,
  );
}

void main() {
  test('paid-on-behalf amounts encode the full amount and zero share', () {
    final userPaid = SharedExpenseAmounts.paidOnBehalf(
      amount: 800,
      paidByUser: true,
    );
    final contactPaid = SharedExpenseAmounts.paidOnBehalf(
      amount: 800,
      paidByUser: false,
    );

    expect(userPaid.totalAmount, 800);
    expect(userPaid.userShare, 0);
    expect(userPaid.contactShare, 800);
    expect(contactPaid.totalAmount, 800);
    expect(contactPaid.userShare, 800);
    expect(contactPaid.contactShare, 0);
  });

  test('shared-cost amounts preserve the existing share formulas', () {
    final userPaid = SharedExpenseAmounts.sharedCost(
      totalAmount: 1000,
      counterpartyShare: 400,
      paidByUser: true,
    );
    final contactPaid = SharedExpenseAmounts.sharedCost(
      totalAmount: 1000,
      counterpartyShare: 400,
      paidByUser: false,
    );

    expect(userPaid.userShare, 600);
    expect(userPaid.contactShare, 400);
    expect(contactPaid.userShare, 400);
    expect(contactPaid.contactShare, 600);
  });

  test('classifies paid-on-behalf, shared-cost, and legacy records', () {
    expect(
      SharedExpenseModeResolver.forTransaction(
        _sharedTransaction(
          amount: 800,
          total: 800,
          userShare: 800,
          contactShare: 0,
        ),
      ),
      SharedExpenseMode.paidOnBehalf,
    );
    expect(
      SharedExpenseModeResolver.forTransaction(
        _sharedTransaction(
          amount: 400,
          total: 1000,
          userShare: 400,
          contactShare: 600,
        ),
      ),
      SharedExpenseMode.sharedCost,
    );
    expect(
      SharedExpenseModeResolver.forTransaction(
        _sharedTransaction(amount: 400, userShare: 400),
      ),
      SharedExpenseMode.legacy,
    );
  });
}
