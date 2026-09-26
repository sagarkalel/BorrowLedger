import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpiService {
  const UpiService();

  static String? normalizeUpiId(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  static bool isValidUpiId(String? value) {
    final normalized = normalizeUpiId(value);
    if (normalized == null || normalized.contains(' ')) return false;
    final atIndex = normalized.indexOf('@');
    return atIndex > 0 &&
        atIndex == normalized.lastIndexOf('@') &&
        atIndex < normalized.length - 1;
  }

  static Uri buildPaymentUri({
    required String payeeUpiId,
    required String payeeName,
    required double amount,
    required String note,
  }) {
    final normalized = normalizeUpiId(payeeUpiId);
    if (!isValidUpiId(normalized)) {
      throw ArgumentError('A valid UPI ID is required.');
    }
    if (amount <= 0) {
      throw ArgumentError('A positive amount is required.');
    }

    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': normalized!,
        'pn': payeeName.trim().isEmpty ? 'HisaabMate' : payeeName.trim(),
        'am': amount.toStringAsFixed(2),
        'cu': 'INR',
        'tn': note.trim().isEmpty ? 'HisaabMate settlement' : note.trim(),
      },
    );
  }

  Future<bool> launchPayment(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<ShareResult> shareText({required String text, String? subject}) {
    return SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  Future<void> copyToClipboard(String text) {
    return Clipboard.setData(ClipboardData(text: text));
  }
}
