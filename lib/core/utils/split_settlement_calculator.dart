import 'package:borrow_ledger/core/constants/app_constants.dart';
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

class SplitSettlementRouteEntry {
  final SplitSettlementParty from;
  final SplitSettlementParty to;
  final double amount;

  SplitSettlementRouteEntry({
    required this.from,
    required this.to,
    required this.amount,
  });

  bool get affectsUser => from.isUser || to.isUser;
  bool get userReceives => to.isUser;
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
    final routeEntries = calculateRouteEntries(
      split,
      participants,
      userName: userName,
      unknownName: unknownName,
    );
    final settlements = <SplitSettlementResult>[];
    final participantIdsWithSettlements = <int>{};

    for (final entry in routeEntries) {
      final amount = entry.amount;
      if (amount <= tolerance) continue;

      final debtorParticipant = entry.from.participant;
      final creditorParticipant = entry.to.participant;

      if (debtorParticipant != null) {
        settlements.add(
          SplitSettlementResult(
            participant: debtorParticipant,
            affectsUser: entry.affectsUser,
            participantOwes: true,
            userReceives: entry.userReceives,
            counterpartyName: entry.to.name,
            totalAmount: amount,
            settledAmount: debtorParticipant.paid,
            remainingAmount: amount <= tolerance ? 0 : amount,
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
            affectsUser: entry.affectsUser,
            participantOwes: false,
            userReceives: entry.userReceives,
            counterpartyName: entry.from.name,
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

  static List<SplitSettlementRouteEntry> calculateRouteEntries(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants, {
    String userName = 'you',
    String unknownName = 'Unknown',
  }) {
    final optimizedEntries = _calculateOptimizedRouteEntries(
      split,
      participants,
      userName: userName,
      unknownName: unknownName,
    );

    if (split.settlementRouteMode != AppConstants.splitRouteMediator ||
        participants.length < 2) {
      return optimizedEntries;
    }

    final mediator = _findMediatorParty(
      participants,
      split.settlementMediatorContactId,
      userName,
      unknownName,
    );
    if (mediator == null) return optimizedEntries;

    final routedEntries = <SplitSettlementRouteEntry>[];
    for (final entry in optimizedEntries) {
      if (entry.amount <= tolerance) continue;

      if (_sameParty(entry.from, mediator) || _sameParty(entry.to, mediator)) {
        routedEntries.add(entry);
      } else {
        routedEntries.add(
          SplitSettlementRouteEntry(
            from: entry.from,
            to: mediator,
            amount: entry.amount,
          ),
        );
        routedEntries.add(
          SplitSettlementRouteEntry(
            from: mediator,
            to: entry.to,
            amount: entry.amount,
          ),
        );
      }
    }

    return _mergeRouteEntries(routedEntries);
  }

  static List<SplitSettlementRouteEntry> _calculateOptimizedRouteEntries(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants, {
    required String userName,
    required String unknownName,
  }) {
    final userNet = split.paidByUser - userShare(split, participants);
    final creditors = <SplitSettlementParty>[];
    final debtors = <SplitSettlementParty>[];
    final entries = <SplitSettlementRouteEntry>[];

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
        final unsettledAmount = net - participant.paid;
        if (unsettledAmount <= tolerance) continue;

        creditors.add(
          SplitSettlementParty(
            participant: participant,
            name: participant.contactName ?? unknownName,
            amount: unsettledAmount,
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
        entries.add(
          SplitSettlementRouteEntry(from: debtor, to: creditor, amount: amount),
        );
      }

      debtor.amount -= amount;
      creditor.amount -= amount;
      if (debtor.amount <= tolerance) debtorIndex++;
      if (creditor.amount <= tolerance) creditorIndex++;
    }

    return entries;
  }

  static SplitSettlementParty? _findMediatorParty(
    List<SplitParticipantModel> participants,
    int? mediatorContactId,
    String userName,
    String unknownName,
  ) {
    if (mediatorContactId == null) {
      return SplitSettlementParty(participant: null, name: userName, amount: 0);
    }

    for (final participant in participants) {
      if (participant.contactId == mediatorContactId) {
        return SplitSettlementParty(
          participant: participant,
          name: participant.contactName ?? unknownName,
          amount: 0,
        );
      }
    }

    return null;
  }

  static bool _sameParty(
    SplitSettlementParty first,
    SplitSettlementParty second,
  ) {
    if (first.isUser || second.isUser) return first.isUser && second.isUser;
    return first.participant?.contactId == second.participant?.contactId;
  }

  static List<SplitSettlementRouteEntry> _mergeRouteEntries(
    List<SplitSettlementRouteEntry> entries,
  ) {
    final merged = <String, SplitSettlementRouteEntry>{};

    for (final entry in entries) {
      if (entry.amount <= tolerance || _sameParty(entry.from, entry.to)) {
        continue;
      }

      final fromKey = entry.from.isUser
          ? 'user'
          : 'contact:${entry.from.participant!.contactId}';
      final toKey = entry.to.isUser
          ? 'user'
          : 'contact:${entry.to.participant!.contactId}';
      final key = '$fromKey->$toKey';
      final existing = merged[key];

      merged[key] = SplitSettlementRouteEntry(
        from: entry.from,
        to: entry.to,
        amount: (existing?.amount ?? 0) + entry.amount,
      );
    }

    return merged.values.toList();
  }
}
