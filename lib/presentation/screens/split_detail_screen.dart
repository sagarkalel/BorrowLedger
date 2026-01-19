import 'package:borrow_ledger/core/constants/app_text_styles.dart';
import 'package:borrow_ledger/data/models/split_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
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
    final tr = AppLocalizations.of(context)!;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr.failedToLoad}: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

    // FIXED: Categorize participants correctly - no duplicates
    final fullyPendingParticipants = participants
        .where((p) => p.paid == 0) // Only those who haven't paid anything
        .toList();

    final partiallyPaidParticipants = participants
        .where((p) => p.paid > 0 && !_isFullyPaid(p.paid, p.shareAmount))
        .toList();

    final paidParticipants = participants
        .where((p) => _isFullyPaid(p.paid, p.shareAmount))
        .toList();

    final totalPendingCount =
        fullyPendingParticipants.length + partiallyPaidParticipants.length;
    final canSettle = !isSettled;

    return Scaffold(
      appBar: AppBar(title: Text(tr.splitDetails), elevation: 0),
      body: RefreshIndicator(
        onRefresh: _loadSplit,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
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
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSettled ? tr.settledBadge : tr.pendingBadge,
                            style: AppTextStyles.captionBold.copyWith(
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(split.title, style: AppTextStyles.heading2),
                    const SizedBox(height: 8),

                    // Date and time
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMMM yyyy').format(split.date),
                          style: AppTextStyles.body2.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('hh:mm a').format(split.date),
                          style: AppTextStyles.body2.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    if (split.description != null &&
                        split.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        split.description!,
                        style: AppTextStyles.body2.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Merged amount and balance card
                    _buildMergedFinancialCard(split, participants, isDark),

                    const SizedBox(height: 16),

                    // Improved settlement breakdown card
                    _buildSettlementBreakdownCard(split, participants, isDark),

                    const SizedBox(height: 24),

                    // Participants section header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              tr.participants,
                              style: AppTextStyles.heading4,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${participants.length}',
                                style: AppTextStyles.captionBold.copyWith(
                                  color: Colors.deepPurple.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (totalPendingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$totalPendingCount ${tr.pending}',
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppTheme.warning,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // FIXED: Not Paid Yet section (only ₹0 paid)
            if (fullyPendingParticipants.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    tr.notPaidYet,
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final participant = fullyPendingParticipants[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildParticipantCard(
                        participant,
                        isDark,
                        onMarkPaid: () => _showMarkReceivedDialog(participant),
                      ),
                    );
                  }, childCount: fullyPendingParticipants.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],

            // Partially paid participants
            if (partiallyPaidParticipants.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    tr.partialSettlement,
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final participant = partiallyPaidParticipants[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildParticipantCard(
                        participant,
                        isDark,
                        onMarkPaid: () => _showMarkReceivedDialog(participant),
                      ),
                    );
                  }, childCount: partiallyPaidParticipants.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],

            // Paid participants
            if (paidParticipants.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    tr.paid,
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final participant = paidParticipants[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildParticipantCard(participant, isDark),
                    );
                  }, childCount: paidParticipants.length),
                ),
              ),
            ],

            // Action buttons at bottom
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Settle button (if not settled)
                    if (canSettle) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showSettleConfirmation,
                          icon: const Icon(Icons.check_circle_rounded),
                          label: Text(tr.markAsSettled),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Delete button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showDeleteConfirmation,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(tr.deleteSplitExpense),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: BorderSide(color: AppTheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  // Merged financial card combining total amount and balance
  Widget _buildMergedFinancialCard(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants,
    bool isDark,
  ) {
    final userShare = _calculateUserShare(split, participants);
    final balance = _calculateBalance(split, participants);
    final isPositive = balance > 0;
    final isSettled = split.status == AppConstants.statusSettled;
    final tr = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color.fromARGB(255, 43, 46, 49),
                  const Color.fromARGB(255, 47, 57, 72),
                  const Color.fromARGB(255, 54, 59, 66),
                ]
              : [Colors.white, const Color(0xFFF8FAFC), Colors.white],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative background pattern
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isPositive ? Colors.green : Colors.orange).withValues(
                        alpha: 0.05,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -50,
              bottom: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.purple.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Total amount section
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.purple.shade600,
                          Colors.purple.shade400,
                          Colors.deepPurple.shade500,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr.totalAmount,
                                style: AppTextStyles.body3.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${split.totalAmount.toStringAsFixed(2)}',
                                style: AppTextStyles.amountLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Your share and payment info
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoTile(
                          icon: Icons.person_rounded,
                          label: tr.yourShare,
                          value: '₹${userShare.toStringAsFixed(2)}',
                          color: Colors.blue.shade300,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoTile(
                          icon: Icons.payments_rounded,
                          label: tr.youPaid,
                          value: '₹${split.paidByUser.toStringAsFixed(2)}',
                          color: Colors.purple.shade300,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  // Balance section (only if not settled)
                  if (!isSettled) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isPositive
                              ? [Colors.green.shade50, Colors.green.shade100]
                              : [Colors.orange.shade50, Colors.orange.shade100],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isPositive ? Colors.green : Colors.orange)
                              .withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isPositive ? Colors.green : Colors.orange)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPositive
                                  ? Icons.call_received
                                  : Icons.call_made,
                              color: isPositive
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPositive ? tr.youWillGet : tr.youWillGive,
                                  style: AppTextStyles.body3.copyWith(
                                    color: (isPositive
                                        ? Colors.green.shade800
                                        : Colors.orange.shade900),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${balance.abs().toStringAsFixed(2)}',
                                  style: AppTextStyles.amountMedium.copyWith(
                                    fontSize: 26,
                                    color: isPositive
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isPositive
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: isPositive
                                ? Colors.green.shade600
                                : Colors.orange.shade600,
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Improved settlement breakdown card
  Widget _buildSettlementBreakdownCard(
    SplitExpenseModel split,
    List<SplitParticipantModel> participants,
    bool isDark,
  ) {
    // Calculate total received and expected
    final totalReceived = participants.fold<double>(
      0,
      (sum, p) => sum + p.paid,
    );
    final totalExpected = participants.fold<double>(
      0,
      (sum, p) => sum + p.shareAmount,
    );
    final totalPending = totalExpected - totalReceived;
    final tr = AppLocalizations.of(context)!;

    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.hourglass_bottom_rounded,
                    size: 18,
                    color: totalPending == 0 ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr.collectionProgress,
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (totalPending == 0 ? Colors.green : Colors.orange)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${((totalReceived / totalExpected) * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.captionBold.copyWith(
                    color: totalPending == 0 ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₹${totalReceived.toStringAsFixed(2)} of ₹${totalExpected.toStringAsFixed(2)} collected',
            style: AppTextStyles.body3.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: totalExpected > 0 ? totalReceived / totalExpected : 0,
              minHeight: 10,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                totalPending == 0 ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color.fromARGB(255, 58, 59, 60) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color.fromARGB(255, 71, 76, 82),
                        const Color.fromARGB(255, 66, 72, 81),
                      ]
                    : [Colors.blue.shade100, Colors.blue.shade50],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade400, width: 1.5),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.blue.shade400,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    tr.paymentBreakdown,
                    style: AppTextStyles.heading4.copyWith(
                      color: isDark ? Colors.white : Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Only show collection progress if balance is positive
                if (participants.isNotEmpty) ...[
                  // Progress indicator
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.trending_up_rounded,
                                  size: 18,
                                  color: totalPending == 0
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tr.collectionProgress,
                                  style: AppTextStyles.body2.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (totalPending == 0
                                            ? Colors.green
                                            : Colors.orange)
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${((totalReceived / totalExpected) * 100).toStringAsFixed(0)}%',
                                style: AppTextStyles.captionBold.copyWith(
                                  color: totalPending == 0
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '₹${totalReceived.toStringAsFixed(2)} of ₹${totalExpected.toStringAsFixed(2)} collected',
                          style: AppTextStyles.body3.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: totalExpected > 0
                                ? totalReceived / totalExpected
                                : 0,
                            minHeight: 10,
                            backgroundColor: isDark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              totalPending == 0 ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // "Who Needs to Pay You" section
                  Row(
                    children: [
                      Icon(
                        Icons.group_rounded,
                        size: 18,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr.whoNeedsToPayYou,
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // List each participant
                  ...participants.asMap().entries.map((entry) {
                    final index = entry.key;
                    final participant = entry.value;
                    final remaining =
                        participant.shareAmount - participant.paid;
                    final isPaid = _isFullyPaid(
                      participant.paid,
                      participant.shareAmount,
                    );

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < participants.length - 1 ? 10 : 0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPaid
                                ? Colors.green.withValues(alpha: 0.3)
                                : (isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[200]!),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors
                                  .primaries[(participant
                                              .contactName
                                              ?.hashCode ??
                                          0) %
                                      Colors.primaries.length]
                                  .withValues(alpha: 0.15),
                              child: Text(
                                participant.contactName?.isNotEmpty == true
                                    ? participant.contactName![0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      Colors.primaries[(participant
                                                  .contactName
                                                  ?.hashCode ??
                                              0) %
                                          Colors.primaries.length],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Name
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    participant.contactName ?? tr.unknown,
                                    style: AppTextStyles.body2.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  if (participant.paid > 0 && !isPaid) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tr.paid} ₹${participant.paid.toStringAsFixed(2)}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.green.shade300,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Amount or status
                            if (isPaid)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      tr.paid,
                                      style: AppTextStyles.captionBold.copyWith(
                                        color: Colors.green.shade700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '₹${remaining.toStringAsFixed(2)}',
                                  style: AppTextStyles.body2.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPaid
              ? AppTheme.success.withValues(alpha: 0.3)
              : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
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
                fontSize: 18,
                color:
                    Colors.primaries[(participant.contactName?.hashCode ?? 0) %
                        Colors.primaries.length],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.contactName ?? tr.unknown,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${tr.share}: ₹${participant.shareAmount.toStringAsFixed(2)}',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    if (participant.paid > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${tr.paid}: ₹${participant.paid.toStringAsFixed(2)}',
                        style: AppTextStyles.caption.copyWith(
                          color: isPartiallyPaid
                              ? AppTheme.warning
                              : AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isPaid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tr.paidBadge,
                    style: AppTextStyles.captionBold.copyWith(
                      fontSize: 10,
                      color: AppTheme.success,
                      letterSpacing: 0.5,
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
                  style: AppTextStyles.amountSmall.copyWith(
                    fontSize: 17,
                    color: isPartiallyPaid ? AppTheme.warning : Colors.orange,
                  ),
                ),
                if (remaining != 0.0) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onMarkPaid,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      // decoration: BoxDecoration(
                      //   color: AppTheme.success.withValues(alpha:0.1),
                      //   borderRadius: BorderRadius.circular(8),
                      //   border: Border.all(
                      //     color: AppTheme.success.withValues(alpha:0.3),
                      //     width: 1,
                      //   ),
                      // ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.done_all_rounded,
                            size: 13,
                            color: Colors.green.shade400,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            isPartiallyPaid ? tr.addMore : tr.markReceived,
                            style: AppTextStyles.captionBold.copyWith(
                              fontSize: 11,
                              color: Colors.green,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: Colors.green,
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

  // UPDATED: Settle confirmation with validation
  void _showSettleConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final participants = _split?.participants ?? [];

    // Check if all participants have paid
    final allPaid = participants.every(
      (p) => _isFullyPaid(p.paid, p.shareAmount),
    );

    // Calculate pending participants
    final pendingCount = participants
        .where((p) => !_isFullyPaid(p.paid, p.shareAmount))
        .length;

    final totalPending = participants.fold<double>(
      0,
      (sum, p) => sum + (p.shareAmount - p.paid),
    );
    final tr = AppLocalizations.of(context)!;

    // If not all paid, show warning dialog
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

    // If all paid, show normal confirmation
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

  // Extracted settle logic
  Future<void> _performSettle() async {
    final tr = AppLocalizations.of(context)!;
    final updatedSplit = _split!.copyWith(status: AppConstants.statusSettled);
    await context.read<SplitCubit>().updateSplit(updatedSplit);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr.splitMarkedAsSettled),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadSplit();
    }
  }

  void _showDeleteConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          tr.deleteSplitExpense,
          style: AppTextStyles.heading4.copyWith(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          tr.deleteSplitConfirmMessage,
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
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SplitCubit>().deleteSplit(_split!.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr.splitExpenseDeleted),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              tr.delete,
              style: AppTextStyles.button.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
