import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _wholeNumberFormat = NumberFormat.decimalPattern(
    'en_IN',
  );
  static final NumberFormat _decimalNumberFormat =
      NumberFormat.decimalPattern('en_IN')
        ..minimumFractionDigits = 2
        ..maximumFractionDigits = 2;

  static String format(
    num? amount, {
    String symbol = '₹',
    bool showSign = false,
    bool forceDecimals = false,
  }) {
    final safeAmount = amount ?? 0;
    final isNegative = safeAmount < 0;
    final absoluteAmount = safeAmount.abs();
    final hasFraction = (absoluteAmount - absoluteAmount.truncate()).abs() > 0;
    final formatter = forceDecimals || hasFraction
        ? _decimalNumberFormat
        : _wholeNumberFormat;
    final sign = isNegative
        ? '-'
        : showSign && safeAmount > 0
        ? '+'
        : '';

    return '$sign$symbol ${formatter.format(absoluteAmount)}';
  }

  static String formatCode(
    num? amount, {
    String code = 'INR',
    bool showSign = false,
    bool forceDecimals = false,
  }) {
    return format(
      amount,
      symbol: code,
      showSign: showSign,
      forceDecimals: forceDecimals,
    );
  }
}

extension CurrencyFormatting on num {
  String toCurrency({
    String symbol = '₹',
    bool showSign = false,
    bool forceDecimals = false,
  }) {
    return CurrencyFormatter.format(
      this,
      symbol: symbol,
      showSign: showSign,
      forceDecimals: forceDecimals,
    );
  }

  String toCurrencyCode({
    String code = 'INR',
    bool showSign = false,
    bool forceDecimals = false,
  }) {
    return CurrencyFormatter.formatCode(
      this,
      code: code,
      showSign: showSign,
      forceDecimals: forceDecimals,
    );
  }
}
