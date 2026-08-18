import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import 'app_list_avatar.dart';
import 'app_pill_badge.dart';

class ContactSummaryCard extends StatelessWidget {
  final String contactName;
  final String? phoneNumber;
  final int transactionCount;
  final double netBalance;
  final int cashCount;
  final int udhariCount;
  final int sharedSpendCount;
  final int splitCount;
  final double splitNet;
  final VoidCallback onTap;

  const ContactSummaryCard({
    super.key,
    required this.contactName,
    this.phoneNumber,
    required this.transactionCount,
    required this.netBalance,
    this.cashCount = 0,
    this.udhariCount = 0,
    this.sharedSpendCount = 0,
    this.splitCount = 0,
    this.splitNet = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tr = AppLocalizations.of(context)!;

    // netBalance > 0 means you'll GET money (they owe you) - Green
    // netBalance < 0 means you'll GIVE money (you owe them) - Orange
    final isSettled = netBalance.abs() < 0.01;
    final isPositive = netBalance > 0;
    final directionColor = isSettled
        ? colorScheme.onSurfaceVariant
        : isPositive
        ? AppTheme.moneyInColor
        : AppTheme.moneyOutColor;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              // Avatar with status indicator
              AppListAvatar(
                label: contactName,
                indicatorIcon: isSettled
                    ? Icons.done_all_rounded
                    : isPositive
                    ? Icons.call_received
                    : Icons.call_made,
                indicatorColor: directionColor,
                isSubtleIndicator: isSettled,
                size: 38,
              ),
              const SizedBox(width: 10),

              // Contact Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      contactName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    _buildMetaInfo(context),
                    if (splitCount > 0 && splitNet.abs() >= 0.01) ...[
                      const SizedBox(height: 4),
                      _buildSplitDueHint(context, tr),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Amount and direction
              _buildAmountSection(context, directionColor, isPositive, tr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final metaColor = colorScheme.onSurfaceVariant;
    final tr = AppLocalizations.of(context)!;

    return Row(
      children: [
        // Phone
        if (phoneNumber != null && phoneNumber!.isNotEmpty) ...[
          Icon(Icons.phone, size: 10, color: metaColor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              phoneNumber!,
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

        // Category breakdown
        if (cashCount > 0 ||
            udhariCount > 0 ||
            sharedSpendCount > 0 ||
            splitCount > 0) ...[
          if (cashCount > 0) ...[
            _buildCategoryBadge(context, tr.cash, cashCount),
            if (udhariCount > 0 || sharedSpendCount > 0 || splitCount > 0)
              const SizedBox(width: 4),
          ],
          if (udhariCount > 0) ...[
            _buildCategoryBadge(context, tr.udhari, udhariCount),
            if (sharedSpendCount > 0 || splitCount > 0)
              const SizedBox(width: 4),
          ],
          if (sharedSpendCount > 0) ...[
            _buildCategoryBadge(context, tr.sharedSpend, sharedSpendCount),
            if (splitCount > 0) const SizedBox(width: 4),
          ],
          if (splitCount > 0)
            _buildCategoryBadge(context, tr.splits, splitCount),
        ] else ...[
          // Fallback to total count
          Icon(Icons.receipt_long, size: 10, color: metaColor),
          const SizedBox(width: 3),
          Text(
            '$transactionCount',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: metaColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSplitDueHint(BuildContext context, AppLocalizations tr) {
    final isPositive = splitNet > 0;
    final color = isPositive ? AppTheme.moneyInColor : AppTheme.moneyOutColor;

    return Row(
      children: [
        Icon(Icons.call_split_rounded, size: 11, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${tr.splits}: ${isPositive ? tr.youWillGet : tr.youWillGive} ${CurrencyFormatter.format(splitNet.abs())}',
            style: TextStyle(
              fontSize: 10,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBadge(BuildContext context, String label, int count) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildAmountSection(
    BuildContext context,
    Color directionColor,
    bool isPositive,
    AppLocalizations tr,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSettled = netBalance.abs() < 0.01;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Amount
            Text(
              CurrencyFormatter.format(netBalance.abs()),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: directionColor,
              ),
            ),
            const SizedBox(height: 3),
            // Direction badge
            AppPillBadge(
              label: isSettled
                  ? tr.settled
                  : isPositive
                  ? tr.youWillGet
                  : tr.youWillGive,
              icon: isSettled
                  ? Icons.done_all_rounded
                  : isPositive
                  ? Icons.call_received
                  : Icons.call_made,
              color: directionColor,
              fontSize: 7.5,
            ),
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
}
