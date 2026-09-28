import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/core/services/upi_service.dart';
import 'package:borrow_ledger/presentation/widgets/upi_id_setup_sheet.dart';
import 'package:borrow_ledger/presentation/widgets/upi_app_picker_sheet.dart';
import 'package:borrow_ledger/presentation/widgets/upi_phone_payment_sheet.dart';
import 'package:borrow_ledger/presentation/widgets/upi_settlement_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    expect(find.text('Pay using UPI ID'), findsOneWidget);
    expect(find.text('Share payment details'), findsNothing);
    expect(find.text('Use phone number in UPI app'), findsNothing);
  });

  testWidgets('phone helper appears only when explicitly enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showUpiSettlementActionSheet(
              context,
              isPayable: true,
              contactName: 'Rohit',
              amount: 350,
              contactPhone: '9373061711',
              showPhoneOption: true,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Pay using phone number'), findsOneWidget);
    expect(
      find.text(
        'Copy the number and search for the contact manually in your UPI app',
      ),
      findsOneWidget,
    );
  });

  testWidgets('phone payment sheet uses one combined copy and open action', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => null,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showUpiPhonePaymentSheet(
              context,
              contactName: 'Rohit',
              phoneNumber: '9373061711',
              amount: 350,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Pay using phone number'), findsOneWidget);
    expect(find.text('Rohit'), findsOneWidget);
    expect(find.textContaining('9373061711'), findsOneWidget);
    expect(find.text('₹ 350'), findsOneWidget);

    expect(find.text('Copy number & open UPI app'), findsOneWidget);
    final actionButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(actionButton.onPressed, isNotNull);
  });

  testWidgets('branded UPI app picker shows and returns the selected app', (
    tester,
  ) async {
    String? selectedPackage;

    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              selectedPackage = await showUpiAppPickerSheet(
                context,
                apps: const [
                  UpiAppInfo(
                    packageName: 'com.google.android.apps.nbu.paisa.user',
                    label: 'Google Pay',
                  ),
                  UpiAppInfo(packageName: 'com.phonepe.app', label: 'PhonePe'),
                ],
                contactName: 'Rohit',
                phoneNumber: '9373061711',
                amount: 350,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Open UPI app'), findsOneWidget);
    expect(find.text('Google Pay'), findsOneWidget);
    expect(find.text('PhonePe'), findsOneWidget);
    expect(find.textContaining('9373061711'), findsOneWidget);

    await tester.tap(find.text('PhonePe'));
    await tester.pumpAndSettle();

    expect(selectedPackage, 'com.phonepe.app');
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
