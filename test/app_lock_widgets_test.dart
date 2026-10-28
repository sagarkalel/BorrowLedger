import 'package:borrow_ledger/core/services/app_lock_service.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/app_lock_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthenticator implements AppLockAuthenticator {
  bool authenticateResult = true;
  int authenticateCalls = 0;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    authenticateCalls++;
    return authenticateResult;
  }
}

Future<AppLockService> _enabledService(_FakeAuthenticator authenticator) async {
  SharedPreferences.setMockInitialValues({AppLockService.preferenceKey: true});
  final service = AppLockService(
    authenticator: authenticator,
    preferencesLoader: SharedPreferences.getInstance,
  );
  await service.initialize();
  return service;
}

Widget _testApp({
  required AppLockService service,
  required DateTime Function() now,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: AppLockGate(
      service: service,
      now: now,
      child: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => AppLockGate.of(context)?.markAppReady(),
              child: const Text('Ready'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('successful unlock restores the app', (tester) async {
    final authenticator = _FakeAuthenticator();
    final service = await _enabledService(authenticator);
    var currentTime = DateTime(2026, 1, 1);

    await tester.pumpWidget(_testApp(service: service, now: () => currentTime));
    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();

    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('App locked'), findsNothing);
    expect(authenticator.authenticateCalls, 1);
  });

  testWidgets('cancelled unlock remains locked and can be retried', (
    tester,
  ) async {
    final authenticator = _FakeAuthenticator()..authenticateResult = false;
    final service = await _enabledService(authenticator);
    var currentTime = DateTime(2026, 1, 1);

    await tester.pumpWidget(_testApp(service: service, now: () => currentTime));
    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();

    expect(find.text('App locked'), findsOneWidget);
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('App locked'), findsOneWidget);
    expect(authenticator.authenticateCalls, 2);
  });

  testWidgets('brief backgrounding does not prompt again', (tester) async {
    final authenticator = _FakeAuthenticator();
    final service = await _enabledService(authenticator);
    var currentTime = DateTime(2026, 1, 1);

    await tester.pumpWidget(_testApp(service: service, now: () => currentTime));
    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();
    expect(authenticator.authenticateCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    currentTime = currentTime.add(const Duration(seconds: 30));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(authenticator.authenticateCalls, 1);
  });

  testWidgets('backgrounding for one minute requires authentication', (
    tester,
  ) async {
    final authenticator = _FakeAuthenticator();
    final service = await _enabledService(authenticator);
    var currentTime = DateTime(2026, 1, 1);

    await tester.pumpWidget(_testApp(service: service, now: () => currentTime));
    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    currentTime = currentTime.add(const Duration(minutes: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(authenticator.authenticateCalls, 2);
    expect(find.text('App locked'), findsNothing);
  });
}
