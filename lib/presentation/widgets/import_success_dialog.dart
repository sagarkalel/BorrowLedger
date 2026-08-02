import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_dialog_components.dart';

class ImportSuccessDialog extends StatelessWidget {
  final int transactionsCount;
  final int splitsCount;
  final int expensesCount;
  final VoidCallback onRestart;

  const ImportSuccessDialog({
    super.key,
    required this.transactionsCount,
    required this.splitsCount,
    required this.expensesCount,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return AppDialogShell(
      icon: const AppDialogIcon(
        icon: Icons.check_circle_rounded,
        color: AppTheme.successColor,
      ),
      title: tr.importSuccessful,
      content: [
        AppDialogNotice(
          color: AppTheme.successColor,
          child: Column(
            children: [
              Text(
                tr.successfullyImported,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(context, transactionsCount, tr.trans),
                  _buildStat(context, splitsCount, tr.splits),
                  _buildStat(context, expensesCount, tr.exp),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppDialogNotice(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr.restartRecommended,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      actions: [
        Expanded(
          child: FilledButton(onPressed: onRestart, child: Text(tr.done)),
        ),
      ],
    );
  }

  Widget _buildStat(BuildContext context, int value, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.successColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
