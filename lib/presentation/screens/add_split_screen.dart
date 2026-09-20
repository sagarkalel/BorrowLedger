import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/core/utils/currency_formatter.dart';
import 'package:borrow_ledger/core/utils/form_input_utils.dart';
import 'package:borrow_ledger/core/utils/split_settlement_calculator.dart';
import 'package:borrow_ledger/data/models/split_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/contact_model.dart';
import '../../data/repositories/contact_repository.dart';
import '../cubit/split_cubit.dart';
import '../widgets/app_amount_field.dart';
import '../widgets/app_date_field.dart';
import '../widgets/app_dialog_components.dart';
import '../widgets/app_list_avatar.dart';
import '../widgets/app_pill_badge.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/person_picker_sheet.dart';

class _SettlementRouteStep {
  final String fromName;
  final String toName;
  final double amount;

  const _SettlementRouteStep({
    required this.fromName,
    required this.toName,
    required this.amount,
  });
}

class AddSplitScreen extends StatefulWidget {
  final SplitExpenseModel? split;

  const AddSplitScreen({super.key, this.split});

  @override
  State<AddSplitScreen> createState() => _AddSplitScreenState();
}

class _AddSplitScreenState extends State<AddSplitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final List<ParticipantData> _participants = [];
  final List<BillData> _bills = [];
  bool _splitEqually = true;
  String _settlementRouteMode = AppConstants.splitRouteOptimized;
  int? _settlementMediatorContactId;

  @override
  void initState() {
    super.initState();

    // If editing, populate fields
    if (widget.split != null) {
      _titleController.text = widget.split!.title;
      _descriptionController.text = widget.split!.description ?? '';
      _selectedDate = widget.split!.date;
      _settlementRouteMode = widget.split!.settlementRouteMode;
      _settlementMediatorContactId = widget.split!.settlementMediatorContactId;

      // Load participants
      if (widget.split!.participants != null) {
        for (var p in widget.split!.participants!) {
          _participants.add(
            ParticipantData(
              contact: ContactModel(
                id: p.contactId,
                name: p.contactName ?? '-',
              ),
              shareAmount: p.shareAmount,
              expensePaid: p.expensePaid,
              paidAmount: p.paid,
            ),
          );
        }
      }

      _initializeBillsFromSplit(widget.split!);

      if (_settlementRouteMode == AppConstants.splitRouteMediator &&
          _settlementMediatorContactId != null &&
          !_participants.any(
            (participant) =>
                participant.contact.id == _settlementMediatorContactId,
          )) {
        _settlementRouteMode = AppConstants.splitRouteOptimized;
        _settlementMediatorContactId = null;
      }
    }
  }

  void _initializeBillsFromSplit(SplitExpenseModel split) {
    final bills = split.bills ?? const <SplitBillModel>[];
    if (bills.isNotEmpty) {
      _bills.addAll(
        bills.map((bill) {
          ContactModel? paidByContact;
          if (!bill.paidByUser && bill.paidByContactId != null) {
            for (final participant in _participants) {
              if (participant.contact.id == bill.paidByContactId) {
                paidByContact = participant.contact;
                break;
              }
            }
            paidByContact ??= ContactModel(
              id: bill.paidByContactId,
              name: bill.paidByContactName ?? '-',
            );
          }

          return BillData(
            id: bill.id,
            title: bill.title,
            amount: bill.amount,
            paidByUser: bill.paidByUser || paidByContact == null,
            paidByContact: paidByContact,
            date: bill.date,
            note: bill.note,
          );
        }),
      );
      _syncParticipantPaymentsFromBills();
      return;
    }

    if (split.paidByUser > SplitSettlementCalculator.tolerance) {
      _bills.add(
        BillData(
          title: split.title,
          amount: split.paidByUser,
          paidByUser: true,
          date: split.date,
          note: split.description,
        ),
      );
    }

    for (final participant in _participants) {
      if (participant.expensePaid <= SplitSettlementCalculator.tolerance) {
        continue;
      }
      _bills.add(
        BillData(
          title: split.title,
          amount: participant.expensePaid,
          paidByUser: false,
          paidByContact: participant.contact,
          date: split.date,
          note: split.description,
        ),
      );
    }

    if (_bills.isEmpty &&
        split.totalAmount > SplitSettlementCalculator.tolerance) {
      _bills.add(
        BillData(
          title: split.title,
          amount: split.totalAmount,
          paidByUser: true,
          date: split.date,
          note: split.description,
        ),
      );
    }

    _syncParticipantPaymentsFromBills();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.split != null;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? tr.editSplitExpense : tr.splitExpense),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: FilledButton(
          onPressed: _saveSplit,
          child: Text(isEditing ? tr.updateSplit : tr.createSplit),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      AppListAvatar(
                        label: tr.splitExpense,
                        centerIcon: Icons.pie_chart_rounded,
                        indicatorIcon: Icons.group_rounded,
                        indicatorColor: Theme.of(context).colorScheme.secondary,
                        size: 34,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr.splitExpense,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tr.shareCostsWithFriends,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 9),

              _buildComposerSection(
                context,
                icon: Icons.receipt_long_outlined,
                title: 'Split details',
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _titleController,
                      labelText: tr.titleRequired,
                      hintText: tr.egDinnerAtRestaurant,
                      prefixIcon: Icons.title_rounded,
                      isDense: true,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return tr.pleaseEnterTitle;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    AppDateField(
                      labelText: tr.dateRequired,
                      valueText: DateFormat(
                        AppConstants.dateFormat,
                      ).format(_selectedDate),
                      onTap: () => _selectDate(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),

              _buildBillsSection(context, tr),
              const SizedBox(height: 9),

              _buildComposerSection(
                context,
                icon: Icons.calculate_rounded,
                title: 'Split method',
                child: _buildCompactSwitchRow(
                  title: tr.splitEqually,
                  subtitle: tr.divideAmountEvenlyAmongAll,
                  value: _splitEqually,
                  onChanged: (value) {
                    setState(() {
                      _splitEqually = value;
                      if (value) {
                        _calculateShares();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 9),

              _buildParticipantsHeader(context, tr),
              const SizedBox(height: 6),

              // Participants list or empty state
              if (_participants.isEmpty)
                AppDialogNotice(
                  color: AppTheme.warningColor,
                  child: Row(
                    children: [
                      Icon(
                        Icons.group_add_rounded,
                        size: 20,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr.noParticipantsAdded,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tr.addAtLeastOnePerson,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _participants.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 5),
                      itemBuilder: (context, index) {
                        final participant = _participants[index];
                        return _buildParticipantCard(
                          participant,
                          index,
                          isDark,
                        );
                      },
                    ),

                    // Total shares summary for manual mode
                    if (!_splitEqually && _participants.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      AppDialogNotice(
                        color: Theme.of(context).colorScheme.secondary,
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr.yourCalculatedShare(
                                      CurrencyFormatter.format(
                                        _calculateCurrentUserShare(),
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tr.yourCalculatedShareHelp(
                                      CurrencyFormatter.format(_totalAmount),
                                      CurrencyFormatter.format(
                                        _calculateTotalShares(),
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

              if (_participants.isNotEmpty) ...[
                const SizedBox(height: 7),
                _buildPaymentCoverageSummary(context),
              ],

              if (_canUseSettlementRoute) ...[
                const SizedBox(height: 9),
                _buildSettlementRouteSection(isDark),
              ],

              const SizedBox(height: 9),

              _buildComposerSection(
                context,
                icon: Icons.notes_outlined,
                title: 'Note',
                child: CustomTextField(
                  controller: _descriptionController,
                  labelText: tr.descriptionOptional,
                  prefixIcon: Icons.notes_rounded,
                  hintText: tr.whatWasThisExpenseFor,
                  isDense: true,
                  maxLines: 4,
                  maxLength: 200,
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
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
    final accentColor = colorScheme.secondary;

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

  Widget _buildBillsSection(BuildContext context, AppLocalizations tr) {
    final colorScheme = Theme.of(context).colorScheme;

    return _buildComposerSection(
      context,
      icon: Icons.receipt_long_rounded,
      title: tr.splitBills,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr.splitBillsHelp,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _showBillSheet(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(tr.addBill),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (_bills.isEmpty)
            AppDialogNotice(
              color: AppTheme.warningColor,
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.noBillsAdded,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr.addAtLeastOneBill,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: _bills.length > 4 ? 260 : double.infinity,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: _bills.length > 4
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: _bills.length,
                separatorBuilder: (context, index) => const SizedBox(height: 5),
                itemBuilder: (context, index) =>
                    _buildBillTile(_bills[index], index),
              ),
            ),
            const SizedBox(height: 7),
            _buildBillTotalSummary(context, tr),
          ],
        ],
      ),
    );
  }

  Widget _buildBillTile(BillData bill, int index) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final payerName = bill.paidByUser
        ? tr.you
        : (bill.paidByContact?.name ?? tr.unknown);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showBillSheet(bill: bill, index: index),
        child: Container(
          padding: const EdgeInsets.fromLTRB(9, 8, 6, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.splitColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.receipt_outlined,
                  size: 16,
                  color: AppTheme.splitColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${tr.paidBy}: $payerName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.format(bill.amount),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: colorScheme.error,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(30, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  setState(() {
                    _bills.removeAt(index);
                    _syncParticipantPaymentsFromBills();
                    if (_splitEqually) _calculateShares();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillTotalSummary(BuildContext context, AppLocalizations tr) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialogNotice(
      color: AppTheme.splitColor,
      child: Row(
        children: [
          Icon(Icons.summarize_outlined, size: 18, color: AppTheme.splitColor),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              tr.billsTotal,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            CurrencyFormatter.format(_totalAmount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsHeader(BuildContext context, AppLocalizations tr) {
    final colorScheme = Theme.of(context).colorScheme;
    final countColor = _participants.isEmpty
        ? AppTheme.warningColor
        : colorScheme.secondary;

    return Row(
      children: [
        Container(
          width: 21,
          height: 21,
          decoration: BoxDecoration(
            color: countColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(Icons.group_outlined, size: 12.5, color: countColor),
        ),
        const SizedBox(width: 6),
        Text(
          tr.participants,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 7),
        AppPillBadge(
          label: '${_participants.length}',
          color: countColor,
          fontSize: 10,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _addParticipant,
          icon: const Icon(Icons.person_add_rounded, size: 15),
          label: Text(tr.add),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(0, 32),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
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
            child: Switch.adaptive(
              value: value,
              activeThumbColor: colorScheme.secondary,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(
    ParticipantData participant,
    int index,
    bool isDark,
  ) {
    final shareAmount = _splitEqually
        ? _calculateEqualShare()
        : participant.shareAmount;
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                AppListAvatar(
                  label: participant.contact.name,
                  avatar: participant.contact.avatar,
                  indicatorIcon: Icons.group_rounded,
                  indicatorColor: colorScheme.secondary,
                  size: 34,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participant.contact.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (participant.contact.phone != null)
                        Text(
                          participant.contact.phone!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: colorScheme.error,
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.error.withValues(alpha: 0.08),
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_settlementMediatorContactId ==
                          participant.contact.id) {
                        _settlementRouteMode = AppConstants.splitRouteOptimized;
                        _settlementMediatorContactId = null;
                      }
                      for (final bill in _bills) {
                        if (!bill.paidByUser &&
                            bill.paidByContact?.id == participant.contact.id) {
                          bill.paidByUser = true;
                          bill.paidByContact = null;
                        }
                      }
                      _participants.removeAt(index);
                      _syncParticipantPaymentsFromBills();
                      if (!_canUseSettlementRoute) {
                        _settlementRouteMode = AppConstants.splitRouteOptimized;
                        _settlementMediatorContactId = null;
                      }
                      if (_splitEqually) {
                        _calculateShares();
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _splitEqually
                      ? _buildReadonlyAmountTile(
                          labelText: tr.shareAmount,
                          value: shareAmount,
                        )
                      : _buildParticipantAmountField(
                          key: ValueKey('share-${participant.contact.id}'),
                          labelText: tr.shareAmount,
                          initialValue: participant.shareAmount,
                          validator: (value) {
                            final amount = double.tryParse(value ?? '') ?? 0;
                            if (amount < 0) return tr.invalid;
                            final totalAmount = _totalAmount;
                            if (totalAmount <= 0) return null;
                            final otherShares = _participants
                                .asMap()
                                .entries
                                .where((entry) => entry.key != index)
                                .fold<double>(
                                  0,
                                  (sum, entry) => sum + entry.value.shareAmount,
                                );
                            if (otherShares + amount > totalAmount + 0.01) {
                              return tr.totalSharesExceedTotal;
                            }
                            return null;
                          },
                          onChanged: (amount) {
                            setState(() {
                              _participants[index].shareAmount = amount;
                            });
                          },
                          isDark: isDark,
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildReadonlyAmountTile(
                    labelText: tr.paidDuringBill,
                    value: participant.expensePaid,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadonlyAmountTile({
    required String labelText,
    required double value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: labelText,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      ),
      child: Text(
        CurrencyFormatter.format(value),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          height: 1.15,
        ),
      ),
    );
  }

  Widget _buildPaymentCoverageSummary(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalAmount = _totalAmount;
    final paidByUser = _paidByUser;
    final paidByOthers = _totalPaidByParticipants;
    final totalPaid = paidByUser + paidByOthers;
    final remaining = totalAmount - totalPaid;
    final isBalanced = totalAmount > 0 && remaining.abs() <= 0.01;
    final isOver = remaining < -0.01;
    final statusColor = isBalanced
        ? AppTheme.successColor
        : isOver
        ? colorScheme.error
        : AppTheme.warningColor;

    return AppDialogNotice(
      color: statusColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isBalanced
                    ? Icons.check_circle_outline_rounded
                    : isOver
                    ? Icons.error_outline_rounded
                    : Icons.account_balance_wallet_outlined,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Paid total: ${CurrencyFormatter.format(totalPaid)} / ${CurrencyFormatter.format(totalAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              _buildCoverageChip(
                context,
                label: 'You',
                value: paidByUser,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 5),
              _buildCoverageChip(
                context,
                label: 'Others',
                value: paidByOthers,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  isBalanced
                      ? 'Ready'
                      : isOver
                      ? 'Over by ${CurrencyFormatter.format(remaining.abs())}'
                      : 'Left ${CurrencyFormatter.format(remaining)}',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementRouteSection(bool isDark) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final previewSteps = _buildSettlementRoutePreview(tr);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route_rounded, size: 16, color: AppTheme.splitColor),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    tr.settlementRoute,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              tr.routeThroughTrustedPerson,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRouteChoiceChip(
                    label: tr.optimizedRoute,
                    icon: Icons.auto_awesome_rounded,
                    isSelected:
                        _settlementRouteMode ==
                        AppConstants.splitRouteOptimized,
                    onSelected: () => setState(() {
                      _settlementRouteMode = AppConstants.splitRouteOptimized;
                      _settlementMediatorContactId = null;
                    }),
                  ),
                  const SizedBox(width: 6),
                  _buildRouteChoiceChip(
                    label: tr.you,
                    icon: Icons.person_pin_circle_rounded,
                    isSelected:
                        _settlementRouteMode ==
                            AppConstants.splitRouteMediator &&
                        _settlementMediatorContactId == null,
                    onSelected: () => setState(() {
                      _settlementRouteMode = AppConstants.splitRouteMediator;
                      _settlementMediatorContactId = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  ..._participants.map(
                    (participant) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildRouteChoiceChip(
                        label: participant.contact.name,
                        icon: Icons.person_pin_circle_rounded,
                        isSelected:
                            _settlementRouteMode ==
                                AppConstants.splitRouteMediator &&
                            _settlementMediatorContactId ==
                                participant.contact.id,
                        onSelected: () => setState(() {
                          _settlementRouteMode =
                              AppConstants.splitRouteMediator;
                          _settlementMediatorContactId = participant.contact.id;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (previewSteps.isNotEmpty) ...[
              const SizedBox(height: 8),
              AppDialogNotice(
                color: AppTheme.splitColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...previewSteps.map(_buildRoutePreviewRow),
                    const SizedBox(height: 3),
                    Text(
                      tr.routePlanOnly,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteChoiceChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? AppTheme.splitColor
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? AppTheme.splitColor
                  : colorScheme.outlineVariant.withValues(alpha: 0.65),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : icon,
                size: 15,
                color: isSelected ? Colors.white : AppTheme.splitColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutePreviewRow(_SettlementRouteStep step) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              step.fromName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 15,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              step.toName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.format(step.amount),
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.splitColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageChip(
    BuildContext context, {
    required String label,
    required double value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label ${CurrencyFormatter.format(value)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  List<_SettlementRouteStep> _buildSettlementRoutePreview(AppLocalizations tr) {
    final totalAmount = _totalAmount;
    if (totalAmount <= 0 || _participants.isEmpty) return [];

    final split = SplitExpenseModel(
      title: _titleController.text.trim().isEmpty
          ? tr.splitExpense
          : _titleController.text.trim(),
      totalAmount: totalAmount,
      paidByUser: _paidByUser,
      date: _selectedDate,
      status: AppConstants.statusPending,
    );

    final participants = _participants.map((p) {
      return SplitParticipantModel(
        splitId: widget.split?.id ?? 0,
        contactId: p.contact.id ?? 0,
        shareAmount: p.shareAmount,
        expensePaid: p.expensePaid,
        paid: p.paidAmount,
        status: AppConstants.statusPending,
        contactName: p.contact.name,
      );
    }).toList();

    final settlements =
        SplitSettlementCalculator.calculate(
          split,
          participants,
          userName: tr.you,
          unknownName: tr.unknown,
        ).where((settlement) {
          return settlement.remainingAmount >
              SplitSettlementCalculator.tolerance;
        }).toList();

    if (_settlementRouteMode == AppConstants.splitRouteOptimized) {
      return settlements.map((settlement) {
        final participantName =
            settlement.participant.contactName ?? tr.unknown;
        final debtorName = settlement.participantOwes
            ? participantName
            : tr.you;
        final creditorName = settlement.participantOwes
            ? settlement.counterpartyName
            : participantName;
        return _SettlementRouteStep(
          fromName: debtorName,
          toName: creditorName,
          amount: settlement.remainingAmount,
        );
      }).toList();
    }

    var mediatorName = tr.you;
    if (_settlementMediatorContactId != null) {
      mediatorName = tr.unknown;
      for (final participant in _participants) {
        if (participant.contact.id == _settlementMediatorContactId) {
          mediatorName = participant.contact.name;
          break;
        }
      }
    }

    return _buildMediatedRouteSteps(settlements, mediatorName, tr);
  }

  List<_SettlementRouteStep> _buildMediatedRouteSteps(
    List<SplitSettlementResult> settlements,
    String mediatorName,
    AppLocalizations tr,
  ) {
    final totalsByRoute = <String, _SettlementRouteStep>{};

    void addStep(String fromName, String toName, double amount) {
      if (amount <= SplitSettlementCalculator.tolerance || fromName == toName) {
        return;
      }

      final key = '$fromName->$toName';
      final existing = totalsByRoute[key];
      totalsByRoute[key] = _SettlementRouteStep(
        fromName: fromName,
        toName: toName,
        amount: (existing?.amount ?? 0) + amount,
      );
    }

    for (final settlement in settlements) {
      final amount = settlement.remainingAmount;
      final participantName = settlement.participant.contactName ?? tr.unknown;
      final debtorName = settlement.participantOwes ? participantName : tr.you;
      final creditorName = settlement.participantOwes
          ? settlement.counterpartyName
          : participantName;

      if (debtorName == mediatorName || creditorName == mediatorName) {
        addStep(debtorName, creditorName, amount);
      } else {
        addStep(debtorName, mediatorName, amount);
        addStep(mediatorName, creditorName, amount);
      }
    }

    return totalsByRoute.values.toList()..sort((a, b) {
      final fromCompare = a.fromName.compareTo(b.fromName);
      if (fromCompare != 0) return fromCompare;
      return a.toName.compareTo(b.toName);
    });
  }

  Widget _buildParticipantAmountField({
    required Key key,
    required String labelText,
    required double initialValue,
    String? Function(String?)? validator,
    required ValueChanged<double> onChanged,
    required bool isDark,
  }) {
    return TextFormField(
      key: key,
      initialValue: initialValue == 0 ? '' : initialValue.toStringAsFixed(2),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: labelText,
        prefixText: '₹ ',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      ),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: validator,
      onChanged: (value) {
        onChanged(double.tryParse(value) ?? 0);
      },
    );
  }

  double _calculateEqualShare() {
    if (_totalAmount <= 0 || _participants.isEmpty) {
      return 0;
    }

    // Include user + participants
    final totalPeople = _participants.length + 1;

    return _totalAmount / totalPeople;
  }

  void _calculateShares() {
    final shareAmount = _calculateEqualShare();
    for (var participant in _participants) {
      participant.shareAmount = shareAmount;
    }
  }

  double _calculateTotalShares() {
    return _participants.fold(0, (sum, p) => sum + p.shareAmount);
  }

  double _calculateCurrentUserShare() {
    return _totalAmount - _calculateTotalShares();
  }

  double get _totalAmount {
    return _bills.fold<double>(0, (sum, bill) => sum + bill.amount);
  }

  double get _paidByUser {
    return _bills.fold<double>(
      0,
      (sum, bill) => bill.paidByUser ? sum + bill.amount : sum,
    );
  }

  bool get _canUseSettlementRoute => _participants.length >= 2;

  double get _totalPaidByParticipants {
    return _participants.fold<double>(
      0,
      (sum, participant) => sum + participant.expensePaid,
    );
  }

  void _syncParticipantPaymentsFromBills() {
    for (final participant in _participants) {
      participant.expensePaid = _bills.fold<double>(0, (sum, bill) {
        if (bill.paidByUser) return sum;
        if (bill.paidByContact?.id != participant.contact.id) return sum;
        return sum + bill.amount;
      });
    }
  }

  Future<void> _showBillSheet({BillData? bill, int? index}) async {
    final splitTitle = _titleController.text.trim();
    final result = await showModalBottomSheet<BillData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SplitBillSheet(
        bill: bill,
        isEditing: index != null,
        splitTitle: splitTitle,
        participants: _participants,
        selectedDate: _selectedDate,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      if (index == null) {
        _bills.add(result);
      } else {
        _bills[index] = result;
      }
      _syncParticipantPaymentsFromBills();
      if (_splitEqually) _calculateShares();
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

  Future<void> _addParticipant() async {
    final contactRepo = context.read<ContactRepository>();
    final contacts = await contactRepo.getContactsForPicker();
    if (!mounted) return;

    final result = await showPersonPickerSheet(
      context: context,
      contacts: contacts,
    );

    if (result == null || !mounted) return;
    await _addContactAsParticipant(result.contact);
  }

  Future<void> _addContactAsParticipant(ContactModel contact) async {
    final tr = AppLocalizations.of(context)!;
    ContactModel? savedContact;

    try {
      final contactRepo = context.read<ContactRepository>();
      final phoneToCheck = contact.phone?.trim() ?? '';
      final nameToCheck = contact.name.trim();
      final normalizedPhoneToCheck = _normalizePhone(phoneToCheck);

      final existsInList = _participants.any((participant) {
        final sameId =
            contact.id != null && participant.contact.id == contact.id;
        final samePhone =
            normalizedPhoneToCheck.isNotEmpty &&
            _normalizePhone(participant.contact.phone ?? '') ==
                normalizedPhoneToCheck;
        final sameNameWithoutPhone =
            phoneToCheck.isEmpty &&
            participant.contact.name.trim().toLowerCase() ==
                nameToCheck.toLowerCase();
        return sameId || samePhone || sameNameWithoutPhone;
      });

      if (existsInList) {
        showWarningSnackbar(context, tr.thisContactIsAlreadyAdded);
        return;
      }

      if (phoneToCheck.isNotEmpty) {
        final existingContact = await _findExistingContactByPhone(
          contactRepo,
          phoneToCheck,
        );
        if (existingContact != null) {
          final namesDiffer =
              existingContact.name.trim().toLowerCase() !=
              nameToCheck.toLowerCase();
          if (namesDiffer) {
            if (!mounted) return;
            final shouldUseExisting = await _confirmUseExistingContact(
              existingContact,
            );
            if (!shouldUseExisting) return;
          }
          savedContact = existingContact;
        }
      }

      if (savedContact == null && phoneToCheck.isEmpty) {
        final existingContacts = await contactRepo.getAllContacts();
        for (final summary in existingContacts) {
          if (summary.contact.name.trim().toLowerCase() ==
              nameToCheck.toLowerCase()) {
            savedContact = summary.contact;
            break;
          }
        }
      }

      savedContact ??= contact;
      if (savedContact.id == null) {
        final newContactId = await contactRepo.createContact(savedContact);
        savedContact = savedContact.copyWith(id: newContactId);
      }

      if (!mounted) return;
      setState(() {
        _participants.add(
          ParticipantData(
            contact: savedContact!,
            shareAmount: _calculateEqualShare(),
            expensePaid: 0,
            paidAmount: 0,
          ),
        );
        if (_splitEqually) {
          _calculateShares();
        }
      });
    } catch (e) {
      if (!mounted) return;
      showFailureSnackbar(context, '${tr.failedToSave}: $e');
    }
  }

  String _normalizePhone(String phone) {
    return FormInputUtils.normalizePhone(phone);
  }

  Future<ContactModel?> _findExistingContactByPhone(
    ContactRepository contactRepo,
    String phone,
  ) async {
    final exactMatch = await contactRepo.getContactByPhone(phone);
    if (exactMatch != null) return exactMatch;

    final normalizedPhone = _normalizePhone(phone);
    if (normalizedPhone.isEmpty) return null;

    final existingContacts = await contactRepo.getAllContacts();
    for (final summary in existingContacts) {
      if (_normalizePhone(summary.contact.phone ?? '') == normalizedPhone) {
        return summary.contact;
      }
    }
    return null;
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
                color: colorScheme.secondary,
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

  Future<void> _saveSplit() async {
    final tr = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      if (_participants.isEmpty) {
        showFailureSnackbar(context, tr.pleaseAddAtLeastOneParticipant);
        return;
      }

      if (_bills.isEmpty) {
        showFailureSnackbar(context, tr.pleaseAddAtLeastOneBill);
        return;
      }

      final totalAmount = _totalAmount;
      final paidByUser = _paidByUser;
      final totalPaidByParticipants = _totalPaidByParticipants;
      final totalPaidForExpense = paidByUser + totalPaidByParticipants;

      if (totalPaidForExpense > totalAmount + 0.01) {
        showFailureSnackbar(
          context,
          tr.paidTotalExceedsBills(
            CurrencyFormatter.format(totalPaidForExpense - totalAmount),
          ),
        );
        return;
      }

      if ((totalPaidForExpense - totalAmount).abs() > 0.01) {
        showFailureSnackbar(
          context,
          tr.billAmountStillUnassigned(
            CurrencyFormatter.format(totalAmount - totalPaidForExpense),
          ),
        );
        return;
      }

      // Validate shares if not split equally
      if (!_splitEqually) {
        final totalShares = _calculateTotalShares();
        final userShare = totalAmount - totalShares;

        if (userShare < 0) {
          showFailureSnackbar(context, tr.totalSharesExceedTotal);
          return;
        }
      }

      final split = SplitExpenseModel(
        id: widget.split?.id,
        title: _titleController.text.trim(),
        totalAmount: totalAmount,
        paidByUser: paidByUser,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _selectedDate,
        status: AppConstants.statusPending,
        settlementRouteMode: _canUseSettlementRoute
            ? _settlementRouteMode
            : AppConstants.splitRouteOptimized,
        settlementMediatorContactId:
            _canUseSettlementRoute &&
                _settlementRouteMode == AppConstants.splitRouteMediator
            ? _settlementMediatorContactId
            : null,
      );

      final participants = _participants.map((p) {
        final amountToSettle = (p.shareAmount - p.expensePaid).abs();
        final isSettled = amountToSettle <= 0 || p.paidAmount >= amountToSettle;
        return SplitParticipantModel(
          splitId: widget.split?.id ?? 0,
          contactId: p.contact.id!,
          shareAmount: p.shareAmount,
          expensePaid: p.expensePaid,
          paid: p.paidAmount,
          status: isSettled
              ? AppConstants.statusPaid
              : AppConstants.statusPending,
        );
      }).toList();

      final bills = _bills.map((bill) {
        return SplitBillModel(
          id: bill.id,
          splitId: widget.split?.id ?? 0,
          title: bill.title,
          amount: bill.amount,
          paidByUser: bill.paidByUser,
          paidByContactId: bill.paidByUser ? null : bill.paidByContact?.id,
          date: _selectedDate,
          note: bill.note,
        );
      }).toList();

      final splitCubit = context.read<SplitCubit>();
      if (widget.split == null) {
        await splitCubit.createSplit(split, participants, bills);
      } else {
        await splitCubit.updateSplit(split, participants, bills);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }
}

class _SplitBillSheet extends StatefulWidget {
  final BillData? bill;
  final bool isEditing;
  final String splitTitle;
  final List<ParticipantData> participants;
  final DateTime selectedDate;

  const _SplitBillSheet({
    required this.bill,
    required this.isEditing,
    required this.splitTitle,
    required this.participants,
    required this.selectedDate,
  });

  @override
  State<_SplitBillSheet> createState() => _SplitBillSheetState();
}

class _SplitBillSheetState extends State<_SplitBillSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late bool _paidByUser;
  ContactModel? _paidByContact;

  @override
  void initState() {
    super.initState();
    final bill = widget.bill;
    _titleController = TextEditingController(
      text: bill?.title ?? widget.splitTitle,
    );
    _amountController = TextEditingController(
      text: bill == null ? '' : bill.amount.toStringAsFixed(2),
    );
    _paidByUser = bill?.paidByUser ?? true;
    _paidByContact = bill?.paidByContact;

    final participantIds = widget.participants
        .map((participant) => participant.contact.id)
        .whereType<int>()
        .toSet();
    if (!_paidByUser &&
        (_paidByContact?.id == null ||
            !participantIds.contains(_paidByContact!.id))) {
      _paidByUser = true;
      _paidByContact = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 20,
                  color: AppTheme.splitColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isEditing ? tr.editBill : tr.addBill,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _titleController,
              labelText: tr.billNameRequired,
              hintText: tr.billNameHint,
              prefixIcon: Icons.title_rounded,
              isDense: true,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return tr.required;
                return null;
              },
            ),
            const SizedBox(height: 10),
            AppAmountField(
              controller: _amountController,
              labelText: tr.billAmountRequired,
              hintText: '0.00',
              validator: (value) {
                if (value == null || value.trim().isEmpty) return tr.required;
                final amount = double.tryParse(value);
                if (amount == null) return tr.invalid;
                if (amount <= 0) return tr.mustBeGreaterThanZero;
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text(
              tr.paidBy,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _buildPayerChip(
                  label: tr.you,
                  selected: _paidByUser,
                  onTap: () {
                    setState(() {
                      _paidByUser = true;
                      _paidByContact = null;
                    });
                  },
                ),
                ...widget.participants.map((participant) {
                  final contact = participant.contact;
                  final selected =
                      !_paidByUser &&
                      _paidByContact?.id != null &&
                      _paidByContact?.id == contact.id;
                  return _buildPayerChip(
                    label: contact.name,
                    avatar: contact.avatar,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        _paidByUser = false;
                        _paidByContact = contact;
                      });
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
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
                  child: FilledButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      Navigator.pop(
                        context,
                        BillData(
                          id: widget.bill?.id,
                          title: _titleController.text.trim(),
                          amount: double.tryParse(_amountController.text) ?? 0,
                          paidByUser: _paidByUser,
                          paidByContact: _paidByContact,
                          date: widget.selectedDate,
                          note: widget.bill?.note,
                        ),
                      );
                    },
                    child: Text(widget.isEditing ? tr.save : tr.add),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayerChip({
    required String label,
    String? avatar,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      avatar: avatar != null && avatar.trim().isNotEmpty
          ? AppListAvatar(label: label, avatar: avatar, size: 24)
          : Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.person_outline_rounded,
              size: 16,
              color: selected ? Colors.white : AppTheme.splitColor,
            ),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      onPressed: onTap,
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.45,
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : colorScheme.onSurface,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: selected
            ? AppTheme.splitColor
            : colorScheme.outlineVariant.withValues(alpha: 0.7),
      ),
      color: WidgetStateProperty.resolveWith<Color?>(
        (states) => selected ? AppTheme.splitColor : null,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

// Helper class to manage participant data
class ParticipantData {
  final ContactModel contact;
  double shareAmount;
  double expensePaid;
  double paidAmount;

  ParticipantData({
    required this.contact,
    required this.shareAmount,
    this.expensePaid = 0,
    this.paidAmount = 0,
  });
}

class BillData {
  final int? id;
  String title;
  double amount;
  bool paidByUser;
  ContactModel? paidByContact;
  DateTime date;
  String? note;

  BillData({
    this.id,
    required this.title,
    required this.amount,
    required this.paidByUser,
    this.paidByContact,
    required this.date,
    this.note,
  });
}
