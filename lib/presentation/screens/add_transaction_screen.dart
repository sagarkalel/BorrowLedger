import 'dart:developer';

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/cubit/borrow_lend_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/contact_model.dart';
import '../../data/repositories/contact_repository.dart';
import '../../data/repositories/udhari_item_repository.dart';
import '../../data/repositories/udhari_quantity_repository.dart';
import '../widgets/app_amount_field.dart';
import '../widgets/app_date_field.dart';
import '../widgets/app_segmented_control.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/udhari_item_suggestions.dart';
import '../widgets/udhari_quantity_suggestions.dart';
import 'contact_picker_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final String transactionType; // 'lend' or 'borrow'
  final String transactionCategory; // 'cash' or 'udhari'
  final TransactionModel? transaction; // For editing
  final int? prefilledContactId;
  final String? prefilledContactName;
  final String? prefilledContactPhone;

  const AddTransactionScreen({
    super.key,
    required this.transactionType,
    this.transactionCategory = 'cash',
    this.transaction,
    this.prefilledContactId,
    this.prefilledContactName,
    this.prefilledContactPhone,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Udhari-specific controllers
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime? _expectedDate; // Expected return date
  ContactModel? _selectedContact;
  List<ContactModel> _contacts = [];
  bool _isLoadingContacts = true;
  bool _usePhoneContacts = true;

  // Add transaction type and category state
  late String _currentTransactionType;
  late String _currentTransactionCategory;

  @override
  void initState() {
    super.initState();
    _currentTransactionType = widget.transactionType;
    _currentTransactionCategory = widget.transactionCategory;
    _loadContacts();

    // If editing, populate fields
    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description ?? '';
      _nameController.text = widget.transaction!.contactName ?? '';
      _phoneController.text = widget.transaction!.contactPhone ?? '';
      _selectedDate = widget.transaction!.date;
      _currentTransactionType = widget.transaction!.type;
      _currentTransactionCategory = widget.transaction!.category;

      // Populate udhari fields
      _itemNameController.text = widget.transaction!.itemName ?? '';
      _quantityController.text = widget.transaction!.quantity ?? '';
      _expectedDate = widget.transaction!.expectedDate;
    }

    // If prefilled contact info provided
    if (widget.prefilledContactName != null) {
      _nameController.text = widget.prefilledContactName!;
      if (widget.prefilledContactPhone != null) {
        _phoneController.text = widget.prefilledContactPhone!;
      }
      if (widget.prefilledContactId == null) {
        _usePhoneContacts = false;
      }
    }
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoadingContacts = true);
    try {
      final contactRepo = context.read<ContactRepository>();
      final contacts = await contactRepo.getAllContactsWithSummary();

      if (!mounted) return;

      setState(() {
        _contacts = contacts.map((e) => e.contact).toList();
        _isLoadingContacts = false;

        // If editing, find and set the contact
        if (widget.transaction != null) {
          _selectedContact = _contacts
              .where((c) => c.id == widget.transaction!.contactId)
              .firstOrNull;

          _selectedContact ??= ContactModel(
            id: widget.transaction!.contactId,
            name: widget.transaction!.contactName ?? _nameController.text,
            phone: widget.transaction!.contactPhone ?? _phoneController.text,
            avatar: widget.transaction!.contactAvatar,
          );

          _nameController.text = _selectedContact!.name;
          _phoneController.text = _selectedContact!.phone ?? '';
        }
        // If prefilled contact ID provided
        else if (widget.prefilledContactId != null) {
          _selectedContact = _contacts
              .where((c) => c.id == widget.prefilledContactId)
              .firstOrNull;

          if (_selectedContact != null) {
            _nameController.text = _selectedContact!.name;
            _phoneController.text = _selectedContact!.phone ?? '';
            _usePhoneContacts = true;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        final tr = AppLocalizations.of(context);
        setState(() => _isLoadingContacts = false);
        showFailureSnackbar(context, '${tr?.failedToLoad}: $e');
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLend = _currentTransactionType == AppConstants.typeLend;
    final isCash = _currentTransactionCategory == AppConstants.categoryCash;
    final isEditing = widget.transaction != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final actionColor = AppTheme.getTransactionActionColor(
      _currentTransactionType,
    );
    final tr = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing
              ? tr.editTransaction
              : isCash
              ? (isLend ? tr.youGaveMoney : tr.youGotMoney)
              : (isLend ? tr.youGaveOnUdhari : tr.youTookOnUdhari),
        ),
      ),
      bottomNavigationBar: _isLoadingContacts
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _buildSubmitButton(
                label: isEditing ? tr.updateTransaction : tr.saveTransaction,
                color: actionColor,
                onPressed: _saveTransaction,
              ),
            ),
      body: _isLoadingContacts
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 16 + bottomInset),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category switcher (Cash/Udhari)
                    AppSegmentedControl<String>(
                      selectedValue: _currentTransactionCategory,
                      margin: EdgeInsets.zero,
                      segmentHeight: 40,
                      iconSize: 16,
                      fontSize: 10.5,
                      selectedColor: colorScheme.onSurface,
                      onChanged: (category) {
                        setState(() {
                          _currentTransactionCategory = category;
                        });
                      },
                      items: [
                        AppSegmentedControlItem(
                          value: AppConstants.categoryCash,
                          label: tr.cash,
                          icon: Icons.currency_rupee_rounded,
                        ),
                        AppSegmentedControlItem(
                          value: AppConstants.categoryUdhari,
                          label: tr.udhari,
                          icon: Icons.shopping_basket_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Transaction type switcher (Lend/Borrow)
                    AppSegmentedControl<String>(
                      selectedValue: _currentTransactionType,
                      margin: EdgeInsets.zero,
                      segmentHeight: 40,
                      iconSize: 16,
                      fontSize: 10.5,
                      selectedColor: colorScheme.onSurface,
                      onChanged: (type) {
                        setState(() {
                          _currentTransactionType = type;
                        });
                      },
                      items: [
                        AppSegmentedControlItem(
                          value: AppConstants.typeLend,
                          label: tr.youGave,
                          icon: Icons.call_made,
                        ),
                        AppSegmentedControlItem(
                          value: AppConstants.typeBorrow,
                          label: tr.youGot,
                          icon: Icons.call_received,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Transaction type indicator
                    _buildTransactionSummaryCard(context, isCash, isLend, tr),
                    const SizedBox(height: 14),

                    // Contact selection toggle
                    AppSegmentedControl<bool>(
                      selectedValue: _usePhoneContacts,
                      margin: EdgeInsets.zero,
                      segmentHeight: 40,
                      iconSize: 16,
                      fontSize: 10.5,
                      selectedColor: colorScheme.onSurface,
                      onChanged: _setContactInputMode,
                      items: [
                        AppSegmentedControlItem(
                          value: true,
                          label: tr.phoneContacts,
                          icon: Icons.contacts_outlined,
                        ),
                        AppSegmentedControlItem(
                          value: false,
                          label: tr.manualEntry,
                          icon: Icons.edit_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Contact selection (conditional)
                    if (_usePhoneContacts)
                      _buildContactPickerTile(
                        icon: Icons.person_outline,
                        label: tr.selectContactRequired,
                        value: _selectedContact?.name,
                        subtitle: _selectedContact?.phone,
                        isSelected: _selectedContact != null,
                        onTap: () async {
                          final selectedContact = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ContactPickerScreen(),
                            ),
                          );
                          if (selectedContact != null) {
                            setState(() {
                              _selectedContact = selectedContact;
                              _nameController.text = selectedContact.name;
                              _phoneController.text =
                                  selectedContact.phone ?? '';
                            });
                          }
                        },
                      )
                    else ...[
                      // Manual contact entry
                      _buildCompactTextField(
                        controller: _nameController,
                        labelText: tr.contactNameRequired,
                        hintText: tr.enterName,
                        prefixIcon: Icons.person_outline,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return tr.pleaseEnterContactName;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildCompactTextField(
                        controller: _phoneController,
                        labelText: tr.phoneNumberOptional,
                        hintText: tr.enterPhoneNumber,
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Amount field
                    AppAmountField(
                      controller: _amountController,
                      labelText: tr.amountRequired,
                      hintText: tr.enterAmount,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return tr.pleaseEnterAmount;
                        }
                        if (double.tryParse(value) == null) {
                          return tr.pleaseEnterValidAmount;
                        }
                        if (double.parse(value) <= 0) {
                          return tr.amountMustBeGreaterThanZero;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Udhari-specific fields
                    if (!isCash) ...[
                      _buildCompactTextField(
                        controller: _itemNameController,
                        labelText: tr.itemServiceNameRequired,
                        hintText: tr.egMilkMedicalGroceries,
                        prefixIcon: Icons.shopping_bag_outlined,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return tr.pleaseEnterItemOrServiceName;
                          }
                          return null;
                        },
                      ),

                      // Smart suggestions widget
                      UdhariItemSuggestions(
                        controller: _itemNameController,
                        onItemSelected: () {
                          // Optional: Add any action after selection
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildCompactTextField(
                        controller: _quantityController,
                        labelText: tr.quantityOptional,
                        hintText: tr.egQuantityExamples,
                        prefixIcon: Icons.format_list_numbered,
                        textCapitalization: TextCapitalization.words,
                      ),
                      UdhariQuantitySuggestions(
                        controller: _quantityController,
                        onQuantitySelected: () {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 10),
                    // Transaction date
                    AppDateField(
                      prefixIcon: Icons.calendar_today_outlined,
                      labelText: tr.transactionDate,
                      valueText: DateFormat(
                        AppConstants.dateFormat,
                      ).format(_selectedDate),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 10),

                    // Expected return date
                    AppDateField(
                      prefixIcon: Icons.event_outlined,
                      labelText: tr.expectedReturnDateOptional,
                      valueText: _expectedDate == null
                          ? null
                          : DateFormat(
                              AppConstants.dateFormat,
                            ).format(_expectedDate!),
                      placeholderText: tr.tapToSet,
                      onTap: () => _selectExpectedDate(context),
                      clearTooltip: tr.clearDate,
                      onClear: _expectedDate == null
                          ? null
                          : () => setState(() => _expectedDate = null),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    _buildCompactTextField(
                      controller: _descriptionController,
                      labelText: tr.descriptionOptional,
                      hintText: isCash
                          ? tr.addNoteAboutTransaction
                          : tr.addDetailsAboutItems,
                      prefixIcon: Icons.notes_outlined,
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSubmitButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style:
            FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ).copyWith(
              overlayColor: WidgetStatePropertyAll(
                Colors.white.withValues(alpha: isDark ? 0.14 : 0.18),
              ),
            ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSummaryCard(
    BuildContext context,
    bool isCash,
    bool isLend,
    AppLocalizations tr,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = AppTheme.getTransactionActionColor(
      isLend ? AppConstants.typeLend : AppConstants.typeBorrow,
    );
    final title = isCash
        ? (isLend ? tr.youGaveMoney : tr.youGotMoney)
        : (isLend ? tr.youGaveOnUdhari : tr.youTookOnUdhari);
    final subtitle = isCash
        ? (isLend ? tr.theyOweYou : tr.youOweThem)
        : (isLend ? tr.theyNeedToPayForItems : tr.youNeedToPayForItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isLend ? Icons.call_made : Icons.call_received,
              color: accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isCash ? tr.cash : tr.udhari,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTextField({
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? prefixText,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    int? maxLines = 1,
    int? maxLength,
  }) {
    return CustomTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      prefixText: prefixText,
      prefixIcon: prefixIcon,
      keyboardType: keyboardType,
      validator: validator,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      maxLength: maxLength,
      isDense: true,
    );
  }

  Widget _buildContactPickerTile({
    required IconData icon,
    required String label,
    required String? value,
    required VoidCallback onTap,
    String? subtitle,
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasValue = value != null && value.isNotEmpty;
    final displayValue = hasValue ? value : label;
    final borderColor = isSelected
        ? colorScheme.primary.withValues(alpha: 0.45)
        : isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);
    final foregroundColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Material(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: foregroundColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: hasValue
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: hasValue
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.68,
                              ),
                        height: 1.25,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setContactInputMode(bool usePhoneContacts) {
    if (_usePhoneContacts == usePhoneContacts) return;

    setState(() {
      _usePhoneContacts = usePhoneContacts;

      if (!usePhoneContacts) {
        if (_selectedContact != null) {
          _nameController.text = _selectedContact!.name;
          _phoneController.text = _selectedContact!.phone ?? '';
        }
        return;
      }

      if (_selectedContact?.id != null) {
        _selectedContact =
            _contacts.where((c) => c.id == _selectedContact!.id).firstOrNull ??
            _selectedContact;
        _nameController.text = _selectedContact!.name;
        _phoneController.text = _selectedContact!.phone ?? '';
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectExpectedDate(BuildContext context) async {
    final tr = AppLocalizations.of(context)!;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: tr.selectExpectedReturnDate,
    );
    if (picked != null) {
      setState(() {
        _expectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    final tr = AppLocalizations.of(context)!;

    if (_formKey.currentState!.validate()) {
      final contactRepo = context.read<ContactRepository>();
      final borrowLendCubit = context.read<BorrowLendCubit>();
      ContactModel? contactToUse;

      // Handle contact selection based on mode
      if (_usePhoneContacts) {
        if (_selectedContact == null) {
          showWarningSnackbar(context, tr.pleaseSelectContactFromPhone);
          return;
        }

        if (_selectedContact!.id == null) {
          try {
            final id = await contactRepo.createContact(_selectedContact!);
            contactToUse = _selectedContact!.copyWith(id: id);
          } catch (e) {
            if (mounted) showFailureSnackbar(context, '${tr.failedToSave}: $e');
            return;
          }
        } else {
          contactToUse = _selectedContact;
        }
      } else {
        final name = _nameController.text.trim();
        final phone = _phoneController.text.trim();

        if (name.isEmpty) {
          showFailureSnackbar(context, tr.pleaseEnterContactName);
          return;
        }

        try {
          final existingContacts = await contactRepo
              .getAllContactsWithSummary();
          final existing = existingContacts
              .where(
                (c) =>
                    c.contact.name.toLowerCase() == name.toLowerCase() &&
                    (phone.isEmpty ||
                        c.contact.phone == null ||
                        c.contact.phone == phone),
              )
              .firstOrNull;

          if (existing != null) {
            contactToUse = existing.contact;
          } else {
            final newContact = ContactModel(
              name: name,
              phone: phone.isEmpty ? null : phone,
            );
            final id = await contactRepo.createContact(newContact);
            contactToUse = newContact.copyWith(id: id);
          }
        } catch (e) {
          if (mounted) showFailureSnackbar(context, '${tr.failedToSave}: $e');
          return;
        }
      }

      if (contactToUse == null || contactToUse.id == null) {
        if (mounted) showFailureSnackbar(context, tr.failedToSave);
        return;
      }

      // Record item usage for udhari transactions
      if (_currentTransactionCategory == AppConstants.categoryUdhari &&
          _itemNameController.text.trim().isNotEmpty) {
        try {
          final udhariRepo = UdhariItemRepository();
          await udhariRepo.recordItemUsage(_itemNameController.text.trim());
          log('Recorded udhari item usage: ${_itemNameController.text.trim()}');
        } catch (e) {
          log('Failed to record item usage: $e');
          // Don't block transaction if item recording fails
        }
      }

      if (_currentTransactionCategory == AppConstants.categoryUdhari &&
          _quantityController.text.trim().isNotEmpty) {
        try {
          final quantityRepo = UdhariQuantityRepository();
          await quantityRepo.recordQuantityUsage(
            _quantityController.text.trim(),
          );
          log(
            'Recorded udhari quantity usage: ${_quantityController.text.trim()}',
          );
        } catch (e) {
          log('Failed to record quantity usage: $e');
        }
      }

      final isSavingCash =
          _currentTransactionCategory == AppConstants.categoryCash;
      final itemName = _itemNameController.text.trim();
      final quantity = _quantityController.text.trim();
      final description = _descriptionController.text.trim();

      final transaction = TransactionModel(
        id: widget.transaction?.id,
        type: _currentTransactionType,
        category: _currentTransactionCategory,
        contactId: contactToUse.id!,
        amount: double.parse(_amountController.text.trim()),
        itemName: isSavingCash || itemName.isEmpty ? null : itemName,
        quantity: isSavingCash || quantity.isEmpty ? null : quantity,
        expectedDate: _expectedDate,
        description: description.isEmpty ? null : description,
        date: _selectedDate,
        createdAt: widget.transaction?.createdAt,
        updatedAt: widget.transaction?.updatedAt,
        isSettlement: widget.transaction?.isSettlement ?? false,
        contactName: contactToUse.name,
        contactPhone: contactToUse.phone,
        contactAvatar: contactToUse.avatar,
      );
      log("transaction: ${transaction.toMap()}");
      try {
        if (widget.transaction == null) {
          await borrowLendCubit.createTransaction(transaction);
        } else {
          await borrowLendCubit.updateTransaction(transaction);
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) showFailureSnackbar(context, '${tr.failedToSave}: $e');
      }
    }
  }
}
