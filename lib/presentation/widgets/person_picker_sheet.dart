import 'package:borrow_ledger/core/utils/form_input_utils.dart';
import 'package:borrow_ledger/data/models/contact_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/screens/contact_picker_screen.dart';
import 'package:flutter/material.dart';

import 'app_dialog_components.dart';
import 'custom_text_field.dart';
import 'empty_state_widget.dart';
import 'app_loading_state.dart';

enum _PersonPickerMode { people, manual }

class PersonPickerResult {
  final ContactModel contact;
  final bool isManual;

  const PersonPickerResult({required this.contact, required this.isManual});
}

Future<PersonPickerResult?> showPersonPickerSheet({
  required BuildContext context,
  required List<ContactModel> contacts,
  ContactModel? selectedContact,
  String? manualName,
  String? manualPhone,
}) {
  return showModalBottomSheet<PersonPickerResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PersonPickerSheet(
      contacts: contacts,
      selectedContact: selectedContact,
      manualName: manualName,
      manualPhone: manualPhone,
    ),
  );
}

class PersonPickerSheet extends StatefulWidget {
  final List<ContactModel> contacts;
  final ContactModel? selectedContact;
  final String? manualName;
  final String? manualPhone;

  const PersonPickerSheet({
    super.key,
    required this.contacts,
    this.selectedContact,
    this.manualName,
    this.manualPhone,
  });

  @override
  State<PersonPickerSheet> createState() => _PersonPickerSheetState();
}

class _PersonPickerSheetState extends State<PersonPickerSheet> {
  late final TextEditingController _searchController;
  late final TextEditingController _manualNameController;
  late final TextEditingController _manualPhoneController;
  _PersonPickerMode _mode = _PersonPickerMode.people;
  String _manualError = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _manualNameController = TextEditingController(text: widget.manualName);
    _manualPhoneController = TextEditingController(text: widget.manualPhone);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualNameController.dispose();
    _manualPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final colorScheme = Theme.of(context).colorScheme;
    final isPeopleMode = _mode == _PersonPickerMode.people;
    final peopleHeight = (screenHeight - bottomInset - 28)
        .clamp(screenHeight * 0.56, screenHeight * 0.78)
        .toDouble();
    final query = _searchController.text.trim().toLowerCase();
    final filteredContacts = widget.contacts.where((contact) {
      if (query.isEmpty) return true;
      final nameMatch = contact.name.toLowerCase().contains(query);
      final phoneMatch = contact.phone?.toLowerCase().contains(query) ?? false;
      return nameMatch || phoneMatch;
    }).toList();

    final child = isPeopleMode
        ? SizedBox(
            height: peopleHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildSheetHeader(context, tr, colorScheme),
                CustomTextField(
                  controller: _searchController,
                  labelText: tr.search,
                  hintText: tr.searchContactsByNameOrPhone,
                  prefixIcon: Icons.search_rounded,
                  isDense: true,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildContactResults(
                    context,
                    tr,
                    filteredContacts,
                    fillAvailable: true,
                  ),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildSheetHeader(context, tr, colorScheme),
                _buildManualEntryForm(context, tr, colorScheme),
              ],
            ),
          );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomInset),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.bottomCenter,
        child: child,
      ),
    );
  }

  List<Widget> _buildSheetHeader(
    BuildContext context,
    AppLocalizations tr,
    ColorScheme colorScheme,
  ) {
    return [
      Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        tr.selectContactRequired,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      _buildSourceSelector(context, tr),
      const SizedBox(height: 10),
    ];
  }

  Widget _buildSourceSelector(BuildContext context, AppLocalizations tr) {
    return Row(
      children: [
        Expanded(
          child: _PersonSourceButton(
            icon: Icons.people_alt_outlined,
            label: tr.people,
            isSelected: _mode == _PersonPickerMode.people,
            onTap: () => setState(() => _mode = _PersonPickerMode.people),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _PersonSourceButton(
            icon: Icons.contacts_outlined,
            label: tr.phoneContacts,
            isSelected: false,
            onTap: _choosePhoneContact,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _PersonSourceButton(
            icon: Icons.edit_outlined,
            label: tr.manualEntry,
            isSelected: _mode == _PersonPickerMode.manual,
            onTap: () => setState(() => _mode = _PersonPickerMode.manual),
          ),
        ),
      ],
    );
  }

  Widget _buildManualEntryForm(
    BuildContext context,
    AppLocalizations tr,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        CustomTextField(
          controller: _manualNameController,
          labelText: tr.contactNameRequired,
          hintText: tr.enterName,
          prefixIcon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
          isDense: true,
          onChanged: (_) => _clearManualError(),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _manualPhoneController,
          labelText: tr.phoneNumberOptional,
          hintText: tr.enterPhoneNumber,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: FormInputUtils.phoneInputFormatters,
          isDense: true,
          onChanged: (_) => _clearManualError(),
        ),
        if (_manualError.isNotEmpty) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _manualError,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.error,
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saveManual,
            icon: const Icon(Icons.check_rounded, size: 17),
            label: Text(tr.add),
          ),
        ),
      ],
    );
  }

  void _clearManualError() {
    if (_manualError.isNotEmpty) setState(() => _manualError = '');
  }

  Widget _buildContactResults(
    BuildContext context,
    AppLocalizations tr,
    List<ContactModel> filteredContacts, {
    bool fillAvailable = false,
  }) {
    final hasSearch = _searchController.text.trim().isNotEmpty;

    if (filteredContacts.isEmpty) {
      return SizedBox(
        height: fillAvailable ? double.infinity : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: EmptyStateWidget(
            icon: hasSearch
                ? Icons.manage_search_rounded
                : Icons.person_add_alt_1_outlined,
            title: hasSearch ? tr.noMatchingContacts : tr.noContactsYet,
            message: hasSearch
                ? tr.searchContactsByNameOrPhone
                : tr.manualEntry,
            compact: true,
          ),
        ),
      );
    }

    final list = ListView.separated(
      padding: EdgeInsets.only(bottom: fillAvailable ? 4 : 0),
      shrinkWrap: !fillAvailable,
      itemCount: filteredContacts.length + 1,
      separatorBuilder: (context, index) {
        if (index >= filteredContacts.length - 1) {
          return const SizedBox.shrink();
        }
        return const SizedBox(height: 6);
      },
      itemBuilder: (context, index) {
        if (index == filteredContacts.length) {
          return AppLoadMoreFooter(
            isLoading: false,
            hasMoreData: false,
            hasItems: filteredContacts.isNotEmpty,
            itemCount: filteredContacts.length,
          );
        }

        final contact = filteredContacts[index];
        final isSelected =
            widget.selectedContact?.id != null &&
            widget.selectedContact?.id == contact.id;
        return _PersonSheetContactTile(
          contact: contact,
          isSelected: isSelected,
          onTap: () => Navigator.pop(
            context,
            PersonPickerResult(contact: contact, isManual: false),
          ),
        );
      },
    );

    if (fillAvailable) return list;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: list,
    );
  }

  Future<void> _choosePhoneContact() async {
    final selectedContact = await Navigator.push<ContactModel>(
      context,
      MaterialPageRoute(builder: (_) => const ContactPickerScreen()),
    );
    if (!mounted || selectedContact == null) return;

    final existingContact = await _resolveExistingContactFor(
      selectedContact,
      confirmNameMismatch: false,
    );
    if (!mounted) return;

    Navigator.pop(
      context,
      PersonPickerResult(
        contact: existingContact ?? selectedContact,
        isManual: existingContact == null && selectedContact.id == null,
      ),
    );
  }

  Future<void> _saveManual() async {
    final tr = AppLocalizations.of(context)!;
    final name = _manualNameController.text.trim();
    final phone = _manualPhoneController.text.trim();

    if (name.isEmpty) {
      setState(() => _manualError = tr.pleaseEnterContactName);
      return;
    }
    if (!FormInputUtils.isValidOptionalPhone(phone)) {
      setState(() => _manualError = tr.invalidPhone);
      return;
    }

    final manualContact = ContactModel(
      name: name,
      phone: phone.isEmpty ? null : phone,
    );
    final existingContact = await _resolveExistingContactFor(
      manualContact,
      confirmNameMismatch: true,
    );
    if (!mounted) return;
    if (existingContact != null) {
      Navigator.pop(
        context,
        PersonPickerResult(contact: existingContact, isManual: false),
      );
      return;
    }

    Navigator.pop(
      context,
      PersonPickerResult(contact: manualContact, isManual: true),
    );
  }

  Future<ContactModel?> _resolveExistingContactFor(
    ContactModel candidate, {
    required bool confirmNameMismatch,
  }) async {
    final phone = candidate.phone?.trim() ?? '';
    final normalizedPhone = FormInputUtils.normalizePhone(phone);
    ContactModel? existingContact;

    if (normalizedPhone.isNotEmpty) {
      for (final contact in widget.contacts) {
        if (FormInputUtils.normalizePhone(contact.phone ?? '') ==
            normalizedPhone) {
          existingContact = contact;
          break;
        }
      }
    } else {
      final candidateName = candidate.name.trim().toLowerCase();
      for (final contact in widget.contacts) {
        if (contact.phone?.trim().isNotEmpty == true) continue;
        if (contact.name.trim().toLowerCase() == candidateName) {
          existingContact = contact;
          break;
        }
      }
    }

    if (existingContact == null) return null;
    final namesDiffer =
        existingContact.name.trim().toLowerCase() !=
        candidate.name.trim().toLowerCase();
    if (!confirmNameMismatch || !namesDiffer) return existingContact;

    final shouldUseExisting = await _confirmUseExistingContact(existingContact);
    return shouldUseExisting ? existingContact : null;
  }

  Future<bool> _confirmUseExistingContact(ContactModel existingContact) async {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AppDialogShell(
              icon: AppDialogIcon(
                icon: Icons.contact_phone_rounded,
                color: colorScheme.primary,
              ),
              title: tr.phoneAlreadySavedTitle,
              content: [
                Text(
                  tr.phoneAlreadySavedMessage(existingContact.name),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              actions: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(tr.cancel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(tr.useExistingContact),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

class _PersonSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PersonSourceButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected ? colorScheme.primary : colorScheme.onSurface;

    return Material(
      color: isSelected
          ? colorScheme.primary.withValues(alpha: 0.1)
          : colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonSheetContactTile extends StatelessWidget {
  final ContactModel contact;
  final bool isSelected;
  final VoidCallback onTap;

  const _PersonSheetContactTile({
    required this.contact,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = isSelected
        ? colorScheme.primary.withValues(alpha: 0.45)
        : colorScheme.outlineVariant.withValues(alpha: 0.55);

    return Material(
      color: isSelected
          ? colorScheme.primary.withValues(alpha: 0.08)
          : colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  contact.name.isEmpty ? '?' : contact.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (contact.phone?.trim().isNotEmpty == true)
                      Text(
                        contact.phone!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.8,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                size: isSelected ? 18 : 17,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
