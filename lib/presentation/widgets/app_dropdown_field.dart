import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class AppDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? color;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });
}

class AppDropdownField<T> extends StatefulWidget {
  final T? value;
  final List<AppDropdownItem<T>> items;
  final String labelText;
  final IconData? prefixIcon;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool isDense;

  const AppDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.labelText,
    this.prefixIcon,
    this.onChanged,
    this.validator,
    this.isDense = false,
  });

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  late final ValueNotifier<T?> _valueNotifier;

  @override
  void initState() {
    super.initState();
    _valueNotifier = ValueNotifier<T?>(widget.value);
  }

  @override
  void didUpdateWidget(covariant AppDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _valueNotifier.value = widget.value;
    }
  }

  @override
  void dispose() {
    _valueNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fillColor =
        theme.inputDecorationTheme.fillColor ?? colorScheme.surface;
    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );

    return DropdownButtonFormField2<T>(
      valueListenable: _valueNotifier,
      isExpanded: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        prefixIconConstraints: widget.isDense
            ? const BoxConstraints(minWidth: 42, minHeight: 32)
            : null,
        isDense: widget.isDense,
        contentPadding: widget.isDense
            ? const EdgeInsets.symmetric(horizontal: 0, vertical: 3)
            : null,
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          backgroundColor: fillColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      hint: Text(
        widget.labelText,
        style: textStyle?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      style: textStyle,
      iconStyleData: IconStyleData(
        icon: SizedBox(
          width: widget.isDense ? 35 : 48,
          child: Center(
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colorScheme.onSurfaceVariant,
              size: widget.isDense ? 20 : 22,
            ),
          ),
        ),
        openMenuIcon: SizedBox(
          width: widget.isDense ? 35 : 48,
          child: Center(
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              color: colorScheme.onSurfaceVariant,
              size: widget.isDense ? 20 : 22,
            ),
          ),
        ),
        iconEnabledColor: colorScheme.onSurfaceVariant,
        iconDisabledColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        iconSize: 22,
      ),
      buttonStyleData: FormFieldButtonStyleData(
        padding: EdgeInsets.zero,
        height: widget.isDense ? 42 : null,
      ),
      dropdownStyleData: DropdownStyleData(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
        elevation: 2,
        offset: const Offset(0, -2),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      menuItemStyleData: MenuItemStyleData(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(10),
      ),
      items: widget.items
          .map(
            (item) => DropdownItem<T>(
              value: item.value,
              child: _AppDropdownItemContent(
                label: item.label,
                icon: item.icon,
                color: item.color,
              ),
            ),
          )
          .toList(),
      onChanged: widget.onChanged,
      validator: widget.validator,
    );
  }
}

class _AppDropdownItemContent extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const _AppDropdownItemContent({required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = color ?? colorScheme.onSurfaceVariant;

    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
