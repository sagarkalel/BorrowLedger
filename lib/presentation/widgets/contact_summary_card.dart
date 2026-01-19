import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ContactSummaryCard extends StatelessWidget {
  final String contactName;
  final String? phoneNumber;
  final int transactionCount;
  final double netBalance;
  final int cashCount;
  final int udhariCount;
  final VoidCallback onTap;

  const ContactSummaryCard({
    super.key,
    required this.contactName,
    this.phoneNumber,
    required this.transactionCount,
    required this.netBalance,
    this.cashCount = 0,
    this.udhariCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    // netBalance > 0 means you'll GET money (they owe you) - Green
    // netBalance < 0 means you'll GIVE money (you owe them) - Orange
    final isPositive = netBalance >= 0;
    final directionColor = isPositive
        ? AppTheme
              .moneyInColor // Green - you'll get
        : AppTheme.moneyOutColor; // Orange - you'll give

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
              // Avatar with status indicator
              _buildAvatar(contactName, isPositive, directionColor, isDark),
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
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildMetaInfo(isDark),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Amount and direction
              _buildAmountSection(directionColor, isPositive, isDark, tr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
    String contactName,
    bool isPositive,
    Color directionColor,
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
          // Direction indicator
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: directionColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.grey[850]! : Colors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                isPositive ? Icons.call_received : Icons.call_made,
                size: 9,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(bool isDark) {
    return Row(
      children: [
        // Phone
        if (phoneNumber != null && phoneNumber!.isNotEmpty) ...[
          Icon(
            Icons.phone,
            size: 10,
            color: isDark ? Colors.grey[600] : Colors.grey[500],
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              phoneNumber!,
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

        // Category breakdown
        if (cashCount > 0 || udhariCount > 0) ...[
          if (cashCount > 0) ...[
            _buildCategoryBadge(true, cashCount, AppTheme.cashColor, isDark),
            if (udhariCount > 0) const SizedBox(width: 4),
          ],
          if (udhariCount > 0)
            _buildCategoryBadge(
              false,
              udhariCount,
              AppTheme.udhariColor,
              isDark,
            ),
        ] else ...[
          // Fallback to total count
          Icon(
            Icons.receipt_long,
            size: 10,
            color: isDark ? Colors.grey[600] : Colors.grey[500],
          ),
          const SizedBox(width: 3),
          Text(
            '$transactionCount',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryBadge(bool isCash, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            // '${isCash ? "💵 Cash" : "🛒 Udhari"} ($count)',
            '${isCash ? "💵" : "🛒"} ($count)',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(
    Color directionColor,
    bool isPositive,
    bool isDark,
    AppLocalizations tr,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: directionColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.call_received : Icons.call_made,
                    size: 9,
                    color: directionColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isPositive ? tr.youWillGet : tr.youWillGive,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: directionColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
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
}
