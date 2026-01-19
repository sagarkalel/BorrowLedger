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
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Split indicator with modern gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.shade600,
                      Colors.purple.shade400,
                      Colors.deepPurple.shade500,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.pie_chart_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.splitExpense,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.95),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr.shareCostsWithFriends,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title field
              TextFormField(
                controller: _titleController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: tr.titleRequired,
                  hintText: tr.egDinnerAtRestaurant,
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr.pleaseEnterTitle;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Total amount and You paid row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalAmountController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: tr.totalAmountRequired,
                        prefixText: "${tr.rupee} ",
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.currency_rupee_rounded),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
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
                        if (_splitEqually) {
                          setState(() {
                            _calculateShares();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _paidByUserController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: tr.youPaidRequired,
                        prefixText: "${tr.rupee} ",
                        hintText: '0.00',
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet_rounded,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date picker
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: tr.dateRequired,
                    prefixIcon: const Icon(Icons.calendar_today_rounded),
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat(
                          AppConstants.dateFormat,
                        ).format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: tr.descriptionOptional,
                  prefixIcon: const Icon(Icons.notes_rounded),
                  hintText: tr.whatWasThisExpenseFor,
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 24),

              // Split method toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.blue.shade100,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _splitEqually
                            ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calculate_rounded,
                        size: 20,
                        color: _splitEqually
                            ? AppTheme.primaryBlue
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.splitEqually,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            tr.divideAmountEvenlyAmongAll,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
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
                      activeThumbColor: AppTheme.primaryBlue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _participants.isEmpty
                              ? Colors.orange.withValues(alpha: 0.1)
                              : AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_participants.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _participants.isEmpty
                                ? Colors.orange
                                : AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _addParticipant,
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: Text(tr.add),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Participants list or empty state
              if (_participants.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.grey[800]!
                          : Colors.orange.shade100,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.group_add_rounded,
                        size: 48,
                        color: isDark
                            ? Colors.orange.shade200
                            : Colors.orange.shade300,
                      ),
                      Text(
                        tr.noParticipantsAdded,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        tr.addAtLeastOnePerson,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
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
                          const SizedBox(height: 8),
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
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.blue.shade900.withValues(alpha: 0.2)
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.blue.shade700
                                : Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: AppTheme.primaryBlue,
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
                                      color: isDark
                                          ? Colors.blue.shade200
                                          : AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tr.yourShareWillBeRemaining,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
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

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSplit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    isEditing ? tr.updateSplit : tr.createSplit,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors
                .primaries[participant.contact.name.hashCode %
                    Colors.primaries.length]
                .withValues(alpha: 0.15),
            child: Text(
              participant.contact.name[0].toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color:
                    Colors.primaries[participant.contact.name.hashCode %
                        Colors.primaries.length],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.contact.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (participant.contact.phone != null)
                  Text(
                    participant.contact.phone!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),

          // Share amount (editable in manual mode)
          if (_splitEqually)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200, width: 1),
              ),
              child: Text(
                '₹${shareAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: participant.shareAmount.toStringAsFixed(2),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (value) {
                  final amount = double.tryParse(value) ?? 0;
                  setState(() {
                    _participants[index].shareAmount = amount;
                  });
                },
              ),
            ),

          const SizedBox(width: 8),

          // Remove button
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            color: Colors.red,
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(8),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr.contactMustHavePhoneNumber),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }

        // Check if phone number already exists in participants list
        final existsInList = _participants.any(
          (p) => p.contact.phone?.trim() == phoneToCheck,
        );

        if (existsInList) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr.thisContactIsAlreadyAdded),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
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
              paidAmount: 0,
            ),
          );
          if (_splitEqually) {
            _calculateShares();
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr.failedToSave}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _saveSplit() {
    final tr = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      if (_participants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.pleaseAddAtLeastOneParticipant),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      final totalAmount = double.parse(_totalAmountController.text);
      final paidByUser = double.parse(_paidByUserController.text);

      if (paidByUser > totalAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.amountYouPaidCannotExceedTotalAmount),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      // Validate shares if not split equally
      if (!_splitEqually) {
        final totalShares = _calculateTotalShares();
        final userShare = totalAmount - totalShares;

        if (userShare < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr.totalSharesExceedTotal),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
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
        return SplitParticipantModel(
          splitId: widget.split?.id ?? 0,
          contactId: p.contact.id!,
          shareAmount: p.shareAmount,
          paid: p.paidAmount,
          status: p.paidAmount >= p.shareAmount
              ? AppConstants.statusPaid
              : AppConstants.statusPending,
        );
      }).toList();

      if (widget.split == null) {
        context.read<SplitCubit>().createSplit(split, participants);
      } else {
        context.read<SplitCubit>().updateSplit(split);
      }

      Navigator.pop(context);
    }
  }
}

// Helper class to manage participant data
class ParticipantData {
  final ContactModel contact;
  double shareAmount;
  double paidAmount;

  ParticipantData({
    required this.contact,
    required this.shareAmount,
    this.paidAmount = 0,
  });
}
