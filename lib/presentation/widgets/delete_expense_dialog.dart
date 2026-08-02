import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_dialog_components.dart';

class DeleteExpenseDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const DeleteExpenseDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return AppDialogShell(
      icon: const AppDialogIcon(
        icon: Icons.delete_forever_rounded,
        color: AppTheme.errorColor,
      ),
      title: tr.deleteExpenseTitle,
      content: [
        Text(
          tr.thisActionCannotBeUndone,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
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
