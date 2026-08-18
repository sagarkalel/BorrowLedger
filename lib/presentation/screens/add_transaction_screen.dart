import 'dart:developer';

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/core/utils/currency_formatter.dart';
import 'package:borrow_ledger/core/utils/form_input_utils.dart';
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
import '../../data/repositories/shared_spend_purpose_repository.dart';
import '../../data/repositories/udhari_item_repository.dart';
import '../../data/repositories/udhari_quantity_repository.dart';
import '../widgets/app_loading_state.dart';
import '../widgets/app_amount_field.dart';
import '../widgets/app_date_field.dart';
import '../widgets/app_segmented_control.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/person_picker_sheet.dart';
import '../widgets/shared_spend_purpose_suggestions.dart';
import '../widgets/udhari_item_suggestions.dart';
import '../widgets/udhari_quantity_suggestions.dart';

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
  final _sharedTotalController = TextEditingController();

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
  bool _sharedPaidByUser = true;
  bool _sharedSplitEqually = true;

  @override
  void initState() {
    super.initState();
    _currentTransactionType = widget.transactionType;
    _currentTransactionCategory = widget.transactionCategory;
    _sharedPaidByUser = _currentTransactionType == AppConstants.typeLend;
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
      _sharedPaidByUser =
          widget.transaction!.sharedPaidByUser ??
          (widget.transaction!.type == AppConstants.typeLend);
      if (widget.transaction!.sharedTotalAmount != null) {
        _sharedTotalController.text = widget.transaction!.sharedTotalAmount!
            .toString();
      }

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
      final contacts = await contactRepo.getContactsForPicker();

      if (!mounted) return;

      setState(() {
        _contacts = contacts;
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
    _sharedTotalController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCash = _currentTransactionCategory == AppConstants.categoryCash;
    final isShared =
        _currentTransactionCategory == AppConstants.categorySharedSpend;
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
        title: Text(isEditing ? tr.editTransaction : _transactionKindTitle(tr)),
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
          ? const AppPageLoadingState(compact: true)
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottomInset),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSelectedKindCard(context, tr),
                    const SizedBox(height: 9),

                    _buildComposerSection(
                      context,
                      icon: Icons.person_outline_rounded,
                      title: 'Person',
                      child: _buildPersonPickerTile(context, tr),
                    ),
                    const SizedBox(height: 9),

                    _buildComposerSection(
                      context,
                      icon:
                          _currentTransactionCategory ==
                              AppConstants.categorySharedSpend
                          ? Icons.account_balance_wallet_outlined
                          : Icons.swap_vert_rounded,
                      title: _directionSectionTitle(),
                      child: AppSegmentedControl<String>(
                        selectedValue: _currentTransactionType,
                        margin: EdgeInsets.zero,
                        segmentHeight: 36,
                        iconSize: 15,
                        fontSize: 10.5,
                        selectedColor: colorScheme.onSurface,
                        onChanged: (type) {
                          setState(() {
                            _setPayerType(type);
                          });
                        },
                        items: [
                          AppSegmentedControlItem(
                            value: AppConstants.typeLend,
                            label: _userDirectionLabel(),
                            icon: Icons.call_made,
                          ),
                          AppSegmentedControlItem(
                            value: AppConstants.typeBorrow,
                            label: _counterpartyDirectionLabel(),
                            icon: Icons.call_received,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),

                    _buildComposerSection(
                      context,
                      icon: _transactionKindIcon(),
                      title: 'Details',
                      child: _buildDetailsFields(context, colorScheme, tr),
                    ),
                    const SizedBox(height: 9),

                    _buildOutcomePreview(context),
                    const SizedBox(height: 9),

                    _buildComposerSection(
                      context,
                      icon: Icons.calendar_today_outlined,
                      title: 'When',
                      child: Column(
                        children: [
                          AppDateField(
                            prefixIcon: Icons.calendar_today_outlined,
                            labelText: tr.transactionDate,
                            valueText: DateFormat(
                              AppConstants.dateFormat,
                            ).format(_selectedDate),
                            onTap: () => _selectDate(context),
                          ),
                          if (!isShared) ...[
                            const SizedBox(height: 8),
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
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),

                    if (!isShared) ...[
                      _buildComposerSection(
                        context,
                        icon: Icons.notes_outlined,
                        title: 'Note',
                        child: _buildCompactTextField(
                          controller: _descriptionController,
                          labelText: tr.descriptionOptional,
                          hintText: isCash
                              ? tr.addNoteAboutTransaction
                              : tr.addDetailsAboutItems,
                          prefixIcon: Icons.notes_outlined,
                          maxLines: 4,
                          maxLength: 200,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
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

  Widget _buildSelectedKindCard(BuildContext context, AppLocalizations tr) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = AppTheme.getCategoryColor(
      _currentTransactionCategory,
      isDark: isDark,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_transactionKindIcon(), color: accentColor, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _transactionKindTitle(tr),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _transactionKindSubtitle(tr),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposerSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = AppTheme.getCategoryColor(
      _currentTransactionCategory,
      isDark: isDark,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 12.5, color: accentColor),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }

  Widget _buildDetailsFields(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations tr,
  ) {
    final isCash = _currentTransactionCategory == AppConstants.categoryCash;
    final isShared =
        _currentTransactionCategory == AppConstants.categorySharedSpend;

    if (isShared) {
      return _buildSharedSpendFields(colorScheme);
    }

    if (!isCash) {
      return Column(
        children: [
          _buildCompactTextField(
            controller: _itemNameController,
            labelText: tr.itemServiceNameRequired,
            hintText: tr.egMilkMedicalGroceries,
            prefixIcon: Icons.shopping_bag_outlined,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return tr.pleaseEnterItemOrServiceName;
              }
              return null;
            },
          ),
          UdhariItemSuggestions(
            controller: _itemNameController,
            onItemSelected: () => setState(() {}),
          ),
          const SizedBox(height: 9),
          _buildCompactTextField(
            controller: _quantityController,
            labelText: tr.quantityOptional,
            hintText: tr.egQuantityExamples,
            prefixIcon: Icons.format_list_numbered,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          UdhariQuantitySuggestions(
            controller: _quantityController,
            onQuantitySelected: () => setState(() {}),
          ),
          const SizedBox(height: 9),
          AppAmountField(
            controller: _amountController,
            labelText: tr.amountRequired,
            hintText: tr.enterAmount,
            validator: _requiredPositiveAmountValidator,
            onChanged: (_) => setState(() {}),
          ),
        ],
      );
    }

    return AppAmountField(
      controller: _amountController,
      labelText: tr.amountRequired,
      hintText: tr.enterAmount,
      validator: _requiredPositiveAmountValidator,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildOutcomePreview(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isLend = _currentTransactionType == AppConstants.typeLend;
    final isShared =
        _currentTransactionCategory == AppConstants.categorySharedSpend;
    final color = AppTheme.getTransactionDirectionColor(
      _currentTransactionType,
    );
    final icon = isLend ? Icons.call_received_rounded : Icons.call_made_rounded;
    final amount = double.tryParse(_amountController.text.trim());
    final contactName = _contactDisplayName();
    final formattedAmount = _formatAmount(amount);
    final title = isShared
        ? (isLend
              ? tr.personOwesCounterparty(contactName, tr.you, formattedAmount)
              : tr.youOwePerson(contactName, formattedAmount))
        : (isLend
              ? '${tr.youWillGet} $formattedAmount ${tr.fromText} $contactName'
              : '${tr.youWillGive} $formattedAmount ${tr.toText} $contactName');
    final details = _outcomePreviewDetails(contactName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.2,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (details != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: TextStyle(
                      fontSize: 10.8,
                      height: 1.15,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _outcomePreviewDetails(String contactName) {
    final tr = AppLocalizations.of(context)!;
    if (_currentTransactionCategory == AppConstants.categorySharedSpend) {
      final total = _sharedTotalAmount;
      final share = double.tryParse(_amountController.text.trim());
      final userShare = _sharedPaidByUser
          ? (total == null ? null : total - (share ?? 0))
          : share;
      final contactShare = _sharedPaidByUser
          ? share
          : (total == null ? null : total - (share ?? 0));

      return [
        if (total != null) '${tr.total} ${_formatAmount(total)}',
        '${tr.yourShare} ${_formatAmount(userShare)}',
        '${tr.personShare(contactName)} ${_formatAmount(contactShare)}',
      ].join(' • ');
    }

    if (_currentTransactionCategory == AppConstants.categoryUdhari) {
      final item = _itemNameController.text.trim();
      final quantity = _quantityController.text.trim();
      if (item.isEmpty && quantity.isEmpty) return 'Item credit';
      return [
        if (item.isNotEmpty) item,
        if (quantity.isNotEmpty) quantity,
      ].join(' • ');
    }

    return null;
  }

  String _transactionKindTitle(AppLocalizations tr) {
    switch (_currentTransactionCategory) {
      case AppConstants.categoryCash:
        return tr.moneyTransaction;
      case AppConstants.categoryUdhari:
        return tr.udhariItemCredit;
      case AppConstants.categorySharedSpend:
        return tr.sharedSpend;
      default:
        return tr.addNewTransaction;
    }
  }

  String _transactionKindSubtitle(AppLocalizations tr) {
    switch (_currentTransactionCategory) {
      case AppConstants.categoryCash:
        return tr.moneyTransactionOnePersonDescription;
      case AppConstants.categoryUdhari:
        return tr.udhariItemCreditDescription;
      case AppConstants.categorySharedSpend:
        return tr.sharedSpendDescription;
      default:
        return tr.addNewTransaction;
    }
  }

  IconData _transactionKindIcon() {
    switch (_currentTransactionCategory) {
      case AppConstants.categoryCash:
        return Icons.currency_rupee_rounded;
      case AppConstants.categoryUdhari:
        return Icons.shopping_basket_outlined;
      case AppConstants.categorySharedSpend:
        return Icons.receipt_long_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  String _contactDisplayName() {
    final selectedName = _selectedContact?.name.trim();
    if (selectedName?.isNotEmpty == true) return selectedName!;
    final manualName = _nameController.text.trim();
    if (manualName.isNotEmpty) return manualName;
    return AppLocalizations.of(context)!.contactFallback;
  }

  String _directionSectionTitle() {
    final tr = AppLocalizations.of(context)!;
    switch (_currentTransactionCategory) {
      case AppConstants.categorySharedSpend:
        return tr.whoPaid;
      case AppConstants.categoryUdhari:
        return tr.udhariDirection;
      default:
        return tr.moneyDirection;
    }
  }

  String _userDirectionLabel() {
    final tr = AppLocalizations.of(context)!;
    switch (_currentTransactionCategory) {
      case AppConstants.categorySharedSpend:
        return tr.iPaid;
      case AppConstants.categoryUdhari:
        return tr.iGaveItem;
      default:
        return tr.iGave;
    }
  }

  String _counterpartyDirectionLabel() {
    final tr = AppLocalizations.of(context)!;
    switch (_currentTransactionCategory) {
      case AppConstants.categorySharedSpend:
        return tr.personPaid(_contactDisplayName());
      case AppConstants.categoryUdhari:
        return tr.iTookItem;
      default:
        return tr.iGot;
    }
  }

  void _setPayerType(String type) {
    _currentTransactionType = type;
    _sharedPaidByUser = type == AppConstants.typeLend;
    _syncSharedEqualShare();
  }

  Widget _buildCompactSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.15,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch.adaptive(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedSpendFields(ColorScheme colorScheme) {
    final tr = AppLocalizations.of(context)!;
    final contactName = _contactDisplayName();

    return Column(
      children: [
        _buildCompactTextField(
          controller: _descriptionController,
          labelText: tr.purposeRequired,
          hintText: tr.purposeHint,
          prefixIcon: Icons.local_offer_outlined,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return tr.pleaseEnterPurpose;
            }
            return null;
          },
        ),
        SharedSpendPurposeSuggestions(
          controller: _descriptionController,
          onPurposeSelected: () => setState(() {}),
        ),
        const SizedBox(height: 8),
        AppAmountField(
          controller: _sharedTotalController,
          labelText: _sharedPaidByUser
              ? tr.totalBillAmountRequired
              : tr.totalBillAmountOptional,
          hintText: tr.enterFullBillAmount,
          onChanged: (_) => setState(_syncSharedEqualShare),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (!_sharedPaidByUser && text.isEmpty) return null;
            return _requiredPositiveAmountValidator(text);
          },
        ),
        const SizedBox(height: 8),
        _buildCompactSwitchRow(
          title: tr.splitEqually,
          subtitle: _sharedPaidByUser
              ? tr.contactShareBecomesHalf
              : tr.yourShareBecomesHalf,
          value: _sharedSplitEqually,
          onChanged: (value) {
            setState(() {
              _sharedSplitEqually = value;
              _syncSharedEqualShare();
            });
          },
        ),
        const SizedBox(height: 8),
        AppAmountField(
          controller: _amountController,
          labelText: _sharedPaidByUser
              ? tr.personShareRequired(contactName)
              : tr.myShareRequired,
          hintText: _sharedPaidByUser
              ? tr.amountPersonShouldPay(contactName)
              : tr.amountYouShouldPay,
          onChanged: (_) => setState(() {}),
          validator: (value) {
            final baseValidation = _requiredPositiveAmountValidator(value);
            if (baseValidation != null) return baseValidation;

            final total = _sharedTotalAmount;
            final share = double.parse(value!.trim());
            if (total != null && share - total > 0.01) {
              return tr.shareCannotExceedTotalBill;
            }
            return null;
          },
        ),
      ],
    );
  }

  String? _requiredPositiveAmountValidator(String? value) {
    final tr = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return tr.pleaseEnterAmount;
    }
    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return tr.pleaseEnterValidAmount;
    }
    if (amount <= 0) {
      return tr.amountMustBeGreaterThanZero;
    }
    return null;
  }

  double? get _sharedTotalAmount {
    final text = _sharedTotalController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  void _syncSharedEqualShare() {
    if (!_sharedSplitEqually) return;
    final total = _sharedTotalAmount;
    if (total == null || total <= 0) return;
    _amountController.text = (total / 2).toStringAsFixed(2);
  }

  String _formatAmount(double? amount) {
    if (amount == null || amount.isNaN) return CurrencyFormatter.format(0);
    return CurrencyFormatter.format(amount.clamp(0, double.infinity));
  }

  Widget _buildCompactTextField({
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? prefixText,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
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
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      maxLength: maxLength,
      isDense: true,
    );
  }

  Widget _buildPersonPickerTile(BuildContext context, AppLocalizations tr) {
    final hasPerson = _nameController.text.trim().isNotEmpty;
    final subtitle = hasPerson
        ? [
            if (!_usePhoneContacts) tr.manualEntry,
            if (_phoneController.text.trim().isNotEmpty)
              _phoneController.text.trim(),
          ].join(' • ')
        : tr.searchContacts;

    return _buildContactPickerTile(
      icon: hasPerson ? Icons.person_rounded : Icons.person_add_alt_1_outlined,
      label: tr.selectContactRequired,
      value: hasPerson ? _nameController.text.trim() : null,
      subtitle: subtitle,
      isSelected: hasPerson,
      onTap: _showPersonPickerSheet,
    );
  }

  Future<void> _showPersonPickerSheet() async {
    final result = await showPersonPickerSheet(
      context: context,
      contacts: _contacts,
      selectedContact: _selectedContact,
      manualName: _usePhoneContacts ? null : _nameController.text,
      manualPhone: _usePhoneContacts ? null : _phoneController.text,
    );

    if (result == null || !mounted) return;

    setState(() {
      _usePhoneContacts = !result.isManual;
      _selectedContact = result.isManual ? null : result.contact;
      _nameController.text = result.contact.name;
      _phoneController.text = result.contact.phone ?? '';
    });
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
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: foregroundColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
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
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
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
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
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
        if (!FormInputUtils.isValidOptionalPhone(phone)) {
          showFailureSnackbar(context, tr.invalidPhone);
          return;
        }

        try {
          final normalizedPhone = FormInputUtils.normalizePhone(phone);
          final existingContacts = await contactRepo.getContactsForPicker();
          final existing = existingContacts
              .where(
                (c) =>
                    (normalizedPhone.isNotEmpty &&
                        FormInputUtils.normalizePhone(c.phone ?? '') ==
                            normalizedPhone) ||
                    (normalizedPhone.isEmpty &&
                        c.name.toLowerCase() == name.toLowerCase()),
              )
              .firstOrNull;

          if (existing != null) {
            contactToUse = existing;
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

      if (_currentTransactionCategory == AppConstants.categorySharedSpend &&
          _descriptionController.text.trim().isNotEmpty) {
        try {
          final purposeRepo = SharedSpendPurposeRepository();
          await purposeRepo.recordPurposeUsage(
            _descriptionController.text.trim(),
          );
          log(
            'Recorded shared spend purpose usage: ${_descriptionController.text.trim()}',
          );
        } catch (e) {
          log('Failed to record shared spend purpose usage: $e');
        }
      }

      final isSavingShared =
          _currentTransactionCategory == AppConstants.categorySharedSpend;
      final isSavingCash =
          _currentTransactionCategory == AppConstants.categoryCash;
      final itemName = _itemNameController.text.trim();
      final quantity = _quantityController.text.trim();
      final description = _descriptionController.text.trim();
      final amount = double.parse(_amountController.text.trim());
      final sharedTotal = isSavingShared ? _sharedTotalAmount : null;
      final sharedUserShare = isSavingShared
          ? (_sharedPaidByUser
                ? (sharedTotal == null ? null : sharedTotal - amount)
                : amount)
          : null;
      final sharedContactShare = isSavingShared
          ? (_sharedPaidByUser
                ? amount
                : (sharedTotal == null ? null : sharedTotal - amount))
          : null;

      final transaction = TransactionModel(
        id: widget.transaction?.id,
        type: isSavingShared
            ? (_sharedPaidByUser
                  ? AppConstants.typeLend
                  : AppConstants.typeBorrow)
            : _currentTransactionType,
        category: _currentTransactionCategory,
        contactId: contactToUse.id!,
        amount: amount,
        itemName: isSavingCash || isSavingShared || itemName.isEmpty
            ? null
            : itemName,
        quantity: isSavingCash || isSavingShared || quantity.isEmpty
            ? null
            : quantity,
        expectedDate: isSavingShared ? null : _expectedDate,
        description: description.isEmpty ? null : description,
        date: _selectedDate,
        createdAt: widget.transaction?.createdAt,
        updatedAt: widget.transaction?.updatedAt,
        isSettlement: widget.transaction?.isSettlement ?? false,
        sourceType: isSavingShared ? AppConstants.sourceTypeSharedSpend : null,
        sharedTotalAmount: sharedTotal,
        sharedUserShare: sharedUserShare?.clamp(0, double.infinity).toDouble(),
        sharedContactShare: sharedContactShare
            ?.clamp(0, double.infinity)
            .toDouble(),
        sharedPaidByUser: isSavingShared ? _sharedPaidByUser : null,
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
