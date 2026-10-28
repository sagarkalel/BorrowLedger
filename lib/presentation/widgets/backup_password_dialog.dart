import 'package:borrow_ledger/core/services/backup_crypto_service.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_dialog_components.dart';

class BackupPasswordDialog extends StatefulWidget {
  final bool confirmation;
  final bool importing;

  const BackupPasswordDialog({
    super.key,
    this.confirmation = true,
    this.importing = false,
  });

  @override
  State<BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<BackupPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _submit() {
    final tr = AppLocalizations.of(context)!;
    final password = _passwordController.text;
    final requiresConfirmation = !widget.importing && widget.confirmation;
    final validationError = const BackupCryptoService().validatePassword(
      password,
    );
    if (validationError != null) {
      setState(() {
        _error = password.trim().isEmpty
            ? tr.backupPasswordRequired
            : tr.backupPasswordTooShort;
      });
      return;
    }
    if (requiresConfirmation && password != _confirmationController.text) {
      setState(() => _error = tr.backupPasswordsDoNotMatch);
      return;
    }
    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final requiresConfirmation = !widget.importing && widget.confirmation;

    return AppDialogShell(
      icon: const AppDialogIcon(
        icon: Icons.lock_outline_rounded,
        color: AppTheme.warningColor,
      ),
      title: widget.importing
          ? tr.importBackupPasswordTitle
          : tr.backupPasswordTitle,
      content: [
        Text(
          widget.importing
              ? tr.backupPasswordRequiredForRestore
              : tr.backupPasswordRecommendation,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          autofocus: true,
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            labelText: tr.backupPasswordLabel,
            hintText: tr.backupPasswordHint,
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
            ),
          ),
        ),
        if (requiresConfirmation) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _confirmationController,
            obscureText: _obscurePassword,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: tr.confirmBackupPasswordLabel,
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 12),
        AppDialogNotice(
          color: AppTheme.warningColor,
          child: Text(
            tr.backupPasswordCannotBeRecovered,
            style: const TextStyle(fontSize: 12, height: 1.35),
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
            onPressed: _submit,
            child: Text(widget.importing ? tr.unlockBackup : tr.encryptBackup),
          ),
        ),
      ],
    );
  }
}
