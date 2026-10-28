import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_dialog_components.dart';

class LegacyBackupWarningDialog extends StatelessWidget {
  const LegacyBackupWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return AppDialogShell(
      icon: const AppDialogIcon(
        icon: Icons.lock_open_rounded,
        color: AppTheme.warningColor,
      ),
      title: tr.legacyBackupTitle,
      content: [
        AppDialogNotice(
          color: AppTheme.warningColor,
          child: Text(
            tr.legacyBackupWarning,
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
        ),
      ],
      actions: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.cancel),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr.continueImport),
          ),
        ),
      ],
    );
  }
}
