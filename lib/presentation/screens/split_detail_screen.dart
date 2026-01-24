import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/core/constants/app_text_styles.dart';
import 'package:borrow_ledger/data/models/split_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/delete_split_expense_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/split_repository.dart';
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

  // Helper method to check if amount is fully paid (with precision tolerance)
  bool _isFullyPaid(double paid, double shareAmount) {
    const tolerance = 0.01; // 1 cent tolerance for floating point
    return (paid - shareAmount).abs() < tolerance || paid >= shareAmount;
  }

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

    // Categorize participants correctly
    final fullyPendingParticipants = participants
        .where((p) => p.paid == 0)
        .toList();

    final partiallyPaidParticipants = participants
        .where((p) => p.paid > 0 && !_isFullyPaid(p.paid, p.shareAmount))
        .toList();

    final paidParticipants = participants
        .where((p) => _isFullyPaid(p.paid, p.shareAmount))
        .toList();

    final totalPendingCount =
        fullyPendingParticipants.length + partiallyPaidParticipants.length;

    return Scaffold(
      appBar: AppBar(title: Text(tr.splitDetails), elevation: 0),
      body: RefreshIndicator(
        onRefresh: _loadSplit,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Title, Status, Date in one compact card
                    _buildHeaderCard(split, statusColor, isSettled, isDark),
                    const SizedBox(height: 12),

                    // Financial summary card (compact version)
                    _buildFinancialSummaryCard(split, participants, isDark),
                    const SizedBox(height: 12),

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

            // Not Paid Yet section
            if (fullyPendingParticipants.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Text(
                    tr.notPaidYet,
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final participant = fullyPendingParticipants[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildCompactParticipantCard(
                        participant,
                        isDark,
                        onMarkPaid: () => _showMarkReceivedDialog(participant),
                      ),
                    );
                  }, childCount: fullyPendingParticipants.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],

            // Partially paid participants
            if (partiallyPaidParticipants.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Text(
                    tr.partialSettlement,
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final participant = partiallyPaidParticipants[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildCompactParticipantCard(
                        participant,
                        isDark,
                        onMarkPaid: () => _showMarkReceivedDialog(participant),
                      ),
                    );
                  }, childCount: partiallyPaidParticipants.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],

            // Paid participants
            if (paidParticipants.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Text(
                    tr.paid,
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final participant = paidParticipants[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildCompactParticipantCard(participant, isDark),
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
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _showSettleConfirmation,
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(tr.markAsSettled),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            // Delete button
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      split.title,
                      style: AppTextStyles.heading3.copyWith(fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(split.date),
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSettled ? Icons.check_circle : Icons.schedule,
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSettled ? tr.settledBadge : tr.pendingBadge,
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (split.description != null && split.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              split.description!,
              style: AppTextStyles.body3.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // Compact financial summary card
  Widget _buildFinancialSummaryCard(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants,
    bool isDark,
  ) {
    final userShare = _calculateUserShare(split, participants);
    final balance = _calculateBalance(split, participants);
    final isPositive = balance > 0;
    final isSettled = split.status == AppConstants.statusSettled;
    final tr = AppLocalizations.of(context)!;

    // Calculate collection progress
    final totalReceived = participants.fold<double>(
      0,
      (sum, p) => sum + p.paid,
    );
    final totalExpected = participants.fold<double>(
      0,
      (sum, p) => sum + p.shareAmount,
    );
    final progress = totalExpected > 0 ? totalReceived / totalExpected : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey[850]!, Colors.grey[900]!]
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Total amount row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade600, Colors.deepPurple.shade500],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.totalAmount,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${split.totalAmount.toStringAsFixed(2)}',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Details section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Your share and paid in one row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.person_rounded,
                        label: tr.yourShare,
                        value: '₹${userShare.toStringAsFixed(2)}',
                        color: Colors.blue,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.payments_rounded,
                        label: tr.youPaid,
                        value: '₹${split.paidByUser.toStringAsFixed(2)}',
                        color: Colors.purple,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                // Balance section (only if not settled)
                if (!isSettled) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isPositive ? Colors.green : Colors.orange)
                          .withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (isPositive ? Colors.green : Colors.orange)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPositive ? Icons.call_received : Icons.call_made,
                          color: isPositive
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPositive ? tr.youWillGet : tr.youWillGive,
                                style: AppTextStyles.caption.copyWith(
                                  color:
                                      (isPositive
                                              ? Colors.green
                                              : Colors.orange)
                                          .shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${balance.abs().toStringAsFixed(2)}',
                                style: AppTextStyles.body1.copyWith(
                                  fontSize: 18,
                                  color:
                                      (isPositive
                                              ? Colors.green
                                              : Colors.orange)
                                          .shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
                          color: isPositive
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ],

                // Collection progress
                if (participants.isNotEmpty && !isSettled) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.hourglass_bottom_rounded,
                        size: 14,
                        color: progress == 1.0 ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% ${tr.collectionProgress}',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${totalReceived.toStringAsFixed(0)}/₹${totalExpected.toStringAsFixed(0)}',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.2)),
      ),
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
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
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
              color: isDark ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  // Compact participants header
  Widget _buildParticipantsHeader(int total, int pending, bool isDark) {
    final tr = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              tr.participants,
              style: AppTextStyles.heading4.copyWith(fontSize: 15),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100.withValues(
                  alpha: isDark ? 0.2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$total',
                style: AppTextStyles.caption.copyWith(
                  color: isDark
                      ? Colors.deepPurple.shade200
                      : Colors.deepPurple.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        if (pending > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$pending ${tr.pending}',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.warning,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }

  // Compact participant card
  Widget _buildCompactParticipantCard(
    SplitParticipantModel participant,
    bool isDark, {
    VoidCallback? onMarkPaid,
  }) {
    final isPaid = participant.status == AppConstants.statusPaid;
    final isPartiallyPaid =
        participant.paid > 0 && participant.paid < participant.shareAmount;
    final remaining = participant.shareAmount - participant.paid;
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPaid
              ? AppTheme.success.withValues(alpha: 0.3)
              : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Compact avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors
                .primaries[(participant.contactName?.hashCode ?? 0) %
                    Colors.primaries.length]
                .withValues(alpha: 0.15),
            child: Text(
              participant.contactName?.isNotEmpty == true
                  ? participant.contactName![0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color:
                    Colors.primaries[(participant.contactName?.hashCode ?? 0) %
                        Colors.primaries.length],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name and info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.contactName ?? tr.unknown,
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  participant.paid > 0
                      ? 'Paid ₹${participant.paid.toStringAsFixed(2)} of ₹${participant.shareAmount.toStringAsFixed(2)}'
                      : '${tr.shareAmount}: ₹${participant.shareAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.caption.copyWith(
                    color: participant.paid > 0
                        ? (isPartiallyPaid
                              ? AppTheme.warning
                              : AppTheme.success)
                        : (isDark ? Colors.grey[500] : Colors.grey[600]),
                    fontSize: 11,
                    fontWeight: participant.paid > 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          // Status or action
          if (isPaid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 12, color: AppTheme.success),
                  const SizedBox(width: 3),
                  Text(
                    tr.paidBadge,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${remaining.toStringAsFixed(2)}',
                  style: AppTextStyles.body2.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isPartiallyPaid ? AppTheme.warning : Colors.orange,
                  ),
                ),
                if (remaining != 0.0) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: onMarkPaid,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.done_all, size: 11, color: Colors.green),
                          const SizedBox(width: 3),
                          Text(
                            isPartiallyPaid ? tr.addMore : tr.markReceived,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  double _calculateUserShare(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants,
  ) {
    final totalShares = participants.fold<double>(
      0,
      (sum, p) => sum + p.shareAmount,
    );
    return split.totalAmount - totalShares;
  }

  double _calculateBalance(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants,
  ) {
    final userShare = _calculateUserShare(split, participants);
    return split.paidByUser - userShare;
  }

  void _showMarkReceivedDialog(SplitParticipantModel participant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final remaining = participant.shareAmount - participant.paid;
    bool isFullAmount = true;
    final tr = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final color = Colors.green;

          return AlertDialog(
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.markAsReceived,
                        style: AppTextStyles.heading4.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        participant.contactName ?? '-',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount info card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.1 : 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr.shareAmount,
                              style: AppTextStyles.caption.copyWith(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              '₹${participant.shareAmount.toStringAsFixed(2)}',
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        if (participant.paid > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tr.alreadyPaid,
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              Text(
                                '₹${participant.paid.toStringAsFixed(2)}',
                                style: AppTextStyles.body2.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Divider(color: color.withValues(alpha: 0.3), height: 1),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr.remaining,
                              style: AppTextStyles.body2.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Text(
                              '₹${remaining.toStringAsFixed(2)}',
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount type selector
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[100],
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
                  const SizedBox(height: 16),

                  // Amount input (only for partial)
                  if (!isFullAmount) ...[
                    TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: tr.amountReceived,
                        prefixText: '₹ ',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.payments_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear_rounded),
                          onPressed: () {
                            amountController.clear();
                          },
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: color, width: 2),
                        ),
                      ),
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
                    const SizedBox(height: 12),

                    // Amount suggestions
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [0.25, 0.5, 0.75, 1.0].map((percent) {
                        final amount = remaining * percent;
                        final percentage = (percent * 100).toInt();
                        return InkWell(
                          onTap: () =>
                              amountController.text = amount.toStringAsFixed(2),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '$percentage% (₹${amount.toStringAsFixed(0)})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Info box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withValues(
                        alpha: isDark ? 0.1 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.blue.shade200.withValues(
                          alpha: isDark ? 0.3 : 1,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: isDark
                              ? Colors.blue.shade300
                              : Colors.blue.shade700,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isFullAmount
                                ? tr.fullRemainingAmountWillBeMarkedAsReceived
                                : tr.onlyEnteredAmountWillBeMarkedAsReceived,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.blue.shade300
                                  : Colors.blue.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  tr.cancel,
                  style: AppTextStyles.button.copyWith(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ),
              ElevatedButton.icon(
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
                icon: Icon(Icons.done_all_rounded, size: 18),
                label: Text(
                  isFullAmount ? tr.markFull : tr.markPartial,
                  style: AppTextStyles.button.copyWith(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );
        },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final participants = _split?.participants ?? [];

    final allPaid = participants.every(
      (p) => _isFullyPaid(p.paid, p.shareAmount),
    );

    final pendingCount = participants
        .where((p) => !_isFullyPaid(p.paid, p.shareAmount))
        .length;

    final totalPending = participants.fold<double>(
      0,
      (sum, p) => sum + (p.shareAmount - p.paid),
    );
    final tr = AppLocalizations.of(context)!;

    if (!allPaid) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr.pendingPayments,
                  style: AppTextStyles.heading4.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$pendingCount participant${pendingCount > 1 ? 's' : ''} haven\'t fully paid yet.',
                style: AppTextStyles.body2.copyWith(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.totalPending,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            '₹${totalPending.toStringAsFixed(2)}',
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tr.doYouWantToMarkSettled,
                style: AppTextStyles.body3.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                tr.cancel,
                style: AppTextStyles.button.copyWith(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performSettle();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                tr.settleAnyway,
                style: AppTextStyles.button.copyWith(fontSize: 14),
              ),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: AppTheme.successColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              tr.settleSplit,
              style: AppTextStyles.heading4.copyWith(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          tr.allParticipantHasPaidTheirShareMarkAsSetteled,
          style: AppTextStyles.body2.copyWith(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              tr.cancel,
              style: AppTextStyles.button.copyWith(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performSettle();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              tr.markAsSettled,
              style: AppTextStyles.button.copyWith(fontSize: 14),
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
