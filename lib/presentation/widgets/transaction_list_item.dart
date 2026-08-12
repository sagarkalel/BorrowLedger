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
  final bool showContactIdentity;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.onTap,
    this.showContactIdentity = true,
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
    final verticalPadding = showContactIdentity ? 9.0 : 8.0;
    final avatarSize = showContactIdentity ? 38.0 : 36.0;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: verticalPadding,
          ),
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
                size: avatarSize,
              ),
              const SizedBox(width: 10),

              // Contact Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Contact name
                    Text(
                      showContactIdentity
                          ? contactName
                          : _transactionTitle(context, isCash, isSplit),
                      style: TextStyle(
                        fontSize: showContactIdentity ? 14 : 13.5,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Category badge and item info
                    _buildCategoryInfo(context, isCash, isSplit, categoryColor),
                    const SizedBox(height: 3),

                    // Phone, Date, Expected date
                    _buildMetaInfo(context, hasPhone),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Amount and direction
              _buildAmountSection(context, directionColor, isLend),
            ],
          ),
        ),
      ),
    );
  }

  String _transactionTitle(BuildContext context, bool isCash, bool isSplit) {
    final tr = AppLocalizations.of(context)!;
    if (isSplit) {
      final splitTitle = _splitTitle();
      return splitTitle?.isNotEmpty == true ? splitTitle! : tr.split;
    }
    if (!isCash && transaction.itemName?.trim().isNotEmpty == true) {
      return transaction.itemName!.trim();
    }
    if (transaction.description?.trim().isNotEmpty == true) {
      return transaction.description!.trim();
    }
    return isCash ? tr.cash : tr.udhari;
  }

  Widget _buildCategoryInfo(
    BuildContext context,
    bool isCash,
    bool isSplit,
    Color categoryColor,
  ) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final splitTitle = _splitTitle();

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
          fontSize: 8.5,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        ),

        if (showContactIdentity &&
            isSplit &&
            splitTitle != null &&
            splitTitle.isNotEmpty) ...[
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
        if (showContactIdentity &&
            !isCash &&
            !isSplit &&
            transaction.itemName != null) ...[
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

  String? _splitTitle() {
    return transaction.description
        ?.replaceFirst(RegExp(r'^(Split|Split history):\s*'), '')
        .trim();
  }

  Widget _buildMetaInfo(BuildContext context, bool hasPhone) {
    final colorScheme = Theme.of(context).colorScheme;
    final metaColor = colorScheme.onSurfaceVariant;

    return Row(
      children: [
        // Phone
        if (showContactIdentity && hasPhone) ...[
          Icon(Icons.phone, size: 9.5, color: metaColor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              transaction.contactPhone!,
              style: TextStyle(fontSize: 9.5, color: metaColor),
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
        Icon(Icons.calendar_today, size: 9.5, color: metaColor),
        const SizedBox(width: 3),
        Text(
          DateFormat(AppConstants.dateFormat).format(transaction.date),
          style: TextStyle(fontSize: 9.5, color: metaColor),
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
            size: 9.5,
            color: transaction.isOverdue ? Colors.red : metaColor,
          ),
          const SizedBox(width: 2),
          Text(
            DateFormat(
              AppConstants.dateMonthFormat,
            ).format(transaction.expectedDate!),
            style: TextStyle(
              fontSize: 9.5,
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
                fontSize: 16.5,
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
          size: 16,
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
