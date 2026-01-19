import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/cubit/borrow_lend_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/contact_repository.dart';
import 'data/repositories/expense_repository.dart';
import 'data/repositories/split_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'presentation/cubit/contact_cubit.dart';
import 'presentation/cubit/expense_cubit.dart';
import 'presentation/cubit/locale_cubit.dart';
import 'presentation/cubit/split_cubit.dart';
import 'presentation/cubit/theme_cubit.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BorrowLedgerApp());
}

class BorrowLedgerApp extends StatelessWidget {
  const BorrowLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => TransactionRepository()),
        RepositoryProvider(create: (context) => ContactRepository()),
        RepositoryProvider(create: (context) => ExpenseRepository()),
        RepositoryProvider(create: (context) => SplitRepository()),
      ],
      child: Builder(
        builder: (context) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => ThemeCubit()),
              BlocProvider(create: (context) => LocaleCubit()),
              BlocProvider(
                create: (_) =>
                    BorrowLendCubit(context.read<TransactionRepository>()),
              ),
              BlocProvider(
                create: (context) =>
                    ContactCubit(context.read<ContactRepository>()),
              ),
              BlocProvider(
                create: (context) =>
                    ExpenseCubit(context.read<ExpenseRepository>()),
              ),
              BlocProvider(
                create: (context) =>
                    SplitCubit(context.read<SplitRepository>()),
              ),
            ],
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return BlocBuilder<LocaleCubit, Locale>(
                  builder: (context, locale) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        FocusScopeNode currentFocus = FocusScope.of(context);
                        if (!currentFocus.hasPrimaryFocus &&
                            currentFocus.focusedChild != null) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        }
                      },
                      child: MaterialApp(
                        title: tr?.appName,
                        debugShowCheckedModeBanner: false,

                        // Localization configuration
                        locale: locale,
                        localizationsDelegates: const [
                          AppLocalizations.delegate,
                          GlobalMaterialLocalizations.delegate,
                          GlobalWidgetsLocalizations.delegate,
                          GlobalCupertinoLocalizations.delegate,
                        ],
                        supportedLocales: const [
                          Locale('en'), // English
                          Locale('hi'), // Hindi
                          Locale('mr'), // Marathi
                        ],
                        localeResolutionCallback: (locale, supportedLocales) {
                          if (locale == null) {
                            return supportedLocales.first;
                          }

                          // Check if device locale is supported
                          for (var supportedLocale in supportedLocales) {
                            if (supportedLocale.languageCode ==
                                locale.languageCode) {
                              return supportedLocale;
                            }
                          }

                          // Fallback to English
                          return supportedLocales.first;
                        },

                        theme: AppTheme.lightTheme,
                        darkTheme: AppTheme.darkTheme,
                        themeMode: themeMode,
                        home: const SplashScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
