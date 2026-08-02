import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_dialog_components.dart';

class ClearDataDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ClearDataDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return AppDialogShell(
      icon: const AppDialogIcon(
        icon: Icons.warning_amber_rounded,
        color: AppTheme.errorColor,
      ),
      title: tr.clearAllDataTitle,
      content: [
        AppDialogNotice(
          color: AppTheme.errorColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.thisWillPermanentlyDelete,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 10),
              AppDialogBullet(
                text: tr.allTransactionsItem,
                color: AppTheme.errorColor,
              ),
              AppDialogBullet(
                text: tr.allExpensesItem,
                color: AppTheme.errorColor,
              ),
              AppDialogBullet(
                text: tr.allSplitExpensesItem,
                color: AppTheme.errorColor,
              ),
              AppDialogBullet(
                text: tr.allContactReferencesItem,
                color: AppTheme.errorColor,
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
                  tr.considerExportingDataFirst,
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
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(tr.delete),
          ),
        ),
      ],
    );
  }
}
