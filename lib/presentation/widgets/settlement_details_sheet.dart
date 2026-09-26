import 'package:flutter/material.dart';

/// Displays the details of a recorded contact settlement.
///
/// The optional UPI fields are controlled by the caller so each existing
/// screen can keep showing exactly the information it showed before this
/// presentation was shared.
Future<void> showSettlementDetailsSheet(
  BuildContext context, {
  required String title,
  required String netSettlementLabel,
  required String netSettlement,
  required String directBalanceLabel,
  required String directBalance,
  required String splitBalanceLabel,
  required String splitBalance,
  String? offsetNote,
  String? settlementMethodLabel,
  String? settlementMethod,
  String? paymentReferenceLabel,
  String? paymentReference,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _SettlementDetailsSheet(
      title: title,
      netSettlementLabel: netSettlementLabel,
      netSettlement: netSettlement,
      directBalanceLabel: directBalanceLabel,
      directBalance: directBalance,
      splitBalanceLabel: splitBalanceLabel,
      splitBalance: splitBalance,
      offsetNote: offsetNote,
      settlementMethodLabel: settlementMethodLabel,
      settlementMethod: settlementMethod,
      paymentReferenceLabel: paymentReferenceLabel,
      paymentReference: paymentReference,
    ),
  );
}

class _SettlementDetailsSheet extends StatelessWidget {
  final String title;
  final String netSettlementLabel;
  final String netSettlement;
  final String directBalanceLabel;
  final String directBalance;
  final String splitBalanceLabel;
  final String splitBalance;
  final String? offsetNote;
  final String? settlementMethodLabel;
  final String? settlementMethod;
  final String? paymentReferenceLabel;
  final String? paymentReference;

  const _SettlementDetailsSheet({
    required this.title,
    required this.netSettlementLabel,
    required this.netSettlement,
    required this.directBalanceLabel,
    required this.directBalance,
    required this.splitBalanceLabel,
    required this.splitBalance,
    this.offsetNote,
    this.settlementMethodLabel,
    this.settlementMethod,
    this.paymentReferenceLabel,
    this.paymentReference,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasPaymentReference = paymentReference?.trim().isNotEmpty == true;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    _SettlementDetailRow(
                      label: netSettlementLabel,
                      value: netSettlement,
                      isPrimary: true,
                    ),
                    _SettlementDetailRow(
                      label: directBalanceLabel,
                      value: directBalance,
                    ),
                    _SettlementDetailRow(
                      label: splitBalanceLabel,
                      value: splitBalance,
                    ),
                    if (settlementMethod != null &&
                        settlementMethodLabel != null)
                      _SettlementDetailRow(
                        label: settlementMethodLabel!,
                        value: settlementMethod!,
                      ),
                    if (hasPaymentReference && paymentReferenceLabel != null)
                      _SettlementDetailRow(
                        label: paymentReferenceLabel!,
                        value: paymentReference!.trim(),
                      ),
                  ],
                ),
              ),
              if (offsetNote != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(
                      alpha: 0.55,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          offsetNote!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettlementDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPrimary;

  const _SettlementDetailRow({
    required this.label,
    required this.value,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isPrimary ? colorScheme.primary : colorScheme.onSurface,
      fontWeight: FontWeight.w800,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Text(
              ":  $value",
              textAlign: TextAlign.end,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}
