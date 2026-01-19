import 'package:borrow_ledger/data/models/split_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/screens/add_split_screen.dart';
import 'package:borrow_ledger/presentation/widgets/build_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../cubit/split_cubit.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/settings_drawer.dart';
import 'split_detail_screen.dart';

class SplitsScreen extends StatefulWidget {
  const SplitsScreen({super.key});

  @override
  State<SplitsScreen> createState() => _SplitsScreenState();
}

class _SplitsScreenState extends State<SplitsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<SplitCubit>().loadSplits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SplitCubit>().loadMoreSplits();
    }
  }

  bool get _hasActiveFilters =>
      _selectedStatus != null || _searchController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: const SettingsDrawer(),
      appBar: AppBar(
        title: Text(tr.splitExpenses),
        actions: [
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded),
              tooltip: tr.clearFilters,
              onPressed: () {
                setState(() {
                  _selectedStatus = null;
                  _searchController.clear();
                });
                context.read<SplitCubit>().clearFilters();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar & Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: tr.searchSplits,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              context.read<SplitCubit>().setSearchQuery(null);
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
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
                    context.read<SplitCubit>().setSearchQuery(value);
                    setState(() {});
                  },
                  onSubmitted: (value) {
                    context.read<SplitCubit>().searchSplits();
                  },
                ),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      FilterChipWidget(
                        label: tr.all,
                        isSelected: _selectedStatus == null,
                        onSelected: () {
                          setState(() => _selectedStatus = null);
                          context.read<SplitCubit>().clearFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChipWidget(
                        label: tr.pending,
                        icon: Icons.schedule_rounded,
                        color: AppTheme.warningColor,
                        isSelected:
                            _selectedStatus == AppConstants.statusPending,
                        onSelected: () {
                          setState(
                            () => _selectedStatus = AppConstants.statusPending,
                          );
                          context.read<SplitCubit>().setFilterStatus(
                            AppConstants.statusPending,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChipWidget(
                        label: tr.settled,
                        icon: Icons.check_circle_rounded,
                        color: AppTheme.successColor,
                        isSelected:
                            _selectedStatus == AppConstants.statusSettled,
                        onSelected: () {
                          setState(
                            () => _selectedStatus = AppConstants.statusSettled,
                          );
                          context.read<SplitCubit>().setFilterStatus(
                            AppConstants.statusSettled,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: BlocConsumer<SplitCubit, SplitState>(
              listener: (context, state) {
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error!),
                      backgroundColor: AppTheme.errorColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  context.read<SplitCubit>().clearMessages();
                }
                if (state.successMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.successMessage!),
                      backgroundColor: AppTheme.successColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  context.read<SplitCubit>().clearMessages();
                }
              },
              builder: (context, state) {
                if (state.isLoading && state.splits.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.splits.isEmpty && !state.isLoading) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: EmptyStateWidget(
                        icon: Icons.pie_chart_outline_rounded,
                        title: _hasActiveFilters
                            ? tr.noSplitsFound
                            : tr.noSplitExpensesYet,
                        message: _hasActiveFilters
                            ? tr.tryAdjustingFilters
                            : tr.startSplittingExpensesWithFriends,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<SplitCubit>().loadSplits(),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Summary cards
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: _buildSummaryCards(context, state, isDark),
                        ),
                      ),

                      // Splits header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tr.recentSplits,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${state.totalCount} ${tr.total}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Splits list
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == state.splits.length) {
                                // Loading indicator at the end
                                if (state.isLoadingMore) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                } else if (!state.hasMoreData &&
                                    state.splits.length > 10) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: Text(
                                        tr.noMoreSplits,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey[600]
                                              : Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }

                              final split = state.splits[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildSplitCard(context, split, isDark),
                              );
                            },
                            childCount:
                                state.splits.length +
                                (state.hasMoreData || state.isLoadingMore
                                    ? 1
                                    : 0),
                          ),
                        ),
                      ),

                      // Bottom padding
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: 'split_fab',
        onPressed: () {
          final cubit = context.read<SplitCubit>();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSplitScreen()),
          ).then((_) => cubit.loadSplits());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Summary cards widget with simpler words
  Widget _buildSummaryCards(
    BuildContext context,
    SplitState state,
    bool isDark,
  ) {
    final tr = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: BuildSummaryCard(
            title: tr.youWillGet,
            amount: state.totalOwed,
            icon: Icons.call_received,
            color: Colors.green,
            isPositive: true,
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: BuildSummaryCard(
            title: tr.youPaid,
            amount: state.totalPaidByUser,
            icon: Icons.call_made,
            color: AppTheme.splitColor,
            isPositive: false,
          ),
        ),
      ],
    );
  }

  // Helper to calculate balance (what user gets back or needs to give)
  double _calculateBalance(SplitExpenseModel split) {
    final participants = split.participants ?? [];
    final totalShares = participants.fold<double>(
      0,
      (sum, p) => sum + p.shareAmount,
    );
    final userShare = split.totalAmount - totalShares;
    return split.paidByUser - userShare;
  }

  // IMPROVED SPLIT CARD - Shows total and what you get back/need to give
  Widget _buildSplitCard(
    BuildContext context,
    SplitExpenseModel split,
    bool isDark,
  ) {
    final tr = AppLocalizations.of(context)!;

    final participants = split.participants ?? [];
    final isSettled = split.status == AppConstants.statusSettled;
    final statusColor = isSettled
        ? AppTheme.successColor
        : AppTheme.warningColor;

    // Calculate balance
    final balance = _calculateBalance(split);
    final isPositive = balance > 0;

    // FIXED: Calculate payment statistics correctly
    final totalPendingCount = participants
        .where((p) => p.paid == 0) // Only those who haven't paid anything
        .length;

    final totalPaidCount = participants
        .where((p) => p.status == AppConstants.statusPaid)
        .length;

    final partiallyPaidCount = participants
        .where(
          (p) =>
              p.paid > 0 &&
              p.paid < p.shareAmount &&
              p.status != AppConstants.statusPaid,
        )
        .length;

    // Determine if there are partial payments
    final hasPartialPayments = partiallyPaidCount > 0;

    // Calculate total received
    final totalReceived = participants.fold<double>(
      0,
      (sum, p) => sum + p.paid,
    );
    final totalExpected = participants.fold<double>(
      0,
      (sum, p) => sum + p.shareAmount,
    );
    final paymentProgress = totalExpected > 0
        ? totalReceived / totalExpected
        : 0.0;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SplitDetailScreen(splitId: split.id!),
            ),
          );
          if (result == true && mounted) {
            context.read<SplitCubit>().loadSplits();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with purple gradient
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.deepPurple.shade300,
                          AppTheme.splitColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.pie_chart_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          split.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                AppConstants.dateFormat,
                              ).format(split.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSettled
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                          size: 11,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSettled ? tr.settledBadge : tr.pendingBadge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (split.description != null &&
                  split.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  split.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // IMPROVED: Amount info showing Total and Balance
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    // Total Amount
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_rounded,
                                size: 13,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tr.total,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${split.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 44,
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),

                    // Balance - Get Back or Need to Give
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPositive
                                    ? Icons.call_received
                                    : Icons.call_made,
                                size: 13,
                                color: isPositive
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  // isPositive ? 'You Get' : 'You Give',
                                  isPositive ? tr.youGot : tr.youGave,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isPositive
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${balance.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isPositive
                                  ? Colors.green.shade600
                                  : Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Payment progress indicator for pending splits with partial payments
              if (!isSettled && hasPartialPayments) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.hourglass_bottom_rounded,
                              size: 12,
                              color: AppTheme.splitColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tr.collectionProgress,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${(paymentProgress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.splitColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: paymentProgress,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.splitColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Participants summary with badges
              Row(
                children: [
                  Icon(
                    Icons.group_rounded,
                    size: 16,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${participants.length} ${participants.length == 1 ? tr.personSmall : tr.peopleSmall}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (totalPaidCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalPaidCount ${tr.paid}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ),
                  ],
                  if (partiallyPaidCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$partiallyPaidCount ${tr.partial}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.splitColor,
                        ),
                      ),
                    ),
                  ],
                  if (totalPendingCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalPendingCount ${tr.pending}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
