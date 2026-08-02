import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/data/models/split_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/screens/add_split_screen.dart';
import 'package:borrow_ledger/presentation/widgets/build_summary_card.dart';
import 'package:borrow_ledger/presentation/widgets/empty_state_widget.dart';
import 'package:borrow_ledger/presentation/widgets/floating_tab_header_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../cubit/split_cubit.dart';
import '../widgets/app_list_avatar.dart';
import '../widgets/app_pill_badge.dart';
import '../widgets/app_search_field.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/settings_drawer.dart';
import 'split_detail_screen.dart';

class SplitsScreen extends StatefulWidget {
  const SplitsScreen({super.key});

  @override
  State<SplitsScreen> createState() => _SplitsScreenState();
}

class _ParticipantSettlementInfo {
  final bool userReceives;
  final double totalAmount;
  final double settledAmount;
  final double remainingAmount;

  const _ParticipantSettlementInfo({
    required this.userReceives,
    required this.totalAmount,
    required this.settledAmount,
    required this.remainingAmount,
  });
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
      body: BlocConsumer<SplitCubit, SplitState>(
        listener: (context, state) {
          if (state.error != null) {
            showFailureSnackbar(context, state.error!);
            context.read<SplitCubit>().clearMessages();
          }
          if (state.successMessage != null) {
            showSuccessSnackbar(context, state.successMessage!);
            context.read<SplitCubit>().clearMessages();
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.splits.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => context.read<SplitCubit>().loadSplits(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: Column(
                      children: [
                        // Net-Balance cards
                        _buildNetBalanceCard(state),
                        const SizedBox(height: 10),

                        // Summary cards
                        Row(
                          children: [
                            Expanded(
                              child: BuildSummaryCard(
                                title: tr.receivable,
                                amount: _getReceivable(state).abs(),
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
                                amount: _getPayable(state).abs(),
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
                  ),
                ),

                // Search bar & Filter chips
                SliverPersistentHeader(
                  pinned: true,
                  // floating: true,
                  delegate: FloatingTabHeaderDelegate(
                    minHeight: 104,
                    maxHeight: 104,
                    child: _buildSearchBarAndFilters(),
                  ),
                ),
                // Splits header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
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
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (state.splits.isEmpty && !state.isLoading)
                  SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: Icons.pie_chart_outline_rounded,
                      title: _hasActiveFilters
                          ? tr.noSplitsFound
                          : tr.noSplitExpensesYet,
                      message: _hasActiveFilters
                          ? tr.tryAdjustingFilters
                          : tr.startSplittingExpensesWithFriends,
                    ),
                  )
                else
                  // Splits list
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
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
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildSplitCard(context, split, isDark),
                          );
                        },
                        childCount:
                            state.splits.length +
                            (state.hasMoreData || state.isLoadingMore ? 1 : 0),
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

  Widget _buildSearchBarAndFilters() {
    final tr = AppLocalizations.of(context)!;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.only(top: 4),
            child: AppSearchField(
              controller: _searchController,
              hintText: tr.searchSplits,
              onClear: () {
                _searchController.clear();
                context.read<SplitCubit>().setSearchQuery('');
              },
              onChanged: (value) {
                context.read<SplitCubit>().setSearchQuery(value);
                // setState(() {});
              },
              onSubmitted: (_) {
                context.read<SplitCubit>().searchSplits();
              },
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                FilterChipWidget(
                  label: tr.all,
                  isSelected: _selectedStatus == null,
                  onSelected: () {
                    _selectedStatus = null;
                    _searchController.clear();
                    context.read<SplitCubit>().clearFilters();
                  },
                ),
                const SizedBox(width: 8),
                FilterChipWidget(
                  label: tr.pending,
                  icon: Icons.schedule_rounded,
                  color: AppTheme.warningColor,
                  isSelected: _selectedStatus == AppConstants.statusPending,
                  onSelected: () {
                    _selectedStatus = AppConstants.statusPending;
                    _searchController.clear();
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
                  isSelected: _selectedStatus == AppConstants.statusSettled,
                  onSelected: () {
                    _selectedStatus = AppConstants.statusSettled;
                    _searchController.clear();
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
    );
  }

  // Net balance
  Widget _buildNetBalanceCard(SplitState state) {
    final netBalance = _getReceivable(state).abs() - _getPayable(state);
    final isPositive = (netBalance >= 0);
    final colorScheme = Theme.of(context).colorScheme;
    final balanceColor = isPositive
        ? AppTheme.successColor
        : AppTheme.warningColor;
    final tr = AppLocalizations.of(context)!;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            AppListAvatar(
              label: tr.netBalance,
              centerIcon: isPositive
                  ? Icons.account_balance_wallet_rounded
                  : Icons.account_balance_outlined,
              indicatorIcon: isPositive ? Icons.call_received : Icons.call_made,
              indicatorColor: balanceColor,
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
                        isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: balanceColor,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isPositive ? '+' : '-'}₹${netBalance.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            AppPillBadge(
              label: isPositive ? tr.youWillGet : tr.youWillGive,
              icon: isPositive ? Icons.call_received : Icons.call_made,
              color: balanceColor,
              fontSize: 11,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            ),
          ],
        ),
      ),
    );
  }

  // Payable
  double _getPayable(SplitState state) {
    var payable = 0.0;
    for (final i in state.splits) {
      final a = _calculateBalance(i);
      if (a.isNegative) {
        payable = payable - a;
      }
    }
    return payable;
  }

  // Receivable
  double _getReceivable(SplitState state) {
    var receivable = 0.0;
    for (final i in state.splits) {
      final a = _calculateBalance(i);
      if (!a.isNegative) {
        receivable = receivable - a;
      }
    }
    return receivable;
  }

  // Helper to calculate balance (what user gets back or needs to give)
  double _calculateBalance(SplitExpenseModel split) {
    final participants = split.participants ?? [];
    final settlements = _buildParticipantSettlements(split, participants);
    final receivable = settlements
        .where((s) => s.userReceives)
        .fold<double>(0, (sum, s) => sum + s.remainingAmount);
    final payable = settlements
        .where((s) => !s.userReceives)
        .fold<double>(0, (sum, s) => sum + s.remainingAmount);
    return receivable > 0 ? receivable : -payable;
  }

  List<_ParticipantSettlementInfo> _buildParticipantSettlements(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants,
  ) {
    final totalShares = participants.fold<double>(
      0,
      (sum, p) => sum + p.shareAmount,
    );
    final userShare = split.totalAmount - totalShares;
    var userNet = split.paidByUser - userShare;
    const tolerance = 0.01;
    final settlements = <_ParticipantSettlementInfo>[];

    if (userNet > tolerance) {
      for (final participant in participants) {
        final participantOwes =
            participant.shareAmount - participant.expensePaid;
        final allocated = participantOwes > 0
            ? (participantOwes < userNet ? participantOwes : userNet)
            : 0.0;
        final remaining = allocated - participant.paid;
        settlements.add(
          _ParticipantSettlementInfo(
            userReceives: true,
            totalAmount: allocated,
            settledAmount: participant.paid > allocated
                ? allocated
                : participant.paid,
            remainingAmount: remaining <= tolerance ? 0 : remaining,
          ),
        );
        userNet -= allocated;
      }
    } else if (userNet < -tolerance) {
      var userOwes = -userNet;
      for (final participant in participants) {
        final participantCredit =
            participant.expensePaid - participant.shareAmount;
        final allocated = participantCredit > 0
            ? (participantCredit < userOwes ? participantCredit : userOwes)
            : 0.0;
        final remaining = allocated - participant.paid;
        settlements.add(
          _ParticipantSettlementInfo(
            userReceives: false,
            totalAmount: allocated,
            settledAmount: participant.paid > allocated
                ? allocated
                : participant.paid,
            remainingAmount: remaining <= tolerance ? 0 : remaining,
          ),
        );
        userOwes -= allocated;
      }
    } else {
      for (final _ in participants) {
        settlements.add(
          const _ParticipantSettlementInfo(
            userReceives: true,
            totalAmount: 0,
            settledAmount: 0,
            remainingAmount: 0,
          ),
        );
      }
    }

    return settlements;
  }

  // IMPROVED SPLIT CARD - Shows total and what you get back/need to give
  Widget _buildSplitCard(
    BuildContext context,
    SplitExpenseModel split,
    bool isDark,
  ) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final participants = split.participants ?? [];
    final isSettled = split.status == AppConstants.statusSettled;
    final statusColor = isSettled
        ? AppTheme.successColor
        : AppTheme.warningColor;

    // Calculate balance
    final balance = _calculateBalance(split);
    final isPositive = balance >= 0;
    final directionColor = isPositive
        ? AppTheme.moneyInColor
        : AppTheme.moneyOutColor;

    final settlements = _buildParticipantSettlements(split, participants);
    final totalPendingCount = settlements
        .where((s) => s.remainingAmount > 0 && s.settledAmount == 0)
        .length;

    final totalPaidCount = settlements
        .where((s) => s.remainingAmount <= 0)
        .length;

    final partiallyPaidCount = settlements
        .where((s) => s.remainingAmount > 0 && s.settledAmount > 0)
        .length;

    final totalReceived = settlements.fold<double>(
      0,
      (sum, s) => sum + s.settledAmount,
    );
    final totalExpected = settlements.fold<double>(
      0,
      (sum, s) => sum + s.totalAmount,
    );
    final paymentProgress = totalExpected > 0
        ? totalReceived / totalExpected
        : 0.0;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SplitDetailScreen(splitId: split.id!),
            ),
          );
          if (result == true && context.mounted) {
            context.read<SplitCubit>().loadSplits();
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppListAvatar(
                    label: split.title,
                    centerIcon: Icons.pie_chart_rounded,
                    indicatorIcon: Icons.group_rounded,
                    indicatorColor: colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          split.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildSplitMetaRow(
                          context,
                          split,
                          participants.length,
                          statusColor,
                          isSettled,
                        ),
                        if (split.description != null &&
                            split.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            split.description!,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildSplitAmountSection(
                    context,
                    balance: balance,
                    totalAmount: split.totalAmount,
                    color: directionColor,
                    isPositive: isPositive,
                    isSettled: isSettled,
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),

              if (!isSettled && totalExpected > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: paymentProgress,
                    minHeight: 4,
                    backgroundColor: colorScheme.outline.withValues(
                      alpha: 0.14,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.secondary,
                    ),
                  ),
                ),
              ],

              if (totalPaidCount > 0 ||
                  partiallyPaidCount > 0 ||
                  totalPendingCount > 0) ...[
                const SizedBox(height: 7),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    if (totalPaidCount > 0)
                      AppPillBadge(
                        label: '$totalPaidCount ${tr.paid}',
                        color: AppTheme.successColor,
                        fontSize: 9,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                      ),
                    if (partiallyPaidCount > 0)
                      AppPillBadge(
                        label: '$partiallyPaidCount ${tr.partial}',
                        color: colorScheme.secondary,
                        fontSize: 9,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                      ),
                    if (totalPendingCount > 0)
                      AppPillBadge(
                        label: '$totalPendingCount ${tr.pending}',
                        color: AppTheme.warningColor,
                        fontSize: 9,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitMetaRow(
    BuildContext context,
    SplitExpenseModel split,
    int participantCount,
    Color statusColor,
    bool isSettled,
  ) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppPillBadge(
          label: isSettled ? tr.settledBadge : tr.pendingBadge,
          icon: isSettled ? Icons.check_circle_rounded : Icons.schedule_rounded,
          color: statusColor,
          fontSize: 9,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 10,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 3),
            Text(
              DateFormat(AppConstants.dateFormat).format(split.date),
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_rounded,
              size: 11,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 3),
            Text(
              '$participantCount ${participantCount == 1 ? tr.personSmall : tr.peopleSmall}',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        AppPillBadge(
          label: '₹${split.totalAmount.toStringAsFixed(2)}',
          color: colorScheme.onSurfaceVariant,
          fontSize: 9,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        ),
      ],
    );
  }

  Widget _buildSplitAmountSection(
    BuildContext context, {
    required double balance,
    required double totalAmount,
    required Color color,
    required bool isPositive,
    required bool isSettled,
  }) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final label = isSettled
        ? tr.settled
        : isPositive
        ? tr.youWillGet
        : tr.youWillGive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSettled ? colorScheme.onSurfaceVariant : color,
              ),
            ),
            Text(
              (isSettled ? totalAmount : balance.abs()).toStringAsFixed(2),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isSettled ? colorScheme.onSurface : color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AppPillBadge(
          label: label,
          icon: isSettled
              ? Icons.done_all_rounded
              : isPositive
              ? Icons.call_received
              : Icons.call_made,
          color: isSettled ? colorScheme.onSurfaceVariant : color,
          fontSize: 8,
        ),
      ],
    );
  }
}
