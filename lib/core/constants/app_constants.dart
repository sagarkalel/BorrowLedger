class AppConstants {
  // App Info
  // static const String appName = 'BorrowLedger';
  // static const String appSlogen = 'Track • Manage • Settle';
  static const String appVersion = '1.0.0';

  // Database
  static const String dbName = 'borrow_ledger.db';
  static const int dbVersion = 6; // UPDATED: Added udhari_items table

  // Storage Keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String firstLaunchKey = 'first_launch';
  static const String backupPathKey = 'backup_path';

  // Transaction Types
  static const String typeBorrow = 'borrow';
  static const String typeLend = 'lend';
  static const String typeExpense = 'expense';
  static const String typeSplit = 'split';

  // Transaction Categories
  static const String categoryCash = 'cash';
  static const String categoryUdhari = 'udhari';

  // Transaction Status
  static const String statusPending = 'pending';
  static const String statusPaid = 'paid';
  static const String statusPartial = 'partial';
  static const String statusSettled = 'settled';

  // Expense Categories
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Travel',
    'Groceries',
    'Others',
  ];

  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateFormat2 = 'dd MMMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String monthYearFormat = 'MMMM yyyy';
  static const String dateMonthFormat = 'dd MMM';

  // Pagination
  static const int itemsPerPage = 20;

  // Animation Durations
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  // Export
  static const String exportFilePrefix = 'borrowledger_backup_';
  static const String csvExtension = '.csv';
  static const String jsonExtension = '.json';
}
