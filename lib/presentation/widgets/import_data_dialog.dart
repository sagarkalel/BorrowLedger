import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_dialog_components.dart';

class ImportDataDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ImportDataDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return AppDialogShell(
      icon: const AppDialogIcon(
        icon: Icons.warning_amber_rounded,
        color: AppTheme.warningColor,
      ),
      title: tr.importData,
      content: [
        AppDialogNotice(
          color: AppTheme.warningColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: AppTheme.warningColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr.thisWillReplaceAllDataWarning,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                tr.currentDataWillBePermanentlyDeleted,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              AppDialogBullet(
                text: tr.allTransactionsDeleted,
                color: AppTheme.warningColor,
              ),
              AppDialogBullet(
                text: tr.allExpensesDeleted,
                color: AppTheme.warningColor,
              ),
              AppDialogBullet(
                text: tr.allSplitsDeleted,
                color: AppTheme.warningColor,
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
                  tr.makeSureHaveBackup,
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
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr.cancel),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(tr.proceed),
          ),
        ),
      ],
    );
  }
}
