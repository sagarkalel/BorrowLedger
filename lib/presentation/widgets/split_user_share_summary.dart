import 'package:borrow_ledger/presentation/widgets/app_dialog_components.dart';
import 'package:flutter/material.dart';

class SplitUserShareSummary extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final Color color;
  final IconData icon;
  final String? secondaryLabel;
  final String? secondaryValue;

  const SplitUserShareSummary({
    super.key,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.color,
    this.icon = Icons.person_outline_rounded,
    this.secondaryLabel,
    this.secondaryValue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSecondaryValue = secondaryLabel != null && secondaryValue != null;

    return AppDialogNotice(
      color: color,
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.2,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (hasSecondaryValue) ...[
            const SizedBox(width: 10),
            Container(
              width: 1,
              height: 42,
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  secondaryLabel!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  secondaryValue!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
