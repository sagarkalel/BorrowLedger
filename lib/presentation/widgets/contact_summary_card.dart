import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_list_avatar.dart';
import 'app_pill_badge.dart';

class ContactSummaryCard extends StatelessWidget {
  final String contactName;
  final String? phoneNumber;
  final int transactionCount;
  final double netBalance;
  final int cashCount;
  final int udhariCount;
  final int splitCount;
  final VoidCallback onTap;

  const ContactSummaryCard({
    super.key,
    required this.contactName,
    this.phoneNumber,
    required this.transactionCount,
    required this.netBalance,
    this.cashCount = 0,
    this.udhariCount = 0,
    this.splitCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tr = AppLocalizations.of(context)!;

    // netBalance > 0 means you'll GET money (they owe you) - Green
    // netBalance < 0 means you'll GIVE money (you owe them) - Orange
    final isPositive = netBalance >= 0;
    final directionColor = isPositive
        ? AppTheme
              .moneyInColor // Green - you'll get
        : AppTheme.moneyOutColor; // Orange - you'll give

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              // Avatar with status indicator
              AppListAvatar(
                label: contactName,
                indicatorIcon: isPositive
                    ? Icons.call_received
                    : Icons.call_made,
                indicatorColor: directionColor,
              ),
              const SizedBox(width: 12),

              // Contact Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    _buildMetaInfo(context),
                  ],
                ),
              ),
              const SizedBox(width: 12),

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
        if (cashCount > 0 || udhariCount > 0 || splitCount > 0) ...[
          if (cashCount > 0) ...[
            _buildCategoryBadge(context, 'Cash', cashCount),
            if (udhariCount > 0 || splitCount > 0) const SizedBox(width: 4),
          ],
          if (udhariCount > 0) ...[
            _buildCategoryBadge(context, 'Udhari', udhariCount),
            if (splitCount > 0) const SizedBox(width: 4),
          ],
          if (splitCount > 0) _buildCategoryBadge(context, 'Split', splitCount),
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
                  netBalance.abs().toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: directionColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Direction badge
            AppPillBadge(
              label: isPositive ? tr.youWillGet : tr.youWillGive,
              icon: isPositive ? Icons.call_received : Icons.call_made,
              color: directionColor,
              fontSize: 8,
            ),
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
}
