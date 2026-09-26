import 'package:borrow_ledger/core/services/share_message_builder.dart';
import 'package:borrow_ledger/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tr = AppLocalizationsEn();

  test('builds a friendly UPI request with the owner name', () {
    final message = ShareMessageBuilder.upiRequest(
      tr: tr,
      contactName: 'Rahul',
      amount: '₹ 500',
      ownerName: 'Sagar',
      upiUri: 'upi://pay/example',
    );

    expect(
      message,
      'Hi Rahul 👋\n\n'
      'Could you please send ₹ 500 to Sagar (me) to settle our balance on '
      'HisaabMate?\n\n'
      'UPI link:\nupi://pay/example\n\n'
      'Thanks,\nSagar',
    );
    expect(message, isNot(contains('send ₹ 500 to me')));
  });

  test('builds friendly payment, statement, and invoice messages', () {
    final paymentMessage = ShareMessageBuilder.upiPaymentDetails(
      tr: tr,
      contactName: 'Rahul',
      amount: '₹ 500',
      ownerName: 'Sagar',
      upiUri: 'upi://pay/example',
    );
    final contactStatement = ShareMessageBuilder.contactStatement(
      tr: tr,
      contactName: 'Rahul',
      dateRange: '01 Jan - 31 Jan',
      ownerName: 'Sagar',
    );
    final ledgerStatement = ShareMessageBuilder.ledgerStatement(
      tr: tr,
      dateRange: '01 Jan - 31 Jan',
      ownerName: 'Sagar',
    );
    final splitInvoice = ShareMessageBuilder.splitInvoice(
      tr: tr,
      splitTitle: 'Dinner',
      ownerName: 'Sagar',
    );

    expect(paymentMessage, contains('Here’s the UPI link for ₹ 500'));
    expect(paymentMessage, contains('Thanks,\nSagar'));
    expect(contactStatement, contains('Hi Rahul 👋'));
    expect(contactStatement, contains('01 Jan - 31 Jan'));
    expect(ledgerStatement, contains('Hi everyone 👋'));
    expect(splitInvoice, contains('HisaabMate split invoice for “Dinner”'));
    expect(splitInvoice, contains('Thanks,\nSagar'));
  });
}
