import 'dart:developer';

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/add_transaction_menu.dart';
import 'package:borrow_ledger/presentation/widgets/app_pill_badge.dart';
import 'package:borrow_ledger/presentation/widgets/app_segmented_control.dart';
import 'package:borrow_ledger/presentation/widgets/app_search_field.dart';
import 'package:borrow_ledger/presentation/widgets/build_summary_card.dart';
import 'package:borrow_ledger/presentation/widgets/floating_tab_header_delegate.dart';
import 'package:borrow_ledger/presentation/widgets/settings_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../cubit/borrow_lend_cubit.dart';
import '../widgets/contact_summary_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/transaction_list_item.dart';
import 'transaction_details_screen.dart';
import 'contact_wise_transactions_screen.dart';
import 'split_detail_screen.dart';

enum BorrowLendViewMode { contacts, cash, udhari, transactions }

class MergedBorrowLendScreen extends StatefulWidget {
  const MergedBorrowLendScreen({super.key});

  @override
  State<MergedBorrowLendScreen> createState() => _MergedBorrowLendScreenState();
}

class _MergedBorrowLendScreenState extends State<MergedBorrowLendScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _animationController;
  late ScrollController _scrollController;
  late ScrollController _contactScrollController;

  BorrowLendViewMode _viewMode = BorrowLendViewMode.contacts;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _contactSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scrollController = ScrollController();
    _contactScrollController = ScrollController();

    // Add scroll listeners for pagination
    _scrollController.addListener(_onTransactionScroll);
    _contactScrollController.addListener(_onContactScroll);

    log('MergedBorrowLendScreen: Initialized');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    log('MergedBorrowLendScreen: Loading initial data');
    final cubit = context.read<BorrowLendCubit>();
    cubit.loadAllData();
    cubit.loadContactSummaries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _contactSearchController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    _contactScrollController.dispose();
    log('MergedBorrowLendScreen: Disposed');
    super.dispose();
  }

  // Pagination: Load more transactions when scrolled to bottom
  void _onTransactionScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<BorrowLendCubit>().loadMoreTransactions();
    }
  }

  // Pagination: Load more contacts when scrolled to bottom
  void _onContactScroll() {
    if (!_contactScrollController.hasClients) return;
    if (_contactScrollController.position.pixels >=
        _contactScrollController.position.maxScrollExtent - 200) {
      context.read<BorrowLendCubit>().loadMoreContactSummaries();
    }
  }

  Future<void> _refreshAllData() async {
    log('MergedBorrowLendScreen: Refreshing all data');
    final cubit = context.read<BorrowLendCubit>();
    await cubit.loadAllData();
    if (_viewMode == BorrowLendViewMode.contacts) {
      await cubit.loadContactSummaries();
    }
  }

  bool _hasActiveFilters(BorrowLendState state) {
    if (_viewMode == BorrowLendViewMode.contacts) {
      return (state.contactSearchQuery != null &&
              state.contactSearchQuery!.isNotEmpty) ||
          (state.contactBalanceFilter != null &&
              state.contactBalanceFilter != 'all');
    } else {
      return (state.filterType != null) ||
          (state.searchQuery != null && state.searchQuery!.isNotEmpty);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: const SettingsDrawer(),
      appBar: AppBar(
        title: Text(tr.moneyTracker),
        actions: [
          BlocBuilder<BorrowLendCubit, BorrowLendState>(
            builder: (context, state) {
              if (_hasActiveFilters(state)) {
                return IconButton(
                  icon: const Icon(Icons.filter_alt_off),
                  tooltip: 'Clear filters',
                  onPressed: () {
                    log('MergedBorrowLendScreen: Clearing filters');
                    final cubit = context.read<BorrowLendCubit>();

                    if (_viewMode == BorrowLendViewMode.contacts) {
                      _contactSearchController.clear();
                      cubit.clearContactFilters();
                    } else {
                      _searchController.clear();
                      cubit.clearFilters();
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocListener<BorrowLendCubit, BorrowLendState>(
        listener: (context, state) {
          // Handle messages
          if (state.error != null) {
            log('MergedBorrowLendScreen: Error - ${state.error}');
            showFailureSnackbar(context, state.error!);
            context.read<BorrowLendCubit>().clearMessages();
          }
          if (state.successMessage != null) {
            log('MergedBorrowLendScreen: Success - ${state.successMessage}');
            showSuccessSnackbar(context, state.successMessage!);
            context.read<BorrowLendCubit>().clearMessages();
          }
        },
        child: RefreshIndicator(
          onRefresh: _refreshAllData,
          child: CustomScrollView(
            controller: _viewMode == BorrowLendViewMode.contacts
                ? _contactScrollController
                : _scrollController,
            slivers: [
              // Dashboard Summary Section (Always visible)
              SliverToBoxAdapter(child: _buildDashboardSummary()),

              // View Mode Selector (Floating/Sticky)
              SliverPersistentHeader(
                pinned: true,
                // floating: true,
                delegate: FloatingTabHeaderDelegate(
                  minHeight: 60,
                  maxHeight: 60,
                  child: _buildViewModeSelector(),
                ),
              ),

              SliverToBoxAdapter(child: _buildActiveControlsSection()),

              // Content based on view mode
              _buildContent(),

              // Loading more indicator
              SliverToBoxAdapter(child: _buildLoadingMoreIndicator()),

              SliverToBoxAdapter(child: const SizedBox(height: kToolbarHeight)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'borrow_lend_fab',
        onPressed: () => showAddTransactionMenu(context, _refreshAllData),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        if (_viewMode == BorrowLendViewMode.contacts) {
          if (state.isLoadingMoreContacts) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
        } else {
          if (state.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInitialLoadingSliver() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      ),
    );
  }

  Widget _buildDashboardSummary() {
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Net balance card
              _buildNetBalanceCard(state),
              const SizedBox(height: 10),

              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: BuildSummaryCard(
                      title: tr.receivable,
                      amount: state.totalReceivable,
                      icon: Icons.call_received,
                      color: AppTheme.moneyInColor,
                      isPositive: true,
                      isCompact: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BuildSummaryCard(
                      title: tr.payable,
                      amount: state.totalPayable,
                      icon: Icons.call_made,
                      color: AppTheme.moneyOutColor,
                      isPositive: false,
                      isCompact: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNetBalanceCard(BorrowLendState state) {
    final isSettled = state.netBalance.abs() < 0.01;
    final isPositive = state.netBalance > 0;
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = isSettled
        ? colorScheme.secondary
        : isPositive
        ? AppTheme.moneyInColor
        : AppTheme.moneyOutColor;
    final tr = AppLocalizations.of(context)!;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSettled
                    ? Icons.done_all_rounded
                    : isPositive
                    ? Icons.account_balance_wallet_rounded
                    : Icons.account_balance_outlined,
                color: accentColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tr.netBalance,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isSettled
                            ? Icons.check_circle_outline_rounded
                            : isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: accentColor,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Text(
                    '${isSettled
                        ? ''
                        : isPositive
                        ? '+'
                        : '-'}₹${state.netBalance.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isSettled ? colorScheme.onSurface : accentColor,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            AppPillBadge(
              label: isSettled
                  ? tr.settled
                  : isPositive
                  ? tr.youWillGet
                  : tr.youWillGive,
              icon: isSettled
                  ? Icons.done_all_rounded
                  : isPositive
                  ? Icons.call_received
                  : Icons.call_made,
              color: accentColor,
              fontSize: 11,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeSelector() {
    final tr = AppLocalizations.of(context)!;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AppSegmentedControl<BorrowLendViewMode>(
        selectedValue: _viewMode,
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        segmentHeight: 44,
        iconSize: 17,
        fontSize: 10.5,
        onChanged: _changeViewMode,
        items: [
          AppSegmentedControlItem(
            value: BorrowLendViewMode.contacts,
            label: tr.contacts,
            icon: Icons.people_outline_rounded,
          ),
          AppSegmentedControlItem(
            value: BorrowLendViewMode.cash,
            label: tr.cash,
            icon: Icons.currency_rupee_rounded,
          ),
          AppSegmentedControlItem(
            value: BorrowLendViewMode.udhari,
            label: tr.udhari,
            icon: Icons.shopping_basket_outlined,
          ),
          AppSegmentedControlItem(
            value: BorrowLendViewMode.transactions,
            label: tr.transactions,
            icon: Icons.receipt_long,
          ),
        ],
      ),
    );
  }

  void _changeViewMode(BorrowLendViewMode mode) {
    if (_viewMode == mode) return;

    setState(() {
      _viewMode = mode;
      _searchController.clear();
      _contactSearchController.clear();
    });

    log('MergedBorrowLendScreen: Switching to ${mode.name} mode');

    final cubit = context.read<BorrowLendCubit>();
    switch (mode) {
      case BorrowLendViewMode.contacts:
        cubit.setViewMode('contacts');
      case BorrowLendViewMode.cash:
        cubit.setViewMode('cash');
      case BorrowLendViewMode.udhari:
        cubit.setViewMode('udhari');
      case BorrowLendViewMode.transactions:
        cubit.setViewMode('cash_udhari');
    }
  }

  Widget _buildActiveControlsSection() {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_viewMode == BorrowLendViewMode.contacts) ...[
            _buildContactSearchBar(),
            _buildContactFilterChips(),
          ] else ...[
            _buildSearchBar(),
            _buildFilterChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildContactFilterChips() {
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Row(
            children: [
              FilterChipWidget(
                label: tr.allContacts,
                icon: Icons.people,
                isSelected:
                    state.contactBalanceFilter == null ||
                    state.contactBalanceFilter == 'all',
                onSelected: () {
                  _contactSearchController.clear();
                  log('MergedBorrowLendScreen: Setting contact filter to All');
                  context.read<BorrowLendCubit>().setContactBalanceFilter(
                    'all',
                  );
                },
              ),
              const SizedBox(width: 8),
              FilterChipWidget(
                label: tr.settled,
                icon: Icons.done_all,
                color: Colors.blue,
                isSelected: state.contactBalanceFilter == 'settled',
                onSelected: () {
                  _contactSearchController.clear();
                  log(
                    'MergedBorrowLendScreen: Setting contact filter to Settled',
                  );
                  context.read<BorrowLendCubit>().setContactBalanceFilter(
                    'settled',
                  );
                },
              ),
              const SizedBox(width: 8),
              FilterChipWidget(
                label: tr.pending,
                icon: Icons.pending_actions,
                color: Colors.orange,
                isSelected: state.contactBalanceFilter == 'pending',
                onSelected: () {
                  _contactSearchController.clear();
                  log(
                    'MergedBorrowLendScreen: Setting contact filter to Pending',
                  );
                  context.read<BorrowLendCubit>().setContactBalanceFilter(
                    'pending',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactSearchBar() {
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.only(top: 4),
      child: AppSearchField(
        controller: _contactSearchController,
        hintText: tr.searchContactsByNameOrPhone,
        onClear: () {
          _contactSearchController.clear();
          context.read<BorrowLendCubit>().setContactSearchQuery('');
        },
        onChanged: (value) {
          context.read<BorrowLendCubit>().setContactSearchQuery(value);
        },
        onSubmitted: (_) {
          context.read<BorrowLendCubit>().searchContactSummaries();
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.only(top: 4),
      child: AppSearchField(
        controller: _searchController,
        hintText: tr.searchTransactionsByNameOrPhone,
        onClear: () {
          _searchController.clear();
          context.read<BorrowLendCubit>().setSearchQuery('');
        },
        onChanged: (value) {
          context.read<BorrowLendCubit>().setSearchQuery(value);
        },
        onSubmitted: (_) =>
            context.read<BorrowLendCubit>().searchTransactions(),
      ),
    );
  }

  Widget _buildFilterChips() {
    final tr = AppLocalizations.of(context)!;
    final isAllTransactionsView = _viewMode == BorrowLendViewMode.transactions;

    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Row(
            children: [
              FilterChipWidget(
                label: tr.all,
                isSelected: state.filterType == null,
                onSelected: () {
                  _searchController.clear();
                  log('MergedBorrowLendScreen: Clearing type filter');
                  context.read<BorrowLendCubit>().setFilterType(null);
                },
              ),
              const SizedBox(width: 8),
              FilterChipWidget(
                label: isAllTransactionsView ? tr.receivable : tr.youGave,
                icon: isAllTransactionsView
                    ? Icons.call_received
                    : Icons.call_made,
                color: isAllTransactionsView
                    ? AppTheme.moneyInColor
                    : AppTheme.moneyOutColor,
                isSelected: state.filterType == AppConstants.typeLend,
                onSelected: () {
                  _searchController.clear();
                  log('MergedBorrowLendScreen: Setting filter to Lend');
                  context.read<BorrowLendCubit>().setFilterType(
                    AppConstants.typeLend,
                  );
                },
              ),
              const SizedBox(width: 8),
              FilterChipWidget(
                label: isAllTransactionsView ? tr.payable : tr.youGot,
                icon: isAllTransactionsView
                    ? Icons.call_made
                    : Icons.call_received,
                color: isAllTransactionsView
                    ? AppTheme.moneyOutColor
                    : AppTheme.moneyInColor,
                isSelected: state.filterType == AppConstants.typeBorrow,
                onSelected: () {
                  _searchController.clear();
                  log('MergedBorrowLendScreen: Setting filter to Borrow');
                  context.read<BorrowLendCubit>().setFilterType(
                    AppConstants.typeBorrow,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    switch (_viewMode) {
      case BorrowLendViewMode.contacts:
        return _buildContactsView();
      case BorrowLendViewMode.cash:
      case BorrowLendViewMode.udhari:
      case BorrowLendViewMode.transactions:
        return _buildTransactionsView();
    }
  }

  Widget _buildContactsView() {
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        if (state.isLoadingContacts && state.contactSummaries.isEmpty) {
          return _buildInitialLoadingSliver();
        }

        if (state.contactSummaries.isEmpty) {
          final String emptyTitle;
          final String emptyMessage;

          if (state.contactSearchQuery != null &&
              state.contactSearchQuery!.isNotEmpty) {
            emptyTitle = tr.noContactsFound;
            emptyMessage =
                '${tr.noContactsFound} "${state.contactSearchQuery}"';
          } else if (state.contactBalanceFilter == 'settled') {
            emptyTitle = tr.noSettledContacts;
            emptyMessage = tr.noContactsWithZeroBalance;
          } else if (state.contactBalanceFilter == 'pending') {
            emptyTitle = tr.noPendingContacts;
            emptyMessage = tr.noContactsWithPendingBalance;
          } else {
            emptyTitle = tr.noContactsYet;
            emptyMessage = tr.startTrackingYourMoney;
          }

          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              icon: Icons.people_outline,
              title: emptyTitle,
              message: emptyMessage,
              compact: true,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 16,
            top: 6,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final contactSummary = state.contactSummaries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ContactSummaryCard(
                  contactName: contactSummary.contact.name,
                  phoneNumber: contactSummary.contact.phone,
                  transactionCount: contactSummary.transactionCount,
                  netBalance: contactSummary.netBalance,
                  cashCount: contactSummary.cashCount,
                  udhariCount: contactSummary.udhariCount,
                  splitCount: contactSummary.splitCount,
                  onTap: () async {
                    log(
                      'MergedBorrowLendScreen: Opening contact details for ${contactSummary.contact.name}',
                    );
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContactWiseTransactionsScreen(
                          contactId: contactSummary.contact.id,
                          contactName: contactSummary.contact.name,
                        ),
                      ),
                    );
                    log(
                      'MergedBorrowLendScreen: Returned from contact details',
                    );
                    _refreshAllData();
                  },
                ),
              );
            }, childCount: state.contactSummaries.length),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsView() {
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        if (state.isLoading && state.transactions.isEmpty) {
          return _buildInitialLoadingSliver();
        }

        if (state.transactions.isEmpty) {
          final String emptyTitle;
          final String emptyMessage;

          final hasFilters = _hasActiveFilters(state);

          if (_viewMode == BorrowLendViewMode.cash) {
            emptyTitle = hasFilters
                ? tr.noMatchingCashTransactions
                : tr.noCashTransactions;
            emptyMessage = hasFilters
                ? tr.tryAdjustingFilters
                : tr.addYourFirstCashTransaction;
          } else if (_viewMode == BorrowLendViewMode.udhari) {
            emptyTitle = hasFilters
                ? tr.noMatchingUdhariTransactions
                : tr.noUdhariTransactions;
            emptyMessage = hasFilters
                ? tr.tryAdjustingFilters
                : tr.addYourFirstUdhariTransaction;
          } else {
            emptyTitle = hasFilters
                ? tr.noMatchingTransactions
                : tr.noTransactionsYet;
            emptyMessage = hasFilters
                ? tr.tryAdjustingFilters
                : tr.addFirstTransaction;
          }

          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              icon: _viewMode == BorrowLendViewMode.cash
                  ? Icons.currency_rupee
                  : Icons.shopping_basket,
              title: emptyTitle,
              message: emptyMessage,
              compact: true,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 16,
            top: 6,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final transaction = state.transactions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: TransactionListItem(
                  transaction: transaction,
                  onTap: () async {
                    log(
                      'MergedBorrowLendScreen: Opening transaction details for ID: ${transaction.id}',
                    );
                    if (transaction.sourceType ==
                            AppConstants.sourceTypeSplit &&
                        transaction.sourceId != null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SplitDetailScreen(splitId: transaction.sourceId!),
                        ),
                      );
                    } else {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionDetailsScreen(
                            transaction: transaction,
                            onUpdate: () {
                              log(
                                'MergedBorrowLendScreen: Transaction updated callback',
                              );
                              _refreshAllData();
                            },
                          ),
                        ),
                      );
                    }
                    log(
                      'MergedBorrowLendScreen: Returned from transaction details',
                    );
                    _refreshAllData();
                  },
                ),
              );
            }, childCount: state.transactions.length),
          ),
        );
      },
    );
  }
}
