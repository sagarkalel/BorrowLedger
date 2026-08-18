// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get comment_app_info => '========== App Information ==========';

  @override
  String get appName => 'HisaabMate';

  @override
  String get appSlogan => 'Track • Split • Settle';

  @override
  String get comment_common => '========== Common ==========';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get update => 'Update';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get proceed => 'Proceed';

  @override
  String get retry => 'Retry';

  @override
  String get gotIt => 'Got It';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get share => 'Share';

  @override
  String get export => 'Export';

  @override
  String get import => 'Import';

  @override
  String get language => 'Language';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get tapToUse => 'Tap to use';

  @override
  String get unknown => 'Unknown';

  @override
  String get you => 'You';

  @override
  String get youWillGet => 'You\'ll Get';

  @override
  String get youWillGive => 'You\'ll Give';

  @override
  String get payable => 'Payable';

  @override
  String get receivable => 'Receivable';

  @override
  String get direction => 'Direction';

  @override
  String get youPaid => 'You Paid';

  @override
  String get required => 'Required';

  @override
  String get invalid => 'Invalid';

  @override
  String get added => 'Added';

  @override
  String get ledger => 'Ledger';

  @override
  String get na => 'N/A';

  @override
  String get collectionProgress => 'Collection Progress';

  @override
  String get contactFallback => 'Contact';

  @override
  String get balance => 'Balance';

  @override
  String get comment_navigation => '========== Navigation ==========';

  @override
  String get home => 'Home';

  @override
  String get people => 'People';

  @override
  String get borrowLend => 'Borrow/Lend';

  @override
  String get splits => 'Splits';

  @override
  String get expenses => 'Expenses';

  @override
  String get settings => 'Settings';

  @override
  String get moneyTracker => 'Money Tracker';

  @override
  String get comment_transactions => '========== Transactions ==========';

  @override
  String get transaction => 'Transaction';

  @override
  String get transactions => 'Transactions';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get editTransaction => 'Edit Transaction';

  @override
  String get deleteTransaction => 'Delete Transaction';

  @override
  String get transactionDetails => 'Transaction Details';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String get allTransactions => 'All transactions';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get addNewTransaction => 'Add New Transaction';

  @override
  String get saveTransaction => 'Save Transaction';

  @override
  String get updateTransaction => 'Update Transaction';

  @override
  String get transactionDate => 'Transaction Date';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get comment_transaction_types =>
      '========== Transaction Types ==========';

  @override
  String get youGave => 'You Gave';

  @override
  String get youGot => 'You Got';

  @override
  String get youGaveMoney => 'You Gave Money';

  @override
  String get youGotMoney => 'You Got Money';

  @override
  String get youGaveOnUdhari => 'You Gave on Udhari';

  @override
  String get youTookOnUdhari => 'You Took on Udhari';

  @override
  String get youTook => 'You Took';

  @override
  String get lend => 'Lend';

  @override
  String get borrow => 'Borrow';

  @override
  String get lending => 'Lending';

  @override
  String get borrowing => 'Borrowing';

  @override
  String get youGaveMoneyDesc => 'You gave money';

  @override
  String get youGotMoneyDesc => 'You got money';

  @override
  String get youGaveOnUdhariDesc => 'You gave on udhari';

  @override
  String get youTookOnUdhariDesc => 'You took on udhari';

  @override
  String get theyOweYou => 'They owe you';

  @override
  String get youOweThem => 'You owe them';

  @override
  String get theyNeedToPayForItems => 'They need to pay for items/service';

  @override
  String get youNeedToPayForItems => 'You need to pay for items/service';

  @override
  String get whoNeedsToPayYou => 'Who Needs to Pay You';

  @override
  String get moneyTransaction => 'Money Transaction';

  @override
  String get moneyTransactionDescription => 'Direct money given or received';

  @override
  String get moneyTransactionOnePersonDescription =>
      'Direct money given or received with one person';

  @override
  String get udhariItemCredit => 'Udhari / Item Credit';

  @override
  String get udhariItemCreditDescription =>
      'Item or service bought/sold on credit';

  @override
  String get sharedSpend => 'Shared Spend';

  @override
  String get sharedSpendDescription => 'One of you paid for something together';

  @override
  String get whoPaid => 'Who paid?';

  @override
  String get udhariDirection => 'Udhari direction';

  @override
  String get moneyDirection => 'Money direction';

  @override
  String get iPaid => 'I paid';

  @override
  String get iGaveItem => 'I gave item';

  @override
  String get iGave => 'I gave';

  @override
  String get iTookItem => 'I took item';

  @override
  String get iGot => 'I got';

  @override
  String get youPaidLabel => 'You paid';

  @override
  String personPaid(Object personName) {
    return '$personName paid';
  }

  @override
  String personPays(Object personName) {
    return '$personName pays';
  }

  @override
  String paysPerson(Object personName) {
    return 'Pays $personName';
  }

  @override
  String get comment_categories => '========== Categories ==========';

  @override
  String get cash => 'Cash';

  @override
  String get udhari => 'Udhari';

  @override
  String get cashMoney => '💵 Cash Money';

  @override
  String get udhariItemsServices => '📦 Udhari (Items/Services)';

  @override
  String get directCashLent => 'Direct cash lent to someone';

  @override
  String get directCashBorrowed => 'Direct cash borrowed from someone';

  @override
  String get soldItemsOnCredit => 'Sold items/service on credit';

  @override
  String get boughtItemsOnCredit => 'Bought items/service on credit';

  @override
  String get cashAndUdhari => 'Cash & Udhari';

  @override
  String get groupSplit => 'Group split';

  @override
  String get groupSplitDescription => 'Split one expense with multiple people';

  @override
  String get comment_amounts => '========== Amounts ==========';

  @override
  String get amount => 'Amount';

  @override
  String get type => 'Type';

  @override
  String get amountRequired => 'Amount *';

  @override
  String get amountSpent => 'Amount Spent';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get totalAmountRequired => 'Total Amount *';

  @override
  String get paidByUser => 'Paid by User';

  @override
  String get paidByYou => 'Paid by You';

  @override
  String get youPaidRequired => 'You Paid *';

  @override
  String get shareAmount => 'Share Amount';

  @override
  String get amountMustBeGreaterThanZero => 'Amount must be greater than 0';

  @override
  String get mustBeGreaterThanZero => 'Must be > 0';

  @override
  String get pleaseEnterAmount => 'Please enter amount';

  @override
  String get pleaseEnterValidAmount => 'Please enter valid amount';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get cannotBeNegative => 'Cannot be negative';

  @override
  String get exceedsTotal => 'Exceeds total';

  @override
  String get amountCanNotExceed => 'Amount cannot exceed';

  @override
  String get netBalance => 'Net Balance';

  @override
  String get totalPending => 'Total Pending';

  @override
  String get purposeRequired => 'Purpose *';

  @override
  String get purposeHint => 'Dinner, petrol, shopping...';

  @override
  String get pleaseEnterPurpose => 'Please enter purpose';

  @override
  String get totalBill => 'Total bill';

  @override
  String get totalBillAmountRequired => 'Total bill amount *';

  @override
  String get totalBillAmountOptional => 'Total bill amount (Optional)';

  @override
  String get enterFullBillAmount => 'Enter full bill amount';

  @override
  String get contactShareBecomesHalf => 'Contact share becomes half of total';

  @override
  String get yourShareBecomesHalf =>
      'Your share becomes half when total is entered';

  @override
  String personShare(Object personName) {
    return '$personName share';
  }

  @override
  String personShareRequired(Object personName) {
    return '$personName share *';
  }

  @override
  String get myShareRequired => 'My share *';

  @override
  String amountPersonShouldPay(Object personName) {
    return 'Amount $personName should pay';
  }

  @override
  String get amountYouShouldPay => 'Amount you should pay';

  @override
  String get shareCannotExceedTotalBill => 'Share cannot exceed total bill';

  @override
  String get comment_contacts => '========== Contacts ==========';

  @override
  String get contact => 'Contact';

  @override
  String get contacts => 'Contacts';

  @override
  String get contactName => 'Contact Name';

  @override
  String get contactNameRequired => 'Contact Name *';

  @override
  String get addContact => 'Add Contact';

  @override
  String get editContact => 'Edit Contact';

  @override
  String get reviewContact => 'Review Contact';

  @override
  String get selectContact => 'Select Contact';

  @override
  String get selectContactRequired => 'Select Contact *';

  @override
  String get pickFromContacts => 'Pick from Contacts';

  @override
  String get createNewContact => 'Create New Contact';

  @override
  String get reviewAndEditContactDetails =>
      'Review and edit contact details before adding';

  @override
  String get contactDetails => 'Contact Details';

  @override
  String get pleaseSelectContact => 'Please select a contact';

  @override
  String get pleaseSelectContactFromPhone =>
      'Please select a contact from your phone';

  @override
  String get noContactsFound => 'No contacts found';

  @override
  String get noContactsYet => 'No contacts yet';

  @override
  String get noContactsAvailableInPhone =>
      'No contacts available in your phone';

  @override
  String get searchContacts => 'Search contacts...';

  @override
  String get searchContactsByNameOrPhone =>
      'Search contacts by name or phone...';

  @override
  String get searchTransactionsByNameOrPhone =>
      'Search transactions by name or phone...';

  @override
  String get allContacts => 'All Contacts';

  @override
  String get noMatchingContacts => 'No matching contacts';

  @override
  String get noSettledContacts => 'No settled contacts';

  @override
  String get noPendingContacts => 'No pending contacts';

  @override
  String get noContactsWithZeroBalance => 'No contacts with zero balance found';

  @override
  String get noContactsWithPendingBalance =>
      'No contacts with pending balance found';

  @override
  String get contactMustHavePhoneNumber => 'Contact must have a phone number';

  @override
  String get thisContactIsAlreadyAdded => 'This contact is already added';

  @override
  String get phoneAlreadySavedTitle => 'Phone already saved';

  @override
  String phoneAlreadySavedMessage(Object contactName) {
    return 'This number is already saved as $contactName. Use that contact for this split?';
  }

  @override
  String get useExistingContact => 'Use Existing';

  @override
  String get contactsAlreadyAddedMarked =>
      'Contacts already added are marked with a checkmark';

  @override
  String get contactsPermissionRequired => 'Contacts permission is required';

  @override
  String get checkingExistingContacts => 'Checking existing contacts...';

  @override
  String get comment_contact_fields => '========== Contact Fields ==========';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneNumbersSmall => 'phone numbers';

  @override
  String get phoneNumberOptional => 'Phone Number (Optional)';

  @override
  String get email => 'Email';

  @override
  String get emailOptional => 'Email (Optional)';

  @override
  String get enterContactName => 'Enter contact name';

  @override
  String get enterName => 'Enter name';

  @override
  String get enterPhoneNumber => 'Enter phone number';

  @override
  String get enterEmailAddress => 'Enter email address';

  @override
  String get pleaseEnterName => 'Please enter a name';

  @override
  String get pleaseEnterContactName => 'Please enter contact name';

  @override
  String get pleaseEnterPhoneNumber => 'Please enter a phone number';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get phoneContacts => 'Phone Contacts';

  @override
  String get manualEntry => 'Manual Entry';

  @override
  String get startTrackingYourMoneyWith => 'Start tracking your money with';

  @override
  String get comment_dates => '========== Dates ==========';

  @override
  String get date => 'Date';

  @override
  String get dateRequired => 'Date *';

  @override
  String get time => 'Time';

  @override
  String get createdAt => 'Created At';

  @override
  String get updatedAt => 'Updated At';

  @override
  String get expectedDate => 'Expected Date';

  @override
  String get expectedReturn => 'Expected Return';

  @override
  String get expectedReturnDateOptional => 'Expected Return Date (Optional)';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectExpectedDate => 'Select Expected Date';

  @override
  String get selectExpectedReturnDate => 'Select Expected Return Date';

  @override
  String get tapToSet => 'Tap to set';

  @override
  String get clearDate => 'Clear date';

  @override
  String get comment_descriptions => '========== Descriptions ==========';

  @override
  String get description => 'Description';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get addDescription => 'Add Description';

  @override
  String get whatDidYouSpendOn => 'What did you spend on?';

  @override
  String get whatWasThisExpenseFor => 'What was this expense for?';

  @override
  String get addNotesOptional => 'Add notes (optional)';

  @override
  String get addNoteAboutTransaction => 'Add a note about this transaction';

  @override
  String get addDetailsAboutItems => 'Add details about the items or service';

  @override
  String get enterDescription => 'Enter description';

  @override
  String get comment_expenses => '========== Expenses ==========';

  @override
  String get expense => 'Expense';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get editExpense => 'Edit Expense';

  @override
  String get deleteExpense => 'Delete Expense';

  @override
  String get saveExpense => 'Save Expense';

  @override
  String get updateExpense => 'Update Expense';

  @override
  String get personalExpense => 'Personal Expense';

  @override
  String get trackYourSpending => 'Track your spending';

  @override
  String get expenseDeleted => 'Expense deleted';

  @override
  String get noExpensesYet => 'No expenses yet';

  @override
  String get startTrackingExpenses =>
      'Start tracking your personal expenses to better manage your finances';

  @override
  String get comment_expense_categories =>
      '========== Expense Categories ==========';

  @override
  String get category => 'Category';

  @override
  String get foodDining => 'Food & Dining';

  @override
  String get transportation => 'Transportation';

  @override
  String get shopping => 'Shopping';

  @override
  String get entertainment => 'Entertainment';

  @override
  String get billsUtilities => 'Bills & Utilities';

  @override
  String get healthcare => 'Healthcare';

  @override
  String get education => 'Education';

  @override
  String get travel => 'Travel';

  @override
  String get groceries => 'Groceries';

  @override
  String get others => 'Others';

  @override
  String get chooseRightCategory =>
      'Choose the right category to track your spending better!';

  @override
  String get comment_splits => '========== Splits ==========';

  @override
  String get split => 'Split';

  @override
  String get splitExpense => 'Split Expense';

  @override
  String get splitExpenses => 'Split Expenses';

  @override
  String get addSplit => 'Add Split';

  @override
  String get editSplit => 'Edit Split';

  @override
  String get editSplitExpense => 'Edit Split Expense';

  @override
  String get deleteSplit => 'Delete Split';

  @override
  String get deleteSplitExpense => 'Delete Split Expense';

  @override
  String get splitDetails => 'Split Details';

  @override
  String get splitDeleted => 'Split deleted';

  @override
  String get splitExpenseDeleted => 'Split expense deleted';

  @override
  String get splitMarkedAsSettled => 'Split marked as settled';

  @override
  String get splitNotFound => 'Split not found';

  @override
  String get noSplitsYet => 'No splits yet';

  @override
  String get noSplitExpensesYet => 'No split expenses yet';

  @override
  String get noMoreSplits => 'No more splits';

  @override
  String get noSplitsFound => 'No splits found';

  @override
  String get startSplittingExpenses =>
      'Start splitting expenses with friends and family';

  @override
  String get startSplittingExpensesWithFriends =>
      'Start splitting expenses with friends';

  @override
  String get shareCostsWithFriends => 'Share costs with friends';

  @override
  String get addParticipants => 'Add Participants';

  @override
  String get participants => 'Participants';

  @override
  String get selectParticipants => 'Select Participants';

  @override
  String get participantsMustBeSelected =>
      'Please select at least one participant';

  @override
  String get noParticipantsAdded => 'No participants added yet';

  @override
  String get addAtLeastOnePerson => 'Add at least one person to split with';

  @override
  String get totalParticipantShares => 'Total participant shares';

  @override
  String get recentSplits => 'Recent Splits';

  @override
  String get searchSplits => 'Search splits...';

  @override
  String get createSplit => 'Create Split';

  @override
  String get updateSplit => 'Update Split';

  @override
  String get settleAnyway => 'Settle Anyway';

  @override
  String get settleSplit => 'Settle Split';

  @override
  String get reviewAndSettleSplit => 'Review & Settle Split';

  @override
  String get notPaidYet => 'Not Paid Yet';

  @override
  String get pendingSettlements => 'Pending Settlements';

  @override
  String get partiallySettled => 'Partially Settled';

  @override
  String get settledOrNoAction => 'Settled / No Action';

  @override
  String get reviewPendingSettlements =>
      'Review pending settlements before closing this split.';

  @override
  String pendingSettlementsWillBeMarkedComplete(Object count) {
    return '$count pending settlement(s) will be marked complete.';
  }

  @override
  String get settlementsToClose => 'Settlements to close';

  @override
  String get settlementRoute => 'Settlement Route';

  @override
  String get optimizedRoute => 'Optimized';

  @override
  String get settleViaPerson => 'Via Person';

  @override
  String get routeThroughTrustedPerson =>
      'Route payments through a trusted person.';

  @override
  String get selectRoutePerson => 'Select route person';

  @override
  String get routePlanOnly =>
      'This only changes the suggested payment path. Mark people as paid after they actually settle.';

  @override
  String get settlementRouteCompleted =>
      'Settlement was completed using this route.';

  @override
  String get settlingWillCloseThesePayments =>
      'This will close these payments and remove generated split ledger entries.';

  @override
  String get allSettlementsAlreadyComplete =>
      'All settlements are already complete. Mark this split as settled?';

  @override
  String get yourShare => 'Your Share';

  @override
  String get paymentBreakdown => 'Payment Breakdown';

  @override
  String get addMore => 'Add More';

  @override
  String get markReceived => 'Mark Received';

  @override
  String get markAsReceived => 'Mark as Received';

  @override
  String get markPaid => 'Mark Paid';

  @override
  String get markAsPaid => 'Mark as Paid';

  @override
  String get alreadyPaid => 'Already Paid';

  @override
  String get amountPaid => 'Amount Paid';

  @override
  String get paidDuringBill => 'Paid during bill';

  @override
  String get remaining => 'Remaining';

  @override
  String get fullAmount => 'Full Amount';

  @override
  String get amountReceived => 'Amount Received';

  @override
  String get markPartial => 'Mark Partial';

  @override
  String get markFull => 'Mark Full';

  @override
  String get pendingPayments => 'Pending Payments';

  @override
  String settledAmountLeft(Object settledAmount, Object leftAmount) {
    return 'Settled $settledAmount • Left $leftAmount';
  }

  @override
  String personOwesCounterparty(
    Object personName,
    Object counterpartyName,
    Object amount,
  ) {
    return '$personName owes $counterpartyName $amount';
  }

  @override
  String owesCounterparty(Object counterpartyName, Object amount) {
    return 'Owes $counterpartyName $amount';
  }

  @override
  String youOwePerson(Object personName, Object amount) {
    return 'You owe $personName $amount';
  }

  @override
  String get fullRemainingAmountWillBeMarkedAsReceived =>
      'The full remaining amount will be marked as received.';

  @override
  String get onlyEnteredAmountWillBeMarkedAsReceived =>
      'Only the entered amount will be marked as received.';

  @override
  String get fullRemainingAmountWillBeMarkedAsPaid =>
      'The full remaining amount will be marked as paid.';

  @override
  String get onlyEnteredAmountWillBeMarkedAsPaid =>
      'Only the entered amount will be marked as paid.';

  @override
  String get deleteSplitConfirmMessage =>
      'Are you sure you want to delete this split expense? This action cannot be undone.';

  @override
  String get doYouWantToMarkSettled =>
      'Do you still want to mark this as settled? This action cannot be undone.';

  @override
  String get allParticipantHasPaidTheirShareMarkAsSetteled =>
      'All participants have paid their share. Mark this split as settled?\n\nThis action cannot be undone.';

  @override
  String get amountYouPaidCannotExceedTotalAmount =>
      'Amount you paid cannot exceed total amount';

  @override
  String get comment_split_fields => '========== Split Fields ==========';

  @override
  String get title => 'Title';

  @override
  String get titleRequired => 'Title *';

  @override
  String get splitTitle => 'Split Title';

  @override
  String get enterSplitTitle => 'Enter split title';

  @override
  String get egDinnerAtRestaurant => 'e.g., Dinner at Restaurant';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get totalCost => 'Total Cost';

  @override
  String get howMuchDidYouPay => 'How much did you pay?';

  @override
  String get enterTotalAmount => 'Enter total amount';

  @override
  String get enterYourShare => 'Enter your share';

  @override
  String get splitEqually => 'Split equally';

  @override
  String get splitByAmount => 'Split by Amount';

  @override
  String get splitMethod => 'Split Method';

  @override
  String get divideAmountEvenlyAmongAll => 'Divide amount evenly among all';

  @override
  String get yourShareWillBeRemaining =>
      'Your share will be the remaining amount';

  @override
  String get comment_status => '========== Status ==========';

  @override
  String get status => 'Status';

  @override
  String get pending => 'Pending';

  @override
  String get paid => 'Paid';

  @override
  String get partial => 'Partial';

  @override
  String get settled => 'Settled';

  @override
  String get overdue => 'Overdue';

  @override
  String get paymentOverdue => 'This payment is overdue';

  @override
  String get synced => 'Synced';

  @override
  String get comment_statistics => '========== Statistics ==========';

  @override
  String get statistics => 'Statistics';

  @override
  String get yourDataOverview => 'Your Data Overview';

  @override
  String get totalTransactions => 'Total Transactions';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get totalSplits => 'Total Splits';

  @override
  String get youOwe => 'You Owe';

  @override
  String get oweYou => 'Owe You';

  @override
  String get totalOwed => 'Total Owed';

  @override
  String get totalPaid => 'Total Paid';

  @override
  String get topCategory => 'Top Category';

  @override
  String get categories => 'Categories';

  @override
  String get overview => 'Overview';

  @override
  String get allExpenses => 'All Expenses';

  @override
  String get addYourFirstExpenseToSeeInsights =>
      'Add your first expense to see insights,\ncharts and spending analysis';

  @override
  String get spendingByCategory => 'Spending by Category';

  @override
  String get monthlyTrend => 'Monthly Trend';

  @override
  String get categoryBreakdown => 'Category Breakdown';

  @override
  String get searchExpenses => 'Search Expenses';

  @override
  String get noMatchingExpenses => 'No matching expenses';

  @override
  String get addFirstExpenseToStartTracking =>
      'Add your first expense to start tracking';

  @override
  String get comment_udhari => '========== Udhari Fields ==========';

  @override
  String get itemName => 'Item Name';

  @override
  String get itemServiceName => 'Item/Service Name';

  @override
  String get itemServiceNameRequired => 'Item/Service Name *';

  @override
  String get itemService => 'Item/Service';

  @override
  String get quantity => 'Quantity';

  @override
  String get quantityOptional => 'Quantity (Optional)';

  @override
  String get enterItemName => 'Enter item name';

  @override
  String get enterQuantity => 'Enter quantity';

  @override
  String get pleaseEnterItemOrServiceName =>
      'Please enter item or service name';

  @override
  String get egMilkMedicalGroceries =>
      'e.g., Milk, Medical Treatment, Groceries';

  @override
  String get egQuantityExamples => 'e.g., 2 liters, 1 session, 5 kg';

  @override
  String get whatDidYouGiveOrTake => 'What did you give or take?';

  @override
  String get howMany => 'How many?';

  @override
  String get comment_settlement => '========== Settlement ==========';

  @override
  String get settlement => 'Settlement';

  @override
  String get settleUp => 'Settle Up';

  @override
  String get markAsSettled => 'Mark as Settled';

  @override
  String get settleAmount => 'Settle Amount';

  @override
  String get settleBalance => 'Settle Balance';

  @override
  String get settlementTransaction => 'Settlement Transaction';

  @override
  String get balanceSettledSuccessfully => 'Balance settled successfully';

  @override
  String get clearThisBalance => 'Clear this balance';

  @override
  String get fullSettlement => 'Full Settlement';

  @override
  String get partialSettlement => 'Partial Settlement';

  @override
  String get settlementAmount => 'Settlement Amount';

  @override
  String get enterSettlementAmount => 'Enter settlement amount';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get setToFullBalance => 'Set to full balance';

  @override
  String get settlePartial => 'Settle Partial';

  @override
  String get settleFull => 'Settle Full';

  @override
  String get partialSettlementInfoPositive =>
      'A \"You Got\" transaction will be created for the entered amount, reducing your balance.';

  @override
  String get partialSettlementInfoNegative =>
      'A \"You Gave\" transaction will be created for the entered amount, reducing your balance.';

  @override
  String get fullSettlementInfoPositive =>
      'A \"You Got\" transaction will be created to settle the full balance to zero.';

  @override
  String get fullSettlementInfoNegative =>
      'A \"You Gave\" transaction will be created to settle the full balance to zero.';

  @override
  String get comment_dialogs_delete => '========== Delete Dialogs ==========';

  @override
  String get deleteExpenseTitle => 'Delete Expense?';

  @override
  String get deleteExpenseMessage =>
      'Are you sure you want to delete this expense?';

  @override
  String get deleteTransactionTitle => 'Delete Transaction?';

  @override
  String get deleteTransactionMessage =>
      'Are you sure you want to delete this transaction?';

  @override
  String get deleteSplitTitle => 'Delete Split?';

  @override
  String get deleteSplitMessage =>
      'Are you sure you want to delete this split expense?';

  @override
  String get actionCannotBeUndone => 'This action cannot be undone';

  @override
  String get permanentlyDelete => 'PERMANENTLY DELETE:';

  @override
  String get thisActionCannotBeUndone =>
      'This action cannot be undone. The expense will be permanently removed from your records.';

  @override
  String get comment_dialogs_clear_data =>
      '========== Clear Data Dialog ==========';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get clearAllDataTitle => 'Clear All Data?';

  @override
  String get clearAllDataMessage => 'This will permanently delete everything';

  @override
  String get deleteEverything => 'Delete Everything';

  @override
  String get deletingData => 'Deleting data...';

  @override
  String get allDataCleared => 'All data has been cleared';

  @override
  String get currentDataWillBeDeleted =>
      'Current data will be permanently deleted:';

  @override
  String get allDataHasBeenCleared => 'All data has been cleared';

  @override
  String get thisWillPermanentlyDelete => 'This will PERMANENTLY DELETE:';

  @override
  String get allTransactionsItem => 'All transactions';

  @override
  String get allExpensesItem => 'All expenses';

  @override
  String get allSplitExpensesItem => 'All split expenses';

  @override
  String get allContactReferencesItem => 'All contact references';

  @override
  String get considerExportingDataFirst =>
      'Consider exporting your data first. This action cannot be undone!';

  @override
  String get comment_dialogs_export => '========== Export Dialog ==========';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportDataTitle => 'Export Data';

  @override
  String get exportDataMessage =>
      'Create a backup file containing all your data';

  @override
  String get whatWillBeExported => 'What will be exported:';

  @override
  String get allTransactionsLendBorrow => 'All transactions (lend/borrow)';

  @override
  String get allPersonalExpenses => 'All personal expenses';

  @override
  String get allSplitExpenses => 'All split expenses';

  @override
  String get contactReferences => 'Contact references';

  @override
  String get canShareBackupFile =>
      'You can share the backup file or save it for later import';

  @override
  String get preparingExport => 'Preparing export...';

  @override
  String get exportSuccessful => 'Export Successful!';

  @override
  String get savedInBackupsFolder => 'Saved in Backups folder';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get comment_dialogs_import => '========== Import Dialog ==========';

  @override
  String get importData => 'Import Data';

  @override
  String get importDataTitle => 'Import Data';

  @override
  String get importDataMessage => 'Restore data from backup file';

  @override
  String get thisWillReplaceAllData =>
      '⚠️ Warning: This will REPLACE all your current data!';

  @override
  String get makeSureHaveBackup =>
      'Make sure you have a backup before proceeding!';

  @override
  String get importingData => 'Importing data...';

  @override
  String get importSuccessful => 'Import Successful!';

  @override
  String get successfullyImported => 'Successfully imported:';

  @override
  String get restartRecommended => 'Restart recommended for best experience';

  @override
  String get restartRecommendedMessage => 'Restart recommended';

  @override
  String get importFailed => 'Import failed';

  @override
  String get thisWillReplaceAllDataWarning => 'This will REPLACE all data!';

  @override
  String get currentDataWillBePermanentlyDeleted =>
      'Current data will be permanently deleted:';

  @override
  String get allTransactionsDeleted => 'All transactions';

  @override
  String get allExpensesDeleted => 'All expenses';

  @override
  String get allSplitsDeleted => 'All splits';

  @override
  String get comment_settings => '========== Settings ==========';

  @override
  String get appearance => 'Appearance';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get information => 'Information';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get comment_theme => '========== Theme ==========';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get systemDefault => 'System Default';

  @override
  String get brightAndClean => 'Bright and clean';

  @override
  String get easyOnEyes => 'Easy on the eyes';

  @override
  String get followDeviceSettings => 'Follow device settings';

  @override
  String get comment_backup => '========== Backup & Restore ==========';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get createBackup => 'Create backup of all data';

  @override
  String get restoreFromBackup => 'Restore from backup file';

  @override
  String get howItWorks => 'How It Works';

  @override
  String get learnBackupRestore => 'Learn about backup & restore';

  @override
  String get howBackupWorks => 'How Backup Works';

  @override
  String get createsJsonFile => 'Creates a JSON file containing:';

  @override
  String get fileSavedLocally => 'The file is saved locally and can be shared.';

  @override
  String get restoresDataFromBackup => 'Restores data from backup:';

  @override
  String get replacesAllCurrentData => 'Replaces all current data';

  @override
  String get importsAllRecords => 'Imports all records';

  @override
  String get maintainsRelationships => 'Maintains relationships';

  @override
  String get alwaysExportBeforeImporting =>
      '⚠️ Always export before importing!';

  @override
  String get bestPractices => 'Best Practices';

  @override
  String get exportRegularly => 'Export regularly (weekly/monthly)';

  @override
  String get storeInCloudStorage => 'Store backups in cloud storage';

  @override
  String get neverDeleteLastBackup => 'Never delete your last backup';

  @override
  String get shareBackupsSecurely => 'Share backups securely';

  @override
  String get backupFilesInJson =>
      'Backup files are in JSON format and can be viewed in any text editor.';

  @override
  String get comment_about => '========== About ==========';

  @override
  String get version => 'Version';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get viewTermsAndConditions => 'View terms and conditions';

  @override
  String get yourDataStaysOnDevice => 'Your data stays on device';

  @override
  String get termsOfServiceContent =>
      'This is a personal finance management app. Use it responsibly and at your own risk. All financial decisions are your responsibility.';

  @override
  String get privacyPolicyContent =>
      'All your data is stored locally on your device. We do not collect, transmit, or share any personal information. Your privacy is our priority.';

  @override
  String get developedBy => 'Developed By: Sagar Kalel';

  @override
  String get comment_permissions => '========== Permissions ==========';

  @override
  String get storagePermissionDenied => 'Storage permission denied';

  @override
  String get contactsPermissionDenied => 'Contacts permission denied';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get comment_empty_states => '========== Empty States ==========';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get startTrackingBorrowLend =>
      'Start tracking your lending and borrowing to stay organized';

  @override
  String get startTrackingYourMoney =>
      'Start tracking your money by adding your first transaction';

  @override
  String get noContactTransactions => 'No transactions found';

  @override
  String get noMatchingTransactions => 'No matching transactions';

  @override
  String get noCashTransactions => 'No cash transactions';

  @override
  String get noUdhariTransactions => 'No udhari transactions';

  @override
  String get noMatchingCashTransactions => 'No matching cash transactions';

  @override
  String get noMatchingUdhariTransactions => 'No matching udhari transactions';

  @override
  String get addFirstTransaction => 'Add your first transaction to get started';

  @override
  String get addYourFirstCashTransaction => 'Add your first cash transaction';

  @override
  String get addYourFirstUdhariTransaction =>
      'Add your first udhari transaction';

  @override
  String get addFirstExpense => 'Add your first expense to get started';

  @override
  String get addFirstSplit => 'Add your first split to get started';

  @override
  String get tryAdjustingFilters => 'Try adjusting your filters';

  @override
  String get tryDifferentSearchTerm => 'Try a different search term';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get comment_view_modes => '========== View Modes ==========';

  @override
  String get viewMode => 'View Mode';

  @override
  String get contactsView => 'Contacts';

  @override
  String get cashView => 'Cash';

  @override
  String get udhariView => 'Udhari';

  @override
  String get allView => 'All';

  @override
  String get comment_validation => '========== Validation Messages ==========';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get invalidPhone => 'Invalid phone number';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get amountTooLow => 'Amount is too low';

  @override
  String get amountTooHigh => 'Amount is too high';

  @override
  String get pleaseSelectDate => 'Please select a date';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get pleaseAddAtLeastOneParticipant =>
      'Please add at least one participant';

  @override
  String get amountPaidCannotExceedTotal =>
      'Amount you paid cannot exceed total amount';

  @override
  String get totalSharesExceedTotal => 'Total shares exceed the total amount';

  @override
  String get comment_actions => '========== Actions ==========';

  @override
  String get viewDetails => 'View Details';

  @override
  String get editDetails => 'Edit Details';

  @override
  String get deleteRecord => 'Delete Record';

  @override
  String get shareData => 'Share Data';

  @override
  String get downloadBackup => 'Download Backup';

  @override
  String get uploadBackup => 'Upload Backup';

  @override
  String get comment_tips => '========== Tips & Hints ==========';

  @override
  String get tip => 'Tip';

  @override
  String get hint => 'Hint';

  @override
  String get note => 'Note';

  @override
  String get info => 'Info';

  @override
  String get warning => 'Warning';

  @override
  String get selectContactFirst => 'Please select a contact first';

  @override
  String get fillAllRequiredFields => 'Please fill all required fields';

  @override
  String get dataWillBeLost => 'Your data will be lost';

  @override
  String get cannotBeUndone => 'This cannot be undone';

  @override
  String get comment_currencies => '========== Currency ==========';

  @override
  String get currency => 'Currency';

  @override
  String get rupee => '₹';

  @override
  String get rupees => 'Rupees';

  @override
  String get inr => 'INR';

  @override
  String get zeroDecimal => '0.00';

  @override
  String get comment_time_periods => '========== Time Periods ==========';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This Week';

  @override
  String get lastWeek => 'Last Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get thisYear => 'This Year';

  @override
  String get allTime => 'All Time';

  @override
  String get custom => 'Custom';

  @override
  String get comment_actions_menu => '========== Transaction Menu ==========';

  @override
  String get selectTransactionType => 'Select Transaction Type';

  @override
  String get whatWouldYouLikeToDo => 'What would you like to do?';

  @override
  String get chooseTransactionType => 'Choose transaction type';

  @override
  String get comment_error_messages => '========== Error Messages ==========';

  @override
  String get error => 'Error';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get tryAgain => 'Try again';

  @override
  String get failedToLoad => 'Failed to load';

  @override
  String get failedToSave => 'Failed to save';

  @override
  String get failedToDelete => 'Failed to delete';

  @override
  String get failedToUpdate => 'Failed to update';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get timeoutError => 'Request timed out';

  @override
  String get shareFailed => 'Failed to share';

  @override
  String get comment_success_messages =>
      '========== Success Messages ==========';

  @override
  String get success => 'Success';

  @override
  String get savedSuccessfully => 'Saved successfully';

  @override
  String get deletedSuccessfully => 'Deleted successfully';

  @override
  String get updatedSuccessfully => 'Updated successfully';

  @override
  String get exportedSuccessfully => 'Exported successfully';

  @override
  String get importedSuccessfully => 'Imported successfully';

  @override
  String get comment_badges => '========== Badges ==========';

  @override
  String get youGaveBadge => 'YOU GAVE';

  @override
  String get youGotBadge => 'YOU GOT';

  @override
  String get cashBadge => 'CASH';

  @override
  String get udhariBadge => 'UDHARI';

  @override
  String get settledBadge => 'SETTLED';

  @override
  String get pendingBadge => 'PENDING';

  @override
  String get paidBadge => 'PAID';

  @override
  String get noActionBadge => 'NO ACTION';

  @override
  String get comment_misc => '========== Miscellaneous ==========';

  @override
  String get loading => 'Loading...';

  @override
  String get pleaseWait => 'Please wait';

  @override
  String get processing => 'Processing...';

  @override
  String get searching => 'Searching...';

  @override
  String get noResults => 'No results found';

  @override
  String get tryDifferentSearch => 'Try a different search';

  @override
  String get refresh => 'Refresh';

  @override
  String get reload => 'Reload';

  @override
  String get more => 'More';

  @override
  String get less => 'Less';

  @override
  String get showMore => 'Show More';

  @override
  String get showLess => 'Show Less';

  @override
  String get allCaughtUp => 'All caught up';

  @override
  String get noMoreData => 'No more data';

  @override
  String get noMoreRecords => 'No more records';

  @override
  String get viewAll => 'View All';

  @override
  String get seeAll => 'See All';

  @override
  String get collapse => 'Collapse';

  @override
  String get expand => 'Expand';

  @override
  String get details => 'Details';

  @override
  String get summary => 'Summary';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get ofText => 'of';

  @override
  String get toText => 'to';

  @override
  String get fromText => 'from';

  @override
  String get withText => 'with';

  @override
  String get byText => 'by';

  @override
  String get onText => 'on';

  @override
  String get atText => 'at';

  @override
  String get inText => 'in';

  @override
  String get trans => 'Trans';

  @override
  String get exp => 'Expenses';

  @override
  String get all => 'All';

  @override
  String get personSmall => 'person';

  @override
  String get peopleSmall => 'people';

  @override
  String get yourProfile => 'Your Profile';

  @override
  String get setYourName => 'Set your name';

  @override
  String get nameUsedInSharedSplits => 'Used in shared splits and reports';

  @override
  String get helpFriendsRecognizeYou =>
      'Help friends recognize who paid or owes';

  @override
  String get yourNameRequired => 'Your Name *';

  @override
  String get pleaseEnterYourName => 'Please enter your name';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get moreOptions => 'More options';

  @override
  String get sharePdfStatement => 'Share PDF Statement';

  @override
  String get shareLedgerPdf => 'Share Ledger PDF';

  @override
  String get preparingStatement => 'Preparing statement...';

  @override
  String get preparingInvoice => 'Preparing invoice...';

  @override
  String get last15Days => 'Last 15 days';

  @override
  String get last3Months => 'Last 3 months';

  @override
  String get last6Months => 'Last 6 months';

  @override
  String get last1Year => 'Last 1 year';

  @override
  String get customRange => 'Custom range';

  @override
  String get borrowLedgerStatement => 'HisaabMate Statement';

  @override
  String get borrowLedgerFullStatement => 'HisaabMate Full Statement';

  @override
  String get splitInvoice => 'Split Invoice';

  @override
  String splitInvoiceFrom(Object ownerName, Object splitTitle) {
    return 'Split invoice from $ownerName: $splitTitle';
  }

  @override
  String splitInvoiceSubject(Object splitTitle) {
    return 'Split Invoice - $splitTitle';
  }

  @override
  String get period => 'Period';

  @override
  String get generatedBy => 'Generated by';

  @override
  String get generatedOn => 'Generated on';

  @override
  String ownerPaid(Object ownerName) {
    return '$ownerName paid';
  }

  @override
  String ownerShare(Object ownerName) {
    return '$ownerName\'s share';
  }

  @override
  String ownerBalance(Object ownerName) {
    return '$ownerName\'s balance';
  }

  @override
  String ownerGets(Object ownerName) {
    return '$ownerName gets';
  }

  @override
  String ownerGives(Object ownerName) {
    return '$ownerName gives';
  }

  @override
  String ownerGave(Object ownerName) {
    return '$ownerName gave';
  }

  @override
  String ownerGot(Object ownerName) {
    return '$ownerName got';
  }

  @override
  String get routedThroughTrustedPerson => 'Routed through trusted person';

  @override
  String get optimizedRouteLabel => 'Optimized route';

  @override
  String get opening => 'Opening';

  @override
  String get closing => 'Closing';

  @override
  String get noTransactionsInDateRange =>
      'No transactions found for this date range.';

  @override
  String get allCategories => 'All categories';

  @override
  String get gaveOnly => 'Gave only';

  @override
  String get gotOnly => 'Got only';

  @override
  String get searchLabel => 'Search';

  @override
  String get comment_language => '========== Language ==========';

  @override
  String get languageChangedTo => 'Language changed to';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिंदी';

  @override
  String get marathi => 'मराठी';
}
