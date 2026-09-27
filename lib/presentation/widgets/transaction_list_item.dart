import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/shared_expense_mode.dart';
import 'app_list_avatar.dart';
import 'app_pill_badge.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;
  final bool showContactIdentity;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.onTap,
    this.showContactIdentity = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLend = transaction.type == AppConstants.typeLend;
    final isCash = transaction.category == AppConstants.categoryCash;
    final isSplit = transaction.category == AppConstants.categorySplit;
    final isShared = transaction.category == AppConstants.categorySharedSpend;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tr = AppLocalizations.of(context)!;

    final actionColor = AppTheme.getTransactionActionColor(transaction.type);

    // Category color (cash = teal, udhari = amber)
    final categoryColor = AppTheme.getCategoryColor(
      transaction.category,
      isDark: theme.brightness == Brightness.dark,
    );

    final contactName = transaction.contactName ?? tr.unknown;
    final hasPhone =
        transaction.contactPhone != null &&
        transaction.contactPhone!.isNotEmpty;
    final verticalPadding = showContactIdentity ? 9.0 : 8.0;
    final avatarSize = showContactIdentity ? 38.0 : 36.0;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: verticalPadding,
          ),
          child: Row(
            children: [
              // Avatar with category icon
              AppListAvatar(
                label: contactName,
                avatar: transaction.contactAvatar,
                indicatorIcon: isSplit
                    ? Icons.call_split_rounded
                    : isShared
                    ? Icons.receipt_long_outlined
                    : isCash
                    ? Icons.currency_rupee
                    : Icons.shopping_bag,
                indicatorColor: categoryColor,
                size: avatarSize,
              ),
              const SizedBox(width: 10),

              // Contact Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Contact name
                    Text(
                      showContactIdentity
                          ? contactName
                          : _transactionTitle(
                              context,
                              isCash,
                              isSplit,
                              isShared,
                            ),
                      style: TextStyle(
                        fontSize: showContactIdentity ? 14 : 13.5,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Category badge and item info
                    _buildCategoryInfo(
                      context,
                      isCash,
                      isSplit,
                      isShared,
                      categoryColor,
                    ),
                    const SizedBox(height: 3),

                    // Phone, Date, Expected date
                    _buildMetaInfo(context, hasPhone),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Amount and direction
              _buildAmountSection(context, actionColor, isLend),
            ],
          ),
        ),
      ),
    );
  }

  String _transactionTitle(
    BuildContext context,
    bool isCash,
    bool isSplit,
    bool isShared,
  ) {
    final tr = AppLocalizations.of(context)!;
    if (isSplit) {
      final splitTitle = _splitTitle();
      return splitTitle?.isNotEmpty == true ? splitTitle! : tr.split;
    }
    if (isShared) {
      if (transaction.description?.trim().isNotEmpty == true) {
        return transaction.description!.trim();
      }
      return tr.sharedSpend;
    }
    if (!isCash && transaction.itemName?.trim().isNotEmpty == true) {
      return transaction.itemName!.trim();
    }
    if (transaction.description?.trim().isNotEmpty == true) {
      return transaction.description!.trim();
    }
    return isCash ? tr.cash : tr.udhari;
  }

  Widget _buildCategoryInfo(
    BuildContext context,
    bool isCash,
    bool isSplit,
    bool isShared,
    Color categoryColor,
  ) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final splitTitle = _splitTitle();

    return Row(
      children: [
        // Category badge
        Flexible(
          fit: FlexFit.loose,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 108),
            child: AppPillBadge(
              label: isSplit
                  ? tr.split
                  : isShared
                  ? _sharedCategoryLabel(tr)
                  : isCash
                  ? tr.cashBadge
                  : tr.udhariBadge,
              icon: isSplit
                  ? Icons.call_split_rounded
                  : isShared
                  ? Icons.receipt_long_outlined
                  : null,
              color: isSplit || isShared
                  ? categoryColor
                  : colorScheme.onSurfaceVariant,
              fontSize: 8.5,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            ),
          ),
        ),

        if (showContactIdentity &&
            isSplit &&
            splitTitle != null &&
            splitTitle.isNotEmpty) ...[
          const SizedBox(width: 6),
          Container(
            width: 2,
            height: 2,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              splitTitle,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        if (showContactIdentity && isShared) ...[
          const SizedBox(width: 6),
          Container(
            width: 2,
            height: 2,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _sharedSpendDetail(context),
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        // For udhari, show item name
        if (showContactIdentity &&
            !isCash &&
            !isSplit &&
            !isShared &&
            transaction.itemName != null) ...[
          const SizedBox(width: 6),
          Container(
            width: 2,
            height: 2,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              transaction.quantity != null
                  ? '${transaction.itemName} • ${transaction.quantity}'
                  : transaction.itemName!,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  String? _splitTitle() {
    return transaction.description
        ?.replaceFirst(RegExp(r'^(Split|Split history):\s*'), '')
        .trim();
  }

  String _sharedSpendDetail(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final contactName = transaction.contactName ?? tr.unknown;
    final amount = CurrencyFormatter.format(transaction.amount);

    if (SharedExpenseModeResolver.forTransaction(transaction) ==
        SharedExpenseMode.paidOnBehalf) {
      final contextText = transaction.sharedPaidByUser == true
          ? tr.paidForPerson(contactName)
          : tr.personPaidForYou(contactName);
      return contextText;
    }

    final total = transaction.sharedTotalAmount;
    final payer = transaction.sharedPaidByUser == true
        ? tr.youPaidLabel
        : tr.personPaid(contactName);
    final shareLabel = transaction.sharedPaidByUser == true
        ? tr.personShare(contactName)
        : tr.yourShare;
    final totalText = total == null
        ? ''
        : ' ${CurrencyFormatter.format(total)}';
    return '$payer$totalText • $shareLabel $amount';
  }

  String _directionBadgeLabel(AppLocalizations tr, bool isLend) {
    if (transaction.isSharedSpend) {
      final sharedMode = SharedExpenseModeResolver.forTransaction(transaction);
      if (sharedMode != SharedExpenseMode.legacy) {
        return _sharedOutcomeLabel(tr);
      }
    }
    return isLend ? tr.youGave : tr.youGot;
  }

  String _sharedOutcomeLabel(AppLocalizations tr) {
    final contactName = transaction.contactName ?? tr.unknown;
    final paidByUser =
        transaction.sharedPaidByUser ??
        (transaction.type == AppConstants.typeLend);
    return paidByUser
        ? tr.personOwesYouShort(contactName)
        : tr.youOwePersonShort(contactName);
  }

  String _sharedCategoryLabel(AppLocalizations tr) {
    switch (SharedExpenseModeResolver.forTransaction(transaction)) {
      case SharedExpenseMode.paidOnBehalf:
        return tr.onBehalf;
      case SharedExpenseMode.sharedCost:
        return tr.sharedCost;
      case SharedExpenseMode.legacy:
        return tr.sharedSpend;
    }
  }

  Widget _buildMetaInfo(BuildContext context, bool hasPhone) {
    final colorScheme = Theme.of(context).colorScheme;
    final metaColor = colorScheme.onSurfaceVariant;

    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: [
        if (showContactIdentity && hasPhone)
          _buildMetaToken(
            context,
            icon: Icons.phone,
            text: transaction.contactPhone!,
            color: metaColor,
            maxWidth: 126,
          ),
        _buildMetaToken(
          context,
          icon: Icons.calendar_today,
          text: DateFormat(AppConstants.dateFormat).format(transaction.date),
          color: metaColor,
        ),
        if (transaction.expectedDate != null)
          _buildMetaToken(
            context,
            icon: transaction.isOverdue ? Icons.warning : Icons.event,
            text: DateFormat(
              AppConstants.dateMonthFormat,
            ).format(transaction.expectedDate!),
            color: transaction.isOverdue ? Colors.red : metaColor,
            bold: true,
          ),
      ],
    );
  }

  Widget _buildMetaToken(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    double maxWidth = 82,
    bool bold = false,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9.5, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(
    BuildContext context,
    Color actionColor,
    bool isLend,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Amount
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 116),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  CurrencyFormatter.format(transaction.amount),
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: actionColor,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            transaction.isSettlement
                // Settlement badge
                ? _buildSettlementBadge(context)
                :
                  // Direction badge (what will happen)
                  _buildDirectionBadge(context, isLend, actionColor),
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

  Widget _buildSettlementBadge(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    final tr = AppLocalizations.of(context)!;

    return AppPillBadge(
      label: tr.settledBadge,
      icon: Icons.done_all,
      color: color,
      fontSize: 8,
    );
  }

  Widget _buildDirectionBadge(
    BuildContext context,
    bool isLend,
    Color actionColor,
  ) {
    final tr = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 116),
      child: AppPillBadge(
        label: _directionBadgeLabel(tr, isLend),
        icon: isLend ? Icons.call_made : Icons.call_received,
        color: actionColor,
        fontSize: 8,
      ),
    );
  }
}
