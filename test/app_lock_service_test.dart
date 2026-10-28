import 'package:borrow_ledger/core/services/app_lock_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthenticator implements AppLockAuthenticator {
  bool supported = true;
  bool authenticateResult = true;
  int authenticateCalls = 0;

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    authenticateCalls++;
    return authenticateResult;
  }
}

class _ErrorAuthenticator implements AppLockAuthenticator {
  final String code;

  const _ErrorAuthenticator(this.code);

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> authenticate({required String localizedReason}) {
    return Future<bool>.error(PlatformException(code: code));
  }
}

Future<AppLockService> _createService(_FakeAuthenticator authenticator) async {
  SharedPreferences.setMockInitialValues({});
  final service = AppLockService(
    authenticator: authenticator,
    preferencesLoader: SharedPreferences.getInstance,
  );
  await service.initialize();
  return service;
}

void main() {
  test('app lock is disabled by default', () async {
    final service = await _createService(_FakeAuthenticator());

    expect(service.isEnabled, isFalse);
  });

  test('enabling persists only after authentication succeeds', () async {
    final authenticator = _FakeAuthenticator();
    final service = await _createService(authenticator);

    final result = await service.setEnabled(
      enabled: true,
      localizedReason: 'Unlock test app',
    );

    expect(result.isAuthenticated, isTrue);
    expect(service.isEnabled, isTrue);
    expect(authenticator.authenticateCalls, 1);
  });

  test('cancelled authentication does not change the setting', () async {
    final authenticator = _FakeAuthenticator()..authenticateResult = false;
    final service = await _createService(authenticator);

    final result = await service.setEnabled(
      enabled: true,
      localizedReason: 'Unlock test app',
    );

    expect(result.status, AppLockAuthStatus.cancelled);
    expect(service.isEnabled, isFalse);
  });

  test('disabling also requires successful authentication', () async {
    final authenticator = _FakeAuthenticator();
    final service = await _createService(authenticator);
    await service.setEnabled(enabled: true, localizedReason: 'Enable');

    authenticator.authenticateResult = false;
    final cancelled = await service.setEnabled(
      enabled: false,
      localizedReason: 'Disable',
    );
    expect(cancelled.isAuthenticated, isFalse);
    expect(service.isEnabled, isTrue);

    authenticator.authenticateResult = true;
    final disabled = await service.setEnabled(
      enabled: false,
      localizedReason: 'Disable',
    );
    expect(disabled.isAuthenticated, isTrue);
    expect(service.isEnabled, isFalse);
  });

  test('unsupported device does not enable app lock', () async {
    final authenticator = _FakeAuthenticator()..supported = false;
    final service = await _createService(authenticator);

    final result = await service.setEnabled(
      enabled: true,
      localizedReason: 'Enable',
    );

    expect(result.status, AppLockAuthStatus.unavailable);
    expect(service.isEnabled, isFalse);
    expect(authenticator.authenticateCalls, 0);
  });

  test('biometric lockout is returned as a retryable auth status', () async {
    final service = AppLockService(
      authenticator: const _ErrorAuthenticator('LockedOut'),
      preferencesLoader: SharedPreferences.getInstance,
    );
    await service.initialize();

    final result = await service.authenticate(localizedReason: 'Unlock');

    expect(result.status, AppLockAuthStatus.lockedOut);
  });
}
