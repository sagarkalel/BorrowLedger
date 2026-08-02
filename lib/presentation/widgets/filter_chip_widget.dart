import 'package:flutter/material.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onSelected;

  const FilterChipWidget({
    super.key,
    required this.label,
    this.icon,
    this.color,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chipColor = color ?? theme.colorScheme.primary;
    final borderColor = isSelected
        ? chipColor.withValues(alpha: 0.32)
        : colorScheme.outline.withValues(alpha: 0.12);
    final backgroundColor = isSelected
        ? chipColor.withValues(alpha: 0.1)
        : colorScheme.surface;
    final foregroundColor = isSelected
        ? chipColor
        : colorScheme.onSurfaceVariant;

    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foregroundColor),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: backgroundColor,
      selectedColor: backgroundColor,
      checkmarkColor: chipColor,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: foregroundColor,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        fontSize: 12.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: borderColor),
      ),
    );
  }
}
