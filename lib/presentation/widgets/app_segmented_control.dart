import 'package:flutter/material.dart';

class AppSegmentedControlItem<T> {
  const AppSegmentedControlItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  final T value;
  final String label;
  final IconData icon;
}

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.margin = const EdgeInsets.fromLTRB(12, 6, 12, 6),
    this.segmentHeight = 48,
    this.iconSize = 18,
    this.fontSize = 11,
    this.selectedColor,
  });

  final List<AppSegmentedControlItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final EdgeInsetsGeometry margin;
  final double segmentHeight;
  final double iconSize;
  final double fontSize;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: _AppSegment<T>(
                item: item,
                selected: item.value == selectedValue,
                onTap: () => onChanged(item.value),
                height: segmentHeight,
                iconSize: iconSize,
                fontSize: fontSize,
                selectedColor: selectedColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _AppSegment<T> extends StatelessWidget {
  const _AppSegment({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.height,
    required this.iconSize,
    required this.fontSize,
    this.selectedColor,
  });

  final AppSegmentedControlItem<T> item;
  final bool selected;
  final VoidCallback onTap;
  final double height;
  final double iconSize;
  final double fontSize;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = selectedColor ?? colorScheme.primary;
    final foregroundColor = selected
        ? activeColor
        : isDark
        ? Colors.grey[400]!
        : Colors.grey[700]!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: selected ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withValues(alpha: isDark ? 0.18 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: iconSize, color: foregroundColor),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
