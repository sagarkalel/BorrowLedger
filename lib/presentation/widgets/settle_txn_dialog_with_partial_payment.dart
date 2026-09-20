// Settle Dialog Widget with Partial Settlement Option
import 'package:borrow_ledger/core/theme/app_theme.dart';
import 'package:borrow_ledger/core/utils/currency_formatter.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettleDialog extends StatefulWidget {
  final double netBalance;
  final bool isPositive;
  final bool isDark;
  final String? balanceLabel;
  final String? contactName;
  final double? directBalance;
  final double? splitBalance;
  final bool isZeroSettlement;
  final VoidCallback onFullSettle;
  final Function(double) onPartialSettle;

  const SettleDialog({
    super.key,
    required this.netBalance,
    required this.isPositive,
    required this.isDark,
    this.balanceLabel,
    this.contactName,
    this.directBalance,
    this.splitBalance,
    this.isZeroSettlement = false,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tr = AppLocalizations.of(context)!;
    final color = widget.isZeroSettlement
        ? colorScheme.secondary
        : widget.isPositive
        ? AppTheme.moneyInColor
        : AppTheme.moneyOutColor;
    final showPartialOption = !widget.isZeroSettlement;

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
                        widget.contactName == null
                            ? tr.settleBalance
                            : tr.settleWithContact(widget.contactName!),
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
                            widget.balanceLabel ?? tr.currentBalance,
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
                                  widget.isZeroSettlement
                                      ? Icons.swap_horiz_rounded
                                      : widget.isPositive
                                      ? Icons.call_received
                                      : Icons.call_made,
                                  size: 12,
                                  color: color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.isZeroSettlement
                                      ? tr.settled
                                      : widget.isPositive
                                      ? tr.toReceive
                                      : tr.toPay,
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
                        widget.isZeroSettlement
                            ? CurrencyFormatter.format(0)
                            : CurrencyFormatter.format(
                                widget.netBalance.abs(),
                                showSign: true,
                              ).replaceFirst(
                                '+',
                                widget.isPositive ? '+' : '-',
                              ),
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

                if (widget.directBalance != null ||
                    widget.splitBalance != null) ...[
                  _buildSettlementBreakdown(colorScheme, color, tr),
                  const SizedBox(height: 16),
                ],

                if (showPartialOption) ...[
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
                            onTap: () =>
                                setState(() => _isPartialSettle = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return tr.pleaseEnterAmount;
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return tr.invalidAmount;
                      }
                      if (amount > widget.netBalance.abs()) {
                        return '${tr.amountCanNotExceed} ${CurrencyFormatter.format(widget.netBalance.abs())}';
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
                  if (_partialRemainingText(tr) != null) ...[
                    Text(
                      _partialRemainingText(tr)!,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
                          _settlementInfoText(tr),
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
                          widget.isZeroSettlement
                              ? tr.clearOffsettingBalances
                              : _isPartialSettle
                              ? tr.settlePartial
                              : tr.settleFull,
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

  Widget _buildSettlementBreakdown(
    ColorScheme colorScheme,
    Color accent,
    AppLocalizations tr,
  ) {
    final direct = widget.directBalance ?? 0;
    final split = widget.splitBalance ?? 0;
    final net = widget.netBalance;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          _buildBreakdownRow(
            label: tr.directBalance,
            amount: direct,
            color: _signedAmountColor(direct, colorScheme),
          ),
          const SizedBox(height: 8),
          _buildBreakdownRow(
            label: tr.splitBalance,
            amount: split,
            color: _signedAmountColor(split, colorScheme),
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 10),
          _buildBreakdownRow(
            label: tr.netSettlement,
            amount: widget.isZeroSettlement ? 0 : net,
            color: accent,
            isStrong: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String label,
    required double amount,
    required Color color,
    bool isStrong = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isStrong ? FontWeight.w700 : FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          _signedMoney(amount),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isStrong ? FontWeight.w800 : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _signedAmountColor(double amount, ColorScheme colorScheme) {
    if (amount.abs() <= 0.01) return colorScheme.onSurfaceVariant;
    return amount > 0 ? AppTheme.moneyInColor : AppTheme.moneyOutColor;
  }

  String _signedMoney(double amount) {
    if (amount.abs() <= 0.01) return CurrencyFormatter.format(0);
    return CurrencyFormatter.format(
      amount.abs(),
      showSign: true,
    ).replaceFirst('+', amount > 0 ? '+' : '-');
  }

  String? _partialRemainingText(AppLocalizations tr) {
    if (!_isPartialSettle || widget.netBalance.abs() <= 0.01) return null;

    final amount = double.tryParse(_amountController.text);
    if (amount == null ||
        amount <= 0 ||
        amount > widget.netBalance.abs() + 0.01) {
      return null;
    }

    final remaining = widget.netBalance.abs() - amount;
    final signedRemaining = remaining <= 0.01
        ? CurrencyFormatter.format(0)
        : CurrencyFormatter.format(
            remaining,
            showSign: true,
          ).replaceFirst('+', widget.isPositive ? '+' : '-');

    return tr.remainingAfterSettlement(signedRemaining);
  }

  String _settlementInfoText(AppLocalizations tr) {
    if (_isPartialSettle) {
      return widget.isPositive
          ? tr.partialSettlementInfoPositive
          : tr.partialSettlementInfoNegative;
    }

    if (widget.isZeroSettlement) {
      return tr.noCashNeededOffset;
    }

    final contactName = widget.contactName;
    if (contactName == null || contactName.trim().isEmpty) {
      return widget.isPositive
          ? tr.fullSettlementInfoPositive
          : tr.fullSettlementInfoNegative;
    }

    final amount = CurrencyFormatter.format(widget.netBalance.abs());
    final direction = widget.isPositive
        ? tr.contactPaysYou(contactName, amount)
        : tr.youPayContact(contactName, amount);

    return '$direction\n${tr.contactSettlementKeepsHistory}';
  }

  List<Widget> _buildAmountSuggestions(Color color) {
    final fullAmount = widget.netBalance.abs();
    if (fullAmount <= 0.01) return [];

    final suggestions = [
      fullAmount * 0.25,
      fullAmount * 0.5,
      fullAmount * 0.75,
      fullAmount,
    ];

    return suggestions.map((amount) {
      final percentage = ((amount / fullAmount) * 100).round();
      return InkWell(
        onTap: () => setState(() {
          _amountController.text = amount.toStringAsFixed(2);
        }),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$percentage% (${CurrencyFormatter.format(amount)})',
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
