import 'package:borrow_ledger/data/models/contact_model.dart';
import 'package:borrow_ledger/data/models/contact_settlement_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contact UPI ID survives model serialization', () {
    final contact = ContactModel(
      id: 1,
      name: 'Asha',
      phone: '9999999999',
      upiId: 'asha@bank',
    );

    final restored = ContactModel.fromMap(contact.toMap());

    expect(restored.upiId, 'asha@bank');
  });

  test('settlement metadata defaults to manual for old data', () {
    final settlement = ContactSettlementModel.fromMap({
      'id': 1,
      'contact_id': 2,
      'net_amount': 100.0,
      'direction': 'lend',
      'direct_cleared': 100.0,
      'split_cleared': 0.0,
      'offset_amount': 0.0,
      'is_partial': 0,
      'note': null,
      'date': DateTime(2026, 1, 1).toIso8601String(),
      'created_at': DateTime(2026, 1, 1).toIso8601String(),
      'updated_at': DateTime(2026, 1, 1).toIso8601String(),
    });

    expect(settlement.settlementMethod, 'manual');
    expect(settlement.paymentReference, isNull);
  });

  test('settlement metadata survives serialization', () {
    final settlement = ContactSettlementModel(
      contactId: 2,
      netAmount: 100,
      direction: 'borrow',
      settlementMethod: 'upi',
      paymentReference: 'UPI123',
      date: DateTime(2026, 1, 1),
    );

    final restored = ContactSettlementModel.fromMap(settlement.toMap());

    expect(restored.settlementMethod, 'upi');
    expect(restored.paymentReference, 'UPI123');
  });
}
