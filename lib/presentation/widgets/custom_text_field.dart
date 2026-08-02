import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;

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
    this.contentPadding,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fieldFillColor =
        fillColor ??
        theme.inputDecorationTheme.fillColor ??
        colorScheme.surface;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldFillColor,
        labelText: labelText,
        hintText: hintText,
        prefixText: prefixText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        prefixIconConstraints: isDense
            ? const BoxConstraints(minWidth: 42, minHeight: 42)
            : null,
        suffixIcon: suffixIcon,
        suffixIconConstraints: isDense
            ? const BoxConstraints(minWidth: 42, minHeight: 42)
            : null,
        isDense: isDense,
        contentPadding:
            contentPadding ??
            (isDense
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                : null),
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
  }
}
