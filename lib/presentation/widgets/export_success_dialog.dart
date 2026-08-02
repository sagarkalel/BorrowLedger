import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_dialog_components.dart';

class ExportSuccessDialog extends StatelessWidget {
  final String fileName;
  final int transactionsCount;
  final int splitsCount;
  final int expensesCount;
  final VoidCallback onShare;

  const ExportSuccessDialog({
    super.key,
    required this.fileName,
    required this.transactionsCount,
    required this.splitsCount,
    required this.expensesCount,
    required this.onShare,
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
      title: tr.exportSuccessful,
      content: [
        AppDialogNotice(
          child: Column(
            children: [
              Icon(Icons.folder_rounded, color: colorScheme.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                fileName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                tr.savedInBackupsFolder,
                style: TextStyle(
                  fontSize: 11.5,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppDialogNotice(
          color: AppTheme.successColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                context,
                transactionsCount,
                tr.trans,
                Icons.swap_horiz_rounded,
              ),
              _buildStat(
                context,
                splitsCount,
                tr.splits,
                Icons.pie_chart_rounded,
              ),
              _buildStat(
                context,
                expensesCount,
                tr.exp,
                Icons.receipt_long_rounded,
              ),
            ],
          ),
        ),
      ],
      actions: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr.close),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share_rounded, size: 18),
            label: Text(tr.share),
          ),
        ),
      ],
    );
  }

  Widget _buildStat(
    BuildContext context,
    int value,
    String label,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppTheme.successColor),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
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
