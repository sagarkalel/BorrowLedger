import 'dart:typed_data';

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/core/services/contact_avatar_service.dart';
import 'package:borrow_ledger/core/services/upi_service.dart';
import 'package:borrow_ledger/core/utils/form_input_utils.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/contact_model.dart';
import '../widgets/custom_text_field.dart';

enum _AvatarAction { camera, gallery, remove }

class ContactEditScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String? email;
  final Uint8List? photo;
  final String? avatar;
  final ContactModel? existingContact;

  const ContactEditScreen({
    super.key,
    required this.name,
    required this.phone,
    this.email,
    this.photo,
    this.avatar,
    this.existingContact,
  });

  @override
  State<ContactEditScreen> createState() => _ContactEditScreenState();
}

class _ContactEditScreenState extends State<ContactEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _upiIdController;
  Uint8List? _photo;
  String? _avatar;
  bool _photoChanged = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _phoneController = TextEditingController(text: widget.phone);
    _emailController = TextEditingController(text: widget.email ?? '');
    _upiIdController = TextEditingController(
      text: widget.existingContact?.upiId ?? '',
    );
    _photo = widget.photo;
    _avatar = widget.avatar;
    // A new contact may arrive with a native phone photo that still needs to
    // be persisted. An existing saved avatar should remain untouched unless
    // the user explicitly changes or removes it.
    _photoChanged = widget.avatar == null && widget.photo != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    final isEditingExistingContact = widget.existingContact?.id != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isEditingExistingContact ? tr.editContact : tr.reviewContact,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showAvatarOptions,
                      child: CircleAvatar(
                        radius: 42,
                        backgroundImage: _photo != null
                            ? MemoryImage(_photo!)
                            : null,
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: isDark ? 0.18 : 0.1,
                        ),
                        child: _photo == null
                            ? Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showAvatarOptions,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEditingExistingContact
                            ? tr.editSavedContactDetails
                            : tr.reviewAndEditContactDetails,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Text(
                tr.contactDetails,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _nameController,
                labelText: tr.name,
                hintText: tr.enterContactName,
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                isDense: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr.pleaseEnterContactName;
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _phoneController,
                labelText: tr.phoneNumber,
                hintText: tr.enterPhoneNumber,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: FormInputUtils.phoneInputFormatters,
                isDense: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr.pleaseEnterPhoneNumber;
                  }
                  if (!FormInputUtils.isValidOptionalPhone(value)) {
                    return tr.invalidPhone;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _upiIdController,
                labelText: tr.upiIdOptional,
                hintText: tr.enterUpiId,
                prefixIcon: Icons.payments_outlined,
                keyboardType: TextInputType.emailAddress,
                isDense: true,
                validator: (value) {
                  final upiId = value?.trim() ?? '';
                  if (upiId.isEmpty) return null;
                  if (!UpiService.isValidUpiId(upiId)) {
                    return tr.invalidUpiId;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _emailController,
                labelText: tr.emailOptional,
                hintText: tr.enterEmailAddress,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                isDense: true,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!value.contains('@') || !value.contains('.')) {
                      return tr.pleaseEnterValidEmail;
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(tr.cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveContact,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isEditingExistingContact
                                ? tr.update
                                : tr.addContact,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAvatarOptions() async {
    final tr = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr.changePhoto,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        sheetContext,
                      ).closeButtonTooltip,
                      icon: const Icon(Icons.close_rounded),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAvatarActionTile(
                  context: sheetContext,
                  icon: Icons.photo_camera_rounded,
                  title: tr.takePhoto,
                  color: colorScheme.primary,
                  onTap: () =>
                      Navigator.pop(sheetContext, _AvatarAction.camera),
                ),
                const SizedBox(height: 8),
                _buildAvatarActionTile(
                  context: sheetContext,
                  icon: Icons.photo_library_rounded,
                  title: tr.chooseFromGallery,
                  color: colorScheme.tertiary,
                  onTap: () =>
                      Navigator.pop(sheetContext, _AvatarAction.gallery),
                ),
                if (_photo != null || _avatar?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  _buildAvatarActionTile(
                    context: sheetContext,
                    icon: Icons.delete_outline_rounded,
                    title: tr.removePhoto,
                    color: colorScheme.error,
                    onTap: () =>
                        Navigator.pop(sheetContext, _AvatarAction.remove),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (action == null) return;
    if (action == _AvatarAction.remove) {
      setState(() {
        _photo = null;
        _avatar = null;
        _photoChanged = true;
      });
      return;
    }

    try {
      final imageSource = action == _AvatarAction.camera
          ? ImageSource.camera
          : ImageSource.gallery;
      final picked = await ImagePicker().pickImage(source: imageSource);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _avatar = null;
        _photoChanged = true;
      });
    } catch (e) {
      if (mounted) {
        showFailureSnackbar(context, '${tr.failedToUpdatePhoto}: $e');
      }
    }
  }

  Widget _buildAvatarActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Icon(icon, color: color, size: 21),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveContact() async {
    if (_formKey.currentState!.validate()) {
      final tr = AppLocalizations.of(context)!;
      setState(() => _isSaving = true);

      String? avatarData = _avatar;
      if (_photoChanged && _photo != null) {
        try {
          avatarData = await ContactAvatarService.instance.saveAvatarBytes(
            _photo!,
            oldAvatar: widget.avatar,
            nameHint: _nameController.text.trim(),
          );
          if (avatarData == null) {
            if (mounted) {
              showWarningSnackbar(context, tr.photoCouldNotBeSaved);
              setState(() => _isSaving = false);
            }
            return;
          }
        } catch (e) {
          if (mounted) {
            showWarningSnackbar(context, tr.photoCouldNotBeSaved);
            setState(() => _isSaving = false);
          }
          return;
        }
      } else if (_photoChanged && _photo == null) {
        await ContactAvatarService.instance.deleteAvatar(widget.avatar);
      }

      final existingContact = widget.existingContact;
      final contact = ContactModel(
        id: existingContact?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        upiId: UpiService.normalizeUpiId(_upiIdController.text),
        avatar: avatarData,
        createdAt: existingContact?.createdAt,
        updatedAt: existingContact?.updatedAt,
      );

      if (mounted) Navigator.pop(context, contact);
    }
  }
}
