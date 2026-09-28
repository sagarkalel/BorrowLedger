import 'package:borrow_ledger/core/constants/app_constants.dart';
import 'package:borrow_ledger/data/models/contact_model.dart';
import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:borrow_ledger/data/repositories/contact_repository.dart';
import 'package:borrow_ledger/data/repositories/split_repository.dart';
import 'package:borrow_ledger/data/repositories/transaction_repository.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/cubit/borrow_lend_cubit.dart';
import 'package:borrow_ledger/presentation/cubit/split_cubit.dart';
import 'package:borrow_ledger/presentation/screens/add_split_screen.dart';
import 'package:borrow_ledger/presentation/screens/add_transaction_screen.dart';
import 'package:borrow_ledger/presentation/widgets/add_transaction_menu.dart';
import 'package:borrow_ledger/presentation/widgets/contact_summary_card.dart';
import 'package:borrow_ledger/presentation/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeContactRepository extends ContactRepository {
  @override
  Future<List<ContactModel>> getContactsForPicker() async => [
    ContactModel(id: 1, name: 'Rahul', phone: '9999999999'),
  ];

  @override
  Future<ContactSummary?> getContactById(int contactId) async {
    if (contactId != 1) return null;
    return ContactSummary(
      contact: ContactModel(id: 1, name: 'Rahul', phone: '9999999999'),
      transactionCount: 0,
      totalLent: 0,
      totalBorrowed: 0,
      netBalance: 0,
      lastTransactionDate: null,
    );
  }

  @override
  Future<ContactModel?> getContactByPhone(String phone) async => null;

  @override
  Future<List<ContactSummary>> getAllContacts({
    int? limit,
    int? offset,
  }) async => [];
}

Widget _localizedApp(Widget home) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

void main() {
  testWidgets('add menu uses the final expense terminology', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showAddTransactionMenu(context, () {}),
              child: const Text('Open menu'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open menu'));
    await tester.pumpAndSettle();

    expect(find.text('What do you want to add?'), findsOneWidget);
    expect(find.text('Udhari'), findsOneWidget);
    expect(
      find.text('Items or services bought or sold on credit.'),
      findsOneWidget,
    );
    expect(find.text('Expense with Someone'), findsOneWidget);
    expect(
      find.text('You paid for them or they paid for you.'),
      findsOneWidget,
    );
    expect(find.text('Group Expense'), findsOneWidget);
    expect(
      find.text('Split one expense with multiple people.'),
      findsOneWidget,
    );
  });

  testWidgets('shared expense form uses clear payer choices', (tester) async {
    final contactRepository = _FakeContactRepository();

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ContactRepository>.value(value: contactRepository),
        ],
        child: BlocProvider(
          create: (_) =>
              BorrowLendCubit(TransactionRepository(), SplitRepository()),
          child: _localizedApp(
            AddTransactionScreen(
              transactionType: AppConstants.typeLend,
              transactionCategory: AppConstants.categorySharedSpend,
              prefilledContactId: 1,
              prefilledContactName: 'Rahul',
              prefilledContactPhone: '9999999999',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('I paid for them'), findsOneWidget);
    expect(find.text('Rahul paid for me'), findsOneWidget);
    expect(
      find.text('Record a payment made for you or by you.'),
      findsOneWidget,
    );
    expect(find.text('We shared the cost'), findsOneWidget);
    expect(find.text('Amount paid for them *'), findsOneWidget);
    expect(find.text('Split equally'), findsNothing);

    await tester.tap(find.text('Rahul paid for me'));
    await tester.pumpAndSettle();

    expect(find.text('Amount paid for you *'), findsOneWidget);
    expect(find.textContaining('You owe Rahul'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(find.text('Split equally'), findsOneWidget);
    expect(find.text('Total bill amount *'), findsOneWidget);
  });

  testWidgets('split opened from a contact preselects that participant', (
    tester,
  ) async {
    final contactRepository = _FakeContactRepository();

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ContactRepository>.value(value: contactRepository),
        ],
        child: BlocProvider(
          create: (_) => SplitCubit(SplitRepository()),
          child: _localizedApp(const AddSplitScreen(prefilledContactId: 1)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rahul'), findsOneWidget);
    expect(find.text('No participants added'), findsNothing);
    expect(find.text('Your Share'), findsOneWidget);
  });

  testWidgets('saved shared expenses use compact mode tags', (tester) async {
    final paidOnBehalf = TransactionModel(
      type: AppConstants.typeLend,
      category: AppConstants.categorySharedSpend,
      contactId: 1,
      contactName: 'Rahul',
      amount: 500,
      date: DateTime(2026, 1, 1),
      description: 'Lunch',
      sharedTotalAmount: 500,
      sharedUserShare: 0,
      sharedContactShare: 500,
      sharedPaidByUser: true,
    );

    await tester.pumpWidget(
      _localizedApp(
        TransactionListItem(transaction: paidOnBehalf, onTap: () {}),
      ),
    );

    expect(find.text('On behalf'), findsOneWidget);
    expect(find.text('Paid for Rahul'), findsOneWidget);
    expect(find.textContaining('Rahul owes you'), findsOneWidget);
    expect(find.textContaining('Rahul owes you ₹500'), findsNothing);
    expect(find.text('Expense with Someone'), findsNothing);

    final sharedCost = TransactionModel(
      type: AppConstants.typeLend,
      category: AppConstants.categorySharedSpend,
      contactId: 1,
      contactName: 'Rahul',
      amount: 500,
      date: DateTime(2026, 1, 2),
      description: 'Dinner',
      sharedTotalAmount: 1000,
      sharedUserShare: 500,
      sharedContactShare: 500,
      sharedPaidByUser: true,
    );

    await tester.pumpWidget(
      _localizedApp(TransactionListItem(transaction: sharedCost, onTap: () {})),
    );

    expect(find.text('Shared cost'), findsOneWidget);
  });

  testWidgets('home contact card separates shared expense mode counts', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(
        ContactSummaryCard(
          contactName: 'Rahul',
          transactionCount: 4,
          netBalance: 500,
          onBehalfCount: 2,
          sharedCostCount: 1,
          splitCount: 1,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('On behalf 2'), findsOneWidget);
    expect(find.text('Shared cost 1'), findsOneWidget);
    expect(find.text('Expense with Someone 3'), findsNothing);
  });

  testWidgets('home contact card collapses category chips on narrow screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _localizedApp(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: ContactSummaryCard(
              contactName: 'Rahul',
              phoneNumber: '+918600491202',
              transactionCount: 12,
              netBalance: 250000,
              cashCount: 2,
              udhariCount: 2,
              onBehalfCount: 2,
              sharedCostCount: 2,
              legacySharedSpendCount: 2,
              splitCount: 2,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('+'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('transaction card handles long shared-expense labels', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final transaction = TransactionModel(
      type: AppConstants.typeLend,
      category: AppConstants.categorySharedSpend,
      contactId: 1,
      contactName: 'Rahul with a very long display name for a narrow screen',
      contactPhone: '+918600491202',
      amount: 999999999.99,
      date: DateTime(2026, 1, 1),
      description: 'A long purchase description that must not overflow',
      sharedTotalAmount: 999999999.99,
      sharedUserShare: 0,
      sharedContactShare: 999999999.99,
      sharedPaidByUser: true,
    );

    await tester.pumpWidget(
      _localizedApp(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: TransactionListItem(transaction: transaction, onTap: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
