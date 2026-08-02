import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_dialog_components.dart';

class ExportDataDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ExportDataDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return AppDialogShell(
      icon: const AppDialogIcon(
        icon: Icons.cloud_upload_rounded,
        color: AppTheme.successColor,
      ),
      title: tr.exportData,
      content: [
        Text(
          tr.exportDataMessage,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        AppDialogNotice(
          color: AppTheme.successColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.whatWillBeExported,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: 10),
              AppDialogBullet(
                text: tr.allTransactionsLendBorrow,
                color: AppTheme.successColor,
              ),
              AppDialogBullet(
                text: tr.allPersonalExpenses,
                color: AppTheme.successColor,
              ),
              AppDialogBullet(
                text: tr.allSplitExpenses,
                color: AppTheme.successColor,
              ),
              AppDialogBullet(
                text: tr.contactReferences,
                color: AppTheme.successColor,
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
                  tr.canShareBackupFile,
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
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(tr.export),
          ),
        ),
      ],
    );
  }
}
