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
import '../../core/utils/currency_formatter.dart';
import 'add_transaction_screen.dart';
import 'split_detail_screen.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onUpdate;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isLend = transaction.type == AppConstants.typeLend;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final directionColor = AppTheme.getTransactionActionColor(transaction.type);
    final isDark = theme.brightness == Brightness.dark;
    final categoryColor = AppTheme.getCategoryColor(
      transaction.category,
      isDark: isDark,
    );
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(tr.transactionDetails)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildBadge(
                  icon: isLend ? Icons.call_made : Icons.call_received,
                  label: isLend ? tr.youGaveBadge : tr.youGotBadge,
                  color: directionColor,
                  isDark: isDark,
                ),

                _buildBadge(
                  icon: transaction.isSplit
                      ? Icons.call_split_rounded
                      : transaction.isSharedSpend
                      ? Icons.receipt_long_outlined
                      : transaction.isCash
                      ? Icons.currency_rupee
                      : Icons.shopping_bag,
                  label: transaction.isSplit
                      ? tr.split
                      : transaction.isSharedSpend
                      ? 'Shared'
                      : transaction.isCash
                      ? tr.cashBadge
                      : tr.udhariBadge,
                  color: categoryColor,
                  isDark: isDark,
                ),

                // Settlement badge
                if (transaction.isSettlement)
                  _buildBadge(
                    icon: Icons.done_all,
                    label: tr.settledBadge,
                    color: colorScheme.primary,
                    isDark: isDark,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.07),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: directionColor.withValues(
                        alpha: isDark ? 0.18 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: directionColor.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Icon(
                      isLend ? Icons.call_made : Icons.call_received,
                      color: directionColor,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLend ? tr.youGave : tr.youGot,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(transaction.amount),
                          style: TextStyle(
                            color: directionColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Trending indicator
                  Icon(
                    isLend
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    color: directionColor,
                    size: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Text(
              tr.transactionDetails,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),

            _buildDetailCard(
              context,
              icon: Icons.person_outline_rounded,
              label: tr.contact,
              value: transaction.contactName ?? tr.unknown,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            if (transaction.isSharedSpend) ...[
              _buildDetailCard(
                context,
                icon: Icons.account_balance_wallet_outlined,
                label: tr.paidByUser,
                value: transaction.sharedPaidByUser == true
                    ? tr.you
                    : transaction.contactName ?? tr.unknown,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              if (transaction.sharedTotalAmount != null) ...[
                _buildDetailCard(
                  context,
                  icon: Icons.receipt_long_outlined,
                  label: tr.totalBill,
                  value: CurrencyFormatter.format(
                    transaction.sharedTotalAmount!,
                  ),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
              ],
              if (transaction.sharedUserShare != null) ...[
                _buildDetailCard(
                  context,
                  icon: Icons.person_outline_rounded,
                  label: tr.yourShare,
                  value: CurrencyFormatter.format(transaction.sharedUserShare!),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
              ],
              if (transaction.sharedContactShare != null) ...[
                _buildDetailCard(
                  context,
                  icon: Icons.group_outlined,
                  label: tr.personShare(transaction.contactName ?? tr.unknown),
                  value: CurrencyFormatter.format(
                    transaction.sharedContactShare!,
                  ),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
              ],
            ],
            if (transaction.isUdhari && transaction.itemName != null) ...[
              _buildDetailCard(
                context,
                icon: Icons.shopping_bag_rounded,
                label: tr.itemService,
                value: transaction.itemName!,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
            ],

            if (transaction.isUdhari && transaction.quantity != null) ...[
              _buildDetailCard(
                context,
                icon: Icons.format_list_numbered_rounded,
                label: tr.quantity,
                value: transaction.quantity!,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
            ],

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
              const SizedBox(height: 8),
            ],

            if (transaction.isOverdue) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(
                    alpha: isDark ? 0.16 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: AppTheme.errorColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr.paymentOverdue,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            _buildDetailCard(
              context,
              icon: Icons.calendar_today_rounded,
              label: tr.date,
              value: DateFormat(
                AppConstants.dateFormat2,
              ).format(transaction.date),
              isDark: isDark,
            ),
            const SizedBox(height: 8),

            _buildDetailCard(
              context,
              icon: Icons.access_time_rounded,
              label: tr.time,
              value: DateFormat('hh:mm a').format(transaction.date),
              isDark: isDark,
            ),

            if (transaction.description != null &&
                transaction.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailCard(
                context,
                icon: Icons.notes_rounded,
                label: tr.description,
                value: transaction.description!,
                isDark: isDark,
              ),
            ],

            const SizedBox(height: 20),

            if (transaction.isSplit && transaction.sourceId != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openSplit(context),
                  icon: const Icon(Icons.call_split_rounded, size: 18),
                  label: Text(tr.splitDetails),
                ),
              )
            else if (!transaction.isSplit)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editTransaction(context),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(tr.editTransaction),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteConfirmation(context),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(tr.deleteTransaction),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(
                          color: AppTheme.errorColor.withValues(alpha: 0.6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editTransaction(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          transactionType: transaction.type,
          transactionCategory: transaction.category,
          transaction: transaction,
        ),
      ),
    );

    if (result == true && context.mounted) {
      onUpdate?.call();
      Navigator.pop(context, true);
    }
  }

  Future<void> _openSplit(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SplitDetailScreen(splitId: transaction.sourceId!),
      ),
    );

    if (context.mounted) {
      onUpdate?.call();
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final pageContext = context;

    showDialog(
      context: pageContext,
      builder: (dialogContext) => DeleteTransactionDialog(
        onConfirm: () async {
          // Delete transaction
          await pageContext.read<BorrowLendCubit>().deleteTransaction(
            transaction.id!,
            transaction.contactId,
          );

          // Show success message
          if (pageContext.mounted) {
            showSuccessSnackbar(pageContext, tr.transactionDeleted);
            // Call update callback
            if (onUpdate != null) onUpdate!();

            // Navigate back
            Navigator.pop(pageContext, true);
          }
        },
      ),
    );
  }
}
