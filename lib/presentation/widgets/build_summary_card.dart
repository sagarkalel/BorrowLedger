import 'package:flutter/material.dart';

class BuildSummaryCard extends StatelessWidget {
  const BuildSummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isPositive,
    this.subtitle,
    this.isCompact = false,
  });

  final String title;
  final String? subtitle;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isPositive;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isCompact ? 10 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: isCompact ? 28 : 34,
                      height: isCompact ? 28 : 34,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(isCompact ? 8 : 9),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: isCompact ? 15 : 18,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: color,
                      size: isCompact ? 16 : 19,
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 8 : 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isCompact ? 17 : 20,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    height: 1.15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
