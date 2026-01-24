import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/cubit/borrow_lend_cubit.dart';
import 'package:borrow_ledger/presentation/widgets/delete_transaction_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class ContactTransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onUpdate;

  const ContactTransactionDetailScreen({
    super.key,
    required this.transaction,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isLend = transaction.type == AppConstants.typeLend;
    final color = isLend ? AppTheme.borrowColor : AppTheme.lendColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categoryColor = AppTheme.getCategoryColor(
      transaction.category,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(tr.transactionDetails), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges row - Type, Category, Settlement
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Type badge
                _buildBadge(
                  icon: isLend ? Icons.call_made : Icons.call_received,
                  label: isLend ? tr.youGaveBadge : tr.youGotBadge,
                  color: color,
                  isDark: isDark,
                ),

                // Category badge
                _buildBadge(
                  icon: transaction.isCash
                      ? Icons.currency_rupee
                      : Icons.shopping_bag,
                  label: transaction.isCash ? tr.cashBadge : tr.udhariBadge,
                  color: categoryColor,
                  isDark: isDark,
                ),

                // Settlement badge
                if (transaction.isSettlement)
                  _buildBadge(
                    icon: Icons.done_all,
                    label: tr.settledBadge,
                    color: Colors.blue,
                    isDark: isDark,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Improved Amount card - More compact and modern
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: !isLend
                      ? [
                          AppTheme.successColor,
                          AppTheme.successColor.withValues(alpha: 0.85),
                        ]
                      : [
                          AppTheme.warningColor,
                          AppTheme.warningColor.withValues(alpha: 0.85),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      isLend ? Icons.call_made : Icons.call_received,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Amount and label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLend ? tr.youGave : tr.youGot,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '₹',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              transaction.amount.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Trending indicator
                  Icon(
                    isLend
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 28,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details section
            Text(
              tr.transactionDetails,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Details cards
            _buildDetailCard(
              context,
              icon: Icons.person_outline_rounded,
              label: tr.contact,
              value: transaction.contactName ?? tr.unknown,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            // Udhari-specific fields
            if (transaction.isUdhari && transaction.itemName != null) ...[
              _buildDetailCard(
                context,
                icon: Icons.shopping_bag_rounded,
                label: tr.itemService,
                value: transaction.itemName!,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
            ],

            if (transaction.isUdhari && transaction.quantity != null) ...[
              _buildDetailCard(
                context,
                icon: Icons.format_list_numbered_rounded,
                label: tr.quantity,
                value: transaction.quantity!,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
            ],

            // Expected date (for all transactions)
            if (transaction.expectedDate != null) ...[
              _buildDetailCard(
                context,
                icon: Icons.event_outlined,
                label: tr.expectedReturn,
                value: DateFormat(
                  'dd MMMM yyyy',
                ).format(transaction.expectedDate!),
                isDark: isDark,
                valueColor: transaction.isOverdue ? AppTheme.errorColor : null,
              ),
              const SizedBox(height: 12),
            ],

            // Show overdue indicator
            if (transaction.isOverdue) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50.withValues(alpha: isDark ? 0.1 : 1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.shade200.withValues(
                      alpha: isDark ? 0.3 : 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr.paymentOverdue,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.red.shade300
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Date card
            _buildDetailCard(
              context,
              icon: Icons.calendar_today_rounded,
              label: tr.date,
              value: DateFormat(
                AppConstants.dateFormat2,
              ).format(transaction.date),
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            _buildDetailCard(
              context,
              icon: Icons.access_time_rounded,
              label: tr.time,
              value: DateFormat('hh:mm a').format(transaction.date),
              isDark: isDark,
            ),

            if (transaction.description != null &&
                transaction.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailCard(
                context,
                icon: Icons.notes_rounded,
                label: tr.description,
                value: transaction.description!,
                isDark: isDark,
              ),
            ],

            const SizedBox(height: 32),

            // Delete button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteConfirmation(context),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: Text(tr.deleteTransaction),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: BorderSide(color: AppTheme.errorColor, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        valueColor ??
                        (isDark ? Colors.white : Colors.grey[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => DeleteTransactionDialog(
        onConfirm: () async {
          // Delete transaction
          await context.read<BorrowLendCubit>().deleteTransaction(
            transaction.id!,
            transaction.contactId,
          );

          // Show success message
          if (context.mounted) {
            showSuccessSnackbar(context, tr.transactionDeleted);
            // Call update callback
            if (onUpdate != null) onUpdate!();

            // Navigate back
            Navigator.pop(context, true);
          }
        },
      ),
    );
  }
}
