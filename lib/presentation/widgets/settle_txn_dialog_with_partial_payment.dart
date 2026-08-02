// Settle Dialog Widget with Partial Settlement Option
import 'package:borrow_ledger/core/theme/app_theme.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettleDialog extends StatefulWidget {
  final double netBalance;
  final bool isPositive;
  final bool isDark;
  final VoidCallback onFullSettle;
  final Function(double) onPartialSettle;

  const SettleDialog({
    super.key,
    required this.netBalance,
    required this.isPositive,
    required this.isDark,
    required this.onFullSettle,
    required this.onPartialSettle,
  });

  @override
  State<SettleDialog> createState() => _SettleDialogState();
}

class _SettleDialogState extends State<SettleDialog> {
  bool _isPartialSettle = false;
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isPositive
        ? AppTheme.moneyInColor
        : AppTheme.moneyOutColor;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr.settleBalance,
                        style: theme.dialogTheme.titleTextStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: widget.isDark ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tr.currentBalance,
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isPositive
                                      ? Icons.call_received
                                      : Icons.call_made,
                                  size: 12,
                                  color: color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.isPositive
                                      ? tr.youWillGet
                                      : tr.youWillGive,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.isPositive ? '+' : '-'}₹${widget.netBalance.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSettleTypeButton(
                          label: tr.fullSettlement,
                          icon: Icons.check_circle_outline,
                          isSelected: !_isPartialSettle,
                          onTap: () {
                            setState(() => _isPartialSettle = false);
                            _amountController.clear();
                          },
                        ),
                      ),
                      Expanded(
                        child: _buildSettleTypeButton(
                          label: tr.partial,
                          icon: Icons.payments_outlined,
                          isSelected: _isPartialSettle,
                          onTap: () => setState(() => _isPartialSettle = true),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_isPartialSettle) ...[
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: tr.settlementAmount,
                      hintText: tr.enterSettlementAmount,
                      prefixText: '₹ ',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_circle_up),
                        onPressed: () {
                          _amountController.text = widget.netBalance
                              .abs()
                              .toStringAsFixed(2);
                        },
                        tooltip: tr.setToFullBalance,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: color, width: 1),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return tr.pleaseEnterAmount;
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return tr.invalidAmount;
                      }
                      if (amount > widget.netBalance.abs()) {
                        return '${tr.amountCanNotExceed} ₹${widget.netBalance.abs().toStringAsFixed(2)}';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount suggestions
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _buildAmountSuggestions(color),
                  ),
                  const SizedBox(height: 16),
                ],

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isPartialSettle
                              ? (widget.isPositive
                                    ? tr.partialSettlementInfoPositive
                                    : tr.partialSettlementInfoNegative)
                              : (widget.isPositive
                                    ? tr.fullSettlementInfoPositive
                                    : tr.fullSettlementInfoNegative),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

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
                      child: ElevatedButton.icon(
                        onPressed: _handleSettle,
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: Text(
                          _isPartialSettle ? tr.settlePartial : tr.settleFull,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettleTypeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = widget.isPositive
        ? AppTheme.moneyInColor
        : AppTheme.moneyOutColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (widget.isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (widget.isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAmountSuggestions(Color color) {
    final fullAmount = widget.netBalance.abs();
    final suggestions = [
      fullAmount * 0.25,
      fullAmount * 0.5,
      fullAmount * 0.75,
      fullAmount,
    ];

    return suggestions.map((amount) {
      final percentage = ((amount / fullAmount) * 100).round();
      return InkWell(
        onTap: () => _amountController.text = amount.toStringAsFixed(2),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$percentage% (₹${amount.toStringAsFixed(0)})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _handleSettle() {
    if (_isPartialSettle) {
      if (_formKey.currentState!.validate()) {
        final amount = double.parse(_amountController.text);
        widget.onPartialSettle(amount);
      }
    } else {
      widget.onFullSettle();
    }
  }
}
