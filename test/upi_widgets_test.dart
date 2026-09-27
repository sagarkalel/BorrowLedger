import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/upi_id_setup_sheet.dart';
import 'package:borrow_ledger/presentation/widgets/upi_settlement_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('UPI action sheet shows contextual actions', (tester) async {
    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showUpiSettlementActionSheet(
              context,
              isPayable: false,
              contactName: 'Rahul',
              amount: 1250,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('UPI settlement'), findsOneWidget);
    expect(find.text('Request via UPI'), findsOneWidget);
    expect(find.text('Share request'), findsNothing);
    expect(find.text('Rahul'), findsOneWidget);
    expect(find.text('₹ 1,250'), findsOneWidget);
  });

  testWidgets('payable UPI sheet shows only the direct payment action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showUpiSettlementActionSheet(
              context,
              isPayable: true,
              contactName: 'Rahul',
              amount: 1250,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Pay by UPI'), findsOneWidget);
    expect(find.text('Share payment details'), findsNothing);
  });

  testWidgets('UPI setup validates and saves before closing', (tester) async {
    String? savedUpiId;

    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showUpiIdSetupSheet(
              context,
              owner: UpiIdSetupOwner.profile,
              displayName: 'Me',
              onSave: (upiId) async {
                savedUpiId = upiId;
                return true;
              },
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Add your UPI ID'), findsOneWidget);

    await tester.tap(find.text('Save & continue'));
    await tester.pump();
    expect(find.text('Enter a valid UPI ID'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'me@bank');
    await tester.tap(find.text('Save & continue'));
    await tester.pumpAndSettle();

    expect(savedUpiId, 'me@bank');
    expect(find.text('Add your UPI ID'), findsNothing);
  });
}
