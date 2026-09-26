import 'package:borrow_ledger/core/services/upi_service.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum UpiIdSetupOwner { contact, profile }

Future<bool?> showUpiIdSetupSheet(
  BuildContext context, {
  required UpiIdSetupOwner owner,
  required String displayName,
  String? initialUpiId,
  required Future<bool> Function(String upiId) onSave,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _UpiIdSetupSheet(
      owner: owner,
      displayName: displayName,
      initialUpiId: initialUpiId,
      onSave: onSave,
    ),
  );
}

class _UpiIdSetupSheet extends StatefulWidget {
  final UpiIdSetupOwner owner;
  final String displayName;
  final String? initialUpiId;
  final Future<bool> Function(String upiId) onSave;

  const _UpiIdSetupSheet({
    required this.owner,
    required this.displayName,
    required this.initialUpiId,
    required this.onSave,
  });

  @override
  State<_UpiIdSetupSheet> createState() => _UpiIdSetupSheetState();
}

class _UpiIdSetupSheetState extends State<_UpiIdSetupSheet> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUpiId ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isContact = widget.owner == UpiIdSetupOwner.contact;
    final title = isContact
        ? tr.addContactUpiId(widget.displayName)
        : tr.addYourUpiId;
    final description = isContact
        ? tr.requiredToPayThroughUpi
        : tr.requiredToRequestMoney;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            6,
            20,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.payments_outlined,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: tr.upiId,
                    hintText: tr.enterUpiId,
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (value) {
                    if (!UpiService.isValidUpiId(value)) {
                      return tr.invalidUpiId;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context, false),
                        child: Text(tr.notNow),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(tr.saveAndContinue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final success = await widget.onSave(
      UpiService.normalizeUpiId(_controller.text)!,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _isSaving = false);
    }
  }
}
