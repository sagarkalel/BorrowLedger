import 'dart:developer';

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/add_transaction_menu.dart';
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
import 'contact_transaction_detail_screen.dart';
import 'contact_wise_transactions_screen.dart';

enum BorrowLendViewMode { contacts, cash, udhari, cashAndUdhari }

class MergedBorrowLendScreen extends StatefulWidget {
  const MergedBorrowLendScreen({super.key});

  @override
  State<MergedBorrowLendScreen> createState() => _MergedBorrowLendScreenState();
}

class _MergedBorrowLendScreenState extends State<MergedBorrowLendScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => false;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    log('MergedBorrowLendScreen: didChangeDependencies - Loading initial data');
    context.read<BorrowLendCubit>().loadAllData();
    context.read<BorrowLendCubit>().loadContactSummaries();
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<BorrowLendCubit>().loadMoreTransactions();
    }
  }

  // Pagination: Load more contacts when scrolled to bottom
  void _onContactScroll() {
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
                  minHeight: 86,
                  maxHeight: 86,
                  child: _buildViewModeSelector(),
                ),
              ),

              // Contact search bar
              if (_viewMode == BorrowLendViewMode.contacts)
                SliverToBoxAdapter(child: _buildContactSearchBar()),

              // Filter chips for contacts view
              if (_viewMode == BorrowLendViewMode.contacts)
                SliverToBoxAdapter(child: _buildContactFilterChips()),

              if (_viewMode != BorrowLendViewMode.contacts) ...[
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search bar (only for cash/udhari view)
                      _buildSearchBar(),

                      // Filter chips (only for cash/udhari view)
                      _buildFilterChips(),
                    ],
                  ),
                ),
              ],

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
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
        } else {
          if (state.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDashboardSummary() {
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Net balance card
              _buildNetBalanceCard(state),
              const SizedBox(height: 12),

              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: BuildSummaryCard(
                      title: tr.receivable,
                      amount: state.totalReceivable,
                      icon: Icons.call_received,
                      color: Colors.green,
                      isPositive: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BuildSummaryCard(
                      title: tr.payable,
                      amount: state.totalPayable,
                      icon: Icons.call_made,
                      color: Colors.orange,
                      isPositive: false,
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
    final isPositive = (state.netBalance >= 0);

    final Color primaryColor;
    final Color accentColor;

    if (isPositive) {
      primaryColor = AppTheme.primaryGreen;
      accentColor = AppTheme.primaryBlue;
    } else {
      primaryColor = const Color(0xFFFFB74D);
      // secondaryColor = const Color(0xFFFFB74D);
      accentColor = AppTheme.borrowColor;
    }

    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor, primaryColor, accentColor],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.2),
            blurRadius: 4,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 5,
            offset: const Offset(4, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isPositive
                  ? Icons.account_balance_wallet_rounded
                  : Icons.account_balance_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tr.netBalance,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: Colors.white.withOpacity(0.9),
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Text(
                  '${isPositive ? '+' : '-'}₹${state.netBalance.abs().toStringAsFixed(2)}',
                  // '₹${state.netBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.call_received : Icons.call_made,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  isPositive ? tr.youWillGet : tr.youWillGive,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tr = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        // Enhanced gradient background
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF5F5F5)],
        ),
        borderRadius: BorderRadius.circular(14),
        // Enhanced shadow with multiple layers
        boxShadow: [
          // Main shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          // Secondary shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
          // Highlight on top (for light mode)
          if (!isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: 8,
              offset: const Offset(0, -1),
              spreadRadius: 0,
            ),
        ],
        // Border for definition
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildViewModeTab(
              label: tr.contacts,
              icon: Icons.people_outline_rounded,
              mode: BorrowLendViewMode.contacts,
            ),
          ),
          Expanded(
            child: _buildViewModeTab(
              label: tr.cash,
              icon: Icons.currency_rupee_rounded,
              mode: BorrowLendViewMode.cash,
            ),
          ),
          Expanded(
            child: _buildViewModeTab(
              label: tr.udhari,
              icon: Icons.shopping_basket_outlined,
              mode: BorrowLendViewMode.udhari,
            ),
          ),
          Expanded(
            child: _buildViewModeTab(
              label: tr.cashAndUdhari,
              icon: Icons.receipt_long,
              mode: BorrowLendViewMode.cashAndUdhari,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeTab({
    required String label,
    required IconData icon,
    required BorrowLendViewMode mode,
  }) {
    final isSelected = _viewMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = mode == BorrowLendViewMode.contacts
        ? AppTheme.primaryGreen
        : mode == BorrowLendViewMode.cash
        ? AppTheme.cashColor
        : mode == BorrowLendViewMode.udhari
        ? AppTheme.udhariColor
        : const Color.fromARGB(255, 139, 84, 235);

    return GestureDetector(
      onTap: () {
        if (_viewMode != mode) {
          setState(() {
            _viewMode = mode;
            _searchController.clear();
            _contactSearchController.clear();
          });

          log('MergedBorrowLendScreen: Switching to ${mode.name} mode');

          final cubit = context.read<BorrowLendCubit>();
          if (mode == BorrowLendViewMode.contacts) {
            cubit.setViewMode('contacts');
          } else if (mode == BorrowLendViewMode.cash) {
            cubit.setViewMode('cash');
          } else if (mode == BorrowLendViewMode.udhari) {
            cubit.setViewMode('udhari');
          } else if (mode == BorrowLendViewMode.cashAndUdhari) {
            cubit.setViewMode('cash_udhari');
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          // Tab shadow when selected
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ]
              : null,
          // Border for selected tab
          border: isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : isDark
                  ? Colors.grey[400]
                  : Colors.grey[700],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isDark
                    ? Colors.grey[400]
                    : Colors.grey[700],
                letterSpacing: isSelected ? 0.2 : 0,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactFilterChips() {
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    log(
                      'MergedBorrowLendScreen: Setting contact filter to All',
                    );
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
          ),
        );
      },
    );
  }

  Widget _buildContactSearchBar() {
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(top: 4),
      child: TextField(
        controller: _contactSearchController,
        decoration: InputDecoration(
          hintText: tr.searchContactsByNameOrPhone,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _contactSearchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _contactSearchController.clear();
                    context.read<BorrowLendCubit>().setContactSearchQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[850]
              : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          context.read<BorrowLendCubit>().setContactSearchQuery(value);
          setState(() {});
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(top: 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: tr.searchTransactionsByNameOrPhone,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    context.read<BorrowLendCubit>().setSearchQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[850]
              : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          context.read<BorrowLendCubit>().setSearchQuery(value);
          // setState(() {});
        },
        onSubmitted: (_) =>
            context.read<BorrowLendCubit>().searchTransactions(),
      ),
    );
  }

  Widget _buildFilterChips() {
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  label: tr.youGave,
                  icon: Icons.call_made,
                  color: AppTheme.moneyOutColor,
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
                  label: tr.youGot,
                  icon: Icons.call_received,
                  color: AppTheme.moneyInColor,
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
      case BorrowLendViewMode.cashAndUdhari:
        return _buildTransactionsView();
    }
  }

  Widget _buildContactsView() {
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        if (state.isLoadingContacts && state.contactSummaries.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
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
            child: EmptyStateWidget(
              icon: Icons.people_outline,
              title: emptyTitle,
              message: emptyMessage,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
            top: 8,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final contactSummary = state.contactSummaries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ContactSummaryCard(
                  contactName: contactSummary.contact.name,
                  phoneNumber: contactSummary.contact.phone,
                  transactionCount: contactSummary.transactionCount,
                  netBalance: contactSummary.netBalance,
                  cashCount: contactSummary.cashCount,
                  udhariCount: contactSummary.udhariCount,
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
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
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
            child: EmptyStateWidget(
              icon: _viewMode == BorrowLendViewMode.cash
                  ? Icons.currency_rupee
                  : Icons.shopping_basket,
              title: emptyTitle,
              message: emptyMessage,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
            top: 8,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final transaction = state.transactions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TransactionListItem(
                  transaction: transaction,
                  onTap: () async {
                    log(
                      'MergedBorrowLendScreen: Opening transaction details for ID: ${transaction.id}',
                    );
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContactTransactionDetailScreen(
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
