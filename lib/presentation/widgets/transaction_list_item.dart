import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'app_list_avatar.dart';
import 'app_pill_badge.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLend = transaction.type == AppConstants.typeLend;
    final isCash = transaction.category == AppConstants.categoryCash;
    final isSplit = transaction.category == AppConstants.categorySplit;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tr = AppLocalizations.of(context)!;

    // Direction color (what will happen)
    // lend = you gave -> you'll GET back (green)
    // borrow = you got -> you'll GIVE back (orange)
    final directionColor = AppTheme.getTransactionDirectionColor(
      transaction.type,
    );

    // Category color (cash = teal, udhari = amber)
    final categoryColor = AppTheme.getCategoryColor(
      transaction.category,
      isDark: theme.brightness == Brightness.dark,
    );

    final contactName = transaction.contactName ?? tr.unknown;
    final hasPhone =
        transaction.contactPhone != null &&
        transaction.contactPhone!.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              // Avatar with category icon
              AppListAvatar(
                label: contactName,
                indicatorIcon: isSplit
                    ? Icons.call_split_rounded
                    : isCash
                    ? Icons.currency_rupee
                    : Icons.shopping_bag,
                indicatorColor: categoryColor,
              ),
              const SizedBox(width: 12),

              // Contact Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Contact name
                    Text(
                      contactName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Category badge and item info
                    _buildCategoryInfo(context, isCash, isSplit, categoryColor),
                    const SizedBox(height: 4),

                    // Phone, Date, Expected date
                    _buildMetaInfo(context, hasPhone),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Amount and direction
              _buildAmountSection(context, directionColor, isLend),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryInfo(
    BuildContext context,
    bool isCash,
    bool isSplit,
    Color categoryColor,
  ) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final splitTitle = transaction.description
        ?.replaceFirst(RegExp(r'^Split:\s*'), '')
        .trim();

    return Row(
      children: [
        // Category badge
        AppPillBadge(
          label: isSplit
              ? tr.split
              : isCash
              ? tr.cashBadge
              : tr.udhariBadge,
          icon: isSplit ? Icons.call_split_rounded : null,
          color: isSplit ? categoryColor : colorScheme.onSurfaceVariant,
          fontSize: 9,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        ),

        if (isSplit && splitTitle != null && splitTitle.isNotEmpty) ...[
          const SizedBox(width: 6),
          Container(
            width: 2,
            height: 2,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              splitTitle,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        // For udhari, show item name
        if (!isCash && !isSplit && transaction.itemName != null) ...[
          const SizedBox(width: 6),
          Container(
            width: 2,
            height: 2,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              transaction.quantity != null
                  ? '${transaction.itemName} • ${transaction.quantity}'
                  : transaction.itemName!,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetaInfo(BuildContext context, bool hasPhone) {
    final colorScheme = Theme.of(context).colorScheme;
    final metaColor = colorScheme.onSurfaceVariant;

    return Row(
      children: [
        // Phone
        if (hasPhone) ...[
          Icon(Icons.phone, size: 10, color: metaColor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              transaction.contactPhone!,
              style: TextStyle(fontSize: 10, color: metaColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 2,
            height: 2,
            decoration: BoxDecoration(
              color: metaColor.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],

        // Date
        Icon(Icons.calendar_today, size: 10, color: metaColor),
        const SizedBox(width: 3),
        Text(
          DateFormat(AppConstants.dateFormat).format(transaction.date),
          style: TextStyle(fontSize: 10, color: metaColor),
        ),

        // Expected date
        if (transaction.expectedDate != null) ...[
          const SizedBox(width: 6),
          Container(
            width: 2,
            height: 2,
            decoration: BoxDecoration(
              color: metaColor.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            transaction.isOverdue ? Icons.warning : Icons.event,
            size: 10,
            color: transaction.isOverdue ? Colors.red : metaColor,
          ),
          const SizedBox(width: 2),
          Text(
            DateFormat(
              AppConstants.dateMonthFormat,
            ).format(transaction.expectedDate!),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: transaction.isOverdue ? Colors.red : metaColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmountSection(
    BuildContext context,
    Color directionColor,
    bool isLend,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Amount
            Text(
              '₹${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: directionColor,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            transaction.isSettlement
                // Settlement badge
                ? _buildSettlementBadge(context)
                :
                  // Direction badge (what will happen)
                  _buildDirectionBadge(context, isLend, directionColor),
          ],
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildSettlementBadge(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    final tr = AppLocalizations.of(context)!;

    return AppPillBadge(
      label: tr.settledBadge,
      icon: Icons.done_all,
      color: color,
      fontSize: 8,
    );
  }

  Widget _buildDirectionBadge(
    BuildContext context,
    bool isLend,
    Color directionColor,
  ) {
    final tr = AppLocalizations.of(context)!;
    return AppPillBadge(
      label: isLend ? tr.youWillGet : tr.youWillGive,
      icon: isLend ? Icons.call_received : Icons.call_made,
      color: directionColor,
      fontSize: 8,
    );
  }
}
