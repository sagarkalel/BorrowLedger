import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_lock_service.dart';

/// Stores only the local scheduling state for the optional App Lock reminder.
class AppLockDiscoveryService extends ChangeNotifier {
  static const String lastShownKey = 'app_lock_discovery_last_shown_ms';
  static const String displayCountKey = 'app_lock_discovery_display_count';
  static const String dismissedKey = 'app_lock_discovery_dismissed';
  static const String completedKey = 'app_lock_discovery_completed';

  static const Duration reminderInterval = Duration(days: 7);
  static const int maxDisplays = 3;

  static final AppLockDiscoveryService instance = AppLockDiscoveryService(
    appLockService: AppLockService.instance,
  );

  final AppLockService appLockService;
  final Future<SharedPreferences> Function() _preferencesLoader;

  SharedPreferences? _preferences;
  bool _initialized = false;
  bool _initializationFailed = false;
  bool _dismissed = false;
  bool _completed = false;
  int _displayCount = 0;
  DateTime? _lastShownAt;
  bool _displayRecordedForCurrentWindow = false;

  AppLockDiscoveryService({
    required this.appLockService,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance {
    appLockService.addListener(_onAppLockChanged);
  }

  bool get isInitialized => _initialized;
  bool get initializationFailed => _initializationFailed;
  bool get isPermanentlyDismissed => _dismissed;
  bool get isCompleted => _completed;
  int get displayCount => _displayCount;
  DateTime? get lastShownAt => _lastShownAt;

  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;

    _initializationFailed = false;
    try {
      final preferences = await _preferencesLoader();
      _preferences = preferences;
      _dismissed = preferences.getBool(dismissedKey) ?? false;
      _completed = preferences.getBool(completedKey) ?? false;
      _displayCount = _readDisplayCount(preferences.getInt(displayCountKey));
      _lastShownAt = _readTimestamp(preferences.getInt(lastShownKey));
      _displayRecordedForCurrentWindow = false;
      _initialized = true;

      if (appLockService.isEnabled && !_completed) {
        await markFeatureConfigured();
      } else {
        notifyListeners();
      }
    } catch (_) {
      // Discovery is optional. If preferences cannot be read, omit the
      // reminder without affecting the app-lock gate or app startup.
      _initialized = false;
      _initializationFailed = true;
      notifyListeners();
    }
  }

  bool canShow({DateTime? now}) {
    if (!_initialized ||
        _initializationFailed ||
        !appLockService.isInitialized ||
        appLockService.initializationFailed ||
        appLockService.isEnabled ||
        _dismissed ||
        _completed ||
        _displayCount >= maxDisplays) {
      return false;
    }

    final currentTime = now ?? DateTime.now();
    final lastShown = _lastShownAt;
    if (lastShown == null) return true;

    if (currentTime.isBefore(lastShown)) return false;
    if (currentTime.difference(lastShown) < reminderInterval) return false;

    _displayRecordedForCurrentWindow = false;
    return true;
  }

  /// Records one banner presentation. Repeated calls for the same reminder
  /// window do not increment the display count again.
  Future<void> recordDisplayed({DateTime? now}) async {
    if (!canShow(now: now) || _displayRecordedForCurrentWindow) return;

    final currentTime = now ?? DateTime.now();
    _displayRecordedForCurrentWindow = true;
    _displayCount = (_displayCount + 1).clamp(0, maxDisplays).toInt();
    _lastShownAt = currentTime;
    notifyListeners();

    final preferences = _preferences;
    if (preferences == null) return;
    try {
      await preferences.setInt(
        lastShownKey,
        currentTime.millisecondsSinceEpoch,
      );
      await preferences.setInt(displayCountKey, _displayCount);
    } catch (_) {
      // Keep the in-memory state for this process. A later launch may show
      // the reminder again if persistence was unavailable.
    }
  }

  Future<void> dismissPermanently() async {
    if (!_initialized) return;
    _dismissed = true;
    notifyListeners();

    try {
      await _preferences?.setBool(dismissedKey, true);
    } catch (_) {
      // The current process remains dismissed even if persistence fails.
    }
  }

  Future<void> markFeatureConfigured() async {
    if (!_initialized || _completed) return;
    _completed = true;
    notifyListeners();

    try {
      await _preferences?.setBool(completedKey, true);
    } catch (_) {
      // App Lock remains authoritative; this only affects future reminders.
    }
  }

  @override
  void dispose() {
    appLockService.removeListener(_onAppLockChanged);
    super.dispose();
  }

  void _onAppLockChanged() {
    if (!_initialized || !appLockService.isEnabled || _completed) {
      notifyListeners();
      return;
    }
    markFeatureConfigured();
  }

  int _readDisplayCount(int? value) {
    if (value == null || value < 0) return 0;
    return value.clamp(0, maxDisplays).toInt();
  }

  DateTime? _readTimestamp(int? value) {
    if (value == null || value <= 0) return null;
    try {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } catch (_) {
      return null;
    }
  }
}
