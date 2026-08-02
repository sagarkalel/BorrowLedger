import 'package:flutter/material.dart';

class AppPillBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const AppPillBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.fontSize = 9,
    this.padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeColor = color ?? colorScheme.onSurfaceVariant;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: badgeColor),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
