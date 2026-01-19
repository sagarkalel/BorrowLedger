import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      isDark: isDark,
    );
    final categoryBgColor = AppTheme.getCategoryBgColor(
      transaction.category,
      isDark,
    );

    final contactName = transaction.contactName ?? tr.unknown;
    final hasPhone =
        transaction.contactPhone != null &&
        transaction.contactPhone!.isNotEmpty;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar with category icon
              _buildAvatar(contactName, isCash, categoryColor, isDark),
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
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Category badge and item info
                    _buildCategoryInfo(
                      context,
                      isCash,
                      categoryColor,
                      categoryBgColor,
                      isDark,
                    ),
                    const SizedBox(height: 4),

                    // Phone, Date, Expected date
                    _buildMetaInfo(hasPhone, isDark),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Amount and direction
              _buildAmountSection(context, directionColor, isLend, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
    String contactName,
    bool isCash,
    Color categoryColor,
    bool isDark,
  ) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.primaries[contactName.hashCode % Colors.primaries.length]
                .withValues(alpha: 0.3),
            Colors.primaries[contactName.hashCode % Colors.primaries.length],
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              contactName.isNotEmpty ? contactName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Category indicator
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: categoryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.grey[850]! : Colors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                isCash ? Icons.currency_rupee : Icons.shopping_bag,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInfo(
    BuildContext context,
    bool isCash,
    Color categoryColor,
    Color categoryBgColor,
    bool isDark,
  ) {
    final tr = AppLocalizations.of(context)!;
    return Row(
      children: [
        // Category badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: categoryBgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCash ? '💵 ${tr.cashBadge}' : '🛍️ ${tr.udhariBadge}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: categoryColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),

        // For udhari, show item name
        if (!isCash && transaction.itemName != null) ...[
          const SizedBox(width: 6),
          Container(
            width: 2,
            height: 2,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[400],
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
                color: categoryColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetaInfo(bool hasPhone, bool isDark) {
    return Row(
      children: [
        // Phone
        if (hasPhone) ...[
          Icon(
            Icons.phone,
            size: 10,
            color: isDark ? Colors.grey[600] : Colors.grey[500],
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              transaction.contactPhone!,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 2,
            height: 2,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],

        // Date
        Icon(
          Icons.calendar_today,
          size: 10,
          color: isDark ? Colors.grey[600] : Colors.grey[500],
        ),
        const SizedBox(width: 3),
        Text(
          DateFormat(AppConstants.dateFormat).format(transaction.date),
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[600] : Colors.grey[500],
          ),
        ),

        // Expected date
        if (transaction.expectedDate != null) ...[
          const SizedBox(width: 6),
          Container(
            width: 2,
            height: 2,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            transaction.isOverdue ? Icons.warning : Icons.event,
            size: 10,
            color: transaction.isOverdue
                ? Colors.red
                : (isDark ? Colors.grey[600] : Colors.grey[500]),
          ),
          const SizedBox(width: 2),
          Text(
            DateFormat(
              AppConstants.dateMonthFormat,
            ).format(transaction.expectedDate!),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: transaction.isOverdue
                  ? Colors.red
                  : (isDark ? Colors.grey[600] : Colors.grey[500]),
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
    bool isDark,
  ) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Amount
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: directionColor,
                  ),
                ),
                Text(
                  transaction.amount.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: directionColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            transaction.isSettlement
                // Settlement badge
                ? _buildSettlementBadge(context, isDark)
                :
                  // Direction badge (what will happen)
                  _buildDirectionBadge(context, isLend, directionColor),
          ],
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
      ],
    );
  }

  Widget _buildSettlementBadge(BuildContext context, bool isDark) {
    final color = isDark ? Colors.blue.shade400 : Colors.blue.shade600;
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all, size: 9, color: color),
          const SizedBox(width: 3),
          Text(
            tr.settledBadge,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionBadge(
    BuildContext context,
    bool isLend,
    Color directionColor,
  ) {
    final tr = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: directionColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLend ? Icons.call_made : Icons.call_received,
            size: 9,
            color: directionColor,
          ),
          const SizedBox(width: 3),
          Text(
            isLend ? tr.youGave : tr.youGot,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: directionColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
