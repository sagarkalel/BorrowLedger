import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/core/services/upi_service.dart';
import 'package:borrow_ledger/core/utils/currency_formatter.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/upi_app_picker_sheet.dart';
import 'package:flutter/material.dart';

Future<void> showUpiPhonePaymentSheet(
  BuildContext context, {
  required String contactName,
  required String phoneNumber,
  required double amount,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _UpiPhonePaymentSheet(
      contactName: contactName,
      phoneNumber: phoneNumber.trim(),
      amount: amount,
    ),
  );
}

class _UpiPhonePaymentSheet extends StatefulWidget {
  final String contactName;
  final String phoneNumber;
  final double amount;

  const _UpiPhonePaymentSheet({
    required this.contactName,
    required this.phoneNumber,
    required this.amount,
  });

  @override
  State<_UpiPhonePaymentSheet> createState() => _UpiPhonePaymentSheetState();
}

class _UpiPhonePaymentSheetState extends State<_UpiPhonePaymentSheet> {
  bool _isOpening = false;

  Future<void> _copyNumberAndOpenUpiApp() async {
    if (_isOpening) return;
    final tr = AppLocalizations.of(context)!;

    try {
      await const UpiService().copyToClipboard(widget.phoneNumber);
      if (!mounted) return;
      showSuccessSnackbar(context, tr.numberCopied);
    } catch (_) {
      if (mounted) {
        showFailureSnackbar(context, tr.somethingWentWrong);
      }
      return;
    }

    final upiService = const UpiService();
    setState(() => _isOpening = true);
    if (UpiService.supportsNativeUpiAppPicker) {
      final apps = await upiService.getAvailableUpiApps();
      if (!mounted) return;
      setState(() => _isOpening = false);

      if (apps.isEmpty) {
        showFailureSnackbar(context, tr.noUpiAppFound);
        return;
      }

      final selectedPackage = await showUpiAppPickerSheet(
        context,
        apps: apps,
        contactName: widget.contactName,
        phoneNumber: widget.phoneNumber,
        amount: widget.amount,
      );
      if (!mounted || selectedPackage == null) return;

      setState(() => _isOpening = true);
      final launchResult = await upiService.launchUpiApp(
        packageName: selectedPackage,
      );
      if (!mounted) return;

      setState(() => _isOpening = false);
      if (launchResult == UpiAppLaunchResult.launched) {
        Navigator.pop(context);
      } else {
        showFailureSnackbar(context, tr.noUpiAppFound);
      }
      return;
    }

    final launchResult = await upiService.launchUpiApp();
    if (!mounted) return;

    setState(() => _isOpening = false);
    if (launchResult == UpiAppLaunchResult.launched) {
      Navigator.pop(context);
    } else if (launchResult == UpiAppLaunchResult.unavailable) {
      showFailureSnackbar(context, tr.noUpiAppFound);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: Icon(
                        Icons.phone_outlined,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr.payUsingPhoneNumber,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.42,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        widget.contactName.trim().isEmpty
                            ? '?'
                            : widget.contactName.trim()[0].toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.contactName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            widget.phoneNumber,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(widget.amount),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.verifyRecipientBeforePaying,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr.phoneNumberCannotBeVerified,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                              fontSize: 11.5,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _StepRow(number: '1', text: tr.searchForNumberOrSelectContact),
              _StepRow(number: '2', text: tr.confirmRecipientName),
              _StepRow(number: '3', text: tr.confirmPaymentAmount),
              _StepRow(number: '4', text: tr.enterUpiPinOnlyInUpiApp),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isOpening ? null : _copyNumberAndOpenUpiApp,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: _isOpening
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.copy_outlined),
                  label: Text(tr.copyNumberAndOpenUpiApp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 11.5, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}
