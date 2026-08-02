import 'package:borrow_ledger/core/constants/app_functions.dart';
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
import 'contact_picker_screen.dart';

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

              _buildPaymentCoverageSummary(context),
              const SizedBox(height: 10),

              AppDateField(
                labelText: tr.dateRequired,
                valueText: DateFormat(
                  AppConstants.dateFormat,
                ).format(_selectedDate),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 10),

              CustomTextField(
                controller: _descriptionController,
                labelText: tr.descriptionOptional,
                prefixIcon: Icons.notes_rounded,
                hintText: tr.whatWasThisExpenseFor,
                isDense: true,
                maxLines: 2,
                maxLength: 200,
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

              const SizedBox(height: 12),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveSplit,
                  child: Text(isEditing ? tr.updateSplit : tr.createSplit),
                ),
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
                      _participants.removeAt(index);
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
                          labelText: 'Share',
                          value: shareAmount,
                        )
                      : _buildParticipantAmountField(
                          key: ValueKey('share-${participant.contact.id}'),
                          labelText: 'Share',
                          initialValue: participant.shareAmount,
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
                    labelText: 'Paid bill',
                    initialValue: participant.expensePaid,
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

  Widget _buildParticipantAmountField({
    required Key key,
    required String labelText,
    required double initialValue,
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
    final tr = AppLocalizations.of(context)!;
    final contact = await Navigator.push<ContactModel>(
      context,
      MaterialPageRoute(builder: (_) => const ContactPickerScreen()),
    );

    if (contact != null && mounted) {
      // Get or ensure contact has ID by checking database first
      ContactModel? savedContact;

      try {
        final contactRepo = context.read<ContactRepository>();
        final phoneToCheck = contact.phone?.trim() ?? '';

        if (phoneToCheck.isEmpty) {
          showWarningSnackbar(context, tr.contactMustHavePhoneNumber);
          return;
        }

        // Check if phone number already exists in participants list
        final existsInList = _participants.any(
          (p) => p.contact.phone?.trim() == phoneToCheck,
        );

        if (existsInList) {
          showWarningSnackbar(context, tr.thisContactIsAlreadyAdded);
          return;
        }

        // Check if contact exists in database by phone
        final existingContact = await contactRepo.getContactByPhone(
          phoneToCheck,
        );

        if (existingContact != null) {
          // Contact exists, use it
          savedContact = existingContact;
        } else {
          // Contact doesn't exist, create it
          final newContactId = await contactRepo.createContact(contact);
          savedContact = contact.copyWith(id: newContactId);
        }

        // Add to participants list
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
        showFailureSnackbar(context, tr.failedToSave);
      }
    }
  }

  void _saveSplit() {
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

      if (widget.split == null) {
        context.read<SplitCubit>().createSplit(split, participants);
      } else {
        context.read<SplitCubit>().updateSplit(split, participants);
      }

      Navigator.pop(context);
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
