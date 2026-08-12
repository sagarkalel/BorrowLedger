import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// No description provided for @comment_app_info.
  ///
  /// In en, this message translates to:
  /// **'========== App Information =========='**
  String get comment_app_info;

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'HisaabMate'**
  String get appName;

  /// Application tagline
  ///
  /// In en, this message translates to:
  /// **'Track • Split • Settle'**
  String get appSlogan;

  /// No description provided for @comment_common.
  ///
  /// In en, this message translates to:
  /// **'========== Common =========='**
  String get comment_common;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get gotIt;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @tapToUse.
  ///
  /// In en, this message translates to:
  /// **'Tap to use'**
  String get tapToUse;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @youWillGet.
  ///
  /// In en, this message translates to:
  /// **'You\'ll Get'**
  String get youWillGet;

  /// No description provided for @youWillGive.
  ///
  /// In en, this message translates to:
  /// **'You\'ll Give'**
  String get youWillGive;

  /// No description provided for @payable.
  ///
  /// In en, this message translates to:
  /// **'Payable'**
  String get payable;

  /// No description provided for @receivable.
  ///
  /// In en, this message translates to:
  /// **'Receivable'**
  String get receivable;

  /// No description provided for @direction.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get direction;

  /// No description provided for @youPaid.
  ///
  /// In en, this message translates to:
  /// **'You Paid'**
  String get youPaid;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalid;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @ledger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledger;

  /// No description provided for @na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// No description provided for @collectionProgress.
  ///
  /// In en, this message translates to:
  /// **'Collection Progress'**
  String get collectionProgress;

  /// No description provided for @comment_navigation.
  ///
  /// In en, this message translates to:
  /// **'========== Navigation =========='**
  String get comment_navigation;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @borrowLend.
  ///
  /// In en, this message translates to:
  /// **'Borrow/Lend'**
  String get borrowLend;

  /// No description provided for @splits.
  ///
  /// In en, this message translates to:
  /// **'Splits'**
  String get splits;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @moneyTracker.
  ///
  /// In en, this message translates to:
  /// **'Money Tracker'**
  String get moneyTracker;

  /// No description provided for @comment_transactions.
  ///
  /// In en, this message translates to:
  /// **'========== Transactions =========='**
  String get comment_transactions;

  /// No description provided for @transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transaction;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get editTransaction;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @transactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionDeleted;

  /// No description provided for @allTransactions.
  ///
  /// In en, this message translates to:
  /// **'All transactions'**
  String get allTransactions;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @addNewTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add New Transaction'**
  String get addNewTransaction;

  /// No description provided for @saveTransaction.
  ///
  /// In en, this message translates to:
  /// **'Save Transaction'**
  String get saveTransaction;

  /// No description provided for @updateTransaction.
  ///
  /// In en, this message translates to:
  /// **'Update Transaction'**
  String get updateTransaction;

  /// No description provided for @transactionDate.
  ///
  /// In en, this message translates to:
  /// **'Transaction Date'**
  String get transactionDate;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @comment_transaction_types.
  ///
  /// In en, this message translates to:
  /// **'========== Transaction Types =========='**
  String get comment_transaction_types;

  /// No description provided for @youGave.
  ///
  /// In en, this message translates to:
  /// **'You Gave'**
  String get youGave;

  /// No description provided for @youGot.
  ///
  /// In en, this message translates to:
  /// **'You Got'**
  String get youGot;

  /// No description provided for @youGaveMoney.
  ///
  /// In en, this message translates to:
  /// **'You Gave Money'**
  String get youGaveMoney;

  /// No description provided for @youGotMoney.
  ///
  /// In en, this message translates to:
  /// **'You Got Money'**
  String get youGotMoney;

  /// No description provided for @youGaveOnUdhari.
  ///
  /// In en, this message translates to:
  /// **'You Gave on Udhari'**
  String get youGaveOnUdhari;

  /// No description provided for @youTookOnUdhari.
  ///
  /// In en, this message translates to:
  /// **'You Took on Udhari'**
  String get youTookOnUdhari;

  /// No description provided for @youTook.
  ///
  /// In en, this message translates to:
  /// **'You Took'**
  String get youTook;

  /// No description provided for @lend.
  ///
  /// In en, this message translates to:
  /// **'Lend'**
  String get lend;

  /// No description provided for @borrow.
  ///
  /// In en, this message translates to:
  /// **'Borrow'**
  String get borrow;

  /// No description provided for @lending.
  ///
  /// In en, this message translates to:
  /// **'Lending'**
  String get lending;

  /// No description provided for @borrowing.
  ///
  /// In en, this message translates to:
  /// **'Borrowing'**
  String get borrowing;

  /// No description provided for @youGaveMoneyDesc.
  ///
  /// In en, this message translates to:
  /// **'You gave money'**
  String get youGaveMoneyDesc;

  /// No description provided for @youGotMoneyDesc.
  ///
  /// In en, this message translates to:
  /// **'You got money'**
  String get youGotMoneyDesc;

  /// No description provided for @youGaveOnUdhariDesc.
  ///
  /// In en, this message translates to:
  /// **'You gave on udhari'**
  String get youGaveOnUdhariDesc;

  /// No description provided for @youTookOnUdhariDesc.
  ///
  /// In en, this message translates to:
  /// **'You took on udhari'**
  String get youTookOnUdhariDesc;

  /// No description provided for @theyOweYou.
  ///
  /// In en, this message translates to:
  /// **'They owe you'**
  String get theyOweYou;

  /// No description provided for @youOweThem.
  ///
  /// In en, this message translates to:
  /// **'You owe them'**
  String get youOweThem;

  /// No description provided for @theyNeedToPayForItems.
  ///
  /// In en, this message translates to:
  /// **'They need to pay for items/service'**
  String get theyNeedToPayForItems;

  /// No description provided for @youNeedToPayForItems.
  ///
  /// In en, this message translates to:
  /// **'You need to pay for items/service'**
  String get youNeedToPayForItems;

  /// No description provided for @whoNeedsToPayYou.
  ///
  /// In en, this message translates to:
  /// **'Who Needs to Pay You'**
  String get whoNeedsToPayYou;

  /// No description provided for @comment_categories.
  ///
  /// In en, this message translates to:
  /// **'========== Categories =========='**
  String get comment_categories;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @udhari.
  ///
  /// In en, this message translates to:
  /// **'Udhari'**
  String get udhari;

  /// No description provided for @cashMoney.
  ///
  /// In en, this message translates to:
  /// **'💵 Cash Money'**
  String get cashMoney;

  /// No description provided for @udhariItemsServices.
  ///
  /// In en, this message translates to:
  /// **'📦 Udhari (Items/Services)'**
  String get udhariItemsServices;

  /// No description provided for @directCashLent.
  ///
  /// In en, this message translates to:
  /// **'Direct cash lent to someone'**
  String get directCashLent;

  /// No description provided for @directCashBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Direct cash borrowed from someone'**
  String get directCashBorrowed;

  /// No description provided for @soldItemsOnCredit.
  ///
  /// In en, this message translates to:
  /// **'Sold items/service on credit'**
  String get soldItemsOnCredit;

  /// No description provided for @boughtItemsOnCredit.
  ///
  /// In en, this message translates to:
  /// **'Bought items/service on credit'**
  String get boughtItemsOnCredit;

  /// No description provided for @cashAndUdhari.
  ///
  /// In en, this message translates to:
  /// **'Cash & Udhari'**
  String get cashAndUdhari;

  /// No description provided for @comment_amounts.
  ///
  /// In en, this message translates to:
  /// **'========== Amounts =========='**
  String get comment_amounts;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount *'**
  String get amountRequired;

  /// No description provided for @amountSpent.
  ///
  /// In en, this message translates to:
  /// **'Amount Spent'**
  String get amountSpent;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @totalAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Total Amount *'**
  String get totalAmountRequired;

  /// No description provided for @paidByUser.
  ///
  /// In en, this message translates to:
  /// **'Paid by User'**
  String get paidByUser;

  /// No description provided for @paidByYou.
  ///
  /// In en, this message translates to:
  /// **'Paid by You'**
  String get paidByYou;

  /// No description provided for @youPaidRequired.
  ///
  /// In en, this message translates to:
  /// **'You Paid *'**
  String get youPaidRequired;

  /// No description provided for @shareAmount.
  ///
  /// In en, this message translates to:
  /// **'Share Amount'**
  String get shareAmount;

  /// No description provided for @amountMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get amountMustBeGreaterThanZero;

  /// No description provided for @mustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Must be > 0'**
  String get mustBeGreaterThanZero;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount'**
  String get pleaseEnterAmount;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid amount'**
  String get pleaseEnterValidAmount;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @cannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Cannot be negative'**
  String get cannotBeNegative;

  /// No description provided for @exceedsTotal.
  ///
  /// In en, this message translates to:
  /// **'Exceeds total'**
  String get exceedsTotal;

  /// No description provided for @amountCanNotExceed.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot exceed'**
  String get amountCanNotExceed;

  /// No description provided for @netBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get netBalance;

  /// No description provided for @totalPending.
  ///
  /// In en, this message translates to:
  /// **'Total Pending'**
  String get totalPending;

  /// No description provided for @comment_contacts.
  ///
  /// In en, this message translates to:
  /// **'========== Contacts =========='**
  String get comment_contacts;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @contactName.
  ///
  /// In en, this message translates to:
  /// **'Contact Name'**
  String get contactName;

  /// No description provided for @contactNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Contact Name *'**
  String get contactNameRequired;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addContact;

  /// No description provided for @editContact.
  ///
  /// In en, this message translates to:
  /// **'Edit Contact'**
  String get editContact;

  /// No description provided for @reviewContact.
  ///
  /// In en, this message translates to:
  /// **'Review Contact'**
  String get reviewContact;

  /// No description provided for @selectContact.
  ///
  /// In en, this message translates to:
  /// **'Select Contact'**
  String get selectContact;

  /// No description provided for @selectContactRequired.
  ///
  /// In en, this message translates to:
  /// **'Select Contact *'**
  String get selectContactRequired;

  /// No description provided for @pickFromContacts.
  ///
  /// In en, this message translates to:
  /// **'Pick from Contacts'**
  String get pickFromContacts;

  /// No description provided for @createNewContact.
  ///
  /// In en, this message translates to:
  /// **'Create New Contact'**
  String get createNewContact;

  /// No description provided for @reviewAndEditContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Review and edit contact details before adding'**
  String get reviewAndEditContactDetails;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// No description provided for @pleaseSelectContact.
  ///
  /// In en, this message translates to:
  /// **'Please select a contact'**
  String get pleaseSelectContact;

  /// No description provided for @pleaseSelectContactFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Please select a contact from your phone'**
  String get pleaseSelectContactFromPhone;

  /// No description provided for @noContactsFound.
  ///
  /// In en, this message translates to:
  /// **'No contacts found'**
  String get noContactsFound;

  /// No description provided for @noContactsYet.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get noContactsYet;

  /// No description provided for @noContactsAvailableInPhone.
  ///
  /// In en, this message translates to:
  /// **'No contacts available in your phone'**
  String get noContactsAvailableInPhone;

  /// No description provided for @searchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts...'**
  String get searchContacts;

  /// No description provided for @searchContactsByNameOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Search contacts by name or phone...'**
  String get searchContactsByNameOrPhone;

  /// No description provided for @searchTransactionsByNameOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Search transactions by name or phone...'**
  String get searchTransactionsByNameOrPhone;

  /// No description provided for @allContacts.
  ///
  /// In en, this message translates to:
  /// **'All Contacts'**
  String get allContacts;

  /// No description provided for @noMatchingContacts.
  ///
  /// In en, this message translates to:
  /// **'No matching contacts'**
  String get noMatchingContacts;

  /// No description provided for @noSettledContacts.
  ///
  /// In en, this message translates to:
  /// **'No settled contacts'**
  String get noSettledContacts;

  /// No description provided for @noPendingContacts.
  ///
  /// In en, this message translates to:
  /// **'No pending contacts'**
  String get noPendingContacts;

  /// No description provided for @noContactsWithZeroBalance.
  ///
  /// In en, this message translates to:
  /// **'No contacts with zero balance found'**
  String get noContactsWithZeroBalance;

  /// No description provided for @noContactsWithPendingBalance.
  ///
  /// In en, this message translates to:
  /// **'No contacts with pending balance found'**
  String get noContactsWithPendingBalance;

  /// No description provided for @contactMustHavePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Contact must have a phone number'**
  String get contactMustHavePhoneNumber;

  /// No description provided for @thisContactIsAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'This contact is already added'**
  String get thisContactIsAlreadyAdded;

  /// No description provided for @phoneAlreadySavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone already saved'**
  String get phoneAlreadySavedTitle;

  /// No description provided for @phoneAlreadySavedMessage.
  ///
  /// In en, this message translates to:
  /// **'This number is already saved as {contactName}. Use that contact for this split?'**
  String phoneAlreadySavedMessage(Object contactName);

  /// No description provided for @useExistingContact.
  ///
  /// In en, this message translates to:
  /// **'Use Existing'**
  String get useExistingContact;

  /// No description provided for @contactsAlreadyAddedMarked.
  ///
  /// In en, this message translates to:
  /// **'Contacts already added are marked with a checkmark'**
  String get contactsAlreadyAddedMarked;

  /// No description provided for @contactsPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission is required'**
  String get contactsPermissionRequired;

  /// No description provided for @checkingExistingContacts.
  ///
  /// In en, this message translates to:
  /// **'Checking existing contacts...'**
  String get checkingExistingContacts;

  /// No description provided for @comment_contact_fields.
  ///
  /// In en, this message translates to:
  /// **'========== Contact Fields =========='**
  String get comment_contact_fields;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneNumbersSmall.
  ///
  /// In en, this message translates to:
  /// **'phone numbers'**
  String get phoneNumbersSmall;

  /// No description provided for @phoneNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (Optional)'**
  String get phoneNumberOptional;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (Optional)'**
  String get emailOptional;

  /// No description provided for @enterContactName.
  ///
  /// In en, this message translates to:
  /// **'Enter contact name'**
  String get enterContactName;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @enterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter email address'**
  String get enterEmailAddress;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// No description provided for @pleaseEnterContactName.
  ///
  /// In en, this message translates to:
  /// **'Please enter contact name'**
  String get pleaseEnterContactName;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @phoneContacts.
  ///
  /// In en, this message translates to:
  /// **'Phone Contacts'**
  String get phoneContacts;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// No description provided for @startTrackingYourMoneyWith.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your money with'**
  String get startTrackingYourMoneyWith;

  /// No description provided for @comment_dates.
  ///
  /// In en, this message translates to:
  /// **'========== Dates =========='**
  String get comment_dates;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @dateRequired.
  ///
  /// In en, this message translates to:
  /// **'Date *'**
  String get dateRequired;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get updatedAt;

  /// No description provided for @expectedDate.
  ///
  /// In en, this message translates to:
  /// **'Expected Date'**
  String get expectedDate;

  /// No description provided for @expectedReturn.
  ///
  /// In en, this message translates to:
  /// **'Expected Return'**
  String get expectedReturn;

  /// No description provided for @expectedReturnDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Expected Return Date (Optional)'**
  String get expectedReturnDateOptional;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectExpectedDate.
  ///
  /// In en, this message translates to:
  /// **'Select Expected Date'**
  String get selectExpectedDate;

  /// No description provided for @selectExpectedReturnDate.
  ///
  /// In en, this message translates to:
  /// **'Select Expected Return Date'**
  String get selectExpectedReturnDate;

  /// No description provided for @tapToSet.
  ///
  /// In en, this message translates to:
  /// **'Tap to set'**
  String get tapToSet;

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get clearDate;

  /// No description provided for @comment_descriptions.
  ///
  /// In en, this message translates to:
  /// **'========== Descriptions =========='**
  String get comment_descriptions;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @addDescription.
  ///
  /// In en, this message translates to:
  /// **'Add Description'**
  String get addDescription;

  /// No description provided for @whatDidYouSpendOn.
  ///
  /// In en, this message translates to:
  /// **'What did you spend on?'**
  String get whatDidYouSpendOn;

  /// No description provided for @whatWasThisExpenseFor.
  ///
  /// In en, this message translates to:
  /// **'What was this expense for?'**
  String get whatWasThisExpenseFor;

  /// No description provided for @addNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Add notes (optional)'**
  String get addNotesOptional;

  /// No description provided for @addNoteAboutTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add a note about this transaction'**
  String get addNoteAboutTransaction;

  /// No description provided for @addDetailsAboutItems.
  ///
  /// In en, this message translates to:
  /// **'Add details about the items or service'**
  String get addDetailsAboutItems;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescription;

  /// No description provided for @comment_expenses.
  ///
  /// In en, this message translates to:
  /// **'========== Expenses =========='**
  String get comment_expenses;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpense;

  /// No description provided for @deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get deleteExpense;

  /// No description provided for @saveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save Expense'**
  String get saveExpense;

  /// No description provided for @updateExpense.
  ///
  /// In en, this message translates to:
  /// **'Update Expense'**
  String get updateExpense;

  /// No description provided for @personalExpense.
  ///
  /// In en, this message translates to:
  /// **'Personal Expense'**
  String get personalExpense;

  /// No description provided for @trackYourSpending.
  ///
  /// In en, this message translates to:
  /// **'Track your spending'**
  String get trackYourSpending;

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get expenseDeleted;

  /// No description provided for @noExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpensesYet;

  /// No description provided for @startTrackingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your personal expenses to better manage your finances'**
  String get startTrackingExpenses;

  /// No description provided for @comment_expense_categories.
  ///
  /// In en, this message translates to:
  /// **'========== Expense Categories =========='**
  String get comment_expense_categories;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @foodDining.
  ///
  /// In en, this message translates to:
  /// **'Food & Dining'**
  String get foodDining;

  /// No description provided for @transportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get transportation;

  /// No description provided for @shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// No description provided for @entertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get entertainment;

  /// No description provided for @billsUtilities.
  ///
  /// In en, this message translates to:
  /// **'Bills & Utilities'**
  String get billsUtilities;

  /// No description provided for @healthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get healthcare;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// No description provided for @groceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get groceries;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @chooseRightCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose the right category to track your spending better!'**
  String get chooseRightCategory;

  /// No description provided for @comment_splits.
  ///
  /// In en, this message translates to:
  /// **'========== Splits =========='**
  String get comment_splits;

  /// No description provided for @split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// No description provided for @splitExpense.
  ///
  /// In en, this message translates to:
  /// **'Split Expense'**
  String get splitExpense;

  /// No description provided for @splitExpenses.
  ///
  /// In en, this message translates to:
  /// **'Split Expenses'**
  String get splitExpenses;

  /// No description provided for @addSplit.
  ///
  /// In en, this message translates to:
  /// **'Add Split'**
  String get addSplit;

  /// No description provided for @editSplit.
  ///
  /// In en, this message translates to:
  /// **'Edit Split'**
  String get editSplit;

  /// No description provided for @editSplitExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Split Expense'**
  String get editSplitExpense;

  /// No description provided for @deleteSplit.
  ///
  /// In en, this message translates to:
  /// **'Delete Split'**
  String get deleteSplit;

  /// No description provided for @deleteSplitExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete Split Expense'**
  String get deleteSplitExpense;

  /// No description provided for @splitDetails.
  ///
  /// In en, this message translates to:
  /// **'Split Details'**
  String get splitDetails;

  /// No description provided for @splitDeleted.
  ///
  /// In en, this message translates to:
  /// **'Split deleted'**
  String get splitDeleted;

  /// No description provided for @splitExpenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Split expense deleted'**
  String get splitExpenseDeleted;

  /// No description provided for @splitMarkedAsSettled.
  ///
  /// In en, this message translates to:
  /// **'Split marked as settled'**
  String get splitMarkedAsSettled;

  /// No description provided for @splitNotFound.
  ///
  /// In en, this message translates to:
  /// **'Split not found'**
  String get splitNotFound;

  /// No description provided for @noSplitsYet.
  ///
  /// In en, this message translates to:
  /// **'No splits yet'**
  String get noSplitsYet;

  /// No description provided for @noSplitExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No split expenses yet'**
  String get noSplitExpensesYet;

  /// No description provided for @noMoreSplits.
  ///
  /// In en, this message translates to:
  /// **'No more splits'**
  String get noMoreSplits;

  /// No description provided for @noSplitsFound.
  ///
  /// In en, this message translates to:
  /// **'No splits found'**
  String get noSplitsFound;

  /// No description provided for @startSplittingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Start splitting expenses with friends and family'**
  String get startSplittingExpenses;

  /// No description provided for @startSplittingExpensesWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Start splitting expenses with friends'**
  String get startSplittingExpensesWithFriends;

  /// No description provided for @shareCostsWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Share costs with friends'**
  String get shareCostsWithFriends;

  /// No description provided for @addParticipants.
  ///
  /// In en, this message translates to:
  /// **'Add Participants'**
  String get addParticipants;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @selectParticipants.
  ///
  /// In en, this message translates to:
  /// **'Select Participants'**
  String get selectParticipants;

  /// No description provided for @participantsMustBeSelected.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one participant'**
  String get participantsMustBeSelected;

  /// No description provided for @noParticipantsAdded.
  ///
  /// In en, this message translates to:
  /// **'No participants added yet'**
  String get noParticipantsAdded;

  /// No description provided for @addAtLeastOnePerson.
  ///
  /// In en, this message translates to:
  /// **'Add at least one person to split with'**
  String get addAtLeastOnePerson;

  /// No description provided for @totalParticipantShares.
  ///
  /// In en, this message translates to:
  /// **'Total participant shares'**
  String get totalParticipantShares;

  /// No description provided for @recentSplits.
  ///
  /// In en, this message translates to:
  /// **'Recent Splits'**
  String get recentSplits;

  /// No description provided for @searchSplits.
  ///
  /// In en, this message translates to:
  /// **'Search splits...'**
  String get searchSplits;

  /// No description provided for @createSplit.
  ///
  /// In en, this message translates to:
  /// **'Create Split'**
  String get createSplit;

  /// No description provided for @updateSplit.
  ///
  /// In en, this message translates to:
  /// **'Update Split'**
  String get updateSplit;

  /// No description provided for @settleAnyway.
  ///
  /// In en, this message translates to:
  /// **'Settle Anyway'**
  String get settleAnyway;

  /// No description provided for @settleSplit.
  ///
  /// In en, this message translates to:
  /// **'Settle Split'**
  String get settleSplit;

  /// No description provided for @reviewAndSettleSplit.
  ///
  /// In en, this message translates to:
  /// **'Review & Settle Split'**
  String get reviewAndSettleSplit;

  /// No description provided for @notPaidYet.
  ///
  /// In en, this message translates to:
  /// **'Not Paid Yet'**
  String get notPaidYet;

  /// No description provided for @pendingSettlements.
  ///
  /// In en, this message translates to:
  /// **'Pending Settlements'**
  String get pendingSettlements;

  /// No description provided for @partiallySettled.
  ///
  /// In en, this message translates to:
  /// **'Partially Settled'**
  String get partiallySettled;

  /// No description provided for @settledOrNoAction.
  ///
  /// In en, this message translates to:
  /// **'Settled / No Action'**
  String get settledOrNoAction;

  /// No description provided for @reviewPendingSettlements.
  ///
  /// In en, this message translates to:
  /// **'Review pending settlements before closing this split.'**
  String get reviewPendingSettlements;

  /// No description provided for @pendingSettlementsWillBeMarkedComplete.
  ///
  /// In en, this message translates to:
  /// **'{count} pending settlement(s) will be marked complete.'**
  String pendingSettlementsWillBeMarkedComplete(Object count);

  /// No description provided for @settlementsToClose.
  ///
  /// In en, this message translates to:
  /// **'Settlements to close'**
  String get settlementsToClose;

  /// No description provided for @settlementRoute.
  ///
  /// In en, this message translates to:
  /// **'Settlement Route'**
  String get settlementRoute;

  /// No description provided for @optimizedRoute.
  ///
  /// In en, this message translates to:
  /// **'Optimized'**
  String get optimizedRoute;

  /// No description provided for @settleViaPerson.
  ///
  /// In en, this message translates to:
  /// **'Via Person'**
  String get settleViaPerson;

  /// No description provided for @routeThroughTrustedPerson.
  ///
  /// In en, this message translates to:
  /// **'Route payments through a trusted person.'**
  String get routeThroughTrustedPerson;

  /// No description provided for @selectRoutePerson.
  ///
  /// In en, this message translates to:
  /// **'Select route person'**
  String get selectRoutePerson;

  /// No description provided for @routePlanOnly.
  ///
  /// In en, this message translates to:
  /// **'This only changes the suggested payment path. Mark people as paid after they actually settle.'**
  String get routePlanOnly;

  /// No description provided for @settlementRouteCompleted.
  ///
  /// In en, this message translates to:
  /// **'Settlement was completed using this route.'**
  String get settlementRouteCompleted;

  /// No description provided for @settlingWillCloseThesePayments.
  ///
  /// In en, this message translates to:
  /// **'This will close these payments and remove generated split ledger entries.'**
  String get settlingWillCloseThesePayments;

  /// No description provided for @allSettlementsAlreadyComplete.
  ///
  /// In en, this message translates to:
  /// **'All settlements are already complete. Mark this split as settled?'**
  String get allSettlementsAlreadyComplete;

  /// No description provided for @yourShare.
  ///
  /// In en, this message translates to:
  /// **'Your Share'**
  String get yourShare;

  /// No description provided for @paymentBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Payment Breakdown'**
  String get paymentBreakdown;

  /// No description provided for @addMore.
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get addMore;

  /// No description provided for @markReceived.
  ///
  /// In en, this message translates to:
  /// **'Mark Received'**
  String get markReceived;

  /// No description provided for @markAsReceived.
  ///
  /// In en, this message translates to:
  /// **'Mark as Received'**
  String get markAsReceived;

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark Paid'**
  String get markPaid;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @alreadyPaid.
  ///
  /// In en, this message translates to:
  /// **'Already Paid'**
  String get alreadyPaid;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid'**
  String get amountPaid;

  /// No description provided for @paidDuringBill.
  ///
  /// In en, this message translates to:
  /// **'Paid during bill'**
  String get paidDuringBill;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @fullAmount.
  ///
  /// In en, this message translates to:
  /// **'Full Amount'**
  String get fullAmount;

  /// No description provided for @amountReceived.
  ///
  /// In en, this message translates to:
  /// **'Amount Received'**
  String get amountReceived;

  /// No description provided for @markPartial.
  ///
  /// In en, this message translates to:
  /// **'Mark Partial'**
  String get markPartial;

  /// No description provided for @markFull.
  ///
  /// In en, this message translates to:
  /// **'Mark Full'**
  String get markFull;

  /// No description provided for @pendingPayments.
  ///
  /// In en, this message translates to:
  /// **'Pending Payments'**
  String get pendingPayments;

  /// No description provided for @settledAmountLeft.
  ///
  /// In en, this message translates to:
  /// **'Settled {settledAmount} • Left {leftAmount}'**
  String settledAmountLeft(Object settledAmount, Object leftAmount);

  /// No description provided for @personOwesCounterparty.
  ///
  /// In en, this message translates to:
  /// **'{personName} owes {counterpartyName} {amount}'**
  String personOwesCounterparty(
    Object personName,
    Object counterpartyName,
    Object amount,
  );

  /// No description provided for @owesCounterparty.
  ///
  /// In en, this message translates to:
  /// **'Owes {counterpartyName} {amount}'**
  String owesCounterparty(Object counterpartyName, Object amount);

  /// No description provided for @youOwePerson.
  ///
  /// In en, this message translates to:
  /// **'You owe {personName} {amount}'**
  String youOwePerson(Object personName, Object amount);

  /// No description provided for @fullRemainingAmountWillBeMarkedAsReceived.
  ///
  /// In en, this message translates to:
  /// **'The full remaining amount will be marked as received.'**
  String get fullRemainingAmountWillBeMarkedAsReceived;

  /// No description provided for @onlyEnteredAmountWillBeMarkedAsReceived.
  ///
  /// In en, this message translates to:
  /// **'Only the entered amount will be marked as received.'**
  String get onlyEnteredAmountWillBeMarkedAsReceived;

  /// No description provided for @fullRemainingAmountWillBeMarkedAsPaid.
  ///
  /// In en, this message translates to:
  /// **'The full remaining amount will be marked as paid.'**
  String get fullRemainingAmountWillBeMarkedAsPaid;

  /// No description provided for @onlyEnteredAmountWillBeMarkedAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Only the entered amount will be marked as paid.'**
  String get onlyEnteredAmountWillBeMarkedAsPaid;

  /// No description provided for @deleteSplitConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this split expense? This action cannot be undone.'**
  String get deleteSplitConfirmMessage;

  /// No description provided for @doYouWantToMarkSettled.
  ///
  /// In en, this message translates to:
  /// **'Do you still want to mark this as settled? This action cannot be undone.'**
  String get doYouWantToMarkSettled;

  /// No description provided for @allParticipantHasPaidTheirShareMarkAsSetteled.
  ///
  /// In en, this message translates to:
  /// **'All participants have paid their share. Mark this split as settled?\n\nThis action cannot be undone.'**
  String get allParticipantHasPaidTheirShareMarkAsSetteled;

  /// No description provided for @amountYouPaidCannotExceedTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount you paid cannot exceed total amount'**
  String get amountYouPaidCannotExceedTotalAmount;

  /// No description provided for @comment_split_fields.
  ///
  /// In en, this message translates to:
  /// **'========== Split Fields =========='**
  String get comment_split_fields;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get titleRequired;

  /// No description provided for @splitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split Title'**
  String get splitTitle;

  /// No description provided for @enterSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter split title'**
  String get enterSplitTitle;

  /// No description provided for @egDinnerAtRestaurant.
  ///
  /// In en, this message translates to:
  /// **'e.g., Dinner at Restaurant'**
  String get egDinnerAtRestaurant;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// No description provided for @howMuchDidYouPay.
  ///
  /// In en, this message translates to:
  /// **'How much did you pay?'**
  String get howMuchDidYouPay;

  /// No description provided for @enterTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter total amount'**
  String get enterTotalAmount;

  /// No description provided for @enterYourShare.
  ///
  /// In en, this message translates to:
  /// **'Enter your share'**
  String get enterYourShare;

  /// No description provided for @splitEqually.
  ///
  /// In en, this message translates to:
  /// **'Split equally'**
  String get splitEqually;

  /// No description provided for @splitByAmount.
  ///
  /// In en, this message translates to:
  /// **'Split by Amount'**
  String get splitByAmount;

  /// No description provided for @splitMethod.
  ///
  /// In en, this message translates to:
  /// **'Split Method'**
  String get splitMethod;

  /// No description provided for @divideAmountEvenlyAmongAll.
  ///
  /// In en, this message translates to:
  /// **'Divide amount evenly among all'**
  String get divideAmountEvenlyAmongAll;

  /// No description provided for @yourShareWillBeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Your share will be the remaining amount'**
  String get yourShareWillBeRemaining;

  /// No description provided for @comment_status.
  ///
  /// In en, this message translates to:
  /// **'========== Status =========='**
  String get comment_status;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @paymentOverdue.
  ///
  /// In en, this message translates to:
  /// **'This payment is overdue'**
  String get paymentOverdue;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @comment_statistics.
  ///
  /// In en, this message translates to:
  /// **'========== Statistics =========='**
  String get comment_statistics;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @yourDataOverview.
  ///
  /// In en, this message translates to:
  /// **'Your Data Overview'**
  String get yourDataOverview;

  /// No description provided for @totalTransactions.
  ///
  /// In en, this message translates to:
  /// **'Total Transactions'**
  String get totalTransactions;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @totalSplits.
  ///
  /// In en, this message translates to:
  /// **'Total Splits'**
  String get totalSplits;

  /// No description provided for @youOwe.
  ///
  /// In en, this message translates to:
  /// **'You Owe'**
  String get youOwe;

  /// No description provided for @oweYou.
  ///
  /// In en, this message translates to:
  /// **'Owe You'**
  String get oweYou;

  /// No description provided for @totalOwed.
  ///
  /// In en, this message translates to:
  /// **'Total Owed'**
  String get totalOwed;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @topCategory.
  ///
  /// In en, this message translates to:
  /// **'Top Category'**
  String get topCategory;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @allExpenses.
  ///
  /// In en, this message translates to:
  /// **'All Expenses'**
  String get allExpenses;

  /// No description provided for @addYourFirstExpenseToSeeInsights.
  ///
  /// In en, this message translates to:
  /// **'Add your first expense to see insights,\ncharts and spending analysis'**
  String get addYourFirstExpenseToSeeInsights;

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get spendingByCategory;

  /// No description provided for @monthlyTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly Trend'**
  String get monthlyTrend;

  /// No description provided for @categoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get categoryBreakdown;

  /// No description provided for @searchExpenses.
  ///
  /// In en, this message translates to:
  /// **'Search Expenses'**
  String get searchExpenses;

  /// No description provided for @noMatchingExpenses.
  ///
  /// In en, this message translates to:
  /// **'No matching expenses'**
  String get noMatchingExpenses;

  /// No description provided for @addFirstExpenseToStartTracking.
  ///
  /// In en, this message translates to:
  /// **'Add your first expense to start tracking'**
  String get addFirstExpenseToStartTracking;

  /// No description provided for @comment_udhari.
  ///
  /// In en, this message translates to:
  /// **'========== Udhari Fields =========='**
  String get comment_udhari;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @itemServiceName.
  ///
  /// In en, this message translates to:
  /// **'Item/Service Name'**
  String get itemServiceName;

  /// No description provided for @itemServiceNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Item/Service Name *'**
  String get itemServiceNameRequired;

  /// No description provided for @itemService.
  ///
  /// In en, this message translates to:
  /// **'Item/Service'**
  String get itemService;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @quantityOptional.
  ///
  /// In en, this message translates to:
  /// **'Quantity (Optional)'**
  String get quantityOptional;

  /// No description provided for @enterItemName.
  ///
  /// In en, this message translates to:
  /// **'Enter item name'**
  String get enterItemName;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get enterQuantity;

  /// No description provided for @pleaseEnterItemOrServiceName.
  ///
  /// In en, this message translates to:
  /// **'Please enter item or service name'**
  String get pleaseEnterItemOrServiceName;

  /// No description provided for @egMilkMedicalGroceries.
  ///
  /// In en, this message translates to:
  /// **'e.g., Milk, Medical Treatment, Groceries'**
  String get egMilkMedicalGroceries;

  /// No description provided for @egQuantityExamples.
  ///
  /// In en, this message translates to:
  /// **'e.g., 2 liters, 1 session, 5 kg'**
  String get egQuantityExamples;

  /// No description provided for @whatDidYouGiveOrTake.
  ///
  /// In en, this message translates to:
  /// **'What did you give or take?'**
  String get whatDidYouGiveOrTake;

  /// No description provided for @howMany.
  ///
  /// In en, this message translates to:
  /// **'How many?'**
  String get howMany;

  /// No description provided for @comment_settlement.
  ///
  /// In en, this message translates to:
  /// **'========== Settlement =========='**
  String get comment_settlement;

  /// No description provided for @settlement.
  ///
  /// In en, this message translates to:
  /// **'Settlement'**
  String get settlement;

  /// No description provided for @settleUp.
  ///
  /// In en, this message translates to:
  /// **'Settle Up'**
  String get settleUp;

  /// No description provided for @markAsSettled.
  ///
  /// In en, this message translates to:
  /// **'Mark as Settled'**
  String get markAsSettled;

  /// No description provided for @settleAmount.
  ///
  /// In en, this message translates to:
  /// **'Settle Amount'**
  String get settleAmount;

  /// No description provided for @settleBalance.
  ///
  /// In en, this message translates to:
  /// **'Settle Balance'**
  String get settleBalance;

  /// No description provided for @settlementTransaction.
  ///
  /// In en, this message translates to:
  /// **'Settlement Transaction'**
  String get settlementTransaction;

  /// No description provided for @balanceSettledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Balance settled successfully'**
  String get balanceSettledSuccessfully;

  /// No description provided for @clearThisBalance.
  ///
  /// In en, this message translates to:
  /// **'Clear this balance'**
  String get clearThisBalance;

  /// No description provided for @fullSettlement.
  ///
  /// In en, this message translates to:
  /// **'Full Settlement'**
  String get fullSettlement;

  /// No description provided for @partialSettlement.
  ///
  /// In en, this message translates to:
  /// **'Partial Settlement'**
  String get partialSettlement;

  /// No description provided for @settlementAmount.
  ///
  /// In en, this message translates to:
  /// **'Settlement Amount'**
  String get settlementAmount;

  /// No description provided for @enterSettlementAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter settlement amount'**
  String get enterSettlementAmount;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @setToFullBalance.
  ///
  /// In en, this message translates to:
  /// **'Set to full balance'**
  String get setToFullBalance;

  /// No description provided for @settlePartial.
  ///
  /// In en, this message translates to:
  /// **'Settle Partial'**
  String get settlePartial;

  /// No description provided for @settleFull.
  ///
  /// In en, this message translates to:
  /// **'Settle Full'**
  String get settleFull;

  /// No description provided for @partialSettlementInfoPositive.
  ///
  /// In en, this message translates to:
  /// **'A \"You Got\" transaction will be created for the entered amount, reducing your balance.'**
  String get partialSettlementInfoPositive;

  /// No description provided for @partialSettlementInfoNegative.
  ///
  /// In en, this message translates to:
  /// **'A \"You Gave\" transaction will be created for the entered amount, reducing your balance.'**
  String get partialSettlementInfoNegative;

  /// No description provided for @fullSettlementInfoPositive.
  ///
  /// In en, this message translates to:
  /// **'A \"You Got\" transaction will be created to settle the full balance to zero.'**
  String get fullSettlementInfoPositive;

  /// No description provided for @fullSettlementInfoNegative.
  ///
  /// In en, this message translates to:
  /// **'A \"You Gave\" transaction will be created to settle the full balance to zero.'**
  String get fullSettlementInfoNegative;

  /// No description provided for @comment_dialogs_delete.
  ///
  /// In en, this message translates to:
  /// **'========== Delete Dialogs =========='**
  String get comment_dialogs_delete;

  /// No description provided for @deleteExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense?'**
  String get deleteExpenseTitle;

  /// No description provided for @deleteExpenseMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this expense?'**
  String get deleteExpenseMessage;

  /// No description provided for @deleteTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction?'**
  String get deleteTransactionTitle;

  /// No description provided for @deleteTransactionMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?'**
  String get deleteTransactionMessage;

  /// No description provided for @deleteSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Split?'**
  String get deleteSplitTitle;

  /// No description provided for @deleteSplitMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this split expense?'**
  String get deleteSplitMessage;

  /// No description provided for @actionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get actionCannotBeUndone;

  /// No description provided for @permanentlyDelete.
  ///
  /// In en, this message translates to:
  /// **'PERMANENTLY DELETE:'**
  String get permanentlyDelete;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. The expense will be permanently removed from your records.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @comment_dialogs_clear_data.
  ///
  /// In en, this message translates to:
  /// **'========== Clear Data Dialog =========='**
  String get comment_dialogs_clear_data;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @clearAllDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data?'**
  String get clearAllDataTitle;

  /// No description provided for @clearAllDataMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete everything'**
  String get clearAllDataMessage;

  /// No description provided for @deleteEverything.
  ///
  /// In en, this message translates to:
  /// **'Delete Everything'**
  String get deleteEverything;

  /// No description provided for @deletingData.
  ///
  /// In en, this message translates to:
  /// **'Deleting data...'**
  String get deletingData;

  /// No description provided for @allDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data has been cleared'**
  String get allDataCleared;

  /// No description provided for @currentDataWillBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Current data will be permanently deleted:'**
  String get currentDataWillBeDeleted;

  /// No description provided for @allDataHasBeenCleared.
  ///
  /// In en, this message translates to:
  /// **'All data has been cleared'**
  String get allDataHasBeenCleared;

  /// No description provided for @thisWillPermanentlyDelete.
  ///
  /// In en, this message translates to:
  /// **'This will PERMANENTLY DELETE:'**
  String get thisWillPermanentlyDelete;

  /// No description provided for @allTransactionsItem.
  ///
  /// In en, this message translates to:
  /// **'All transactions'**
  String get allTransactionsItem;

  /// No description provided for @allExpensesItem.
  ///
  /// In en, this message translates to:
  /// **'All expenses'**
  String get allExpensesItem;

  /// No description provided for @allSplitExpensesItem.
  ///
  /// In en, this message translates to:
  /// **'All split expenses'**
  String get allSplitExpensesItem;

  /// No description provided for @allContactReferencesItem.
  ///
  /// In en, this message translates to:
  /// **'All contact references'**
  String get allContactReferencesItem;

  /// No description provided for @considerExportingDataFirst.
  ///
  /// In en, this message translates to:
  /// **'Consider exporting your data first. This action cannot be undone!'**
  String get considerExportingDataFirst;

  /// No description provided for @comment_dialogs_export.
  ///
  /// In en, this message translates to:
  /// **'========== Export Dialog =========='**
  String get comment_dialogs_export;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @exportDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportDataTitle;

  /// No description provided for @exportDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a backup file containing all your data'**
  String get exportDataMessage;

  /// No description provided for @whatWillBeExported.
  ///
  /// In en, this message translates to:
  /// **'What will be exported:'**
  String get whatWillBeExported;

  /// No description provided for @allTransactionsLendBorrow.
  ///
  /// In en, this message translates to:
  /// **'All transactions (lend/borrow)'**
  String get allTransactionsLendBorrow;

  /// No description provided for @allPersonalExpenses.
  ///
  /// In en, this message translates to:
  /// **'All personal expenses'**
  String get allPersonalExpenses;

  /// No description provided for @allSplitExpenses.
  ///
  /// In en, this message translates to:
  /// **'All split expenses'**
  String get allSplitExpenses;

  /// No description provided for @contactReferences.
  ///
  /// In en, this message translates to:
  /// **'Contact references'**
  String get contactReferences;

  /// No description provided for @canShareBackupFile.
  ///
  /// In en, this message translates to:
  /// **'You can share the backup file or save it for later import'**
  String get canShareBackupFile;

  /// No description provided for @preparingExport.
  ///
  /// In en, this message translates to:
  /// **'Preparing export...'**
  String get preparingExport;

  /// No description provided for @exportSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Export Successful!'**
  String get exportSuccessful;

  /// No description provided for @savedInBackupsFolder.
  ///
  /// In en, this message translates to:
  /// **'Saved in Backups folder'**
  String get savedInBackupsFolder;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @comment_dialogs_import.
  ///
  /// In en, this message translates to:
  /// **'========== Import Dialog =========='**
  String get comment_dialogs_import;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @importDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importDataTitle;

  /// No description provided for @importDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Restore data from backup file'**
  String get importDataMessage;

  /// No description provided for @thisWillReplaceAllData.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Warning: This will REPLACE all your current data!'**
  String get thisWillReplaceAllData;

  /// No description provided for @makeSureHaveBackup.
  ///
  /// In en, this message translates to:
  /// **'Make sure you have a backup before proceeding!'**
  String get makeSureHaveBackup;

  /// No description provided for @importingData.
  ///
  /// In en, this message translates to:
  /// **'Importing data...'**
  String get importingData;

  /// No description provided for @importSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Import Successful!'**
  String get importSuccessful;

  /// No description provided for @successfullyImported.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported:'**
  String get successfullyImported;

  /// No description provided for @restartRecommended.
  ///
  /// In en, this message translates to:
  /// **'Restart recommended for best experience'**
  String get restartRecommended;

  /// No description provided for @restartRecommendedMessage.
  ///
  /// In en, this message translates to:
  /// **'Restart recommended'**
  String get restartRecommendedMessage;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// No description provided for @thisWillReplaceAllDataWarning.
  ///
  /// In en, this message translates to:
  /// **'This will REPLACE all data!'**
  String get thisWillReplaceAllDataWarning;

  /// No description provided for @currentDataWillBePermanentlyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Current data will be permanently deleted:'**
  String get currentDataWillBePermanentlyDeleted;

  /// No description provided for @allTransactionsDeleted.
  ///
  /// In en, this message translates to:
  /// **'All transactions'**
  String get allTransactionsDeleted;

  /// No description provided for @allExpensesDeleted.
  ///
  /// In en, this message translates to:
  /// **'All expenses'**
  String get allExpensesDeleted;

  /// No description provided for @allSplitsDeleted.
  ///
  /// In en, this message translates to:
  /// **'All splits'**
  String get allSplitsDeleted;

  /// No description provided for @comment_settings.
  ///
  /// In en, this message translates to:
  /// **'========== Settings =========='**
  String get comment_settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @comment_theme.
  ///
  /// In en, this message translates to:
  /// **'========== Theme =========='**
  String get comment_theme;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @brightAndClean.
  ///
  /// In en, this message translates to:
  /// **'Bright and clean'**
  String get brightAndClean;

  /// No description provided for @easyOnEyes.
  ///
  /// In en, this message translates to:
  /// **'Easy on the eyes'**
  String get easyOnEyes;

  /// No description provided for @followDeviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Follow device settings'**
  String get followDeviceSettings;

  /// No description provided for @comment_backup.
  ///
  /// In en, this message translates to:
  /// **'========== Backup & Restore =========='**
  String get comment_backup;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create backup of all data'**
  String get createBackup;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup file'**
  String get restoreFromBackup;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// No description provided for @learnBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Learn about backup & restore'**
  String get learnBackupRestore;

  /// No description provided for @howBackupWorks.
  ///
  /// In en, this message translates to:
  /// **'How Backup Works'**
  String get howBackupWorks;

  /// No description provided for @createsJsonFile.
  ///
  /// In en, this message translates to:
  /// **'Creates a JSON file containing:'**
  String get createsJsonFile;

  /// No description provided for @fileSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'The file is saved locally and can be shared.'**
  String get fileSavedLocally;

  /// No description provided for @restoresDataFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restores data from backup:'**
  String get restoresDataFromBackup;

  /// No description provided for @replacesAllCurrentData.
  ///
  /// In en, this message translates to:
  /// **'Replaces all current data'**
  String get replacesAllCurrentData;

  /// No description provided for @importsAllRecords.
  ///
  /// In en, this message translates to:
  /// **'Imports all records'**
  String get importsAllRecords;

  /// No description provided for @maintainsRelationships.
  ///
  /// In en, this message translates to:
  /// **'Maintains relationships'**
  String get maintainsRelationships;

  /// No description provided for @alwaysExportBeforeImporting.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Always export before importing!'**
  String get alwaysExportBeforeImporting;

  /// No description provided for @bestPractices.
  ///
  /// In en, this message translates to:
  /// **'Best Practices'**
  String get bestPractices;

  /// No description provided for @exportRegularly.
  ///
  /// In en, this message translates to:
  /// **'Export regularly (weekly/monthly)'**
  String get exportRegularly;

  /// No description provided for @storeInCloudStorage.
  ///
  /// In en, this message translates to:
  /// **'Store backups in cloud storage'**
  String get storeInCloudStorage;

  /// No description provided for @neverDeleteLastBackup.
  ///
  /// In en, this message translates to:
  /// **'Never delete your last backup'**
  String get neverDeleteLastBackup;

  /// No description provided for @shareBackupsSecurely.
  ///
  /// In en, this message translates to:
  /// **'Share backups securely'**
  String get shareBackupsSecurely;

  /// No description provided for @backupFilesInJson.
  ///
  /// In en, this message translates to:
  /// **'Backup files are in JSON format and can be viewed in any text editor.'**
  String get backupFilesInJson;

  /// No description provided for @comment_about.
  ///
  /// In en, this message translates to:
  /// **'========== About =========='**
  String get comment_about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @viewTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'View terms and conditions'**
  String get viewTermsAndConditions;

  /// No description provided for @yourDataStaysOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on device'**
  String get yourDataStaysOnDevice;

  /// No description provided for @termsOfServiceContent.
  ///
  /// In en, this message translates to:
  /// **'This is a personal finance management app. Use it responsibly and at your own risk. All financial decisions are your responsibility.'**
  String get termsOfServiceContent;

  /// No description provided for @privacyPolicyContent.
  ///
  /// In en, this message translates to:
  /// **'All your data is stored locally on your device. We do not collect, transmit, or share any personal information. Your privacy is our priority.'**
  String get privacyPolicyContent;

  /// No description provided for @developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed By: Sagar Kalel'**
  String get developedBy;

  /// No description provided for @comment_permissions.
  ///
  /// In en, this message translates to:
  /// **'========== Permissions =========='**
  String get comment_permissions;

  /// No description provided for @storagePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Storage permission denied'**
  String get storagePermissionDenied;

  /// No description provided for @contactsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission denied'**
  String get contactsPermissionDenied;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @comment_empty_states.
  ///
  /// In en, this message translates to:
  /// **'========== Empty States =========='**
  String get comment_empty_states;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @startTrackingBorrowLend.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your lending and borrowing to stay organized'**
  String get startTrackingBorrowLend;

  /// No description provided for @startTrackingYourMoney.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your money by adding your first transaction'**
  String get startTrackingYourMoney;

  /// No description provided for @noContactTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noContactTransactions;

  /// No description provided for @noMatchingTransactions.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions'**
  String get noMatchingTransactions;

  /// No description provided for @noCashTransactions.
  ///
  /// In en, this message translates to:
  /// **'No cash transactions'**
  String get noCashTransactions;

  /// No description provided for @noUdhariTransactions.
  ///
  /// In en, this message translates to:
  /// **'No udhari transactions'**
  String get noUdhariTransactions;

  /// No description provided for @noMatchingCashTransactions.
  ///
  /// In en, this message translates to:
  /// **'No matching cash transactions'**
  String get noMatchingCashTransactions;

  /// No description provided for @noMatchingUdhariTransactions.
  ///
  /// In en, this message translates to:
  /// **'No matching udhari transactions'**
  String get noMatchingUdhariTransactions;

  /// No description provided for @addFirstTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add your first transaction to get started'**
  String get addFirstTransaction;

  /// No description provided for @addYourFirstCashTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add your first cash transaction'**
  String get addYourFirstCashTransaction;

  /// No description provided for @addYourFirstUdhariTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add your first udhari transaction'**
  String get addYourFirstUdhariTransaction;

  /// No description provided for @addFirstExpense.
  ///
  /// In en, this message translates to:
  /// **'Add your first expense to get started'**
  String get addFirstExpense;

  /// No description provided for @addFirstSplit.
  ///
  /// In en, this message translates to:
  /// **'Add your first split to get started'**
  String get addFirstSplit;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get tryAdjustingFilters;

  /// No description provided for @tryDifferentSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearchTerm;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @comment_view_modes.
  ///
  /// In en, this message translates to:
  /// **'========== View Modes =========='**
  String get comment_view_modes;

  /// No description provided for @viewMode.
  ///
  /// In en, this message translates to:
  /// **'View Mode'**
  String get viewMode;

  /// No description provided for @contactsView.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsView;

  /// No description provided for @cashView.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashView;

  /// No description provided for @udhariView.
  ///
  /// In en, this message translates to:
  /// **'Udhari'**
  String get udhariView;

  /// No description provided for @allView.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allView;

  /// No description provided for @comment_validation.
  ///
  /// In en, this message translates to:
  /// **'========== Validation Messages =========='**
  String get comment_validation;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhone;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @amountTooLow.
  ///
  /// In en, this message translates to:
  /// **'Amount is too low'**
  String get amountTooLow;

  /// No description provided for @amountTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Amount is too high'**
  String get amountTooHigh;

  /// No description provided for @pleaseSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get pleaseSelectDate;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @pleaseAddAtLeastOneParticipant.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one participant'**
  String get pleaseAddAtLeastOneParticipant;

  /// No description provided for @amountPaidCannotExceedTotal.
  ///
  /// In en, this message translates to:
  /// **'Amount you paid cannot exceed total amount'**
  String get amountPaidCannotExceedTotal;

  /// No description provided for @totalSharesExceedTotal.
  ///
  /// In en, this message translates to:
  /// **'Total shares exceed the total amount'**
  String get totalSharesExceedTotal;

  /// No description provided for @comment_actions.
  ///
  /// In en, this message translates to:
  /// **'========== Actions =========='**
  String get comment_actions;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Details'**
  String get editDetails;

  /// No description provided for @deleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get deleteRecord;

  /// No description provided for @shareData.
  ///
  /// In en, this message translates to:
  /// **'Share Data'**
  String get shareData;

  /// No description provided for @downloadBackup.
  ///
  /// In en, this message translates to:
  /// **'Download Backup'**
  String get downloadBackup;

  /// No description provided for @uploadBackup.
  ///
  /// In en, this message translates to:
  /// **'Upload Backup'**
  String get uploadBackup;

  /// No description provided for @comment_tips.
  ///
  /// In en, this message translates to:
  /// **'========== Tips & Hints =========='**
  String get comment_tips;

  /// No description provided for @tip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tip;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @selectContactFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a contact first'**
  String get selectContactFirst;

  /// No description provided for @fillAllRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get fillAllRequiredFields;

  /// No description provided for @dataWillBeLost.
  ///
  /// In en, this message translates to:
  /// **'Your data will be lost'**
  String get dataWillBeLost;

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone'**
  String get cannotBeUndone;

  /// No description provided for @comment_currencies.
  ///
  /// In en, this message translates to:
  /// **'========== Currency =========='**
  String get comment_currencies;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @rupee.
  ///
  /// In en, this message translates to:
  /// **'₹'**
  String get rupee;

  /// No description provided for @rupees.
  ///
  /// In en, this message translates to:
  /// **'Rupees'**
  String get rupees;

  /// No description provided for @inr.
  ///
  /// In en, this message translates to:
  /// **'INR'**
  String get inr;

  /// No description provided for @zeroDecimal.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get zeroDecimal;

  /// No description provided for @comment_time_periods.
  ///
  /// In en, this message translates to:
  /// **'========== Time Periods =========='**
  String get comment_time_periods;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @comment_actions_menu.
  ///
  /// In en, this message translates to:
  /// **'========== Transaction Menu =========='**
  String get comment_actions_menu;

  /// No description provided for @selectTransactionType.
  ///
  /// In en, this message translates to:
  /// **'Select Transaction Type'**
  String get selectTransactionType;

  /// No description provided for @whatWouldYouLikeToDo.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get whatWouldYouLikeToDo;

  /// No description provided for @chooseTransactionType.
  ///
  /// In en, this message translates to:
  /// **'Choose transaction type'**
  String get chooseTransactionType;

  /// No description provided for @comment_error_messages.
  ///
  /// In en, this message translates to:
  /// **'========== Error Messages =========='**
  String get comment_error_messages;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get failedToSave;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete'**
  String get failedToDelete;

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update'**
  String get failedToUpdate;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'Request timed out'**
  String get timeoutError;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to share'**
  String get shareFailed;

  /// No description provided for @comment_success_messages.
  ///
  /// In en, this message translates to:
  /// **'========== Success Messages =========='**
  String get comment_success_messages;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deletedSuccessfully;

  /// No description provided for @updatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully'**
  String get updatedSuccessfully;

  /// No description provided for @exportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Exported successfully'**
  String get exportedSuccessfully;

  /// No description provided for @importedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Imported successfully'**
  String get importedSuccessfully;

  /// No description provided for @comment_badges.
  ///
  /// In en, this message translates to:
  /// **'========== Badges =========='**
  String get comment_badges;

  /// No description provided for @youGaveBadge.
  ///
  /// In en, this message translates to:
  /// **'YOU GAVE'**
  String get youGaveBadge;

  /// No description provided for @youGotBadge.
  ///
  /// In en, this message translates to:
  /// **'YOU GOT'**
  String get youGotBadge;

  /// No description provided for @cashBadge.
  ///
  /// In en, this message translates to:
  /// **'CASH'**
  String get cashBadge;

  /// No description provided for @udhariBadge.
  ///
  /// In en, this message translates to:
  /// **'UDHARI'**
  String get udhariBadge;

  /// No description provided for @settledBadge.
  ///
  /// In en, this message translates to:
  /// **'SETTLED'**
  String get settledBadge;

  /// No description provided for @pendingBadge.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get pendingBadge;

  /// No description provided for @paidBadge.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get paidBadge;

  /// No description provided for @noActionBadge.
  ///
  /// In en, this message translates to:
  /// **'NO ACTION'**
  String get noActionBadge;

  /// No description provided for @comment_misc.
  ///
  /// In en, this message translates to:
  /// **'========== Miscellaneous =========='**
  String get comment_misc;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get pleaseWait;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search'**
  String get tryDifferentSearch;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get allCaughtUp;

  /// No description provided for @noMoreData.
  ///
  /// In en, this message translates to:
  /// **'No more data'**
  String get noMoreData;

  /// No description provided for @noMoreRecords.
  ///
  /// In en, this message translates to:
  /// **'No more records'**
  String get noMoreRecords;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @ofText.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofText;

  /// No description provided for @toText.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get toText;

  /// No description provided for @fromText.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get fromText;

  /// No description provided for @withText.
  ///
  /// In en, this message translates to:
  /// **'with'**
  String get withText;

  /// No description provided for @byText.
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get byText;

  /// No description provided for @onText.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get onText;

  /// No description provided for @atText.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get atText;

  /// No description provided for @inText.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get inText;

  /// No description provided for @trans.
  ///
  /// In en, this message translates to:
  /// **'Trans'**
  String get trans;

  /// No description provided for @exp.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get exp;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @personSmall.
  ///
  /// In en, this message translates to:
  /// **'person'**
  String get personSmall;

  /// No description provided for @peopleSmall.
  ///
  /// In en, this message translates to:
  /// **'people'**
  String get peopleSmall;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get yourProfile;

  /// No description provided for @setYourName.
  ///
  /// In en, this message translates to:
  /// **'Set your name'**
  String get setYourName;

  /// No description provided for @nameUsedInSharedSplits.
  ///
  /// In en, this message translates to:
  /// **'Used in shared splits and reports'**
  String get nameUsedInSharedSplits;

  /// No description provided for @helpFriendsRecognizeYou.
  ///
  /// In en, this message translates to:
  /// **'Help friends recognize who paid or owes'**
  String get helpFriendsRecognizeYou;

  /// No description provided for @yourNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Your Name *'**
  String get yourNameRequired;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @sharePdfStatement.
  ///
  /// In en, this message translates to:
  /// **'Share PDF Statement'**
  String get sharePdfStatement;

  /// No description provided for @shareLedgerPdf.
  ///
  /// In en, this message translates to:
  /// **'Share Ledger PDF'**
  String get shareLedgerPdf;

  /// No description provided for @preparingStatement.
  ///
  /// In en, this message translates to:
  /// **'Preparing statement...'**
  String get preparingStatement;

  /// No description provided for @last15Days.
  ///
  /// In en, this message translates to:
  /// **'Last 15 days'**
  String get last15Days;

  /// No description provided for @last3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get last3Months;

  /// No description provided for @last6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get last6Months;

  /// No description provided for @last1Year.
  ///
  /// In en, this message translates to:
  /// **'Last 1 year'**
  String get last1Year;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get customRange;

  /// No description provided for @borrowLedgerStatement.
  ///
  /// In en, this message translates to:
  /// **'HisaabMate Statement'**
  String get borrowLedgerStatement;

  /// No description provided for @borrowLedgerFullStatement.
  ///
  /// In en, this message translates to:
  /// **'HisaabMate Full Statement'**
  String get borrowLedgerFullStatement;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @generatedBy.
  ///
  /// In en, this message translates to:
  /// **'Generated by'**
  String get generatedBy;

  /// No description provided for @generatedOn.
  ///
  /// In en, this message translates to:
  /// **'Generated on'**
  String get generatedOn;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get opening;

  /// No description provided for @closing.
  ///
  /// In en, this message translates to:
  /// **'Closing'**
  String get closing;

  /// No description provided for @noTransactionsInDateRange.
  ///
  /// In en, this message translates to:
  /// **'No transactions found for this date range.'**
  String get noTransactionsInDateRange;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @gaveOnly.
  ///
  /// In en, this message translates to:
  /// **'Gave only'**
  String get gaveOnly;

  /// No description provided for @gotOnly.
  ///
  /// In en, this message translates to:
  /// **'Got only'**
  String get gotOnly;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @comment_language.
  ///
  /// In en, this message translates to:
  /// **'========== Language =========='**
  String get comment_language;

  /// Message shown when language is changed
  ///
  /// In en, this message translates to:
  /// **'Language changed to'**
  String get languageChangedTo;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get hindi;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get marathi;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
