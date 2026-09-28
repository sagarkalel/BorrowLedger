import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpiAppLaunchResult { launched, cancelled, unavailable }

class UpiAppInfo {
  final String packageName;
  final String label;

  const UpiAppInfo({required this.packageName, required this.label});
}

class UpiService {
  const UpiService();

  static const _platformChannel = MethodChannel(
    'com.example.borrow_ledger/upi',
  );

  static bool get supportsNativeUpiAppPicker => Platform.isAndroid;

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

  /// Returns installed UPI apps without creating a payment request.
  Future<List<UpiAppInfo>> getAvailableUpiApps() async {
    if (!Platform.isAndroid) return const [];

    try {
      final rawApps = await _platformChannel.invokeMethod<List<dynamic>>(
        'getUpiApps',
      );
      return (rawApps ?? const [])
          .whereType<Map>()
          .map(
            (rawApp) => UpiAppInfo(
              packageName: rawApp['packageName'] as String? ?? '',
              label: rawApp['label'] as String? ?? '',
            ),
          )
          .where((app) => app.packageName.isNotEmpty && app.label.isNotEmpty)
          .toList(growable: false);
    } on PlatformException {
      return const [];
    }
  }

  /// Opens a selected UPI app without creating a payment request.
  ///
  /// Android launches the package selected in the Flutter app picker. A bare
  /// `upi://pay` URI can resolve to a UPI app but is rejected by the app as an
  /// incomplete payment request, so the user must search for and verify the
  /// recipient inside the selected UPI app.
  Future<UpiAppLaunchResult> launchUpiApp({String? packageName}) async {
    if (Platform.isAndroid) {
      if (packageName == null || packageName.trim().isEmpty) {
        return UpiAppLaunchResult.unavailable;
      }
      try {
        final result = await _platformChannel.invokeMethod<String>(
          'openUpiApp',
          {'packageName': packageName},
        );
        return switch (result) {
          'launched' => UpiAppLaunchResult.launched,
          'cancelled' => UpiAppLaunchResult.cancelled,
          _ => UpiAppLaunchResult.unavailable,
        };
      } on PlatformException {
        return UpiAppLaunchResult.unavailable;
      }
    }

    final launched = await launchUrl(
      Uri(scheme: 'upi', host: 'pay'),
      mode: LaunchMode.externalApplication,
    );
    return launched
        ? UpiAppLaunchResult.launched
        : UpiAppLaunchResult.unavailable;
  }

  Future<ShareResult> shareText({required String text, String? subject}) {
    return SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  Future<void> copyToClipboard(String text) {
    return Clipboard.setData(ClipboardData(text: text));
  }
}
