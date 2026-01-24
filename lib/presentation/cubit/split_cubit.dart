import 'dart:async';
import 'dart:developer';

import 'package:borrow_ledger/data/models/split_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/split_repository.dart';

// Pagination constants for splits
class SplitPaginationConstants {
  static const int defaultPageSize = 20;
}

// Split State with Pagination
class SplitState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<SplitExpenseModel> splits;
  final String? filterStatus;
  final String? searchQuery;
  final double totalPaidByUser;
  final double totalOwed;
  final double totalReceivable;
  final double totalPayable;
  final String? error;
  final String? successMessage;
  final DateTime? lastUpdate;

  // Pagination state
  final int currentPage;
  final bool hasMoreData;
  final int totalCount;

  SplitState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.splits = const [],
    this.filterStatus,
    this.searchQuery,
    this.totalPaidByUser = 0.0,
    this.totalOwed = 0.0,
    this.totalReceivable = 0.0,
    this.totalPayable = 0.0,
    this.error,
    this.successMessage,
    this.lastUpdate,
    this.currentPage = 0,
    this.hasMoreData = true,
    this.totalCount = 0,
  });

  SplitState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<SplitExpenseModel>? splits,
    String? filterStatus,
    bool clearFilterStatus = false,
    String? searchQuery,
    bool clearSearchQuery = false,
    double? totalPaidByUser,
    double? totalOwed,
    double? totalReceivable,
    double? totalPayable,
    String? error,
    String? successMessage,
    DateTime? lastUpdate,
    int? currentPage,
    bool? hasMoreData,
    int? totalCount,
  }) {
    return SplitState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      splits: splits ?? this.splits,
      filterStatus: clearFilterStatus
          ? null
          : (filterStatus ?? this.filterStatus),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      totalPaidByUser: totalPaidByUser ?? this.totalPaidByUser,
      totalOwed: totalOwed ?? this.totalOwed,
      totalReceivable: totalReceivable ?? this.totalReceivable,
      totalPayable: totalPayable ?? this.totalPayable,
      error: error,
      successMessage: successMessage,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

// Split Cubit with Pagination
class SplitCubit extends Cubit<SplitState> {
  final SplitRepository _repository;
  late Timer timer;

  SplitCubit(this._repository) : super(SplitState());

  /// Load splits (first page)
  Future<void> loadSplits() async {
    log('SplitCubit: Loading splits...');
    emit(
      state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 0,
        hasMoreData: true,
      ),
    );

    try {
      // Load summary
      final summary = await _repository.getSplitSummary();
      log(
        'SplitCubit: Summary - Paid: ₹${summary['total_paid_by_user']}, Owed: ₹${summary['total_owed']}, totalPayable: ₹${summary['total_payable']}, totalReceivable: ₹${summary['total_receivable']},',
      );

      // Load first page
      final splits = await _loadSplitsPage(0);
      final totalCount = await _getSplitCount();
      final hasMoreData =
          splits.length >= SplitPaginationConstants.defaultPageSize;

      log('SplitCubit: Loaded ${splits.length} splits (total: $totalCount)');

      emit(
        state.copyWith(
          isLoading: false,
          splits: splits,
          totalPaidByUser: summary['total_paid_by_user'] ?? 0.0,
          totalOwed: summary['total_owed'] ?? 0.0,
          totalPayable: summary['total_payable'] ?? 0.0,
          totalReceivable: summary['total_receivable'] ?? 0.0,
          error: null,
          lastUpdate: DateTime.now(),
          currentPage: 0,
          hasMoreData: hasMoreData,
          totalCount: totalCount,
        ),
      );
    } catch (e) {
      log('SplitCubit: Error loading splits - $e');
      emit(
        state.copyWith(isLoading: false, error: 'Failed to load splits: $e'),
      );
    }
  }

  /// Load more splits (pagination)
  Future<void> loadMoreSplits() async {
    if (state.isLoadingMore || !state.hasMoreData) {
      log(
        'SplitCubit: Cannot load more - isLoadingMore: ${state.isLoadingMore}, hasMoreData: ${state.hasMoreData}',
      );
      return;
    }

    final nextPage = state.currentPage + 1;
    log('SplitCubit: Loading page $nextPage...');
    emit(state.copyWith(isLoadingMore: true, error: null));

    try {
      final newSplits = await _loadSplitsPage(nextPage);

      if (newSplits.isEmpty) {
        log('SplitCubit: No more splits to load');
        emit(
          state.copyWith(
            isLoadingMore: false,
            hasMoreData: false,
            currentPage: nextPage,
          ),
        );
        return;
      }

      final allSplits = [...state.splits, ...newSplits];
      final hasMoreData =
          newSplits.length >= SplitPaginationConstants.defaultPageSize;

      log(
        'SplitCubit: Loaded ${newSplits.length} more splits (total: ${allSplits.length})',
      );

      emit(
        state.copyWith(
          isLoadingMore: false,
          splits: allSplits,
          currentPage: nextPage,
          hasMoreData: hasMoreData,
          lastUpdate: DateTime.now(),
        ),
      );
    } catch (e) {
      log('SplitCubit: Error loading more splits - $e');
      emit(
        state.copyWith(
          isLoadingMore: false,
          error: 'Failed to load more splits: $e',
        ),
      );
    }
  }

  /// Internal method to load a specific page of splits
  Future<List<SplitExpenseModel>> _loadSplitsPage(int page) async {
    final offset = page * SplitPaginationConstants.defaultPageSize;
    final limit = SplitPaginationConstants.defaultPageSize;

    log('SplitCubit: Loading page $page (offset: $offset, limit: $limit)');

    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      log('SplitCubit: Searching with query: "${state.searchQuery}"');
      return await _repository.searchSplits(
        state.searchQuery!,
        limit: limit,
        offset: offset,
      );
    } else if (state.filterStatus != null) {
      log('SplitCubit: Filtering by status: ${state.filterStatus}');
      return await _repository.getSplitsByStatus(
        state.filterStatus!,
        limit: limit,
        offset: offset,
      );
    } else {
      log('SplitCubit: Fetching all splits');
      return await _repository.getAllSplits(limit: limit, offset: offset);
    }
  }

  /// Get total split count for current filters
  Future<int> _getSplitCount() async {
    try {
      return await _repository.getSplitCount(status: state.filterStatus);
    } catch (e) {
      log('SplitCubit: Error getting split count - $e');
      return 0;
    }
  }

  /// Create a new split expense
  Future<void> createSplit(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants,
  ) async {
    log('SplitCubit: Creating split - ${split.title}');
    try {
      final splitId = await _repository.createSplitExpense(split);
      log('SplitCubit: Split created with ID: $splitId');

      // Update participants with the split ID
      final updatedParticipants = participants
          .map((p) => p.copyWith(splitId: splitId))
          .toList();

      await _repository.createParticipants(updatedParticipants);
      log('SplitCubit: ${participants.length} participants added');

      emit(
        state.copyWith(successMessage: 'Split expense created successfully'),
      );
      await loadSplits();
    } catch (e) {
      log('SplitCubit: Error creating split - $e');
      emit(state.copyWith(error: 'Failed to create split: $e'));
    }
  }

  /// Update an existing split expense
  Future<void> updateSplit(SplitExpenseModel split) async {
    log('SplitCubit: Updating split ID: ${split.id}');
    try {
      await _repository.updateSplitExpense(split);
      log('SplitCubit: Split updated successfully');
      emit(
        state.copyWith(successMessage: 'Split expense updated successfully'),
      );
      await loadSplits();
    } catch (e) {
      log('SplitCubit: Error updating split - $e');
      emit(state.copyWith(error: 'Failed to update split: $e'));
    }
  }

  /// Delete a split expense
  Future<void> deleteSplit(int id) async {
    log('SplitCubit: Deleting split ID: $id');
    try {
      await _repository.deleteSplit(id);
      log('SplitCubit: Split deleted successfully');
      emit(
        state.copyWith(successMessage: 'Split expense deleted successfully'),
      );
      await loadSplits();
    } catch (e) {
      log('SplitCubit: Error deleting split - $e');
      emit(state.copyWith(error: 'Failed to delete split: $e'));
    }
  }

  /// Mark participant as paid
  Future<void> markParticipantAsPaid(int participantId, double amount) async {
    log('SplitCubit: Marking participant $participantId as paid');
    try {
      await _repository.markParticipantAsPaid(participantId, amount);
      log('SplitCubit: Participant marked as paid');
      emit(state.copyWith(successMessage: 'Marked as paid'));
      await loadSplits();
    } catch (e) {
      log('SplitCubit: Error marking as paid - $e');
      emit(state.copyWith(error: 'Failed to update payment: $e'));
    }
  }

  /// Settle entire split - marks all participants as fully paid
  /// This is the proper way to settle a split - it updates both participant payments and status
  Future<void> settleSplit(int splitId) async {
    log('SplitCubit: Settling split ID: $splitId');
    try {
      await _repository.settleSplit(splitId);
      log(
        'SplitCubit: Split settled successfully - all participants marked as paid',
      );
      emit(state.copyWith(successMessage: 'Split marked as settled'));
      await loadSplits();
    } catch (e) {
      log('SplitCubit: Error settling split - $e');
      emit(state.copyWith(error: 'Failed to settle split: $e'));
    }
  }

  /// Set filter by status
  void setFilterStatus(String? status) {
    log('SplitCubit: Setting filter status to: ${status ?? "All"}');
    if (status == null) {
      emit(state.copyWith(clearFilterStatus: true, clearSearchQuery: true));
    } else {
      emit(state.copyWith(filterStatus: status, clearSearchQuery: true));
    }
    loadSplits();
  }

  /// Set search query
  void setSearchQuery(String? query) {
    log('SplitCubit: Setting search query to: "${query ?? ""}"');
    emit(state.copyWith(searchQuery: query));
    if (query == null || query.isEmpty) {
      loadSplits();
    } else {
      timer = Timer(const Duration(milliseconds: 500), () {
        if (!timer.isActive) loadSplits();
      });
    }
  }

  /// Search splits
  void searchSplits() {
    log('SplitCubit: Executing search');
    loadSplits();
  }

  /// Clear all filters
  void clearFilters() {
    log('SplitCubit: Clearing all filters');
    emit(state.copyWith(clearFilterStatus: true, clearSearchQuery: true));
    loadSplits();
  }

  /// Clear success/error messages
  void clearMessages() {
    emit(state.copyWith(error: null, successMessage: null));
  }

  /// Reset pagination
  void resetPagination() {
    log('SplitCubit: Resetting pagination');
    emit(state.copyWith(currentPage: 0, hasMoreData: true, splits: []));
  }

  @override
  Future<void> close() {
    if (timer.isActive) timer.cancel();
    return super.close();
  }
}
