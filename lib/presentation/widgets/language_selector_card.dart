import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/locale_cubit.dart';

/// Compact language selector card for settings drawer
class LanguageSelectorCard extends StatelessWidget {
  final ColorScheme colorScheme;

  const LanguageSelectorCard({super.key, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                _buildLanguageOption(
                  context,
                  '🇬🇧',
                  tr.english,
                  'en',
                  locale.languageCode,
                  colorScheme,
                  tr,
                ),
                Divider(
                  height: 1,
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                _buildLanguageOption(
                  context,
                  '🇮🇳',
                  tr.hindi,
                  'hi',
                  locale.languageCode,
                  colorScheme,
                  tr,
                ),
                Divider(
                  height: 1,
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                _buildLanguageOption(
                  context,
                  '🇮🇳',
                  tr.marathi,
                  'mr',
                  locale.languageCode,
                  colorScheme,
                  tr,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String flag,
    String label,
    String languageCode,
    String currentLanguage,
    ColorScheme colorScheme,
    AppLocalizations tr,
  ) {
    final isSelected = languageCode == currentLanguage;

    return InkWell(
      onTap: () {
        context.read<LocaleCubit>().setLocale(languageCode);
        showSuccessSnackbar(context, '${tr.languageChangedTo} $label');
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Center(
                child: Text(flag, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: colorScheme.primary,
                size: 20,
              )
            else
              const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
