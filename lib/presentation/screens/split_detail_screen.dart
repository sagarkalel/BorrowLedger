import 'dart:io';
import 'dart:ui' as ui;

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/core/constants/app_text_styles.dart';
import 'package:borrow_ledger/core/utils/split_settlement_calculator.dart';
import 'package:borrow_ledger/data/models/split_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/app_dialog_components.dart';
import 'package:borrow_ledger/presentation/widgets/app_list_avatar.dart';
import 'package:borrow_ledger/presentation/widgets/app_pill_badge.dart';
import 'package:borrow_ledger/presentation/widgets/custom_text_field.dart';
import 'package:borrow_ledger/presentation/widgets/delete_split_expense_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/split_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../cubit/split_cubit.dart';

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
        body: const Center(child: CircularProgressIndicator()),
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

            // Bottom action button
            if (!isSettled)
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
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
      final profile = await context.read<UserProfileRepository>().getProfile();
      final ownerName = _profileDisplayName(profile.name);
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
    final participants = split.participants ?? [];
    final settlements = SplitSettlementCalculator.calculate(
      split,
      participants,
      userName: ownerName,
    );
    final userShare = SplitSettlementCalculator.userShare(split, participants);
    final balance = SplitSettlementCalculator.userBalance(split, participants);
    final paidByOthers = participants.fold<double>(
      0,
      (sum, participant) => sum + participant.expensePaid,
    );
    final totalPaid = split.paidByUser + paidByOthers;
    final isSettled = split.status == AppConstants.statusSettled;
    final width = 1080.0;
    final rowHeight = 86.0;
    final descriptionHeight =
        split.description != null && split.description!.trim().isNotEmpty
        ? 72.0
        : 0.0;
    final height =
        820.0 + descriptionHeight + (participants.length * rowHeight);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width, height);
    final colorScheme = Theme.of(context).colorScheme;
    final background = colorScheme.surface;
    final textColor = colorScheme.onSurface;
    final mutedColor = colorScheme.onSurfaceVariant;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final receiveColor = AppTheme.moneyInColor;
    final giveColor = AppTheme.moneyOutColor;
    final balanceColor = balance >= 0 ? receiveColor : giveColor;

    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final pagePadding = 58.0;
    var y = 52.0;

    _drawRoundedRect(
      canvas,
      Rect.fromLTWH(pagePadding, y, width - pagePadding * 2, 118),
      primaryColor.withValues(alpha: 0.12),
      radius: 28,
      strokeColor: primaryColor.withValues(alpha: 0.22),
    );
    _drawText(
      canvas,
      'BorrowLedger',
      Offset(pagePadding + 34, y + 24),
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: primaryColor,
    );
    _drawText(
      canvas,
      'Split Invoice',
      Offset(pagePadding + 34, y + 62),
      fontSize: 42,
      fontWeight: FontWeight.w800,
      color: textColor,
    );
    _drawPill(
      canvas,
      isSettled ? 'SETTLED' : 'PENDING',
      Offset(width - pagePadding - 214, y + 38),
      isSettled ? AppTheme.successColor : AppTheme.warningColor,
      width: 180,
      height: 42,
    );

    y += 154;
    _drawText(
      canvas,
      split.title,
      Offset(pagePadding, y),
      fontSize: 38,
      fontWeight: FontWeight.w800,
      color: textColor,
      maxWidth: width - pagePadding * 2,
    );
    y += 54;
    _drawText(
      canvas,
      DateFormat(AppConstants.dateTimeFormat).format(split.date),
      Offset(pagePadding, y),
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: mutedColor,
    );

    if (descriptionHeight > 0) {
      y += 44;
      _drawRoundedRect(
        canvas,
        Rect.fromLTWH(pagePadding, y, width - pagePadding * 2, 56),
        mutedColor.withValues(alpha: 0.07),
        radius: 16,
      );
      _drawText(
        canvas,
        split.description!.trim(),
        Offset(pagePadding + 20, y + 15),
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: mutedColor,
        maxWidth: width - pagePadding * 2 - 40,
      );
      y += 72;
    }

    y += 34;
    final summaryCardWidth = (width - pagePadding * 2 - 24) / 2;
    _drawMetricCard(
      canvas,
      Rect.fromLTWH(pagePadding, y, summaryCardWidth, 126),
      label: 'Total bill',
      value: _money(split.totalAmount),
      color: primaryColor,
      textColor: textColor,
      mutedColor: mutedColor,
    );
    _drawMetricCard(
      canvas,
      Rect.fromLTWH(
        pagePadding + summaryCardWidth + 24,
        y,
        summaryCardWidth,
        126,
      ),
      label: balance.abs() < 0.01
          ? '${_possessive(ownerName)} balance'
          : balance >= 0
          ? '$ownerName gets'
          : '$ownerName gives',
      value: _money(balance.abs()),
      color: balance.abs() < 0.01 ? mutedColor : balanceColor,
      textColor: textColor,
      mutedColor: mutedColor,
    );

    y += 150;
    final miniCardWidth = (width - pagePadding * 2 - 32) / 3;
    _drawMetricCard(
      canvas,
      Rect.fromLTWH(pagePadding, y, miniCardWidth, 104),
      label: '$ownerName paid',
      value: _money(split.paidByUser),
      color: primaryColor,
      textColor: textColor,
      mutedColor: mutedColor,
      compact: true,
    );
    _drawMetricCard(
      canvas,
      Rect.fromLTWH(pagePadding + miniCardWidth + 16, y, miniCardWidth, 104),
      label: '${_possessive(ownerName)} share',
      value: _money(userShare),
      color: colorScheme.secondary,
      textColor: textColor,
      mutedColor: mutedColor,
      compact: true,
    );
    _drawMetricCard(
      canvas,
      Rect.fromLTWH(
        pagePadding + (miniCardWidth + 16) * 2,
        y,
        miniCardWidth,
        104,
      ),
      label: 'Paid total',
      value: _money(totalPaid),
      color: totalPaid >= split.totalAmount
          ? AppTheme.successColor
          : AppTheme.warningColor,
      textColor: textColor,
      mutedColor: mutedColor,
      compact: true,
    );

    y += 144;
    _drawText(
      canvas,
      'Participants',
      Offset(pagePadding, y),
      fontSize: 30,
      fontWeight: FontWeight.w800,
      color: textColor,
    );
    _drawText(
      canvas,
      '${participants.length} people',
      Offset(width - pagePadding - 138, y + 6),
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: mutedColor,
    );
    y += 50;

    _drawRoundedRect(
      canvas,
      Rect.fromLTWH(pagePadding, y, width - pagePadding * 2, 46),
      mutedColor.withValues(alpha: 0.08),
      radius: 14,
    );
    _drawTableHeader(
      canvas,
      Offset(pagePadding, y),
      width - pagePadding * 2,
      mutedColor,
    );
    y += 58;

    for (var i = 0; i < participants.length; i++) {
      final participant = participants[i];
      final settlement = i < settlements.length ? settlements[i] : null;
      final remaining = settlement?.remainingAmount ?? 0;
      final rowColor = remaining <= 0
          ? AppTheme.successColor
          : settlement?.userReceives == false
          ? giveColor
          : receiveColor;
      _drawParticipantInvoiceRow(
        canvas,
        Rect.fromLTWH(pagePadding, y, width - pagePadding * 2, rowHeight - 12),
        participant,
        remaining,
        rowColor,
        textColor,
        mutedColor,
        ownerName,
        settlement?.userReceives,
      );
      y += rowHeight;
    }

    _drawText(
      canvas,
      'Generated by $ownerName • ${DateFormat(AppConstants.dateTimeFormat).format(DateTime.now())}',
      Offset(pagePadding, height - 52),
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: mutedColor,
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

  String _profileDisplayName(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'You' : trimmed;
  }

  String _possessive(String name) {
    if (name == 'You') return 'Your';
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

  void _drawPill(
    Canvas canvas,
    String label,
    Offset offset,
    Color color, {
    required double width,
    required double height,
  }) {
    _drawRoundedRect(
      canvas,
      Rect.fromLTWH(offset.dx, offset.dy, width, height),
      color.withValues(alpha: 0.12),
      radius: height / 2,
      strokeColor: color.withValues(alpha: 0.22),
    );
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: width);
    painter.paint(
      canvas,
      Offset(
        offset.dx + (width - painter.width) / 2,
        offset.dy + (height - painter.height) / 2,
      ),
    );
  }

  void _drawMetricCard(
    Canvas canvas,
    Rect rect, {
    required String label,
    required String value,
    required Color color,
    required Color textColor,
    required Color mutedColor,
    bool compact = false,
  }) {
    _drawRoundedRect(
      canvas,
      rect,
      color.withValues(alpha: 0.08),
      radius: 22,
      strokeColor: color.withValues(alpha: 0.14),
    );
    _drawText(
      canvas,
      label,
      Offset(rect.left + 22, rect.top + (compact ? 18 : 24)),
      fontSize: compact ? 19 : 22,
      fontWeight: FontWeight.w700,
      color: mutedColor,
      maxWidth: rect.width - 44,
    );
    _drawText(
      canvas,
      value,
      Offset(rect.left + 22, rect.top + (compact ? 50 : 62)),
      fontSize: compact ? 30 : 38,
      fontWeight: FontWeight.w800,
      color: textColor,
      maxWidth: rect.width - 44,
    );
  }

  void _drawTableHeader(
    Canvas canvas,
    Offset offset,
    double width,
    Color mutedColor,
  ) {
    _drawText(
      canvas,
      'Person',
      Offset(offset.dx + 18, offset.dy + 13),
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: mutedColor,
    );
    _drawText(
      canvas,
      'Share',
      Offset(offset.dx + width * 0.45, offset.dy + 13),
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: mutedColor,
    );
    _drawText(
      canvas,
      'Paid',
      Offset(offset.dx + width * 0.62, offset.dy + 13),
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: mutedColor,
    );
    _drawText(
      canvas,
      'Balance',
      Offset(offset.dx + width * 0.79, offset.dy + 13),
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: mutedColor,
    );
  }

  void _drawParticipantInvoiceRow(
    Canvas canvas,
    Rect rect,
    SplitParticipantModel participant,
    double remaining,
    Color rowColor,
    Color textColor,
    Color mutedColor,
    String ownerName,
    bool? userReceives,
  ) {
    _drawRoundedRect(
      canvas,
      rect,
      mutedColor.withValues(alpha: 0.035),
      radius: 16,
      strokeColor: mutedColor.withValues(alpha: 0.08),
    );
    final balanceText = remaining <= 0
        ? 'Settled'
        : userReceives == false
        ? '$ownerName owes ${_money(remaining)}'
        : 'Owes $ownerName ${_money(remaining)}';
    final paidTotal = participant.expensePaid + participant.paid;
    _drawText(
      canvas,
      participant.contactName ?? 'Unknown',
      Offset(rect.left + 18, rect.top + 16),
      fontSize: 23,
      fontWeight: FontWeight.w800,
      color: textColor,
      maxWidth: rect.width * 0.38,
    );
    _drawText(
      canvas,
      'Settled ${_money(participant.paid)}',
      Offset(rect.left + 18, rect.top + 44),
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: mutedColor,
      maxWidth: rect.width * 0.38,
    );
    _drawText(
      canvas,
      _money(participant.shareAmount),
      Offset(rect.left + rect.width * 0.45, rect.top + 27),
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: textColor,
      maxWidth: rect.width * 0.15,
    );
    _drawText(
      canvas,
      _money(paidTotal),
      Offset(rect.left + rect.width * 0.62, rect.top + 27),
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: textColor,
      maxWidth: rect.width * 0.15,
    );
    _drawText(
      canvas,
      balanceText,
      Offset(rect.left + rect.width * 0.79, rect.top + 27),
      fontSize: remaining <= 0 ? 20 : 16,
      fontWeight: FontWeight.w800,
      color: rowColor,
      maxWidth: rect.width * 0.18,
    );
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
