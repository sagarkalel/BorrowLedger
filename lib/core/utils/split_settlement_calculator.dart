import 'package:borrow_ledger/data/models/split_model.dart';

class SplitSettlementResult {
  final SplitParticipantModel participant;
  final bool affectsUser;
  final bool participantOwes;
  final bool userReceives;
  final String counterpartyName;
  final double totalAmount;
  final double settledAmount;
  final double remainingAmount;

  const SplitSettlementResult({
    required this.participant,
    required this.affectsUser,
    required this.participantOwes,
    required this.userReceives,
    required this.counterpartyName,
    required this.totalAmount,
    required this.settledAmount,
    required this.remainingAmount,
  });
}

class SplitSettlementParty {
  final SplitParticipantModel? participant;
  final String name;
  double amount;

  SplitSettlementParty({
    required this.participant,
    required this.name,
    required this.amount,
  });

  bool get isUser => participant == null;
}

class SplitSettlementCalculator {
  static const double tolerance = 0.01;

  static double userShare(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants,
  ) {
    final participantShares = participants.fold<double>(
      0,
      (sum, participant) => sum + participant.shareAmount,
    );
    return split.totalAmount - participantShares;
  }

  static double userBalance(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants,
  ) {
    final settlements = calculate(split, participants);
    final receivable = settlements
        .where(
          (settlement) => settlement.affectsUser && settlement.userReceives,
        )
        .fold<double>(0, (sum, settlement) => sum + settlement.remainingAmount);
    final payable = settlements
        .where(
          (settlement) => settlement.affectsUser && !settlement.userReceives,
        )
        .fold<double>(0, (sum, settlement) => sum + settlement.remainingAmount);
    return receivable > 0 ? receivable : -payable;
  }

  static List<SplitSettlementResult> calculate(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants, {
    String userName = 'you',
    String unknownName = 'Unknown',
  }) {
    final userNet = split.paidByUser - userShare(split, participants);
    final settlements = <SplitSettlementResult>[];
    final participantIdsWithSettlements = <int>{};
    final creditors = <SplitSettlementParty>[];
    final debtors = <SplitSettlementParty>[];

    if (userNet > tolerance) {
      creditors.add(
        SplitSettlementParty(
          participant: null,
          name: userName,
          amount: userNet,
        ),
      );
    } else if (userNet < -tolerance) {
      debtors.add(
        SplitSettlementParty(
          participant: null,
          name: userName,
          amount: -userNet,
        ),
      );
    }

    for (final participant in participants) {
      final net = participant.expensePaid - participant.shareAmount;

      if (net > tolerance) {
        creditors.add(
          SplitSettlementParty(
            participant: participant,
            name: participant.contactName ?? unknownName,
            amount: net,
          ),
        );
      } else if (net < -tolerance) {
        final unsettledAmount = net.abs() - participant.paid;
        if (unsettledAmount <= tolerance) continue;

        debtors.add(
          SplitSettlementParty(
            participant: participant,
            name: participant.contactName ?? unknownName,
            amount: unsettledAmount,
          ),
        );
      }
    }

    var debtorIndex = 0;
    var creditorIndex = 0;
    while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
      final debtor = debtors[debtorIndex];
      final creditor = creditors[creditorIndex];
      final amount = debtor.amount < creditor.amount
          ? debtor.amount
          : creditor.amount;

      if (amount > tolerance) {
        final debtorParticipant = debtor.participant;
        final creditorParticipant = creditor.participant;

        if (debtorParticipant != null) {
          final remaining = amount;
          settlements.add(
            SplitSettlementResult(
              participant: debtorParticipant,
              affectsUser: creditor.isUser,
              participantOwes: true,
              userReceives: creditor.isUser,
              counterpartyName: creditor.name,
              totalAmount: amount,
              settledAmount: debtorParticipant.paid,
              remainingAmount: remaining <= tolerance ? 0 : remaining,
            ),
          );
          final participantId = debtorParticipant.id;
          if (participantId != null) {
            participantIdsWithSettlements.add(participantId);
          }
        } else if (creditorParticipant != null) {
          final remaining = amount - creditorParticipant.paid;
          settlements.add(
            SplitSettlementResult(
              participant: creditorParticipant,
              affectsUser: true,
              participantOwes: false,
              userReceives: false,
              counterpartyName: debtor.name,
              totalAmount: amount,
              settledAmount: creditorParticipant.paid,
              remainingAmount: remaining <= tolerance ? 0 : remaining,
            ),
          );
          final participantId = creditorParticipant.id;
          if (participantId != null) {
            participantIdsWithSettlements.add(participantId);
          }
        }
      }

      debtor.amount -= amount;
      creditor.amount -= amount;
      if (debtor.amount <= tolerance) debtorIndex++;
      if (creditor.amount <= tolerance) creditorIndex++;
    }

    for (final participant in participants) {
      final participantId = participant.id;
      if (participantId != null &&
          participantIdsWithSettlements.contains(participantId)) {
        continue;
      }

      settlements.add(
        SplitSettlementResult(
          participant: participant,
          affectsUser: false,
          participantOwes: false,
          userReceives: false,
          counterpartyName: '',
          totalAmount: 0,
          settledAmount: participant.paid,
          remainingAmount: 0,
        ),
      );
    }

    return settlements;
  }
}
