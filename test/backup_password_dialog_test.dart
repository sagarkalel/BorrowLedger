import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/backup_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _DialogHost extends StatefulWidget {
  final bool importing;

  const _DialogHost({required this.importing});

  @override
  State<_DialogHost> createState() => _DialogHostState();
}

class _DialogHostState extends State<_DialogHost> {
  bool _dialogCompleted = false;
  String? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (_) =>
                      BackupPasswordDialog(importing: widget.importing),
                );
                if (!mounted) return;
                setState(() {
                  _dialogCompleted = true;
                  _result = result;
                });
              },
              child: const Text('Open'),
            ),
            if (_dialogCompleted) Text(_result ?? 'cancelled'),
          ],
        ),
      ),
    );
  }
}

Widget _testApp({required bool importing}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: _DialogHost(importing: importing),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('import dialog has only one password field', (tester) async {
    await tester.pumpWidget(_testApp(importing: true));
    await _openDialog(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Confirm password'), findsNothing);
    expect(find.text('Unlock'), findsOneWidget);
  });

  testWidgets('export dialog keeps password confirmation', (tester) async {
    await tester.pumpWidget(_testApp(importing: false));
    await _openDialog(tester);

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Encrypt backup'), findsOneWidget);
  });

  testWidgets('import accepts one valid password without mismatch validation', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(importing: true));
    await _openDialog(tester);

    await tester.enterText(find.byType(TextField).first, 'correct password');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('correct password'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsNothing);
  });

  testWidgets('import rejects an empty or short password', (tester) async {
    await tester.pumpWidget(_testApp(importing: true));
    await _openDialog(tester);

    await tester.enterText(find.byType(TextField).first, 'short');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(
      find.text('Password must be at least 8 characters.'),
      findsOneWidget,
    );
    expect(find.text('Unlock'), findsOneWidget);
  });

  testWidgets('export rejects mismatched passwords', (tester) async {
    await tester.pumpWidget(_testApp(importing: false));
    await _openDialog(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'correct password');
    await tester.enterText(fields.at(1), 'different password');
    await tester.tap(find.text('Encrypt backup'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('cancelled import returns no password', (tester) async {
    await tester.pumpWidget(_testApp(importing: true));
    await _openDialog(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('cancelled'), findsOneWidget);
  });
}
