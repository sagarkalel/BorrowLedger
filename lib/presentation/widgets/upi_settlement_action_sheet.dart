import 'package:borrow_ledger/core/theme/app_theme.dart';
import 'package:borrow_ledger/core/utils/currency_formatter.dart';
import 'package:borrow_ledger/core/utils/form_input_utils.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum UpiSettlementAction { pay, request, share, usePhoneNumber }

Future<UpiSettlementAction?> showUpiSettlementActionSheet(
  BuildContext context, {
  required bool isPayable,
  required String contactName,
  required double amount,
  String? contactPhone,
  bool hasVerifiedUpiId = false,
  bool showPhoneOption = false,
}) {
  final tr = AppLocalizations.of(context)!;
  final color = isPayable ? AppTheme.moneyOutColor : AppTheme.moneyInColor;

  return showModalBottomSheet<UpiSettlementAction>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final colorScheme = theme.colorScheme;
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.payments_outlined,
                        color: color,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.upiSettlement,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            contactName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(amount),
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPayable
                            ? Icons.call_made_rounded
                            : Icons.call_received_rounded,
                        color: color,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPayable ? tr.youNeedToPay : tr.youNeedToReceive,
                        style: TextStyle(
                          color: color,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _UpiActionCard(
                  icon: Icons.payments_outlined,
                  title: isPayable ? tr.payUsingUpiId : tr.requestViaUpi,
                  description: isPayable
                      ? hasVerifiedUpiId
                            ? tr.openUpiAppWithSavedUpiId
                            : tr.addContactUpiIdFirst
                      : tr.sharePaymentLinkToReceive,
                  color: color,
                  emphasized: true,
                  onTap: () => Navigator.pop(
                    sheetContext,
                    isPayable
                        ? UpiSettlementAction.pay
                        : UpiSettlementAction.request,
                  ),
                ),
                if (isPayable &&
                    showPhoneOption &&
                    FormInputUtils.isValidOptionalPhone(contactPhone)) ...[
                  const SizedBox(height: 10),
                  _UpiActionCard(
                    icon: Icons.phone_outlined,
                    title: tr.payUsingPhoneNumber,
                    description: tr.phoneNumberPaymentDescription,
                    color: color,
                    onTap: () => Navigator.pop(
                      sheetContext,
                      UpiSettlementAction.usePhoneNumber,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _UpiActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool emphasized;
  final VoidCallback onTap;

  const _UpiActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: emphasized
          ? color.withValues(alpha: 0.1)
          : colorScheme.onSurface.withValues(alpha: 0.035),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: emphasized ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
