import 'dart:developer';

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/cubit/borrow_lend_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/contact_model.dart';
import '../../data/repositories/contact_repository.dart';
import '../../data/repositories/udhari_item_repository.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/udhari_item_suggestions.dart';
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

          if (_selectedContact != null) {
            _nameController.text = _selectedContact!.name;
            _phoneController.text = _selectedContact!.phone ?? '';
          }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? tr.editTransaction
              : isCash
              ? (isLend ? tr.youGaveMoney : tr.youGotMoney)
              : (isLend ? tr.youGaveOnUdhari : tr.youTookOnUdhari),
        ),
      ),
      body: _isLoadingContacts
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category switcher (Cash/Udhari)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildCategorySwitchButton(
                              context: context,
                              label: tr.cash,
                              icon: Icons.currency_rupee_rounded,
                              color: AppTheme.successColor,
                              isSelected: isCash,
                              onTap: () {
                                setState(() {
                                  _currentTransactionCategory =
                                      AppConstants.categoryCash;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildCategorySwitchButton(
                              context: context,
                              label: tr.udhari,
                              icon: Icons.shopping_basket_rounded,
                              color: AppTheme.infoColor,
                              isSelected: !isCash,
                              onTap: () {
                                setState(() {
                                  _currentTransactionCategory =
                                      AppConstants.categoryUdhari;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Transaction type switcher (Lend/Borrow)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTypeSwitchButton(
                              context: context,
                              label: isCash
                                  ? tr.youGaveMoney
                                  : tr.youGaveOnUdhari,
                              icon: Icons.call_made,
                              color: isCash
                                  ? AppTheme.successColor
                                  : Colors.orangeAccent,
                              isSelected: isLend,
                              onTap: () {
                                setState(() {
                                  _currentTransactionType =
                                      AppConstants.typeLend;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildTypeSwitchButton(
                              context: context,
                              label: isCash
                                  ? tr.youGotMoney
                                  : tr.youTookOnUdhari,
                              icon: Icons.call_received,
                              color: isCash
                                  ? AppTheme.warningColor
                                  : Colors.purple,
                              isSelected: !isLend,
                              onTap: () {
                                setState(() {
                                  _currentTransactionType =
                                      AppConstants.typeBorrow;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Transaction type indicator
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLend
                            ? (isCash
                                  ? AppTheme.successColor.withValues(alpha: 0.1)
                                  : Colors.blue.withValues(alpha: 0.1))
                            : (isCash
                                  ? AppTheme.warningColor.withValues(alpha: 0.1)
                                  : Colors.orangeAccent.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLend
                              ? (isCash
                                    ? AppTheme.successColor.withValues(
                                        alpha: 0.3,
                                      )
                                    : Colors.blue.withValues(alpha: 0.3))
                              : (isCash
                                    ? AppTheme.warningColor.withValues(
                                        alpha: 0.3,
                                      )
                                    : Colors.orangeAccent.withValues(
                                        alpha: 0.3,
                                      )),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isLend
                                  ? (isCash
                                        ? AppTheme.successColor
                                        : Colors.blue)
                                  : (isCash
                                        ? AppTheme.warningColor
                                        : Colors.purple),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isLend ? Icons.call_made : Icons.call_received,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCash
                                      ? (isLend
                                            ? tr.youGaveMoney
                                            : tr.youGotMoney)
                                      : (isLend
                                            ? tr.youGaveOnUdhari
                                            : tr.youTookOnUdhari),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isCash
                                      ? (isLend ? tr.theyOweYou : tr.youOweThem)
                                      : (isLend
                                            ? tr.theyNeedToPayForItems
                                            : tr.youNeedToPayForItems),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCash
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isCash ? '💵' : '📦',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCash ? tr.cash : tr.udhari,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isCash
                                        ? Colors.green
                                        : Colors.deepOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contact selection toggle
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<bool>(
                            segments: [
                              ButtonSegment(
                                value: true,
                                label: Text(tr.phoneContacts),
                                icon: Icon(Icons.contacts, size: 18),
                              ),
                              ButtonSegment(
                                value: false,
                                label: Text(tr.manualEntry),
                                icon: Icon(Icons.edit, size: 18),
                              ),
                            ],
                            selected: {_usePhoneContacts},
                            onSelectionChanged: (Set<bool> selection) {
                              setState(() {
                                _usePhoneContacts = selection.first;
                                _selectedContact = null;
                                _nameController.clear();
                                _phoneController.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Contact selection (conditional)
                    if (_usePhoneContacts)
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
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
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedContact != null
                                  ? AppTheme.primaryGreen
                                  : (isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!),
                              width: _selectedContact != null ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: _selectedContact != null
                                    ? AppTheme.primaryGreen
                                    : Theme.of(context).hintColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedContact != null
                                          ? _selectedContact!.name
                                          : tr.selectContactRequired,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedContact != null
                                            ? (isDark
                                                  ? Colors.white
                                                  : Colors.grey[900])
                                            : Theme.of(context).hintColor,
                                      ),
                                    ),
                                    if (_selectedContact != null &&
                                        _selectedContact!.phone != null)
                                      Text(
                                        _selectedContact!.phone!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Theme.of(context).hintColor,
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Manual contact entry
                      CustomTextField(
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
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _phoneController,
                        labelText: tr.phoneNumberOptional,
                        hintText: tr.enterPhoneNumber,
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Amount field
                    CustomTextField(
                      controller: _amountController,
                      labelText: tr.amountRequired,
                      hintText: tr.enterAmount,
                      prefixText: '₹ ',
                      prefixIcon: Icons.currency_rupee,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
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
                    const SizedBox(height: 16),

                    // Udhari-specific fields
                    if (!isCash) ...[
                      CustomTextField(
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

                      CustomTextField(
                        controller: _quantityController,
                        labelText: tr.quantityOptional,
                        hintText: tr.egQuantityExamples,
                        prefixIcon: Icons.format_list_numbered,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Transaction date
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr.transactionDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat(
                                      AppConstants.dateFormat,
                                    ).format(_selectedDate),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.grey[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Theme.of(context).hintColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Expected return date
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _selectExpectedDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _expectedDate != null
                                ? AppTheme.primaryGreen
                                : (isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!),
                            width: _expectedDate != null ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_outlined,
                              color: _expectedDate != null
                                  ? AppTheme.primaryGreen
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr.expectedReturnDateOptional,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _expectedDate == null
                                        ? tr.tapToSet
                                        : DateFormat(
                                            AppConstants.dateFormat,
                                          ).format(_expectedDate!),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _expectedDate == null
                                          ? (isDark
                                                ? Colors.grey[600]
                                                : Colors.grey[400])
                                          : (isDark
                                                ? Colors.white
                                                : Colors.grey[900]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_expectedDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () =>
                                    setState(() => _expectedDate = null),
                                iconSize: 20,
                                tooltip: tr.clearDate,
                                visualDensity: VisualDensity.compact,
                              )
                            else
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Theme.of(context).hintColor,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    CustomTextField(
                      controller: _descriptionController,
                      labelText: tr.descriptionOptional,
                      hintText: isCash
                          ? tr.addNoteAboutTransaction
                          : tr.addDetailsAboutItems,
                      prefixIcon: Icons.notes_outlined,
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: isLend
                              ? (isCash ? AppTheme.successColor : Colors.blue)
                              : (isCash
                                    ? AppTheme.warningColor
                                    : Colors.orangeAccent),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          isEditing ? tr.updateTransaction : tr.saveTransaction,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategorySwitchButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : isDark
              ? Colors.grey[850]
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : isDark
                  ? Colors.grey[400]
                  : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isDark
                    ? Colors.grey[400]
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSwitchButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : isDark
              ? Colors.grey[850]
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : isDark
                  ? Colors.grey[400]
                  : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isDark
                    ? Colors.grey[400]
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
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

      final transaction = TransactionModel(
        id: widget.transaction?.id,
        type: _currentTransactionType,
        category: _currentTransactionCategory,
        contactId: contactToUse.id!,
        amount: double.parse(_amountController.text),
        itemName: _itemNameController.text.isEmpty
            ? null
            : _itemNameController.text,
        quantity: _quantityController.text.isEmpty
            ? null
            : _quantityController.text,
        expectedDate: _expectedDate,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        date: _selectedDate,
        contactName: contactToUse.name,
      );
      log("transaction: ${transaction.toMap()}");
      try {
        if (widget.transaction == null) {
          await context.read<BorrowLendCubit>().createTransaction(transaction);
        } else {
          await context.read<BorrowLendCubit>().updateTransaction(transaction);
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
