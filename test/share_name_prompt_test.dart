import 'package:borrow_ledger/data/repositories/user_profile_repository.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/share_name_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _testApp(Widget child, UserProfileRepository repository) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: RepositoryProvider.value(value: repository, child: child),
  );
}

void main() {
  testWidgets('name-only prompt saves the name and preserves profile data', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'user_profile_phone': '9876543210',
      'user_profile_upi_id': 'sagar@bank',
    });
    final repository = UserProfileRepository();
    String? savedName;

    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              savedName = await ensureShareOwnerName(
                context,
                requirePhone: false,
              );
            },
            child: const Text('Open'),
          ),
        ),
        repository,
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.text('Used in messages shared outside HisaabMate'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Sagar');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final profile = await repository.getProfile();
    expect(savedName, 'Sagar');
    expect(profile.name, 'Sagar');
    expect(profile.phone, '9876543210');
    expect(profile.upiId, 'sagar@bank');
  });
}
