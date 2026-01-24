import 'dart:async';
import 'dart:developer';

import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/contact_model.dart';
import '../../data/repositories/transaction_repository.dart';

// Pagination constants
class PaginationConstants {
  static const int defaultPageSize = 10;
  static const int contactsPageSize = 10;
  static const int recentTransactionsLimit = 10;
  static const int dashboardContactsLimit = 10;
}

class BorrowLendState {
  final bool isLoading;
  final bool isLoadingMore;
  final double totalLent;
  final double totalBorrowed;
  final double totalReceivable;
  final double totalPayable;
  final double netBalance;

  // Category-wise breakdown
  final double cashLent;
  final double cashBorrowed;
  final double cashNet;
  final double udhariGiven;
  final double udhariTaken;
  final double udhariNet;

  // Transactions
  final List<TransactionModel> transactions;
  final List<TransactionModel> recentTransactions;
  final String? filterType;
  final String? filterCategory; // 'cash' or 'udhari'
  final String? searchQuery;

  // Contacts (for contacts view)
  final List<ContactSummary> contactSummaries;
  final bool isLoadingContacts;
  final bool isLoadingMoreContacts;
  final String? contactSearchQuery;
  final String? contactBalanceFilter; // 'all', 'settled', 'pending'

  final String? error;
  final String? successMessage;
  final DateTime? lastUpdate;

  // Pagination state for transactions
  final int currentPage;
  final bool hasMoreData;
  final int totalCount;

  // Pagination state for contacts
  final int currentContactsPage;
  final bool hasMoreContacts;
  final int totalContactsCount;

  // Active view mode tracking
  final String? activeViewMode; // 'contacts', 'cash', 'udhari'

  BorrowLendState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.totalLent = 0.0,
    this.totalBorrowed = 0.0,
    this.totalReceivable = 0.0,
    this.totalPayable = 0.0,
    this.netBalance = 0.0,
    this.cashLent = 0.0,
    this.cashBorrowed = 0.0,
    this.cashNet = 0.0,
    this.udhariGiven = 0.0,
    this.udhariTaken = 0.0,
    this.udhariNet = 0.0,
    this.transactions = const [],
    this.recentTransactions = const [],
    this.filterType,
    this.filterCategory,
    this.searchQuery,
    this.contactSummaries = const [],
    this.isLoadingContacts = false,
    this.isLoadingMoreContacts = false,
    this.contactSearchQuery,
    this.contactBalanceFilter,
    this.error,
    this.successMessage,
    this.lastUpdate,
    this.currentPage = 0,
    this.hasMoreData = true,
    this.totalCount = 0,
    this.currentContactsPage = 0,
    this.hasMoreContacts = true,
    this.totalContactsCount = 0,
    this.activeViewMode,
  });

  BorrowLendState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    double? totalLent,
    double? totalBorrowed,
    double? totalPayable,
    double? totalReceivable,
    double? netBalance,
    double? cashLent,
    double? cashBorrowed,
    double? cashNet,
    double? udhariGiven,
    double? udhariTaken,
    double? udhariNet,
    List<TransactionModel>? transactions,
    List<TransactionModel>? recentTransactions,
    String? filterType,
    bool clearFilterType = false,
    String? filterCategory,
    bool clearFilterCategory = false,
    String? searchQuery,
    bool clearSearchQuery = false,
    List<ContactSummary>? contactSummaries,
    bool? isLoadingContacts,
    bool? isLoadingMoreContacts,
    String? contactSearchQuery,
    bool clearContactSearchQuery = false,
    String? contactBalanceFilter,
    bool clearContactBalanceFilter = false,
    String? error,
    String? successMessage,
    DateTime? lastUpdate,
    int? currentPage,
    bool? hasMoreData,
    int? totalCount,
    int? currentContactsPage,
    bool? hasMoreContacts,
    int? totalContactsCount,
    String? activeViewMode,
    bool clearActiveViewMode = false,
  }) {
    return BorrowLendState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalLent: totalLent ?? this.totalLent,
      totalBorrowed: totalBorrowed ?? this.totalBorrowed,
      totalReceivable: totalReceivable ?? this.totalReceivable,
      totalPayable: totalPayable ?? this.totalPayable,
      netBalance: netBalance ?? this.netBalance,
      cashLent: cashLent ?? this.cashLent,
      cashBorrowed: cashBorrowed ?? this.cashBorrowed,
      cashNet: cashNet ?? this.cashNet,
      udhariGiven: udhariGiven ?? this.udhariGiven,
      udhariTaken: udhariTaken ?? this.udhariTaken,
      udhariNet: udhariNet ?? this.udhariNet,
      transactions: transactions ?? this.transactions,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
      filterCategory: clearFilterCategory
          ? null
          : (filterCategory ?? this.filterCategory),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      contactSummaries: contactSummaries ?? this.contactSummaries,
      isLoadingContacts: isLoadingContacts ?? this.isLoadingContacts,
      isLoadingMoreContacts:
          isLoadingMoreContacts ?? this.isLoadingMoreContacts,
      contactSearchQuery: clearContactSearchQuery
          ? null
          : (contactSearchQuery ?? this.contactSearchQuery),
      contactBalanceFilter: clearContactBalanceFilter
          ? null
          : (contactBalanceFilter ?? this.contactBalanceFilter),
      error: error,
      successMessage: successMessage,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      totalCount: totalCount ?? this.totalCount,
      currentContactsPage: currentContactsPage ?? this.currentContactsPage,
      hasMoreContacts: hasMoreContacts ?? this.hasMoreContacts,
      totalContactsCount: totalContactsCount ?? this.totalContactsCount,
      activeViewMode: clearActiveViewMode
          ? null
          : (activeViewMode ?? this.activeViewMode),
    );
  }
}

class BorrowLendCubit extends Cubit<BorrowLendState> {
  final TransactionRepository _transactionRepository;
  late Timer timer;
  BorrowLendCubit(this._transactionRepository) : super(BorrowLendState());

  /// Load all data (dashboard summary + initial transactions)
  Future<void> loadAllData() async {
    log('BorrowLendCubit: Loading all data...');
    emit(
      state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 0,
        hasMoreData: true,
      ),
    );

    try {
      // Get dashboard summary with category breakdown
      log('BorrowLendCubit: Fetching dashboard summary...');
      final summary = await _transactionRepository.getDashboardSummary();
      final totalLent = summary['total_lent'] ?? 0.0;
      final totalBorrowed = summary['total_borrowed'] ?? 0.0;
      final netBalance = summary['net_balance'] ?? 0.0;
      final cashLent = summary['cash_lent'] ?? 0.0;
      final cashBorrowed = summary['cash_borrowed'] ?? 0.0;
      final cashNet = summary['cash_net'] ?? 0.0;
      final udhariGiven = summary['udhari_given'] ?? 0.0;
      final udhariTaken = summary['udhari_taken'] ?? 0.0;
      final udhariNet = summary['udhari_net'] ?? 0.0;
      final totalReceivable = summary['total_receivable'] ?? 0.0;
      final totalPayable = summary['total_payable'] ?? 0.0;

      log(
        'BorrowLendCubit: Summary - Total: ₹$netBalance (Cash: ₹$cashNet, Udhari: ₹$udhariNet)',
      );

      // Get recent transactions (limited to 10 from DB)
      log('BorrowLendCubit: Fetching recent transactions...');
      final recentTransactions = await _transactionRepository
          .getRecentTransactions(
            limit: PaginationConstants.recentTransactionsLimit,
          );
      log(
        'BorrowLendCubit: Found ${recentTransactions.length} recent transactions',
      );

      // Get first page of transactions based on filters
      log('BorrowLendCubit: Fetching first page of transactions...');
      final transactions = await _loadTransactionsPage(0);

      // Get total count for pagination
      final totalCount = await _getTransactionCount();
      final hasMoreData =
          transactions.length >= PaginationConstants.defaultPageSize;

      log(
        'BorrowLendCubit: Found ${transactions.length} transactions (total: $totalCount)',
      );

      emit(
        state.copyWith(
          isLoading: false,
          totalLent: totalLent,
          totalBorrowed: totalBorrowed,
          totalReceivable: totalReceivable,
          totalPayable: totalPayable,
          netBalance: netBalance,
          cashLent: cashLent,
          cashBorrowed: cashBorrowed,
          cashNet: cashNet,
          udhariGiven: udhariGiven,
          udhariTaken: udhariTaken,
          udhariNet: udhariNet,
          transactions: transactions,
          recentTransactions: recentTransactions,
          error: null,
          lastUpdate: DateTime.now(),
          currentPage: 0,
          hasMoreData: hasMoreData,
          totalCount: totalCount,
        ),
      );
      log('BorrowLendCubit: Data loaded successfully at ${DateTime.now()}');
    } catch (e) {
      log('BorrowLendCubit: Error loading data - $e');
      emit(state.copyWith(isLoading: false, error: 'Failed to load data: $e'));
    }
  }

  /* =======================
     CONTACT SUMMARIES
  ======================== */

  /// Load contact summaries (first page) from database
  Future<void> loadContactSummaries() async {
    log('BorrowLendCubit: Loading contact summaries...');
    emit(
      state.copyWith(
        isLoadingContacts: true,
        error: null,
        currentContactsPage: 0,
        hasMoreContacts: true,
      ),
    );

    try {
      final contacts = await _loadContactSummariesPage(0);
      final totalCount = await _getContactSummariesCount();
      final hasMoreContacts =
          contacts.length >= PaginationConstants.contactsPageSize;

      log(
        'BorrowLendCubit: Loaded ${contacts.length} contact summaries (total: $totalCount)',
      );

      emit(
        state.copyWith(
          isLoadingContacts: false,
          contactSummaries: contacts,
          error: null,
          lastUpdate: DateTime.now(),
          currentContactsPage: 0,
          hasMoreContacts: hasMoreContacts,
          totalContactsCount: totalCount,
        ),
      );
    } catch (e) {
      log('BorrowLendCubit: Error loading contact summaries - $e');
      emit(
        state.copyWith(
          isLoadingContacts: false,
          error: 'Failed to load contacts: $e',
        ),
      );
    }
  }

  /// Load more contact summaries (pagination)
  Future<void> loadMoreContactSummaries() async {
    if (state.isLoadingMoreContacts || !state.hasMoreContacts) {
      log(
        'BorrowLendCubit: Cannot load more contacts - isLoadingMore: ${state.isLoadingMoreContacts}, hasMore: ${state.hasMoreContacts}',
      );
      return;
    }

    final nextPage = state.currentContactsPage + 1;
    log('BorrowLendCubit: Loading contacts page $nextPage...');
    emit(state.copyWith(isLoadingMoreContacts: true, error: null));

    try {
      final newContacts = await _loadContactSummariesPage(nextPage);

      if (newContacts.isEmpty) {
        log('BorrowLendCubit: No more contacts to load');
        emit(
          state.copyWith(
            isLoadingMoreContacts: false,
            hasMoreContacts: false,
            currentContactsPage: nextPage,
          ),
        );
        return;
      }

      final allContacts = [...state.contactSummaries, ...newContacts];
      final hasMoreContacts =
          newContacts.length >= PaginationConstants.contactsPageSize;

      log(
        'BorrowLendCubit: Loaded ${newContacts.length} more contacts (total: ${allContacts.length})',
      );

      emit(
        state.copyWith(
          isLoadingMoreContacts: false,
          contactSummaries: allContacts,
          currentContactsPage: nextPage,
          hasMoreContacts: hasMoreContacts,
          lastUpdate: DateTime.now(),
        ),
      );
    } catch (e) {
      log('BorrowLendCubit: Error loading more contacts - $e');
      emit(
        state.copyWith(
          isLoadingMoreContacts: false,
          error: 'Failed to load more contacts: $e',
        ),
      );
    }
  }

  /// Internal method to load a specific page of contact summaries from DB
  Future<List<ContactSummary>> _loadContactSummariesPage(int page) async {
    final offset = page * PaginationConstants.contactsPageSize;
    final limit = PaginationConstants.contactsPageSize;

    log(
      'BorrowLendCubit: Loading contacts page $page (offset: $offset, limit: $limit)',
    );
    log(
      'BorrowLendCubit: Contact filters - Search: "${state.contactSearchQuery}", Balance: ${state.contactBalanceFilter}',
    );

    // Get contact summaries from repository with proper SQL filtering
    final summaryList = await _transactionRepository.getContactWiseSummary(
      limit: limit,
      offset: offset,
      searchQuery: state.contactSearchQuery,
      balanceFilter: state.contactBalanceFilter ?? 'all',
    );

    // Convert to ContactSummary objects
    List<ContactSummary> contacts = [];
    for (var summary in summaryList) {
      final contactId = summary['contact_id'] as int?;
      final contactName = summary['contact_name'] as String? ?? 'Unknown';
      final contactPhone = summary['contact_phone'] as String?;
      final contactAvatar = summary['contact_avatar'] as String?;
      final totalLent = (summary['total_lent'] as num?)?.toDouble() ?? 0.0;
      final totalBorrowed =
          (summary['total_borrowed'] as num?)?.toDouble() ?? 0.0;
      final transactionCount = summary['total_transactions'] as int? ?? 0;
      final lastTransactionDate = summary['last_transaction_date'] != null
          ? DateTime.parse(summary['last_transaction_date'] as String)
          : DateTime.now();
      final cashCount = summary['cash_count'] as int? ?? 0;
      final udhariCount = summary['udhari_count'] as int? ?? 0;
      final netBalance = totalLent - totalBorrowed;

      contacts.add(
        ContactSummary(
          contact: ContactModel(
            name: contactName,
            id: contactId,
            phone: contactPhone,
            avatar: contactAvatar,
          ),
          totalBorrowed: totalBorrowed,
          totalLent: totalLent,
          transactionCount: transactionCount,
          netBalance: netBalance,
          lastTransactionDate: lastTransactionDate,
          cashCount: cashCount,
          udhariCount: udhariCount,
        ),
      );
    }

    return contacts;
  }

  /// Get total contact summaries count
  Future<int> _getContactSummariesCount() async {
    try {
      return await _transactionRepository.getContactSummaryCount(
        searchQuery: state.contactSearchQuery,
        balanceFilter: state.contactBalanceFilter ?? 'all',
      );
    } catch (e) {
      log('BorrowLendCubit: Error getting contact count - $e');
      return 0;
    }
  }

  /// Set contact search query
  void setContactSearchQuery(String? query) {
    log('BorrowLendCubit: Setting contact search query to: "${query ?? ""}"');
    emit(state.copyWith(contactSearchQuery: query));
    if (query == null || query.isEmpty) {
      loadContactSummaries();
    } else {
      timer = Timer(const Duration(milliseconds: 500), () {
        if (!timer.isActive) loadContactSummaries();
      });
    }
  }

  /// Execute contact search
  void searchContactSummaries() {
    log('BorrowLendCubit: Executing contact search');
    loadContactSummaries();
  }

  /// Set contact balance filter
  void setContactBalanceFilter(String? filter) {
    log(
      'BorrowLendCubit: Setting contact balance filter to: ${filter ?? "all"}',
    );
    emit(
      state.copyWith(
        contactBalanceFilter: filter,
        clearContactSearchQuery: true,
      ),
    );
    loadContactSummaries();
  }

  /// Clear contact filters
  void clearContactFilters() {
    log('BorrowLendCubit: Clearing contact filters');
    emit(
      state.copyWith(
        clearContactSearchQuery: true,
        clearContactBalanceFilter: true,
      ),
    );
    loadContactSummaries();
  }

  /* =======================
     TRANSACTIONS
  ======================== */

  /// Load only transactions (for faster refresh when filters change)
  Future<void> loadTransactions() async {
    log('BorrowLendCubit: Loading transactions...');
    emit(
      state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 0,
        hasMoreData: true,
      ),
    );

    try {
      final transactions = await _loadTransactionsPage(0);
      final totalCount = await _getTransactionCount();
      final hasMoreData =
          transactions.length >= PaginationConstants.defaultPageSize;

      log(
        'BorrowLendCubit: Found ${transactions.length} transactions (total: $totalCount)',
      );

      emit(
        state.copyWith(
          isLoading: false,
          transactions: transactions,
          error: null,
          lastUpdate: DateTime.now(),
          currentPage: 0,
          hasMoreData: hasMoreData,
          totalCount: totalCount,
        ),
      );
      log(
        'BorrowLendCubit: Transactions loaded successfully at ${DateTime.now()}',
      );
    } catch (e) {
      log('BorrowLendCubit: Error loading transactions - $e');
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to load transactions: $e',
        ),
      );
    }
  }

  /// Load more transactions (pagination)
  Future<void> loadMoreTransactions() async {
    if (state.isLoadingMore || !state.hasMoreData) {
      log(
        'BorrowLendCubit: Cannot load more - isLoadingMore: ${state.isLoadingMore}, hasMoreData: ${state.hasMoreData}',
      );
      return;
    }

    final nextPage = state.currentPage + 1;
    log('BorrowLendCubit: Loading page $nextPage...');
    emit(state.copyWith(isLoadingMore: true, error: null));

    try {
      final newTransactions = await _loadTransactionsPage(nextPage);

      if (newTransactions.isEmpty) {
        log('BorrowLendCubit: No more transactions to load');
        emit(
          state.copyWith(
            isLoadingMore: false,
            hasMoreData: false,
            currentPage: nextPage,
          ),
        );
        return;
      }

      final allTransactions = [...state.transactions, ...newTransactions];
      final hasMoreData =
          newTransactions.length >= PaginationConstants.defaultPageSize;

      log(
        'BorrowLendCubit: Loaded ${newTransactions.length} more transactions (total: ${allTransactions.length})',
      );

      emit(
        state.copyWith(
          isLoadingMore: false,
          transactions: allTransactions,
          currentPage: nextPage,
          hasMoreData: hasMoreData,
          lastUpdate: DateTime.now(),
        ),
      );
    } catch (e) {
      log('BorrowLendCubit: Error loading more transactions - $e');
      emit(
        state.copyWith(
          isLoadingMore: false,
          error: 'Failed to load more transactions: $e',
        ),
      );
    }
  }

  /// Internal method to load a specific page of transactions
  Future<List<TransactionModel>> _loadTransactionsPage(int page) async {
    final offset = page * PaginationConstants.defaultPageSize;
    final limit = PaginationConstants.defaultPageSize;

    log('BorrowLendCubit: Loading page $page (offset: $offset, limit: $limit)');
    log(
      'BorrowLendCubit: Current filters - Type: ${state.filterType}, Category: ${state.filterCategory}, Query: ${state.searchQuery}',
    );

    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      log('BorrowLendCubit: Searching with query: "${state.searchQuery}"');
      return await _transactionRepository.searchTransactions(
        state.searchQuery!,
        category: state.filterCategory == 'cash_udhari'
            ? null
            : state.filterCategory,
        type: state.filterType,
        limit: limit,
        offset: offset,
      );
    } else if (state.filterCategory != null && state.filterType != null) {
      log(
        'BorrowLendCubit: Filtering by category: ${state.filterCategory} AND type: ${state.filterType}',
      );
      return await _transactionRepository.getTransactionsByCategoryAndType(
        state.filterCategory!,
        state.filterType!,
        limit: limit * 2,
        offset: offset,
      );
    } else if (state.filterCategory != null &&
        state.filterCategory != 'cash_udhari') {
      log('BorrowLendCubit: Filtering by category: ${state.filterCategory}');
      return await _transactionRepository.getTransactionsByCategory(
        state.filterCategory!,
        limit: limit,
        offset: offset,
      );
    } else if (state.filterType != null) {
      log('BorrowLendCubit: Filtering by type: ${state.filterType}');
      return await _transactionRepository.getTransactionsByType(
        state.filterType!,
        limit: limit,
        offset: offset,
      );
    } else {
      log('BorrowLendCubit: Fetching all transactions');
      return await _transactionRepository.getAllTransactions(
        limit: limit,
        offset: offset,
      );
    }
  }

  /// Get total transaction count for current filters
  Future<int> _getTransactionCount() async {
    try {
      return await _transactionRepository.getTransactionCount(
        type: state.filterType,
        category: state.filterCategory,
      );
    } catch (e) {
      log('BorrowLendCubit: Error getting transaction count - $e');
      return 0;
    }
  }

  /* =======================
     CRUD OPERATIONS
  ======================== */

  /// Create a new transaction
  Future<void> createTransaction(TransactionModel transaction) async {
    log(
      'BorrowLendCubit: Creating ${transaction.category} transaction - ${transaction.type}',
    );
    try {
      await _transactionRepository.createTransaction(transaction);
      log('BorrowLendCubit: Transaction created successfully');
      emit(state.copyWith(successMessage: 'Transaction created successfully'));
      await loadAllData();
      // Also reload contacts if in contacts view
      if (state.activeViewMode == 'contacts') {
        await loadContactSummaries();
      }
    } catch (e) {
      log('BorrowLendCubit: Error creating transaction - $e');
      emit(state.copyWith(error: 'Failed to create transaction: $e'));
    }
  }

  /// Update an existing transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    log('BorrowLendCubit: Updating transaction ID: ${transaction.id}');
    try {
      await _transactionRepository.updateTransaction(transaction);
      log('BorrowLendCubit: Transaction updated successfully');
      emit(state.copyWith(successMessage: 'Transaction updated successfully'));
      await loadAllData();
      // Also reload contacts if in contacts view
      if (state.activeViewMode == 'contacts') {
        await loadContactSummaries();
      }
    } catch (e) {
      log('BorrowLendCubit: Error updating transaction - $e');
      emit(state.copyWith(error: 'Failed to update transaction: $e'));
    }
  }

  /// Delete a transaction
  Future<void> deleteTransaction(int txnId, int contactId) async {
    log('BorrowLendCubit: Deleting transaction ID: $txnId');
    try {
      await _transactionRepository.deleteTransaction(txnId);
      log('BorrowLendCubit: Transaction deleted successfully');
      emit(state.copyWith(successMessage: 'Transaction deleted successfully'));
      await loadAllData();
      // Also reload contacts if in contacts view
      if (state.activeViewMode == 'contacts') {
        await loadContactSummaries();
      }
    } catch (e) {
      log('BorrowLendCubit: Error deleting transaction - $e');
      emit(state.copyWith(error: 'Failed to delete transaction: $e'));
    }
  }

  /* =======================
     FILTERS & VIEW MODE
  ======================== */

  /// Set filter by transaction type (Lend/Borrow)
  void setFilterType(String? type) {
    log('BorrowLendCubit: Setting filter type to: ${type ?? "All"}');
    log('BorrowLendCubit: Active view mode: ${state.activeViewMode}');

    if (type == null) {
      emit(state.copyWith(clearFilterType: true, clearSearchQuery: true));
    } else {
      emit(state.copyWith(filterType: type, clearSearchQuery: true));
    }
    loadTransactions();
  }

  /// Set active view mode (contacts/cash/udhari)
  void setViewMode(String mode) {
    log('BorrowLendCubit: Setting view mode to: $mode');

    if (mode == 'contacts') {
      emit(
        state.copyWith(
          activeViewMode: 'contacts',
          clearFilterCategory: true,
          clearFilterType: true,
          clearSearchQuery: true,
        ),
      );
      loadContactSummaries();
    } else if (mode == 'cash') {
      emit(
        state.copyWith(
          activeViewMode: 'cash',
          filterCategory: 'cash',
          clearFilterType: true,
          clearSearchQuery: true,
        ),
      );
      loadTransactions();
    } else if (mode == 'udhari') {
      emit(
        state.copyWith(
          activeViewMode: 'udhari',
          filterCategory: 'udhari',
          clearFilterType: true,
          clearSearchQuery: true,
        ),
      );
      loadTransactions();
    } else if (mode == 'cash_udhari') {
      emit(
        state.copyWith(
          activeViewMode: 'cash_udhari',
          clearFilterCategory: true,
          clearFilterType: true,
          clearSearchQuery: true,
        ),
      );
      loadTransactions();
    }
  }

  /// Set search query for transactions
  void setSearchQuery(String? query) {
    log('BorrowLendCubit: Setting search query to: "${query ?? ""}"');
    emit(state.copyWith(searchQuery: query));
    if (query == null || query.isEmpty) {
      loadTransactions();
    } else {
      timer = Timer(const Duration(milliseconds: 500), () {
        if (!timer.isActive) loadTransactions();
      });
    }
  }

  /// Search transactions
  void searchTransactions() {
    log('BorrowLendCubit: Executing search');
    loadTransactions();
  }

  /// Clear all filters
  void clearFilters() {
    log(
      'BorrowLendCubit: Clearing filters (keeping view mode: ${state.activeViewMode})',
    );

    if (state.activeViewMode == 'contacts') {
      clearContactFilters();
    } else if (state.activeViewMode == 'cash') {
      emit(state.copyWith(clearFilterType: true, clearSearchQuery: true));
      loadTransactions();
    } else if (state.activeViewMode == 'udhari') {
      emit(state.copyWith(clearFilterType: true, clearSearchQuery: true));
      loadTransactions();
    } else {
      emit(
        state.copyWith(
          clearFilterType: true,
          clearFilterCategory: true,
          clearSearchQuery: true,
        ),
      );
      loadTransactions();
    }
  }

  /// Clear success/error messages
  void clearMessages() {
    emit(state.copyWith(error: null, successMessage: null));
  }

  /// Refresh all data
  Future<void> refreshDashboard() async {
    log('BorrowLendCubit: Refreshing dashboard');
    await loadAllData();
    if (state.activeViewMode == 'contacts') {
      await loadContactSummaries();
    }
  }

  /// Reset pagination (useful when changing filters)
  void resetPagination() {
    log('BorrowLendCubit: Resetting pagination');
    emit(
      state.copyWith(
        currentPage: 0,
        hasMoreData: true,
        transactions: [],
        currentContactsPage: 0,
        hasMoreContacts: true,
        contactSummaries: [],
      ),
    );
  }

  @override
  Future<void> close() {
    if (timer.isActive) timer.cancel();
    return super.close();
  }
}
