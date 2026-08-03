import 'package:borrow_ledger/core/constants/app_constants.dart';
import 'package:borrow_ledger/core/utils/split_settlement_calculator.dart';
import 'package:borrow_ledger/data/models/split_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplitSettlementCalculator', () {
    test('keeps participant-to-participant dues pending', () {
      final split = SplitExpenseModel(
        id: 1,
        title: 'Dinner',
        totalAmount: 300,
        paidByUser: 0,
        date: DateTime(2026, 8, 3),
        status: AppConstants.statusPending,
      );
      final participantB = SplitParticipantModel(
        id: 10,
        splitId: 1,
        contactId: 2,
        shareAmount: 0,
        expensePaid: 300,
        paid: 0,
        status: AppConstants.statusPending,
        contactName: 'B',
      );
      final participantC = SplitParticipantModel(
        id: 11,
        splitId: 1,
        contactId: 3,
        shareAmount: 225,
        expensePaid: 0,
        paid: 0,
        status: AppConstants.statusPending,
        contactName: 'C',
      );

      final settlements = SplitSettlementCalculator.calculate(split, [
        participantB,
        participantC,
      ]);

      expect(
        SplitSettlementCalculator.userShare(split, [
          participantB,
          participantC,
        ]),
        75,
      );
      expect(
        SplitSettlementCalculator.userBalance(split, [
          participantB,
          participantC,
        ]),
        -75,
      );

      final userSettlement = settlements.singleWhere(
        (settlement) => settlement.participant.contactName == 'B',
      );
      expect(userSettlement.affectsUser, isTrue);
      expect(userSettlement.participantOwes, isFalse);
      expect(userSettlement.userReceives, isFalse);
      expect(userSettlement.remainingAmount, 75);

      final participantSettlement = settlements.singleWhere(
        (settlement) => settlement.participant.contactName == 'C',
      );
      expect(participantSettlement.affectsUser, isFalse);
      expect(participantSettlement.participantOwes, isTrue);
      expect(participantSettlement.counterpartyName, 'B');
      expect(participantSettlement.remainingAmount, 225);
    });

    test('subtracts debtor settlement payments from participant dues', () {
      final split = SplitExpenseModel(
        id: 1,
        title: 'Dinner',
        totalAmount: 300,
        paidByUser: 0,
        date: DateTime(2026, 8, 3),
        status: AppConstants.statusPending,
      );
      final participantB = SplitParticipantModel(
        id: 10,
        splitId: 1,
        contactId: 2,
        shareAmount: 0,
        expensePaid: 300,
        paid: 0,
        status: AppConstants.statusPending,
        contactName: 'B',
      );
      final participantC = SplitParticipantModel(
        id: 11,
        splitId: 1,
        contactId: 3,
        shareAmount: 225,
        expensePaid: 0,
        paid: 100,
        status: AppConstants.statusPending,
        contactName: 'C',
      );

      final settlements = SplitSettlementCalculator.calculate(split, [
        participantB,
        participantC,
      ]);
      final participantSettlement = settlements.singleWhere(
        (settlement) => settlement.participant.contactName == 'C',
      );

      expect(participantSettlement.remainingAmount, 125);
    });
  });
}
