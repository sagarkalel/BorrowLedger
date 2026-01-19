import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/contact_model.dart';
import '../../data/repositories/contact_repository.dart';

// Pagination constants for contacts
class ContactPaginationConstants {
  static const int defaultPageSize = 30;
  static const int dashboardLimit = 20;
}

// Contact State with Pagination
class ContactState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<ContactSummary> contacts;
  final String? searchQuery;
  final String? error;
  final String? successMessage;
  final DateTime? lastUpdate;

  // Pagination state
  final int currentPage;
  final bool hasMoreData;
  final int totalCount;

  ContactState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.contacts = const [],
    this.searchQuery,
    this.error,
    this.successMessage,
    this.lastUpdate,
    this.currentPage = 0,
    this.hasMoreData = true,
    this.totalCount = 0,
  });

  ContactState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<ContactSummary>? contacts,
    String? searchQuery,
    bool clearSearchQuery = false,
    String? error,
    String? successMessage,
    DateTime? lastUpdate,
    int? currentPage,
    bool? hasMoreData,
    int? totalCount,
  }) {
    return ContactState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      contacts: contacts ?? this.contacts,
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

// Contact Cubit with Pagination
class ContactCubit extends Cubit<ContactState> {
  final ContactRepository _repository;

  ContactCubit(this._repository) : super(ContactState());

  /// Load contacts (first page)
  Future<void> loadContacts() async {
    log('ContactCubit: Loading contacts...');
    emit(
      state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 0,
        hasMoreData: true,
      ),
    );

    try {
      final contacts = await _loadContactsPage(0);
      final totalCount = await _getContactCount();
      final hasMoreData =
          contacts.length >= ContactPaginationConstants.defaultPageSize;

      log(
        'ContactCubit: Loaded ${contacts.length} contacts (total: $totalCount)',
      );

      emit(
        state.copyWith(
          isLoading: false,
          contacts: contacts,
          error: null,
          lastUpdate: DateTime.now(),
          currentPage: 0,
          hasMoreData: hasMoreData,
          totalCount: totalCount,
        ),
      );
    } catch (e) {
      log('ContactCubit: Error loading contacts - $e');
      emit(
        state.copyWith(isLoading: false, error: 'Failed to load contacts: $e'),
      );
    }
  }

  /// Load more contacts (pagination)
  Future<void> loadMoreContacts() async {
    if (state.isLoadingMore || !state.hasMoreData) {
      log(
        'ContactCubit: Cannot load more - isLoadingMore: ${state.isLoadingMore}, hasMoreData: ${state.hasMoreData}',
      );
      return;
    }

    final nextPage = state.currentPage + 1;
    log('ContactCubit: Loading page $nextPage...');
    emit(state.copyWith(isLoadingMore: true, error: null));

    try {
      final newContacts = await _loadContactsPage(nextPage);

      if (newContacts.isEmpty) {
        log('ContactCubit: No more contacts to load');
        emit(
          state.copyWith(
            isLoadingMore: false,
            hasMoreData: false,
            currentPage: nextPage,
          ),
        );
        return;
      }

      final allContacts = [...state.contacts, ...newContacts];
      final hasMoreData =
          newContacts.length >= ContactPaginationConstants.defaultPageSize;

      log(
        'ContactCubit: Loaded ${newContacts.length} more contacts (total: ${allContacts.length})',
      );

      emit(
        state.copyWith(
          isLoadingMore: false,
          contacts: allContacts,
          currentPage: nextPage,
          hasMoreData: hasMoreData,
          lastUpdate: DateTime.now(),
        ),
      );
    } catch (e) {
      log('ContactCubit: Error loading more contacts - $e');
      emit(
        state.copyWith(
          isLoadingMore: false,
          error: 'Failed to load more contacts: $e',
        ),
      );
    }
  }

  /// Internal method to load a specific page of contacts
  Future<List<ContactSummary>> _loadContactsPage(int page) async {
    final offset = page * ContactPaginationConstants.defaultPageSize;
    final limit = ContactPaginationConstants.defaultPageSize;

    log('ContactCubit: Loading page $page (offset: $offset, limit: $limit)');

    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      log('ContactCubit: Searching with query: "${state.searchQuery}"');
      return await _repository.searchContacts(
        state.searchQuery!,
        limit: limit,
        offset: offset,
      );
    } else {
      log('ContactCubit: Fetching all contacts with transactions');
      return await _repository.getAllContactsWithSummary(
        limit: limit,
        offset: offset,
      );
    }
  }

  /// Get total contact count
  Future<int> _getContactCount() async {
    try {
      return await _repository.getContactCount(onlyWithTransactions: true);
    } catch (e) {
      log('ContactCubit: Error getting contact count - $e');
      return 0;
    }
  }

  /// Create a new contact
  Future<void> createContact(ContactModel contact) async {
    log('ContactCubit: Creating contact - ${contact.name}');
    try {
      await _repository.createContact(contact);
      log('ContactCubit: Contact created successfully');
      emit(state.copyWith(successMessage: 'Contact created successfully'));
      await loadContacts();
    } catch (e) {
      log('ContactCubit: Error creating contact - $e');
      emit(state.copyWith(error: 'Failed to create contact: $e'));
    }
  }

  /// Update an existing contact
  Future<void> updateContact(ContactModel contact) async {
    log('ContactCubit: Updating contact ID: ${contact.id}');
    try {
      await _repository.updateContact(contact);
      log('ContactCubit: Contact updated successfully');
      emit(state.copyWith(successMessage: 'Contact updated successfully'));
      await loadContacts();
    } catch (e) {
      log('ContactCubit: Error updating contact - $e');
      emit(state.copyWith(error: 'Failed to update contact: $e'));
    }
  }

  /// Delete a contact
  Future<void> deleteContact(int id) async {
    log('ContactCubit: Deleting contact ID: $id');
    try {
      await _repository.deleteContact(id);
      log('ContactCubit: Contact deleted successfully');
      emit(state.copyWith(successMessage: 'Contact deleted successfully'));
      await loadContacts();
    } catch (e) {
      log('ContactCubit: Error deleting contact - $e');
      emit(state.copyWith(error: 'Failed to delete contact: $e'));
    }
  }

  /// Set search query
  void setSearchQuery(String? query) {
    log('ContactCubit: Setting search query to: "${query ?? ""}"');
    emit(state.copyWith(searchQuery: query));
    if (query == null || query.isEmpty) {
      loadContacts();
    }
  }

  /// Search contacts
  void searchContacts() {
    log('ContactCubit: Executing search');
    loadContacts();
  }

  /// Clear search
  void clearSearch() {
    log('ContactCubit: Clearing search');
    emit(state.copyWith(clearSearchQuery: true));
    loadContacts();
  }

  /// Clear success/error messages
  void clearMessages() {
    emit(state.copyWith(error: null, successMessage: null));
  }

  /// Reset pagination
  void resetPagination() {
    log('ContactCubit: Resetting pagination');
    emit(state.copyWith(currentPage: 0, hasMoreData: true, contacts: []));
  }
}
