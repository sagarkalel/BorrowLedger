import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AppPageLoadingState extends StatelessWidget {
  final String? message;
  final bool compact;

  const AppPageLoadingState({super.key, this.message, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: compact ? 20 : 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: compact ? 24 : 30,
              height: compact ? 24 : 30,
              child: CircularProgressIndicator(
                strokeWidth: compact ? 2.3 : 2.6,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message ?? tr?.loading ?? 'Loading...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AppSliverLoadingState extends StatelessWidget {
  final String? message;
  final bool compact;

  const AppSliverLoadingState({super.key, this.message, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: AppPageLoadingState(message: message, compact: compact),
    );
  }
}

class AppInlineLoadingState extends StatelessWidget {
  final String? message;
  final EdgeInsetsGeometry padding;

  const AppInlineLoadingState({
    super.key,
    this.message,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message ?? tr?.loading ?? 'Loading...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppLoadMoreFooter extends StatelessWidget {
  final bool isLoading;
  final bool hasMoreData;
  final bool hasItems;
  final int itemCount;
  final int minItemsToShowDone;
  final String? noMoreLabel;

  const AppLoadMoreFooter({
    super.key,
    required this.isLoading,
    required this.hasMoreData,
    required this.hasItems,
    this.itemCount = 0,
    this.minItemsToShowDone = 10,
    this.noMoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppInlineLoadingState(
        padding: EdgeInsets.symmetric(vertical: 14),
      );
    }

    if (!hasItems || hasMoreData || itemCount < minItemsToShowDone) {
      return const SizedBox.shrink();
    }

    final tr = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 20),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 56),
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.check_circle_outline_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.62),
            ),
            const SizedBox(width: 6),
            Text(
              noMoreLabel ?? tr?.noMoreRecords ?? 'No more records',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 56),
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
