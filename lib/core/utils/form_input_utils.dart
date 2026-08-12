import 'package:flutter/services.dart';

class FormInputUtils {
  static final List<TextInputFormatter> phoneInputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
  ];

  static String normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '').trim();
  }

  static bool isValidOptionalPhone(String? phone) {
    final value = phone?.trim() ?? '';
    if (value.isEmpty) return true;

    final digits = normalizePhone(value);
    return digits.length >= 7 && digits.length <= 15;
  }
}
