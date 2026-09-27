import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import 'app_list_avatar.dart';
import 'app_pill_badge.dart';

class ContactSummaryCard extends StatelessWidget {
  final String contactName;
  final String? phoneNumber;
  final String? avatar;
  final int transactionCount;
  final double netBalance;
  final int cashCount;
  final int udhariCount;
  final int sharedSpendCount;
  final int onBehalfCount;
  final int sharedCostCount;
  final int legacySharedSpendCount;
  final int splitCount;
  final double splitNet;
  final VoidCallback onTap;

  const ContactSummaryCard({
    super.key,
    required this.contactName,
    this.phoneNumber,
    this.avatar,
    required this.transactionCount,
    required this.netBalance,
    this.cashCount = 0,
    this.udhariCount = 0,
    this.sharedSpendCount = 0,
    this.onBehalfCount = 0,
    this.sharedCostCount = 0,
    this.legacySharedSpendCount = 0,
    this.splitCount = 0,
    this.splitNet = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tr = AppLocalizations.of(context)!;

    // netBalance > 0 means you'll GET money (they owe you) - Green
    // netBalance < 0 means you'll GIVE money (you owe them) - Orange
    final isSettled = netBalance.abs() < 0.01;
    final isPositive = netBalance > 0;
    final directionColor = isSettled
        ? colorScheme.onSurfaceVariant
        : isPositive
        ? AppTheme.moneyInColor
        : AppTheme.moneyOutColor;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              // Avatar with status indicator
              AppListAvatar(
                label: contactName,
                avatar: avatar,
                indicatorIcon: isSettled
                    ? Icons.done_all_rounded
                    : isPositive
                    ? Icons.call_received
                    : Icons.call_made,
                indicatorColor: directionColor,
                isSubtleIndicator: isSettled,
                size: 38,
              ),
              const SizedBox(width: 10),

              // Contact Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      contactName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    _buildMetaInfo(context),
                    if (splitCount > 0 && splitNet.abs() >= 0.01) ...[
                      const SizedBox(height: 4),
                      _buildSplitDueHint(context, tr),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Amount and direction
              _buildAmountSection(context, directionColor, isPositive, tr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final metaColor = colorScheme.onSurfaceVariant;
    final tr = AppLocalizations.of(context)!;
    final categories = _categoryCounts(tr);
    final hasPhone = phoneNumber?.isNotEmpty == true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPhone)
          Row(
            children: [
              Icon(Icons.phone, size: 10, color: metaColor),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  phoneNumber!,
                  style: TextStyle(fontSize: 10, color: metaColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (hasPhone && categories.isNotEmpty) const SizedBox(height: 3),
        if (categories.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) => _buildFittingCategoryBadges(
              context,
              categories,
              constraints.maxWidth,
            ),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long, size: 10, color: metaColor),
              const SizedBox(width: 3),
              Text(
                '$transactionCount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: metaColor,
                ),
              ),
            ],
          ),
      ],
    );
  }

  List<_CategoryCount> _categoryCounts(AppLocalizations tr) {
    return [
      _CategoryCount(tr.cash, cashCount),
      _CategoryCount(tr.udhari, udhariCount),
      _CategoryCount(tr.onBehalf, onBehalfCount),
      _CategoryCount(tr.sharedCost, sharedCostCount),
      _CategoryCount(tr.sharedSpend, legacySharedSpendCount),
      _CategoryCount(tr.splits, splitCount),
    ].where((category) => category.count > 0).toList();
  }

  Widget _buildFittingCategoryBadges(
    BuildContext context,
    List<_CategoryCount> categories,
    double availableWidth,
  ) {
    if (availableWidth <= 0) return const SizedBox.shrink();

    var visibleCount = categories.length;
    while (visibleCount > 0) {
      final hiddenCount = categories.length - visibleCount;
      final visibleWidth = _badgesWidth(
        context,
        categories.take(visibleCount).map((category) => category.text),
      );
      final overflowWidth = hiddenCount == 0
          ? 0.0
          : _badgesWidth(context, ['+$hiddenCount']);
      final spacing = hiddenCount == 0 || visibleCount == 0 ? 0.0 : 4.0;

      if (visibleWidth + spacing + overflowWidth <= availableWidth) break;
      visibleCount--;
    }

    final children = <Widget>[];
    for (var index = 0; index < visibleCount; index++) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 4));
      children.add(_buildCategoryBadge(context, categories[index]));
    }

    final hiddenCount = categories.length - visibleCount;
    if (hiddenCount > 0) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 4));
      children.add(_buildBadge(context, '+$hiddenCount'));
    }

    return ClipRect(
      child: Row(mainAxisSize: MainAxisSize.max, children: children),
    );
  }

  double _badgesWidth(BuildContext context, Iterable<String> labels) {
    const textStyle = TextStyle(fontSize: 9, fontWeight: FontWeight.w700);
    const horizontalPadding = 10.0;
    const spacing = 4.0;
    var width = 0.0;
    var isFirst = true;

    for (final label in labels) {
      if (!isFirst) width += spacing;
      isFirst = false;
      final painter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      width += painter.width + horizontalPadding;
    }
    return width;
  }

  Widget _buildSplitDueHint(BuildContext context, AppLocalizations tr) {
    final isPositive = splitNet > 0;
    final color = isPositive ? AppTheme.moneyInColor : AppTheme.moneyOutColor;

    return Row(
      children: [
        Icon(Icons.call_split_rounded, size: 11, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${tr.splits}: ${isPositive ? tr.toReceive : tr.toPay} ${CurrencyFormatter.format(splitNet.abs())}',
            style: TextStyle(
              fontSize: 10,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBadge(
    BuildContext context,
    _CategoryCount category,
  ) {
    return _buildBadge(context, category.text);
  }

  Widget _buildBadge(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildAmountSection(
    BuildContext context,
    Color directionColor,
    bool isPositive,
    AppLocalizations tr,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSettled = netBalance.abs() < 0.01;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Amount
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 108),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  CurrencyFormatter.format(netBalance.abs()),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: directionColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            // Direction badge
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 90),
              child: AppPillBadge(
                label: isSettled
                    ? tr.settled
                    : isPositive
                    ? tr.toReceive
                    : tr.toPay,
                icon: isSettled
                    ? Icons.done_all_rounded
                    : isPositive
                    ? Icons.call_received
                    : Icons.call_made,
                color: directionColor,
                fontSize: 7.5,
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right_rounded,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _CategoryCount {
  final String label;
  final int count;

  const _CategoryCount(this.label, this.count);

  String get text => '$label $count';
}
