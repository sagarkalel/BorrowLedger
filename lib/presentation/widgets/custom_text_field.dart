import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_form_field_metrics.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? prefixText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLines;
  final int? maxLength;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final TextCapitalization textCapitalization;
  final VoidCallback? onTap;
  final bool isDense;

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.onTap,
    this.isDense = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMultiline = (maxLines ?? 1) > 1;
    final fieldFillColor =
        theme.inputDecorationTheme.fillColor ?? colorScheme.surface;
    final hasMultilinePrefixIcon = isMultiline && prefixIcon != null;
    final effectiveContentPadding = isDense
        ? EdgeInsets.fromLTRB(
            hasMultilinePrefixIcon ? AppFormFieldMetrics.denseIconSlot : 12,
            isMultiline ? 12 : 10,
            12,
            10,
          )
        : null;

    final textField = TextFormField(
      controller: controller,
      textAlignVertical: isMultiline ? TextAlignVertical.top : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldFillColor,
        alignLabelWithHint: isMultiline,
        labelText: labelText,
        hintText: hintText,
        prefixText: prefixText,
        prefixIcon: hasMultilinePrefixIcon
            ? null
            : prefixIcon != null
            ? Icon(prefixIcon)
            : null,
        prefixIconConstraints: isDense
            ? const BoxConstraints(
                minWidth: AppFormFieldMetrics.denseIconSlot,
                minHeight: AppFormFieldMetrics.denseHeight,
              )
            : null,
        suffixIcon: suffixIcon,
        suffixIconConstraints: isDense
            ? const BoxConstraints(
                minWidth: AppFormFieldMetrics.denseIconSlot,
                minHeight: AppFormFieldMetrics.denseHeight,
              )
            : null,
        isDense: isDense,
        contentPadding: effectiveContentPadding,
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          backgroundColor: fieldFillColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      maxLines: maxLines,
      maxLength: maxLength,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      textCapitalization: textCapitalization,
      onTap: onTap,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );

    if (!hasMultilinePrefixIcon) return textField;

    return Stack(
      children: [
        textField,
        Positioned(
          left: 12,
          top: labelText == null ? 14 : 12,
          child: Icon(
            prefixIcon,
            size: AppFormFieldMetrics.denseIconSize,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
