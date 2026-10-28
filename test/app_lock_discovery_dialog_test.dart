import 'package:borrow_ledger/core/services/app_lock_discovery_service.dart';
import 'package:borrow_ledger/core/services/app_lock_service.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/app_lock_discovery_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthenticator implements AppLockAuthenticator {
  int authenticateCalls = 0;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    authenticateCalls++;
    return true;
  }
}

Future<
  ({
    AppLockService appLock,
    AppLockDiscoveryService discovery,
    _FakeAuthenticator authenticator,
  })
>
_createServices() async {
  SharedPreferences.setMockInitialValues({});
  final authenticator = _FakeAuthenticator();
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
  return (appLock: appLock, discovery: discovery, authenticator: authenticator);
}

Widget _testApp({
  required AppLockDiscoveryService discovery,
  required VoidCallback onSetup,
  ThemeMode themeMode = ThemeMode.light,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    theme: ThemeData.light(useMaterial3: true),
    darkTheme: ThemeData.dark(useMaterial3: true),
    themeMode: themeMode,
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final action = await AppLockDiscoveryDialog.show(
                context,
                discoveryService: discovery,
              );
              if (action == AppLockDiscoveryDialogAction.setup) onSetup();
            },
            child: const Text('Open dialog'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Open dialog'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dialog presents a compact App Lock explanation', (tester) async {
    final services = await _createServices();

    await tester.pumpWidget(
      _testApp(discovery: services.discovery, onSetup: () {}),
    );
    await _openDialog(tester);

    expect(find.text('Protect your app'), findsOneWidget);
    expect(find.text('Set up now'), findsOneWidget);
    expect(find.text('Maybe later'), findsOneWidget);
    expect(
      find.text(
        'Use fingerprint, Face ID, or device credentials to protect your records. Enable it in Security.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Maybe later closes the dialog without authentication', (
    tester,
  ) async {
    final services = await _createServices();

    await tester.pumpWidget(
      _testApp(discovery: services.discovery, onSetup: () {}),
    );
    await _openDialog(tester);
    await tester.tap(find.text('Maybe later'));
    await tester.pumpAndSettle();

    expect(find.text('Protect your app'), findsNothing);
    expect(services.authenticator.authenticateCalls, 0);
  });

  testWidgets('Set up now returns setup without authenticating', (
    tester,
  ) async {
    final services = await _createServices();
    var setupCalls = 0;

    await tester.pumpWidget(
      _testApp(discovery: services.discovery, onSetup: () => setupCalls++),
    );
    await _openDialog(tester);
    await tester.tap(find.text('Set up now'));
    await tester.pumpAndSettle();

    expect(setupCalls, 1);
    expect(services.authenticator.authenticateCalls, 0);
  });

  testWidgets('Don’t show again permanently dismisses the dialog flow', (
    tester,
  ) async {
    final services = await _createServices();

    await tester.pumpWidget(
      _testApp(discovery: services.discovery, onSetup: () {}),
    );
    await _openDialog(tester);
    await tester.tap(find.byTooltip('More App Lock options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Don't show again"));
    await tester.pumpAndSettle();

    expect(find.text('Protect your app'), findsNothing);
    expect(services.discovery.isPermanentlyDismissed, isTrue);
  });

  testWidgets('dialog adapts to dark Marathi narrow layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final services = await _createServices();

    await tester.pumpWidget(
      _testApp(
        discovery: services.discovery,
        onSetup: () {},
        themeMode: ThemeMode.dark,
        locale: const Locale('mr'),
      ),
    );
    await _openDialog(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(AppLockDiscoveryDialog), findsOneWidget);
  });

  testWidgets('dialog contains no ledger-sensitive information', (
    tester,
  ) async {
    final services = await _createServices();

    await tester.pumpWidget(
      _testApp(discovery: services.discovery, onSetup: () {}),
    );
    await _openDialog(tester);

    expect(find.textContaining('₹'), findsNothing);
    expect(find.textContaining('balance'), findsNothing);
    expect(find.textContaining('contact'), findsNothing);
  });
}
