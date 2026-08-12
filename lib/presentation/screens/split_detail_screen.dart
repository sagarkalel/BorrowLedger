import 'dart:io';
import 'dart:ui' as ui;

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/core/constants/app_text_styles.dart';
import 'package:borrow_ledger/core/utils/split_settlement_calculator.dart';
import 'package:borrow_ledger/data/models/split_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/app_dialog_components.dart';
import 'package:borrow_ledger/presentation/widgets/app_loading_state.dart';
import 'package:borrow_ledger/presentation/widgets/app_list_avatar.dart';
import 'package:borrow_ledger/presentation/widgets/app_pill_badge.dart';
import 'package:borrow_ledger/presentation/widgets/custom_text_field.dart';
import 'package:borrow_ledger/presentation/widgets/delete_split_expense_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/share_name_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/split_repository.dart';
import '../cubit/split_cubit.dart';

class _SettlementRouteStep {
  final String fromName;
  final String toName;
  final double amount;

  const _SettlementRouteStep({
    required this.fromName,
    required this.toName,
    required this.amount,
  });
}

class SplitDetailScreen extends StatefulWidget {
  final int splitId;

  const SplitDetailScreen({super.key, required this.splitId});

  @override
  State<SplitDetailScreen> createState() => _SplitDetailScreenState();
}

class _SplitDetailScreenState extends State<SplitDetailScreen> {
  SplitExpenseModel? _split;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSplit();
  }

  Future<void> _loadSplit() async {
    setState(() => _isLoading = true);
    try {
      final splitRepo = context.read<SplitRepository>();
      final split = await splitRepo.getSplitById(widget.splitId);
      if (mounted) {
        setState(() {
          _split = split;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final tr = AppLocalizations.of(context)!;
        showFailureSnackbar(context, '${tr.failedToLoad}: $e');
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(tr.splitDetails), elevation: 0),
        body: const AppPageLoadingState(compact: true),
      );
    }

    if (_split == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr.splitDetails), elevation: 0),
        body: Center(child: Text(tr.splitNotFound)),
      );
    }

    final split = _split!;
    final isSettled = split.status == AppConstants.statusSettled;
    final statusColor = AppTheme.getStatusColor(split.status);
    final participants = split.participants ?? [];

    final settlements = SplitSettlementCalculator.calculate(
      split,
      participants,
      userName: tr.you,
      unknownName: tr.unknown,
    );
    final fullyPendingParticipants = settlements
        .where((s) => s.remainingAmount > 0 && s.participant.paid == 0)
        .toList();

    final partiallyPaidParticipants = settlements
        .where((s) => s.remainingAmount > 0 && s.participant.paid > 0)
        .toList();

    final paidParticipants = settlements
        .where((s) => s.remainingAmount <= 0)
        .toList();

    final totalPendingCount =
        fullyPendingParticipants.length + partiallyPaidParticipants.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.splitDetails),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: tr.share,
            onPressed: _shareSplitInvoice,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSplit,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Title, Status, Date in one compact card
                    _buildHeaderCard(split, statusColor, isSettled, isDark),
                    const SizedBox(height: 8),

                    // Financial summary card (compact version)
                    _buildFinancialSummaryCard(split, participants, isDark),
                    const SizedBox(height: 8),

                    if (participants.length >= 2 &&
                        (isSettled ||
                            (totalPendingCount > 0 &&
                                split.settlementRouteMode ==
                                    AppConstants.splitRouteMediator))) ...[
                      _buildSettlementRouteCard(
                        split,
                        participants,
                        isDark,
                        isSettled: isSettled,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Participants header with count
                    _buildParticipantsHeader(
                      participants.length,
                      totalPendingCount,
                      isDark,
                    ),
                  ],
                ),
              ),
            ),

            // Pending settlements section
            if (fullyPendingParticipants.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 5, 12, 4),
                  child: Text(
                    tr.pendingSettlements,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final settlement = fullyPendingParticipants[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _buildCompactParticipantCard(
                        settlement,
                        isDark,
                        onMarkPaid: () =>
                            _showSettleParticipantDialog(settlement),
                      ),
                    );
                  }, childCount: fullyPendingParticipants.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 4)),
            ],

            // Partially settled participants
            if (partiallyPaidParticipants.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 5, 12, 4),
                  child: Text(
                    tr.partiallySettled,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final settlement = partiallyPaidParticipants[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _buildCompactParticipantCard(
                        settlement,
                        isDark,
                        onMarkPaid: () =>
                            _showSettleParticipantDialog(settlement),
                      ),
                    );
                  }, childCount: partiallyPaidParticipants.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 4)),
            ],

            // Settled or no-action participants
            if (paidParticipants.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 5, 12, 4),
                  child: Text(
                    tr.settledOrNoAction,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final settlement = paidParticipants[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _buildCompactParticipantCard(settlement, isDark),
                    );
                  }, childCount: paidParticipants.length),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            // Bottom action button
            if (!isSettled)
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  child: FilledButton.icon(
                    onPressed: _showSettleConfirmation,
                    icon: const Icon(Icons.fact_check_rounded, size: 20),
                    label: Text(tr.reviewAndSettleSplit),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.warningColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            // Delete button
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: OutlinedButton.icon(
                  onPressed: _showDeleteConfirmation,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(tr.deleteSplitExpense),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: kToolbarHeight)),
          ],
        ),
      ),
    );
  }

  // Compact header card with title, status, and date
  Widget _buildHeaderCard(
    SplitExpenseModel split,
    Color statusColor,
    bool isSettled,
    bool isDark,
  ) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppListAvatar(
                  label: split.title,
                  centerIcon: Icons.pie_chart_rounded,
                  indicatorIcon: Icons.group_rounded,
                  indicatorColor: colorScheme.secondary,
                  size: 38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        split.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(split.date),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppPillBadge(
                  label: isSettled ? tr.settledBadge : tr.pendingBadge,
                  icon: isSettled ? Icons.check_circle : Icons.schedule,
                  color: statusColor,
                  fontSize: 10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ],
            ),
            if (split.description != null && split.description!.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                split.description!,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Compact financial summary card
  Widget _buildFinancialSummaryCard(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants,
    bool isDark,
  ) {
    final userShare = SplitSettlementCalculator.userShare(split, participants);
    final balance = SplitSettlementCalculator.userBalance(split, participants);
    final isPositive = balance > 0;
    final isSettled = split.status == AppConstants.statusSettled;
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final balanceColor = isPositive
        ? AppTheme.successColor
        : AppTheme.warningColor;

    final settlements = SplitSettlementCalculator.calculate(
      split,
      participants,
      unknownName: tr.unknown,
    );
    final totalReceived = settlements.fold<double>(
      0,
      (sum, s) =>
          sum +
          (s.participant.paid > s.totalAmount
              ? s.totalAmount
              : s.participant.paid),
    );
    final totalExpected = settlements.fold<double>(
      0,
      (sum, s) => sum + s.totalAmount,
    );
    final progress = totalExpected > 0 ? totalReceived / totalExpected : 0.0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Column(
          children: [
            Row(
              children: [
                AppListAvatar(
                  label: tr.totalAmount,
                  centerIcon: Icons.account_balance_wallet_rounded,
                  indicatorIcon: Icons.currency_rupee_rounded,
                  indicatorColor: colorScheme.secondary,
                  size: 38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.totalAmount,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${split.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.person_rounded,
                    label: tr.yourShare,
                    value: '₹${userShare.toStringAsFixed(2)}',
                    color: colorScheme.secondary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.payments_rounded,
                    label: tr.youPaid,
                    value: '₹${split.paidByUser.toStringAsFixed(2)}',
                    color: colorScheme.primary,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            if (!isSettled) ...[
              const SizedBox(height: 6),
              AppDialogNotice(
                color: balanceColor,
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.call_received : Icons.call_made,
                      color: balanceColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPositive ? tr.youWillGet : tr.youWillGive,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${balance.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              color: balanceColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: balanceColor,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ],
            if (participants.isNotEmpty && !isSettled) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.hourglass_bottom_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% ${tr.collectionProgress}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${totalReceived.toStringAsFixed(0)}/₹${totalExpected.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: colorScheme.outline.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(balanceColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialogNotice(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.body2.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementRouteCard(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants,
    bool isDark, {
    required bool isSettled,
  }) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final mediatorName = _routeMediatorName(split, participants, tr);
    final isMediatorRoute =
        split.settlementRouteMode == AppConstants.splitRouteMediator;
    final routeSteps = _buildRouteSteps(
      split,
      participants,
      tr,
      ignoreSettledPayments: isSettled,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.splitColor.withValues(
                      alpha: isDark ? 0.18 : 0.11,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.route_rounded,
                    color: AppTheme.splitColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.settlementRoute,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isSettled
                            ? tr.settlementRouteCompleted
                            : isMediatorRoute
                            ? tr.routeThroughTrustedPerson
                            : tr.optimizedRoute,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppDialogNotice(
              color: AppTheme.splitColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppTheme.splitColor,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          isMediatorRoute
                              ? '${tr.settleViaPerson}: $mediatorName'
                              : tr.optimizedRoute,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...routeSteps.map(_buildSettlementRouteStepRow),
                  if (routeSteps.isEmpty)
                    Text(
                      tr.allSettlementsAlreadyComplete,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 7),
                  Text(
                    isSettled ? tr.settlementRouteCompleted : tr.routePlanOnly,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.25,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementRouteStepRow(_SettlementRouteStep step) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              step.fromName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 15,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              step.toName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${step.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.splitColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _routeMediatorName(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants,
    AppLocalizations tr,
  ) {
    final mediatorContactId = split.settlementMediatorContactId;
    if (mediatorContactId == null) return tr.you;

    for (final participant in participants) {
      if (participant.contactId == mediatorContactId) {
        return participant.contactName ?? tr.unknown;
      }
    }
    return tr.unknown;
  }

  List<_SettlementRouteStep> _buildRouteSteps(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants,
    AppLocalizations tr, {
    bool ignoreSettledPayments = false,
    String? userName,
  }) {
    final totalsByRoute = <String, _SettlementRouteStep>{};
    final routeParticipants = ignoreSettledPayments
        ? participants
              .map(
                (participant) => participant.copyWith(
                  paid: 0,
                  status: AppConstants.statusPending,
                ),
              )
              .toList()
        : participants;

    void addStep(String fromName, String toName, double amount) {
      if (amount <= SplitSettlementCalculator.tolerance || fromName == toName) {
        return;
      }

      final key = '$fromName->$toName';
      final existing = totalsByRoute[key];
      totalsByRoute[key] = _SettlementRouteStep(
        fromName: fromName,
        toName: toName,
        amount: (existing?.amount ?? 0) + amount,
      );
    }

    final routeEntries = SplitSettlementCalculator.calculateRouteEntries(
      split,
      routeParticipants,
      userName: userName ?? tr.you,
      unknownName: tr.unknown,
    );

    for (final routeEntry in routeEntries) {
      final amount = routeEntry.amount;
      if (amount <= SplitSettlementCalculator.tolerance) continue;
      addStep(routeEntry.from.name, routeEntry.to.name, amount);
    }

    final steps = totalsByRoute.values.toList()
      ..sort((a, b) {
        final fromCompare = a.fromName.compareTo(b.fromName);
        if (fromCompare != 0) return fromCompare;
        return a.toName.compareTo(b.toName);
      });
    return steps;
  }

  // Compact participants header
  Widget _buildParticipantsHeader(int total, int pending, bool isDark) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              tr.participants,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            AppPillBadge(
              label: '$total',
              color: colorScheme.secondary,
              fontSize: 11,
            ),
          ],
        ),
        if (pending > 0)
          AppPillBadge(
            label: '$pending ${tr.pending}',
            icon: Icons.schedule_rounded,
            color: AppTheme.warning,
            fontSize: 10,
          ),
      ],
    );
  }

  // Compact participant card
  Widget _buildCompactParticipantCard(
    SplitSettlementResult settlement,
    bool isDark, {
    VoidCallback? onMarkPaid,
  }) {
    final participant = settlement.participant;
    final remaining = settlement.remainingAmount;
    final isPaid = remaining <= 0;
    final isPartiallyPaid = participant.paid > 0 && remaining > 0;
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final actionColor = settlement.userReceives
        ? AppTheme.moneyInColor
        : AppTheme.moneyOutColor;
    final actionIcon = settlement.userReceives
        ? Icons.call_received_rounded
        : Icons.call_made_rounded;
    final actionLabel = settlement.userReceives ? tr.markReceived : tr.markPaid;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Column(
          children: [
            Row(
              children: [
                AppListAvatar(
                  label: participant.contactName ?? tr.unknown,
                  indicatorIcon: isPaid
                      ? Icons.check_rounded
                      : Icons.currency_rupee_rounded,
                  indicatorColor: isPaid
                      ? AppTheme.success
                      : isPartiallyPaid
                      ? AppTheme.warning
                      : colorScheme.secondary,
                  size: 38,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participant.contactName ?? tr.unknown,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _participantSubtitle(settlement, tr.shareAmount),
                        style: AppTextStyles.caption.copyWith(
                          color: isPartiallyPaid
                              ? actionColor
                              : colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: isPartiallyPaid
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isPaid)
                  AppPillBadge(
                    label: settlement.totalAmount > 0
                        ? tr.settledBadge
                        : tr.noActionBadge,
                    icon: Icons.check_circle,
                    color: AppTheme.success,
                    fontSize: 10,
                  )
                else
                  Text(
                    '₹${remaining.toStringAsFixed(2)}',
                    style: AppTextStyles.body2.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isPartiallyPaid ? AppTheme.warning : actionColor,
                    ),
                  ),
              ],
            ),
            if (!isPaid && remaining != 0.0) ...[
              const SizedBox(height: 7),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onMarkPaid,
                  icon: Icon(actionIcon, size: 14),
                  label: Text(isPartiallyPaid ? tr.addMore : actionLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _participantSubtitle(
    SplitSettlementResult settlement,
    String shareLabel,
  ) {
    final participant = settlement.participant;
    final remaining = settlement.remainingAmount;
    if (remaining > 0) {
      if (participant.paid > 0) {
        return AppLocalizations.of(context)!.settledAmountLeft(
          '₹${participant.paid.toStringAsFixed(2)}',
          '₹${remaining.toStringAsFixed(2)}',
        );
      }
      if (settlement.participantOwes) {
        return AppLocalizations.of(context)!.owesCounterparty(
          settlement.counterpartyName,
          '₹${remaining.toStringAsFixed(2)}',
        );
      }
      return AppLocalizations.of(context)!.youOwePerson(
        participant.contactName ?? AppLocalizations.of(context)!.unknown,
        '₹${remaining.toStringAsFixed(2)}',
      );
    }

    if (participant.expensePaid > 0) {
      return '$shareLabel: ₹${participant.shareAmount.toStringAsFixed(2)} • ${AppLocalizations.of(context)!.paidDuringBill} ₹${participant.expensePaid.toStringAsFixed(2)}';
    }

    return '$shareLabel: ₹${participant.shareAmount.toStringAsFixed(2)}';
  }

  void _showSettleParticipantDialog(SplitSettlementResult settlement) {
    final participant = settlement.participant;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final remaining = settlement.remainingAmount;
    bool isFullAmount = true;
    final tr = AppLocalizations.of(context)!;
    final userReceives = settlement.userReceives;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final color = userReceives
              ? AppTheme.moneyInColor
              : AppTheme.moneyOutColor;
          final title = userReceives ? tr.markAsReceived : tr.markAsPaid;
          final amountLabel = userReceives ? tr.amountReceived : tr.amountPaid;
          final remainingText = '₹${remaining.toStringAsFixed(2)}';
          final directionText = settlement.participantOwes
              ? tr.personOwesCounterparty(
                  participant.contactName ?? tr.unknown,
                  settlement.counterpartyName,
                  remainingText,
                )
              : tr.youOwePerson(
                  participant.contactName ?? tr.unknown,
                  remainingText,
                );

          return AppDialogShell(
            icon: AppDialogIcon(
              icon: Icons.account_balance_wallet_rounded,
              color: color,
            ),
            title: title,
            content: [
              Text(
                directionText,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              AppDialogNotice(
                color: color,
                child: Column(
                  children: [
                    _buildDialogAmountRow(
                      tr.shareAmount,
                      '₹${participant.shareAmount.toStringAsFixed(2)}',
                    ),
                    if (participant.expensePaid > 0) ...[
                      const SizedBox(height: 6),
                      _buildDialogAmountRow(
                        tr.paidDuringBill,
                        '₹${participant.expensePaid.toStringAsFixed(2)}',
                      ),
                    ],
                    if (participant.paid > 0) ...[
                      const SizedBox(height: 6),
                      _buildDialogAmountRow(
                        tr.alreadyPaid,
                        '₹${participant.paid.toStringAsFixed(2)}',
                      ),
                    ],
                    const SizedBox(height: 8),
                    Divider(color: color.withValues(alpha: 0.22), height: 1),
                    const SizedBox(height: 8),
                    _buildDialogAmountRow(
                      tr.remaining,
                      '₹${remaining.toStringAsFixed(2)}',
                      color: color,
                      isStrong: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Amount type selector
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: isDark ? 0.09 : 0.06,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAmountTypeButton(
                        label: tr.fullAmount,
                        icon: Icons.account_balance_wallet_rounded,
                        isSelected: isFullAmount,
                        onTap: () => setDialogState(() {
                          isFullAmount = true;
                          amountController.clear();
                        }),
                        color: color,
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _buildAmountTypeButton(
                        label: tr.partial,
                        icon: Icons.payments_rounded,
                        isSelected: !isFullAmount,
                        onTap: () => setDialogState(() {
                          isFullAmount = false;
                        }),
                        color: color,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isFullAmount) ...[
                      CustomTextField(
                        controller: amountController,
                        labelText: amountLabel,
                        prefixText: '₹ ',
                        hintText: '0.00',
                        prefixIcon: Icons.payments_rounded,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            amountController.clear();
                          },
                        ),
                        isDense: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return tr.pleaseEnterAmount;
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return tr.pleaseEnterValidAmount;
                          }
                          if (amount > remaining) {
                            return '${tr.amountCanNotExceed} ₹${remaining.toStringAsFixed(2)}';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [0.25, 0.5, 0.75, 1.0].map((percent) {
                          final amount = remaining * percent;
                          final percentage = (percent * 100).toInt();
                          return ActionChip(
                            label: Text(
                              '$percentage%  ₹${amount.toStringAsFixed(0)}',
                            ),
                            onPressed: () => amountController.text = amount
                                .toStringAsFixed(2),
                            visualDensity: VisualDensity.compact,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                            backgroundColor: color.withValues(alpha: 0.09),
                            side: BorderSide(
                              color: color.withValues(alpha: 0.18),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),

              AppDialogNotice(
                color: Theme.of(context).colorScheme.secondary,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isFullAmount
                            ? userReceives
                                  ? tr.fullRemainingAmountWillBeMarkedAsReceived
                                  : tr.fullRemainingAmountWillBeMarkedAsPaid
                            : userReceives
                            ? tr.onlyEnteredAmountWillBeMarkedAsReceived
                            : tr.onlyEnteredAmountWillBeMarkedAsPaid,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            actions: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(tr.cancel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    double amountReceived;

                    if (isFullAmount) {
                      amountReceived = remaining;
                    } else {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      amountReceived = double.parse(amountController.text);
                    }

                    final newPaidAmount = participant.paid + amountReceived;

                    Navigator.pop(dialogContext);

                    await context.read<SplitCubit>().markParticipantAsPaid(
                      participant.id!,
                      newPaidAmount,
                    );

                    if (mounted) {
                      await _loadSplit();
                    }
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: Text(isFullAmount ? tr.markFull : tr.markPartial),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogAmountRow(
    String label,
    String value, {
    Color? color,
    bool isStrong = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final valueColor = color ?? colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: isStrong ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: isStrong ? 15 : 13,
            color: valueColor,
            fontWeight: isStrong ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingSettlementPreview(
    SplitSettlementResult settlement,
    AppLocalizations tr,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final participantName = settlement.participant.contactName ?? tr.unknown;
    final amount = '₹${settlement.remainingAmount.toStringAsFixed(2)}';
    final text = settlement.participantOwes
        ? tr.personOwesCounterparty(
            participantName,
            settlement.counterpartyName,
            amount,
          )
        : tr.youOwePerson(participantName, amount);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            settlement.userReceives
                ? Icons.call_received_rounded
                : Icons.call_made_rounded,
            size: 15,
            color: AppTheme.warningColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.25,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountTypeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettleConfirmation() {
    final participants = _split?.participants ?? [];

    final tr = AppLocalizations.of(context)!;
    final settlements = _split == null
        ? <SplitSettlementResult>[]
        : SplitSettlementCalculator.calculate(
            _split!,
            participants,
            unknownName: tr.unknown,
          );

    final allPaid = settlements.every((s) => s.remainingAmount <= 0);

    final pendingSettlements = settlements
        .where((s) => s.remainingAmount > 0)
        .toList();
    final pendingCount = pendingSettlements.length;

    final totalPending = pendingSettlements.fold<double>(
      0,
      (sum, s) => sum + s.remainingAmount,
    );

    if (!allPaid) {
      showDialog(
        context: context,
        builder: (dialogContext) => AppDialogShell(
          icon: const AppDialogIcon(
            icon: Icons.warning_rounded,
            color: AppTheme.warningColor,
          ),
          title: tr.pendingPayments,
          content: [
            Text(
              tr.reviewPendingSettlements,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            AppDialogNotice(
              color: AppTheme.warningColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDialogAmountRow(
                    tr.totalPending,
                    '₹${totalPending.toStringAsFixed(2)}',
                    color: AppTheme.warningColor,
                    isStrong: true,
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    color: AppTheme.warningColor.withValues(alpha: 0.18),
                    height: 1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr.settlementsToClose,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...pendingSettlements.map(
                    (settlement) =>
                        _buildPendingSettlementPreview(settlement, tr),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr.pendingSettlementsWillBeMarkedComplete(pendingCount),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              tr.settlingWillCloseThesePayments,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          actions: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(tr.cancel),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _performSettle();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.warningColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(tr.settleAnyway),
              ),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AppDialogShell(
        icon: const AppDialogIcon(
          icon: Icons.check_circle_rounded,
          color: AppTheme.successColor,
        ),
        title: tr.settleSplit,
        content: [
          Text(
            tr.allSettlementsAlreadyComplete,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        actions: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr.cancel),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _performSettle();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
              ),
              child: Text(tr.markAsSettled),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performSettle() async {
    final tr = AppLocalizations.of(context)!;
    await context.read<SplitCubit>().settleSplit(_split!.id!);
    if (mounted) {
      showSuccessSnackbar(context, tr.splitMarkedAsSettled);
      await _loadSplit();
    }
  }

  Future<void> _shareSplitInvoice() async {
    final split = _split;
    if (split == null) return;

    final tr = AppLocalizations.of(context)!;
    var loadingShown = false;

    try {
      final ownerName = await ensureShareOwnerName(context);
      if (ownerName == null) return;
      if (!mounted) return;

      loadingShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AppLoadingDialog(message: 'Preparing invoice...'),
      );

      final file = await _createSplitInvoiceImage(split, ownerName);

      if (mounted && loadingShown) {
        Navigator.pop(context);
        loadingShown = false;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Split invoice from $ownerName: ${split.title}',
          subject: 'Split Invoice - ${split.title}',
        ),
      );
    } catch (e) {
      if (mounted && loadingShown) {
        Navigator.pop(context);
      }
      if (mounted) {
        showFailureSnackbar(context, '${tr.shareFailed} $e');
      }
    }
  }

  Future<File> _createSplitInvoiceImage(
    SplitExpenseModel split,
    String ownerName,
  ) async {
    final tr = AppLocalizations.of(context)!;
    final participants = split.participants ?? [];
    final settlements = SplitSettlementCalculator.calculate(
      split,
      participants,
      userName: ownerName,
      unknownName: tr.unknown,
    );
    final userShare = SplitSettlementCalculator.userShare(split, participants);
    final balance = SplitSettlementCalculator.userBalance(split, participants);
    final isSettled = split.status == AppConstants.statusSettled;
    final routeSteps = _buildRouteSteps(
      split,
      participants,
      tr,
      ignoreSettledPayments: isSettled,
      userName: ownerName,
    );
    final width = 1080.0;
    final rowHeight = 58.0;
    final routeTableHeight = routeSteps.isEmpty
        ? 0.0
        : 42.0 + (routeSteps.length * 42.0);
    final routeHeight = routeSteps.isEmpty ? 0.0 : 82.0 + routeTableHeight;
    final descriptionHeight =
        split.description != null && split.description!.trim().isNotEmpty
        ? 54.0
        : 0.0;
    final height =
        740.0 +
        descriptionHeight +
        routeHeight +
        (participants.length * rowHeight);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width, height);
    const background = Color(0xFFF7F8F5);
    const paperColor = Color(0xFFFFFFFF);
    const textColor = Color(0xFF202124);
    const mutedColor = Color(0xFF68716A);
    const lineColor = Color(0xFFE3E7DF);
    const headerFill = Color(0xFFF0F6EA);
    const primaryColor = Color(0xFF78B83F);
    final receiveColor = AppTheme.moneyInColor;
    final giveColor = AppTheme.moneyOutColor;
    final balanceColor = balance >= 0 ? receiveColor : giveColor;

    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    const pagePadding = 58.0;
    final paperRect = Rect.fromLTWH(
      pagePadding,
      42,
      width - pagePadding * 2,
      height - 84,
    );
    _drawRoundedRect(
      canvas,
      paperRect,
      paperColor,
      radius: 28,
      strokeColor: lineColor,
    );

    var y = paperRect.top + 34;
    final left = paperRect.left + 34;
    final right = paperRect.right - 34;

    _drawText(
      canvas,
      'HisaabMate',
      Offset(left, y),
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: primaryColor,
    );
    _drawText(
      canvas,
      isSettled ? 'SETTLED' : 'PENDING',
      Offset(right - 150, y + 4),
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: isSettled ? receiveColor : AppTheme.warningColor,
      maxWidth: 150,
      textAlign: TextAlign.right,
    );
    y += 44;
    _drawText(
      canvas,
      'Split Invoice',
      Offset(left, y),
      fontSize: 46,
      fontWeight: FontWeight.w800,
      color: textColor,
    );
    _drawText(
      canvas,
      '#${split.id ?? DateTime.now().millisecondsSinceEpoch}',
      Offset(right - 220, y + 11),
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: mutedColor,
      maxWidth: 220,
      textAlign: TextAlign.right,
    );
    y += 70;
    _drawHorizontalLine(canvas, left, right, y, lineColor);

    y += 28;
    _drawText(
      canvas,
      split.title,
      Offset(left, y),
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: textColor,
      maxWidth: 480,
    );
    _drawInvoiceMeta(
      canvas,
      label: 'Date',
      value: DateFormat(AppConstants.dateTimeFormat).format(split.date),
      x: right - 320,
      y: y,
      width: 320,
      textColor: textColor,
      mutedColor: mutedColor,
    );
    y += 42;
    if (descriptionHeight > 0) {
      _drawText(
        canvas,
        split.description!.trim(),
        Offset(left, y),
        fontSize: 19,
        fontWeight: FontWeight.w500,
        color: mutedColor,
        maxWidth: 520,
      );
      y += descriptionHeight;
    }

    y += 20;
    final summaryTop = y;
    _drawRoundedRect(
      canvas,
      Rect.fromLTWH(left, summaryTop, right - left, 126),
      headerFill,
      radius: 18,
      strokeColor: lineColor,
    );
    final summaryWidth = (right - left) / 4;
    _drawInvoiceMetric(
      canvas,
      label: 'Total bill',
      value: _money(split.totalAmount),
      x: left + 22,
      y: summaryTop + 24,
      width: summaryWidth - 28,
      color: textColor,
      mutedColor: mutedColor,
    );
    _drawInvoiceMetric(
      canvas,
      label: '$ownerName paid',
      value: _money(split.paidByUser),
      x: left + summaryWidth + 12,
      y: summaryTop + 24,
      width: summaryWidth - 28,
      color: textColor,
      mutedColor: mutedColor,
    );
    _drawInvoiceMetric(
      canvas,
      label: '${_possessive(ownerName)} share',
      value: _money(userShare),
      x: left + summaryWidth * 2 + 12,
      y: summaryTop + 24,
      width: summaryWidth - 28,
      color: textColor,
      mutedColor: mutedColor,
    );
    _drawInvoiceMetric(
      canvas,
      label: balance.abs() < 0.01
          ? '${_possessive(ownerName)} balance'
          : balance >= 0
          ? '$ownerName gets'
          : '$ownerName gives',
      value: _money(balance.abs()),
      x: left + summaryWidth * 3 + 12,
      y: summaryTop + 24,
      width: summaryWidth - 28,
      color: balance.abs() < 0.01 ? textColor : balanceColor,
      mutedColor: mutedColor,
    );
    y += 158;

    if (routeSteps.isNotEmpty) {
      _drawInvoiceSectionTitle(canvas, 'Settlement Route', left, y, textColor);
      _drawText(
        canvas,
        split.settlementRouteMode == AppConstants.splitRouteMediator
            ? 'Routed through trusted person'
            : 'Optimized route',
        Offset(right - 300, y + 5),
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: mutedColor,
        maxWidth: 300,
        textAlign: TextAlign.right,
      );
      y += 42;
      _drawRouteInvoiceTable(
        canvas,
        Rect.fromLTWH(left, y, right - left, routeTableHeight),
        routeSteps,
        textColor,
        mutedColor,
        lineColor,
        headerFill,
        AppTheme.splitColor,
      );
      y += routeHeight;
    }

    _drawInvoiceSectionTitle(canvas, 'Participants', left, y, textColor);
    _drawText(
      canvas,
      '${participants.length} ${participants.length == 1 ? 'participant' : 'participants'}',
      Offset(right - 180, y + 5),
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: mutedColor,
      maxWidth: 180,
      textAlign: TextAlign.right,
    );
    y += 42;

    _drawParticipantInvoiceTableHeader(
      canvas,
      Rect.fromLTWH(left, y, right - left, 42),
      headerFill,
      lineColor,
      mutedColor,
    );
    y += 42;

    for (final participant in participants) {
      final settlement = settlements.firstWhere(
        (item) => item.participant.contactId == participant.contactId,
        orElse: () => SplitSettlementResult(
          participant: participant,
          affectsUser: false,
          participantOwes: false,
          userReceives: false,
          counterpartyName: '',
          totalAmount: 0,
          settledAmount: participant.paid,
          remainingAmount: 0,
        ),
      );
      final remaining = settlement.remainingAmount;
      final rowColor = remaining <= 0
          ? receiveColor
          : settlement.userReceives == false
          ? giveColor
          : receiveColor;
      _drawParticipantInvoiceTableRow(
        canvas,
        Rect.fromLTWH(left, y, right - left, rowHeight),
        participant,
        remaining,
        rowColor,
        textColor,
        mutedColor,
        lineColor,
        ownerName,
        settlement.userReceives,
      );
      y += rowHeight;
    }

    y = height - 120;
    _drawHorizontalLine(canvas, left, right, y, lineColor);
    _drawText(
      canvas,
      'Generated by $ownerName',
      Offset(left, y + 24),
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: mutedColor,
      maxWidth: 430,
    );
    _drawText(
      canvas,
      DateFormat(AppConstants.dateTimeFormat).format(DateTime.now()),
      Offset(right - 280, y + 24),
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: mutedColor,
      maxWidth: 280,
      textAlign: TextAlign.right,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final fileName =
        'split_invoice_${split.id ?? DateTime.now().millisecondsSinceEpoch}_${_safeFilePart(split.title)}.png';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _money(double amount) => '₹${amount.toStringAsFixed(2)}';

  String _possessive(String name) {
    return name.endsWith('s') ? "$name'" : "$name's";
  }

  String _safeFilePart(String value) {
    final safe = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return safe.isEmpty ? 'split' : safe;
  }

  void _drawHorizontalLine(
    Canvas canvas,
    double left,
    double right,
    double y,
    Color color,
  ) {
    canvas.drawLine(
      Offset(left, y),
      Offset(right, y),
      Paint()
        ..color = color
        ..strokeWidth = 1.5,
    );
  }

  void _drawVerticalLine(
    Canvas canvas,
    double x,
    double top,
    double bottom,
    Color color,
  ) {
    canvas.drawLine(
      Offset(x, top),
      Offset(x, bottom),
      Paint()
        ..color = color
        ..strokeWidth = 1.2,
    );
  }

  void _drawInvoiceMeta(
    Canvas canvas, {
    required String label,
    required String value,
    required double x,
    required double y,
    required double width,
    required Color textColor,
    required Color mutedColor,
  }) {
    _drawText(
      canvas,
      label,
      Offset(x, y),
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: mutedColor,
      maxWidth: width,
      textAlign: TextAlign.right,
    );
    _drawText(
      canvas,
      value,
      Offset(x, y + 24),
      fontSize: 19,
      fontWeight: FontWeight.w800,
      color: textColor,
      maxWidth: width,
      textAlign: TextAlign.right,
    );
  }

  void _drawInvoiceMetric(
    Canvas canvas, {
    required String label,
    required String value,
    required double x,
    required double y,
    required double width,
    required Color color,
    required Color mutedColor,
  }) {
    _drawText(
      canvas,
      label,
      Offset(x, y),
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: mutedColor,
      maxWidth: width,
    );
    _drawText(
      canvas,
      value,
      Offset(x, y + 38),
      fontSize: 31,
      fontWeight: FontWeight.w800,
      color: color,
      maxWidth: width,
    );
  }

  void _drawInvoiceSectionTitle(
    Canvas canvas,
    String title,
    double x,
    double y,
    Color color,
  ) {
    _drawText(
      canvas,
      title,
      Offset(x, y),
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }

  void _drawRouteInvoiceTable(
    Canvas canvas,
    Rect rect,
    List<_SettlementRouteStep> steps,
    Color textColor,
    Color mutedColor,
    Color lineColor,
    Color headerFill,
    Color accentColor,
  ) {
    _drawRoundedRect(
      canvas,
      rect,
      Colors.white,
      radius: 14,
      strokeColor: lineColor,
    );
    _drawRoundedRect(
      canvas,
      Rect.fromLTWH(rect.left, rect.top, rect.width, 38),
      headerFill,
      radius: 14,
    );
    _drawVerticalLine(
      canvas,
      rect.left + rect.width * 0.42,
      rect.top,
      rect.bottom,
      lineColor,
    );
    _drawVerticalLine(
      canvas,
      rect.left + rect.width * 0.76,
      rect.top,
      rect.bottom,
      lineColor,
    );
    _drawText(
      canvas,
      'From',
      Offset(rect.left + 18, rect.top + 10),
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: mutedColor,
    );
    _drawText(
      canvas,
      'To',
      Offset(rect.left + rect.width * 0.45, rect.top + 10),
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: mutedColor,
    );
    _drawText(
      canvas,
      'Amount',
      Offset(rect.right - 160, rect.top + 10),
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: mutedColor,
      maxWidth: 140,
      textAlign: TextAlign.right,
    );

    var y = rect.top + 42;
    for (final step in steps) {
      _drawHorizontalLine(canvas, rect.left, rect.right, y, lineColor);
      _drawText(
        canvas,
        step.fromName,
        Offset(rect.left + 18, y + 11),
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: textColor,
        maxWidth: rect.width * 0.36,
      );
      _drawText(
        canvas,
        step.toName,
        Offset(rect.left + rect.width * 0.45, y + 11),
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: textColor,
        maxWidth: rect.width * 0.32,
      );
      _drawText(
        canvas,
        _money(step.amount),
        Offset(rect.right - 170, y + 11),
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: accentColor,
        maxWidth: 150,
        textAlign: TextAlign.right,
      );
      y += 42;
    }
  }

  void _drawParticipantInvoiceTableHeader(
    Canvas canvas,
    Rect rect,
    Color fill,
    Color lineColor,
    Color mutedColor,
  ) {
    _drawRoundedRect(canvas, rect, fill, radius: 12, strokeColor: lineColor);
    _drawParticipantTableVerticals(canvas, rect, lineColor);
    _drawParticipantTableText(
      canvas,
      rect,
      'Person',
      0.02,
      0.28,
      mutedColor,
      isHeader: true,
    );
    _drawParticipantTableText(
      canvas,
      rect,
      'Share',
      0.33,
      0.13,
      mutedColor,
      isHeader: true,
      alignRight: true,
    );
    _drawParticipantTableText(
      canvas,
      rect,
      'Paid',
      0.49,
      0.13,
      mutedColor,
      isHeader: true,
      alignRight: true,
    );
    _drawParticipantTableText(
      canvas,
      rect,
      'Settled',
      0.65,
      0.13,
      mutedColor,
      isHeader: true,
      alignRight: true,
    );
    _drawParticipantTableText(
      canvas,
      rect,
      'Balance',
      0.81,
      0.17,
      mutedColor,
      isHeader: true,
      alignRight: true,
    );
  }

  void _drawParticipantInvoiceTableRow(
    Canvas canvas,
    Rect rect,
    SplitParticipantModel participant,
    double remaining,
    Color rowColor,
    Color textColor,
    Color mutedColor,
    Color lineColor,
    String ownerName,
    bool? userReceives,
  ) {
    _drawParticipantTableVerticals(canvas, rect, lineColor);
    _drawHorizontalLine(canvas, rect.left, rect.right, rect.bottom, lineColor);
    final balanceText = remaining <= 0
        ? 'Settled'
        : userReceives == false
        ? '$ownerName pays'
        : 'Pays $ownerName';

    _drawParticipantTableText(
      canvas,
      rect,
      participant.contactName ?? 'Unknown',
      0.02,
      0.28,
      textColor,
      isHeader: true,
    );
    _drawParticipantTableText(
      canvas,
      rect,
      _money(participant.shareAmount),
      0.33,
      0.13,
      textColor,
      alignRight: true,
    );
    _drawParticipantTableText(
      canvas,
      rect,
      _money(participant.expensePaid),
      0.49,
      0.13,
      textColor,
      alignRight: true,
    );
    _drawParticipantTableText(
      canvas,
      rect,
      _money(participant.paid),
      0.65,
      0.13,
      mutedColor,
      alignRight: true,
    );
    _drawParticipantTableText(
      canvas,
      rect,
      remaining <= 0 ? balanceText : '$balanceText ${_money(remaining)}',
      0.81,
      0.17,
      rowColor,
      isHeader: true,
      alignRight: true,
      fontSize: remaining <= 0 ? 17 : 15,
    );
  }

  void _drawParticipantTableVerticals(Canvas canvas, Rect rect, Color color) {
    for (final factor in [0.31, 0.47, 0.63, 0.79]) {
      _drawVerticalLine(
        canvas,
        rect.left + rect.width * factor,
        rect.top,
        rect.bottom,
        color,
      );
    }
  }

  void _drawParticipantTableText(
    Canvas canvas,
    Rect rect,
    String text,
    double leftFactor,
    double widthFactor,
    Color color, {
    bool isHeader = false,
    bool alignRight = false,
    double fontSize = 16,
  }) {
    final columnLeft = rect.left + rect.width * leftFactor;
    final columnWidth = rect.width * widthFactor;
    _drawText(
      canvas,
      text,
      Offset(columnLeft, rect.top + (rect.height - fontSize * 1.2) / 2),
      fontSize: fontSize,
      fontWeight: isHeader ? FontWeight.w800 : FontWeight.w700,
      color: color,
      maxWidth: columnWidth,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
    );
  }

  void _drawRoundedRect(
    Canvas canvas,
    Rect rect,
    Color color, {
    double radius = 18,
    Color? strokeColor,
  }) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = color);
    if (strokeColor != null) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? maxWidth,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: 1.15,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
      textAlign: textAlign,
    )..layout(maxWidth: maxWidth ?? double.infinity);
    painter.paint(canvas, offset);
  }

  void _showDeleteConfirmation() {
    final tr = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => DeleteSplitExpenseDialog(
        onConfirm: () async {
          await context.read<SplitCubit>().deleteSplit(_split!.id!);
          if (context.mounted) {
            showSuccessSnackbar(context, tr.splitExpenseDeleted);
            Navigator.pop(context, true);
          }
        },
      ),
    );
  }
}
