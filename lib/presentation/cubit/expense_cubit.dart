import 'dart:async';
import 'dart:developer';

import 'package:borrow_ledger/data/models/expense_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/app_loading_delay.dart';
import '../../data/repositories/expense_repository.dart';

class ExpensePaginationConstants {
  static const int defaultPageSize = 20;
}

// Expense State
class ExpenseState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<ExpenseModel> expenses;
  final List<Map<String, dynamic>> categorySummary;
  final String? filterCategory;
  final String? searchQuery;
  final String? error;
  final String? successMessage;
  final DateTime? lastUpdate; // Add timestamp to track updates
  final int currentPage;
  final bool hasMoreData;
  final int totalCount;

  ExpenseState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.expenses = const [],
    this.categorySummary = const [],
    this.filterCategory,
    this.searchQuery,
    this.error,
    this.successMessage,
    this.lastUpdate,
    this.currentPage = 0,
    this.hasMoreData = true,
    this.totalCount = 0,
  });

  ExpenseState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<ExpenseModel>? expenses,
    List<Map<String, dynamic>>? categorySummary,
    String? filterCategory,
    bool clearFilterCategory = false,
    String? searchQuery,
    bool clearSearchQuery = false,
    String? error,
    String? successMessage,
    DateTime? lastUpdate,
    int? currentPage,
    bool? hasMoreData,
    int? totalCount,
  }) {
    return ExpenseState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      expenses: expenses ?? this.expenses,
      categorySummary: categorySummary ?? this.categorySummary,
      filterCategory: clearFilterCategory
          ? null
          : (filterCategory ?? this.filterCategory),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      error: error,
      successMessage: successMessage,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

// Expense Cubit
class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository _repository;
  Timer? _searchTimer;

  ExpenseCubit(this._repository) : super(ExpenseState());

  Future<void> loadExpenses() async {
    emit(
      state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 0,
        hasMoreData: true,
      ),
    );

    try {
      final loadingDelay = state.expenses.isEmpty
          ? AppLoadingDelay.initial()
          : AppLoadingDelay.refresh();

      final expenses = await _loadExpensesPage(0);
      final totalCount = await _getExpenseCount();
      final hasMoreData =
          expenses.length >= ExpensePaginationConstants.defaultPageSize;
      final summary = await _repository.getCategorySummary();

      await loadingDelay;

      emit(
        state.copyWith(
          isLoading: false,
          expenses: expenses,
          categorySummary: summary,
          error: null,
          lastUpdate: DateTime.now(), // Add timestamp
          currentPage: 0,
          hasMoreData: hasMoreData,
          totalCount: totalCount,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, error: 'Failed to load expenses: $e'),
      );
    }
  }

  Future<void> loadMoreExpenses() async {
    if (state.isLoadingMore || !state.hasMoreData || state.isLoading) return;

    final nextPage = state.currentPage + 1;
    emit(state.copyWith(isLoadingMore: true, error: null));

    try {
      final loadingDelay = AppLoadingDelay.loadMore();
      final newExpenses = await _loadExpensesPage(nextPage);
      await loadingDelay;

      if (newExpenses.isEmpty) {
        emit(
          state.copyWith(
            isLoadingMore: false,
            hasMoreData: false,
            currentPage: nextPage,
          ),
        );
        return;
      }

      final allExpenses = [...state.expenses, ...newExpenses];
      final hasMoreData =
          newExpenses.length >= ExpensePaginationConstants.defaultPageSize;

      emit(
        state.copyWith(
          isLoadingMore: false,
          expenses: allExpenses,
          currentPage: nextPage,
          hasMoreData: hasMoreData,
          lastUpdate: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          error: 'Failed to load more expenses: $e',
        ),
      );
    }
  }

  Future<List<ExpenseModel>> _loadExpensesPage(int page) async {
    final offset = page * ExpensePaginationConstants.defaultPageSize;
    final limit = ExpensePaginationConstants.defaultPageSize;

    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      return await _repository.searchExpenses(
        state.searchQuery!,
        limit: limit,
        offset: offset,
      );
    } else if (state.filterCategory != null) {
      return await _repository.getExpensesByCategory(
        state.filterCategory!,
        limit: limit,
        offset: offset,
      );
    } else {
      return await _repository.getAllExpenses(limit: limit, offset: offset);
    }
  }

  Future<int> _getExpenseCount() {
    return _repository.getExpenseCount(
      category: state.filterCategory,
      searchQuery: state.searchQuery,
    );
  }

  Future<void> createExpense(ExpenseModel expense) async {
    try {
      await _repository.createExpense(expense);
      emit(state.copyWith(successMessage: 'Expense added successfully'));
      await loadExpenses();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to create expense: $e'));
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await _repository.updateExpense(expense);
      emit(state.copyWith(successMessage: 'Expense updated successfully'));
      await loadExpenses();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update expense: $e'));
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _repository.deleteExpense(id);
      emit(state.copyWith(successMessage: 'Expense deleted successfully'));
      await loadExpenses();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete expense: $e'));
    }
  }

  void setFilterCategory(String? category) {
    if (category == null) {
      emit(state.copyWith(clearFilterCategory: true, clearSearchQuery: true));
    } else {
      emit(state.copyWith(filterCategory: category, clearSearchQuery: true));
    }
    loadExpenses();
  }

  /// Set search query
  void setSearchQuery(String? query) {
    log('ExpenseCubit: Setting search query to: "${query ?? ""}"');
    _searchTimer?.cancel();
    emit(state.copyWith(searchQuery: query));
    if (query == null || query.isEmpty) {
      loadExpenses();
    } else {
      _searchTimer = Timer(const Duration(milliseconds: 500), () {
        loadExpenses();
      });
    }
  }

  void searchExpenses() {
    loadExpenses();
  }

  /// Clear all filters
  void clearFilters() {
    log('ExpenseCubit: Clearing all filters');
    emit(state.copyWith(clearFilterCategory: true, clearSearchQuery: true));
    loadExpenses();
  }

  void clearMessages() {
    emit(state.copyWith(error: null, successMessage: null));
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }
}
