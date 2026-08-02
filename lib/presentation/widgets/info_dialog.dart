import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_dialog_components.dart';

class InfoDialog extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const InfoDialog({
    super.key,
    required this.title,
    required this.content,
    this.icon = Icons.info_outline_rounded,
    this.color = AppTheme.infoColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return AppDialogShell(
      icon: AppDialogIcon(icon: icon, color: color),
      title: title,
      content: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
      actions: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(tr.gotIt),
          ),
        ),
      ],
    );
  }
}
