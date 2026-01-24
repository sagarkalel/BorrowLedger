import 'dart:async';
import 'dart:developer';

import 'package:borrow_ledger/data/models/expense_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/expense_repository.dart';

// Expense State
class ExpenseState {
  final bool isLoading;
  final List<ExpenseModel> expenses;
  final List<Map<String, dynamic>> categorySummary;
  final String? filterCategory;
  final String? searchQuery;
  final String? error;
  final String? successMessage;
  final DateTime? lastUpdate; // Add timestamp to track updates

  ExpenseState({
    this.isLoading = false,
    this.expenses = const [],
    this.categorySummary = const [],
    this.filterCategory,
    this.searchQuery,
    this.error,
    this.successMessage,
    this.lastUpdate,
  });

  ExpenseState copyWith({
    bool? isLoading,
    List<ExpenseModel>? expenses,
    List<Map<String, dynamic>>? categorySummary,
    String? filterCategory,
    bool clearFilterCategory = false,
    String? searchQuery,
    bool clearSearchQuery = false,
    String? error,
    String? successMessage,
    DateTime? lastUpdate,
  }) {
    return ExpenseState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
      categorySummary: categorySummary ?? this.categorySummary,
      filterCategory: clearFilterCategory
          ? null
          : (filterCategory ?? this.filterCategory),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      error: error,
      successMessage: successMessage,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

// Expense Cubit
class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository _repository;
  late Timer timer;

  ExpenseCubit(this._repository) : super(ExpenseState());

  Future<void> loadExpenses() async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      List<ExpenseModel> expenses;
      List<Map<String, dynamic>> summary = [];
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        expenses = await _repository.searchExpenses(state.searchQuery!);
      } else if (state.filterCategory != null) {
        expenses = await _repository.getExpensesByCategory(
          state.filterCategory!,
        );
      } else {
        expenses = await _repository.getAllExpenses();
      }

      // Load category summary
      summary = await _repository.getCategorySummary();

      emit(
        state.copyWith(
          isLoading: false,
          expenses: expenses,
          categorySummary: summary,
          error: null,
          lastUpdate: DateTime.now(), // Add timestamp
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, error: 'Failed to load expenses: $e'),
      );
    }
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
    emit(state.copyWith(searchQuery: query));
    if (query == null || query.isEmpty) {
      loadExpenses();
    } else {
      timer = Timer(const Duration(milliseconds: 500), () {
        if (!timer.isActive) loadExpenses();
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
    if (timer.isActive) timer.cancel();
    return super.close();
  }
}
