import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/expense_model.dart';
import 'app_dialog_components.dart';
import 'app_list_avatar.dart';

/// Compact expense details bottom sheet.
class ExpenseDetailsBottomSheet extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExpenseDetailsBottomSheet({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = getCategoryColor(expense.category);
    final tr = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and category
                _buildHeader(context, categoryColor),
                const SizedBox(height: 16),

                _buildAmountCard(context, categoryColor, tr),
                const SizedBox(height: 14),

                // Details section
                _buildDetailsSection(context, tr),

                // Description (if available)
                if (expense.description != null &&
                    expense.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDescriptionSection(context, tr),
                ],

                const SizedBox(height: 18),

                // Action buttons
                _buildActionButtons(context, tr),

                // Bottom safe area
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color categoryColor) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        AppListAvatar(
          label: getCategoryLabel(context, expense.category),
          centerIcon: getCategoryIcon(expense.category),
          indicatorIcon: Icons.currency_rupee,
          indicatorColor: categoryColor,
          size: 46,
        ),
        const SizedBox(width: 12),

        // Category and date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getCategoryLabel(context, expense.category),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(expense.date),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard(
    BuildContext context,
    Color categoryColor,
    AppLocalizations tr,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialogNotice(
      color: categoryColor,
      child: Column(
        children: [
          Text(
            tr.amountSpent,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(expense.amount),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: categoryColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, AppLocalizations tr) {
    return AppDialogNotice(
      child: Column(
        children: [
          _buildDetailRow(
            context,
            Icons.calendar_today_outlined,
            tr.date,
            DateFormat('EEEE, dd MMMM yyyy').format(expense.date),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            Icons.access_time_outlined,
            tr.time,
            DateFormat('hh:mm a').format(expense.date),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context, AppLocalizations tr) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialogNotice(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_outlined,
                size: 17,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                tr.description,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            expense.description!,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations tr) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(tr.edit),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(tr.delete),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: BorderSide(
                color: AppTheme.errorColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
