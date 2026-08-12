import 'package:flutter/foundation.dart';

class AppLoadingDelay {
  const AppLoadingDelay._();

  static const bool enabled = true;

  static const Duration initialDuration = Duration(milliseconds: 420);
  static const Duration refreshDuration = Duration(milliseconds: 280);
  static const Duration loadMoreDuration = Duration(milliseconds: 220);

  static Future<void> initial() => _wait(initialDuration);

  static Future<void> refresh() => _wait(refreshDuration);

  static Future<void> loadMore() => _wait(loadMoreDuration);

  static Future<void> _wait(Duration duration) {
    if (!enabled || kReleaseMode) return Future<void>.value();
    return Future<void>.delayed(duration);
  }
}
