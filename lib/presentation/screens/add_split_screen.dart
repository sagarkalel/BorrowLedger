import 'package:borrow_ledger/core/constants/app_functions.dart';
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
import '../widgets/app_segmented_control.dart';
import '../widgets/custom_text_field.dart';
import 'contact_picker_screen.dart';

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

class _AddParticipantSheetResult {
  final bool shouldPickPhoneContact;
  final ContactModel? manualContact;

  const _AddParticipantSheetResult.phoneContacts()
    : shouldPickPhoneContact = true,
      manualContact = null;

  const _AddParticipantSheetResult.manual(this.manualContact)
    : shouldPickPhoneContact = false;
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
  final _totalAmountController = TextEditingController();
  final _paidByUserController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final List<ParticipantData> _participants = [];
  bool _splitEqually = true;
  String _settlementRouteMode = AppConstants.splitRouteOptimized;
  int? _settlementMediatorContactId;

  @override
  void initState() {
    super.initState();

    // If editing, populate fields
    if (widget.split != null) {
      _titleController.text = widget.split!.title;
      _totalAmountController.text = widget.split!.totalAmount.toString();
      _paidByUserController.text = widget.split!.paidByUser.toString();
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

  @override
  void dispose() {
    _titleController.dispose();
    _totalAmountController.dispose();
    _paidByUserController.dispose();
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
        minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: FilledButton(
          onPressed: _saveSplit,
          child: Text(isEditing ? tr.updateSplit : tr.createSplit),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
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
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      AppListAvatar(
                        label: tr.splitExpense,
                        centerIcon: Icons.pie_chart_rounded,
                        indicatorIcon: Icons.group_rounded,
                        indicatorColor: Theme.of(context).colorScheme.secondary,
                        size: 38,
                      ),
                      const SizedBox(width: 10),
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
                                fontSize: 12,
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
              const SizedBox(height: 10),

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
              const SizedBox(height: 10),

              // Total amount and You paid row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppAmountField(
                      controller: _totalAmountController,
                      labelText: tr.totalAmountRequired,
                      hintText: '0.00',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr.required;
                        }
                        if (double.tryParse(value) == null) {
                          return tr.invalid;
                        }
                        if (double.parse(value) <= 0) {
                          return tr.mustBeGreaterThanZero;
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          if (_splitEqually) {
                            _calculateShares();
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppAmountField(
                      controller: _paidByUserController,
                      labelText: tr.youPaidRequired,
                      hintText: '0.00',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr.required;
                        }
                        if (double.tryParse(value) == null) {
                          return tr.invalid;
                        }
                        final amount = double.parse(value);
                        if (amount < 0) {
                          return tr.cannotBeNegative;
                        }
                        final total =
                            double.tryParse(_totalAmountController.text) ?? 0;
                        if (amount > total) {
                          return tr.exceedsTotal;
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              AppDateField(
                labelText: tr.dateRequired,
                valueText: DateFormat(
                  AppConstants.dateFormat,
                ).format(_selectedDate),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 10),

              AppDialogNotice(
                color: Theme.of(context).colorScheme.secondary,
                child: Row(
                  children: [
                    Icon(
                      Icons.calculate_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.splitEqually,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            tr.divideAmountEvenlyAmongAll,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _splitEqually,
                      onChanged: (value) {
                        setState(() {
                          _splitEqually = value;
                          if (value) {
                            _calculateShares();
                          }
                        });
                      },
                      activeThumbColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Participants section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        tr.participants,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      AppPillBadge(
                        label: '${_participants.length}',
                        color: _participants.isEmpty
                            ? AppTheme.warningColor
                            : Theme.of(context).colorScheme.secondary,
                        fontSize: 11,
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _addParticipant,
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: Text(tr.add),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

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
                                    '${tr.totalParticipantShares}: ${tr.rupee}${_calculateTotalShares().toStringAsFixed(2)}',
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
                                    tr.yourShareWillBeRemaining,
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

              const SizedBox(height: 8),

              _buildPaymentCoverageSummary(context),
              const SizedBox(height: 10),

              if (_canUseSettlementRoute) ...[
                _buildSettlementRouteSection(isDark),
                const SizedBox(height: 10),
              ],

              CustomTextField(
                controller: _descriptionController,
                labelText: tr.descriptionOptional,
                prefixIcon: Icons.notes_rounded,
                hintText: tr.whatWasThisExpenseFor,
                isDense: true,
                maxLines: 2,
                maxLength: 200,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Column(
          children: [
            Row(
              children: [
                AppListAvatar(
                  label: participant.contact.name,
                  indicatorIcon: Icons.group_rounded,
                  indicatorColor: colorScheme.secondary,
                  size: 38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participant.contact.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
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
                      _participants.removeAt(index);
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
            const SizedBox(height: 8),
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
                  child: _buildParticipantAmountField(
                    key: ValueKey('paid-${participant.contact.id}'),
                    labelText: tr.paidDuringBill,
                    initialValue: participant.expensePaid,
                    validator: (value) {
                      final amount = double.tryParse(value ?? '') ?? 0;
                      if (amount < 0) return tr.invalid;
                      return null;
                    },
                    onChanged: (amount) {
                      setState(() {
                        _participants[index].expensePaid = amount;
                      });
                    },
                    isDark: isDark,
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
        '₹ ${value.toStringAsFixed(2)}',
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
                size: 18,
                color: statusColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Paid total: ₹${totalPaid.toStringAsFixed(2)} / ₹${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildCoverageChip(
                context,
                label: 'You',
                value: paidByUser,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              _buildCoverageChip(
                context,
                label: 'Others',
                value: paidByOthers,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isBalanced
                      ? 'Ready'
                      : isOver
                      ? 'Over by ₹${remaining.abs().toStringAsFixed(2)}'
                      : 'Left ₹${remaining.toStringAsFixed(2)}',
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
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route_rounded, size: 18, color: AppTheme.splitColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr.settlementRoute,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              tr.routeThroughTrustedPerson,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
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
                  const SizedBox(width: 8),
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
                      padding: const EdgeInsets.only(right: 8),
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
              const SizedBox(height: 10),
              AppDialogNotice(
                color: AppTheme.splitColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...previewSteps.map(_buildRoutePreviewRow),
                    const SizedBox(height: 4),
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
            '₹${step.amount.toStringAsFixed(2)}',
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
        '$label ₹${value.toStringAsFixed(2)}',
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
    if (_totalAmountController.text.isEmpty || _participants.isEmpty) {
      return 0;
    }

    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0;
    // Include user + participants
    final totalPeople = _participants.length + 1;

    return totalAmount / totalPeople;
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

  double get _totalAmount => double.tryParse(_totalAmountController.text) ?? 0;

  double get _paidByUser => double.tryParse(_paidByUserController.text) ?? 0;

  bool get _canUseSettlementRoute => _participants.length >= 2;

  double get _totalPaidByParticipants {
    return _participants.fold<double>(
      0,
      (sum, participant) => sum + participant.expensePaid,
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

  Future<void> _addParticipant() async {
    final result = await showModalBottomSheet<_AddParticipantSheetResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddSplitParticipantSheet(),
    );

    if (result == null || !mounted) return;

    if (result.shouldPickPhoneContact) {
      final contact = await Navigator.push<ContactModel>(
        context,
        MaterialPageRoute(builder: (_) => const ContactPickerScreen()),
      );

      if (contact == null || !mounted) return;
      await _addContactAsParticipant(contact);
      return;
    }

    final manualContact = result.manualContact;
    if (manualContact == null) return;
    await _addContactAsParticipant(manualContact);
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

      final totalAmount = _totalAmount;
      final paidByUser = _paidByUser;
      final totalPaidByParticipants = _totalPaidByParticipants;
      final totalPaidForExpense = paidByUser + totalPaidByParticipants;

      if (totalPaidForExpense > totalAmount + 0.01) {
        showFailureSnackbar(
          context,
          'Paid total exceeds total amount by ₹${(totalPaidForExpense - totalAmount).toStringAsFixed(2)}',
        );
        return;
      }

      if ((totalPaidForExpense - totalAmount).abs() > 0.01) {
        showFailureSnackbar(
          context,
          '₹${(totalAmount - totalPaidForExpense).toStringAsFixed(2)} still needs to be assigned as paid',
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

      final splitCubit = context.read<SplitCubit>();
      if (widget.split == null) {
        await splitCubit.createSplit(split, participants);
      } else {
        await splitCubit.updateSplit(split, participants);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
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

class _AddSplitParticipantSheet extends StatefulWidget {
  const _AddSplitParticipantSheet();

  @override
  State<_AddSplitParticipantSheet> createState() =>
      _AddSplitParticipantSheetState();
}

class _AddSplitParticipantSheetState extends State<_AddSplitParticipantSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _usePhoneContacts = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.addParticipants,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                AppSegmentedControl<bool>(
                  selectedValue: _usePhoneContacts,
                  margin: EdgeInsets.zero,
                  segmentHeight: 40,
                  iconSize: 16,
                  fontSize: 10.5,
                  selectedColor: colorScheme.secondary,
                  onChanged: (value) =>
                      setState(() => _usePhoneContacts = value),
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
                const SizedBox(height: 14),
                if (_usePhoneContacts)
                  _buildContactPickerTile(
                    label: tr.selectContactRequired,
                    icon: Icons.person_outline_rounded,
                    onTap: () => Navigator.pop(
                      context,
                      const _AddParticipantSheetResult.phoneContacts(),
                    ),
                  )
                else ...[
                  CustomTextField(
                    controller: _nameController,
                    labelText: tr.contactNameRequired,
                    hintText: tr.enterName,
                    prefixIcon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    isDense: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return tr.pleaseEnterContactName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _phoneController,
                    labelText: tr.phoneNumberOptional,
                    hintText: tr.enterPhoneNumber,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: FormInputUtils.phoneInputFormatters,
                    isDense: true,
                    validator: (value) {
                      if (!FormInputUtils.isValidOptionalPhone(value)) {
                        return tr.invalidPhone;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submitManualContact,
                      icon: const Icon(Icons.person_add_rounded),
                      label: Text(tr.add),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitManualContact() {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    Navigator.pop(
      context,
      _AddParticipantSheetResult.manual(
        ContactModel(
          name: _nameController.text.trim(),
          phone: phone.isEmpty ? null : phone,
        ),
      ),
    );
  }

  Widget _buildContactPickerTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.secondary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
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
}
