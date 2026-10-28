import 'package:borrow_ledger/core/services/app_lock_discovery_service.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum AppLockDiscoveryDialogAction { setup }

class AppLockDiscoveryDialog extends StatelessWidget {
  final AppLockDiscoveryService? discoveryService;

  const AppLockDiscoveryDialog({super.key, this.discoveryService});

  static Future<AppLockDiscoveryDialogAction?> show(
    BuildContext context, {
    AppLockDiscoveryService? discoveryService,
  }) {
    return showDialog<AppLockDiscoveryDialogAction>(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          AppLockDiscoveryDialog(discoveryService: discoveryService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        tr.appLockDiscoveryTitle,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: tr.appLockDiscoveryMenuLabel,
                    padding: EdgeInsets.zero,
                    iconSize: 21,
                    onSelected: (value) {
                      if (value == 'dismiss') _dismissPermanently(context);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'dismiss',
                        child: Text(tr.appLockDiscoveryDontShowAgain),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                tr.appLockDiscoveryMessage,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 2,
                  runSpacing: 2,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(tr.appLockDiscoveryMaybeLater),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(AppLockDiscoveryDialogAction.setup),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(tr.appLockDiscoverySetUp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _dismissPermanently(BuildContext context) async {
    await (discoveryService ?? AppLockDiscoveryService.instance)
        .dismissPermanently();
    if (context.mounted) Navigator.of(context).pop();
  }
}
