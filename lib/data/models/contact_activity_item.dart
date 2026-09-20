import 'package:borrow_ledger/data/models/contact_settlement_model.dart';
import 'package:borrow_ledger/data/models/transaction_model.dart';

enum ContactActivityKind { transaction, settlement }

class ContactActivityItem {
  final ContactActivityKind kind;
  final TransactionModel? transaction;
  final ContactSettlementModel? settlement;

  const ContactActivityItem._({
    required this.kind,
    this.transaction,
    this.settlement,
  });

  const ContactActivityItem.transaction(TransactionModel transaction)
    : this._(kind: ContactActivityKind.transaction, transaction: transaction);

  const ContactActivityItem.settlement(ContactSettlementModel settlement)
    : this._(kind: ContactActivityKind.settlement, settlement: settlement);

  DateTime get date => transaction?.date ?? settlement!.date;
  DateTime get updatedAt => transaction?.updatedAt ?? settlement!.updatedAt;
  DateTime get createdAt => transaction?.createdAt ?? settlement!.createdAt;
}
