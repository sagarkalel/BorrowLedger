import 'package:borrow_ledger/core/utils/form_input_utils.dart';
import 'package:borrow_ledger/data/models/user_profile_model.dart';
import 'package:borrow_ledger/data/repositories/user_profile_repository.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_dialog_components.dart';
import 'custom_text_field.dart';

Future<String?> ensureShareOwnerName(BuildContext context) async {
  final repository = context.read<UserProfileRepository>();
  final profile = await repository.getProfile();
  final hasCompleteShareProfile =
      profile.hasName &&
      (profile.phone?.trim().isNotEmpty ?? false) &&
      FormInputUtils.isValidOptionalPhone(profile.phone);
  if (hasCompleteShareProfile) return profile.name.trim();
  if (!context.mounted) return null;

  final updatedProfile = await showDialog<UserProfileModel>(
    context: context,
    builder: (_) =>
        _ShareNameDialog(initialProfile: profile, repository: repository),
  );

  return updatedProfile?.name.trim();
}

class _ShareNameDialog extends StatefulWidget {
  final UserProfileModel initialProfile;
  final UserProfileRepository repository;

  const _ShareNameDialog({
    required this.initialProfile,
    required this.repository,
  });

  @override
  State<_ShareNameDialog> createState() => _ShareNameDialogState();
}

class _ShareNameDialogState extends State<_ShareNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile.name);
    _phoneController = TextEditingController(text: widget.initialProfile.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialogShell(
      icon: AppDialogIcon(
        icon: Icons.person_outline_rounded,
        color: colorScheme.primary,
      ),
      title: tr.yourProfile,
      content: [
        Text(
          tr.nameUsedInSharedSplits,
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _nameController,
                labelText: tr.yourNameRequired,
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr.pleaseEnterYourName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: _phoneController,
                labelText: '${tr.phoneNumber} *',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: FormInputUtils.phoneInputFormatters,
                validator: (value) {
                  final phone = value?.trim() ?? '';
                  if (phone.isEmpty) return tr.pleaseEnterPhoneNumber;
                  if (!FormInputUtils.isValidOptionalPhone(phone)) {
                    return tr.invalidPhone;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
      actions: [
        Expanded(
          child: TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: Text(tr.cancel),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(tr.save),
          ),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final profile = widget.initialProfile.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    await widget.repository.saveProfile(profile);

    if (!mounted) return;
    Navigator.pop(context, profile);
  }
}
