import 'package:flutter/material.dart';

class AppDateField extends StatelessWidget {
  final String labelText;
  final String? valueText;
  final String? placeholderText;
  final IconData prefixIcon;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String? clearTooltip;
  final String? Function(String?)? validator;

  const AppDateField({
    super.key,
    required this.labelText,
    required this.valueText,
    required this.onTap,
    this.placeholderText,
    this.prefixIcon = Icons.calendar_today_rounded,
    this.onClear,
    this.clearTooltip,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fillColor =
        theme.inputDecorationTheme.fillColor ?? colorScheme.surface;
    final hasValue = valueText != null && valueText!.isNotEmpty;
    final displayText = hasValue ? valueText! : placeholderText ?? labelText;

    return TextFormField(
      key: ValueKey('$labelText-$displayText'),
      initialValue: displayText,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
        fontSize: 14,
        fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
        color: hasValue
            ? colorScheme.onSurface
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.68),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,
        labelText: labelText,
        prefixIcon: Icon(prefixIcon),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 42,
          minHeight: 42,
        ),
        suffixIcon: SizedBox(
          width: 42,
          child: Center(
            child: hasValue && onClear != null
                ? IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear_rounded),
                    iconSize: 18,
                    tooltip: clearTooltip ?? 'Clear date',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                  )
                : Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 42,
          minHeight: 32,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          backgroundColor: fillColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
