import 'package:borrow_ledger/core/services/upi_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpiService', () {
    test('normalizes and validates UPI IDs', () {
      expect(UpiService.normalizeUpiId('  User@Bank  '), 'user@bank');
      expect(UpiService.isValidUpiId('user@bank'), isTrue);
      expect(UpiService.isValidUpiId('user name@bank'), isFalse);
      expect(UpiService.isValidUpiId('user@'), isFalse);
      expect(UpiService.isValidUpiId(null), isFalse);
    });

    test('builds an encoded INR payment URI', () {
      final uri = UpiService.buildPaymentUri(
        payeeUpiId: 'person@bank',
        payeeName: 'Asha & Co',
        amount: 1250,
        note: 'HisaabMate settlement',
      );

      expect(uri.scheme, 'upi');
      expect(uri.host, 'pay');
      expect(uri.queryParameters['pa'], 'person@bank');
      expect(uri.queryParameters['pn'], 'Asha & Co');
      expect(uri.queryParameters['am'], '1250.00');
      expect(uri.queryParameters['cu'], 'INR');
      expect(uri.queryParameters['tn'], 'HisaabMate settlement');
      expect(uri.toString(), contains('Asha+%26+Co'));
    });

    test('rejects invalid IDs and non-positive amounts', () {
      expect(
        () => UpiService.buildPaymentUri(
          payeeUpiId: 'invalid',
          payeeName: 'Person',
          amount: 10,
          note: 'Test',
        ),
        throwsArgumentError,
      );
      expect(
        () => UpiService.buildPaymentUri(
          payeeUpiId: 'person@bank',
          payeeName: 'Person',
          amount: 0,
          note: 'Test',
        ),
        throwsArgumentError,
      );
    });
  });
}
