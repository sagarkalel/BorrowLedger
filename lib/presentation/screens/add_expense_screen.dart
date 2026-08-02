import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/data/models/expense_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../cubit/expense_cubit.dart';
import '../widgets/app_amount_field.dart';
import '../widgets/app_date_field.dart';
import '../widgets/app_dialog_components.dart';
import '../widgets/app_dropdown_field.dart';
import '../widgets/app_list_avatar.dart';
import '../widgets/custom_text_field.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? expense; // For editing

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();

    // If editing, populate fields
    if (widget.expense != null) {
      _amountController.text = widget.expense!.amount.toString();
      _descriptionController.text = widget.expense!.description ?? '';
      _selectedDate = widget.expense!.date;
      _selectedCategory = widget.expense!.category;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? tr.editExpense : tr.addExpense)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expense indicator
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
                        label: tr.personalExpense,
                        centerIcon: Icons.receipt_long_rounded,
                        indicatorIcon: Icons.currency_rupee,
                        indicatorColor: colorScheme.secondary,
                        size: 38,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr.personalExpense,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tr.trackYourSpending,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
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

              // Amount field
              AppAmountField(
                controller: _amountController,
                labelText: tr.amount,
                hintText: '0.00',
                validator: (value) {
                  if (value == null || value.isEmpty) {
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

              AppDropdownField<String>(
                value: _selectedCategory,
                labelText: tr.category,
                prefixIcon: Icons.category_rounded,
                isDense: true,
                items: AppConstants.expenseCategories
                    .map(
                      (category) => AppDropdownItem(
                        value: category,
                        label: getCategoryLabel(context, category),
                        icon: getCategoryIcon(category),
                        color: getCategoryColor(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr.pleaseSelectCategory;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              AppDateField(
                labelText: tr.date,
                valueText: DateFormat(
                  AppConstants.dateFormat,
                ).format(_selectedDate),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 10),

              // Description field
              CustomTextField(
                controller: _descriptionController,
                labelText: tr.descriptionOptional,
                prefixIcon: Icons.notes_rounded,
                hintText: tr.whatDidYouSpendOn,
                isDense: true,
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 10),

              // Category quick tips
              AppDialogNotice(
                color: colorScheme.secondary,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: colorScheme.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr.chooseRightCategory,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveExpense,
                  child: Text(isEditing ? tr.updateExpense : tr.saveExpense),
                ),
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

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final expense = ExpenseModel(
        id: widget.expense?.id,
        amount: double.parse(_amountController.text),
        category: _selectedCategory!,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        date: _selectedDate,
      );

      if (widget.expense == null) {
        context.read<ExpenseCubit>().createExpense(expense);
      } else {
        context.read<ExpenseCubit>().updateExpense(expense);
      }

      Navigator.pop(context);
    }
  }
}
