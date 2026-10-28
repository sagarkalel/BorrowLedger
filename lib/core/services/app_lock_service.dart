import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLockAuthStatus {
  authenticated,
  cancelled,
  unavailable,
  lockedOut,
  failed,
}

class AppLockAuthResult {
  final AppLockAuthStatus status;

  const AppLockAuthResult(this.status);

  bool get isAuthenticated => status == AppLockAuthStatus.authenticated;
}

abstract class AppLockAuthenticator {
  Future<bool> isDeviceSupported();

  Future<bool> authenticate({required String localizedReason});
}

class LocalAuthAuthenticator implements AppLockAuthenticator {
  final LocalAuthentication _localAuthentication;

  LocalAuthAuthenticator({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  @override
  Future<bool> isDeviceSupported() {
    return _localAuthentication.isDeviceSupported();
  }

  @override
  Future<bool> authenticate({required String localizedReason}) {
    return _localAuthentication.authenticate(
      localizedReason: localizedReason,
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
        useErrorDialogs: false,
        sensitiveTransaction: true,
      ),
    );
  }
}

/// Stores only whether app lock is enabled and delegates credentials to the OS.
class AppLockService extends ChangeNotifier {
  static const String preferenceKey = 'app_lock_enabled';

  static final AppLockService instance = AppLockService();

  final AppLockAuthenticator _authenticator;
  final Future<SharedPreferences> Function() _preferencesLoader;

  SharedPreferences? _preferences;
  bool _enabled = false;
  bool _initialized = false;
  bool _initializationFailed = false;

  AppLockService({
    AppLockAuthenticator? authenticator,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _authenticator = authenticator ?? LocalAuthAuthenticator(),
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  bool get isEnabled => _enabled;
  bool get isInitialized => _initialized;
  bool get initializationFailed => _initializationFailed;

  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;

    _initializationFailed = false;
    try {
      final preferences = await _preferencesLoader();
      _preferences = preferences;
      _enabled = preferences.getBool(preferenceKey) ?? false;
      _initialized = true;
      notifyListeners();
    } catch (_) {
      // Do not silently disable a previously configured lock when preferences
      // cannot be read. The gate presents a retryable security error instead.
      _initialized = false;
      _initializationFailed = true;
      notifyListeners();
    }
  }

  Future<AppLockAuthResult> authenticate({
    required String localizedReason,
  }) async {
    try {
      if (!await _authenticator.isDeviceSupported()) {
        return const AppLockAuthResult(AppLockAuthStatus.unavailable);
      }

      final authenticated = await _authenticator.authenticate(
        localizedReason: localizedReason,
      );
      return AppLockAuthResult(
        authenticated
            ? AppLockAuthStatus.authenticated
            : AppLockAuthStatus.cancelled,
      );
    } on PlatformException catch (error) {
      if (error.code == auth_error.lockedOut ||
          error.code == auth_error.permanentlyLockedOut) {
        return const AppLockAuthResult(AppLockAuthStatus.lockedOut);
      }
      if (error.code == auth_error.notAvailable ||
          error.code == auth_error.notEnrolled ||
          error.code == auth_error.passcodeNotSet ||
          error.code == auth_error.otherOperatingSystem) {
        return const AppLockAuthResult(AppLockAuthStatus.unavailable);
      }
      return const AppLockAuthResult(AppLockAuthStatus.failed);
    } catch (_) {
      return const AppLockAuthResult(AppLockAuthStatus.failed);
    }
  }

  Future<AppLockAuthResult> setEnabled({
    required bool enabled,
    required String localizedReason,
  }) async {
    if (!_initialized || _preferences == null) {
      return const AppLockAuthResult(AppLockAuthStatus.failed);
    }

    final result = await authenticate(localizedReason: localizedReason);
    if (!result.isAuthenticated) return result;

    try {
      final saved = await _preferences!.setBool(preferenceKey, enabled);
      if (!saved) {
        return const AppLockAuthResult(AppLockAuthStatus.failed);
      }
      _enabled = enabled;
      notifyListeners();
      return result;
    } catch (_) {
      return const AppLockAuthResult(AppLockAuthStatus.failed);
    }
  }
}
