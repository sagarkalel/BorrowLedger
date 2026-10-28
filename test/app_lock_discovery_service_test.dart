import 'package:borrow_ledger/core/services/app_lock_discovery_service.dart';
import 'package:borrow_ledger/core/services/app_lock_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthenticator implements AppLockAuthenticator {
  bool authenticateResult = true;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    return authenticateResult;
  }
}

Future<({AppLockService appLock, AppLockDiscoveryService discovery})>
_createServices({
  Map<String, Object> initialValues = const {},
  bool appLockEnabled = false,
  Future<SharedPreferences> Function()? preferencesLoader,
}) async {
  SharedPreferences.setMockInitialValues({
    ...initialValues,
    if (appLockEnabled) AppLockService.preferenceKey: true,
  });
  final appLock = AppLockService(
    authenticator: _FakeAuthenticator(),
    preferencesLoader: SharedPreferences.getInstance,
  );
  await appLock.initialize();
  final discovery = AppLockDiscoveryService(
    appLockService: appLock,
    preferencesLoader: preferencesLoader ?? SharedPreferences.getInstance,
  );
  await discovery.initialize();
  return (appLock: appLock, discovery: discovery);
}

void main() {
  final start = DateTime(2026, 1, 1);

  test('fresh disabled installation can show the discovery banner', () async {
    final services = await _createServices();

    expect(services.discovery.canShow(now: start), isTrue);
    expect(services.discovery.displayCount, 0);
  });

  test(
    'recording a display is idempotent and snoozes for seven days',
    () async {
      final services = await _createServices();

      await services.discovery.recordDisplayed(now: start);
      await services.discovery.recordDisplayed(
        now: start.add(const Duration(minutes: 1)),
      );

      expect(services.discovery.displayCount, 1);
      expect(
        services.discovery.canShow(
          now: start.add(const Duration(days: 6, hours: 23)),
        ),
        isFalse,
      );
      expect(
        services.discovery.canShow(now: start.add(const Duration(days: 7))),
        isTrue,
      );
    },
  );

  test('reminders stop after three total displays', () async {
    final services = await _createServices();
    var current = start;

    for (
      var display = 0;
      display < AppLockDiscoveryService.maxDisplays;
      display++
    ) {
      expect(services.discovery.canShow(now: current), isTrue);
      await services.discovery.recordDisplayed(now: current);
      current = current.add(AppLockDiscoveryService.reminderInterval);
    }

    expect(services.discovery.displayCount, 3);
    expect(services.discovery.canShow(now: current), isFalse);
  });

  test('permanent dismissal suppresses future reminders', () async {
    final services = await _createServices();

    await services.discovery.dismissPermanently();

    expect(services.discovery.isPermanentlyDismissed, isTrue);
    expect(services.discovery.canShow(now: start), isFalse);
  });

  test('existing enabled App Lock completes discovery', () async {
    final services = await _createServices(appLockEnabled: true);

    expect(services.discovery.isCompleted, isTrue);
    expect(services.discovery.canShow(now: start), isFalse);
  });

  test(
    'successful setup completes discovery and later disabling does not remind',
    () async {
      final authenticator = _FakeAuthenticator();
      SharedPreferences.setMockInitialValues({});
      final appLock = AppLockService(
        authenticator: authenticator,
        preferencesLoader: SharedPreferences.getInstance,
      );
      await appLock.initialize();
      final discovery = AppLockDiscoveryService(
        appLockService: appLock,
        preferencesLoader: SharedPreferences.getInstance,
      );
      await discovery.initialize();

      await appLock.setEnabled(enabled: true, localizedReason: 'Enable');
      expect(discovery.isCompleted, isTrue);

      authenticator.authenticateResult = true;
      await appLock.setEnabled(enabled: false, localizedReason: 'Disable');
      expect(discovery.canShow(now: start), isFalse);
    },
  );

  test('cancelled setup does not complete discovery', () async {
    final services = await _createServices();
    final authenticator = _FakeAuthenticator()..authenticateResult = false;
    final appLock = AppLockService(
      authenticator: authenticator,
      preferencesLoader: SharedPreferences.getInstance,
    );
    await appLock.initialize();
    final discovery = AppLockDiscoveryService(
      appLockService: appLock,
      preferencesLoader: SharedPreferences.getInstance,
    );
    await discovery.initialize();

    await appLock.setEnabled(enabled: true, localizedReason: 'Enable');

    expect(discovery.isCompleted, isFalse);
    expect(discovery.canShow(now: start), isTrue);
    expect(services.discovery.canShow(now: start), isTrue);
  });

  test('preference read failure fails closed', () async {
    final appLock = AppLockService(
      preferencesLoader: SharedPreferences.getInstance,
    );
    await appLock.initialize();
    final discovery = AppLockDiscoveryService(
      appLockService: appLock,
      preferencesLoader: () async =>
          throw StateError('preferences unavailable'),
    );

    await discovery.initialize();

    expect(discovery.initializationFailed, isTrue);
    expect(discovery.canShow(now: start), isFalse);
  });

  test('unknown App Lock preference state suppresses the banner', () async {
    SharedPreferences.setMockInitialValues({});
    final appLock = AppLockService(
      preferencesLoader: () async =>
          throw StateError('preferences unavailable'),
    );
    await appLock.initialize();
    final discovery = AppLockDiscoveryService(
      appLockService: appLock,
      preferencesLoader: SharedPreferences.getInstance,
    );
    await discovery.initialize();

    expect(discovery.canShow(now: start), isFalse);
  });

  test('clock rollback does not show the banner immediately', () async {
    final services = await _createServices();
    await services.discovery.recordDisplayed(now: start);

    expect(
      services.discovery.canShow(now: start.subtract(const Duration(days: 1))),
      isFalse,
    );
  });

  test('invalid stored values are normalized safely', () async {
    final services = await _createServices(
      initialValues: {
        AppLockDiscoveryService.displayCountKey: -4,
        AppLockDiscoveryService.lastShownKey: -1,
      },
    );

    expect(services.discovery.displayCount, 0);
    expect(services.discovery.canShow(now: start), isTrue);
  });
}
