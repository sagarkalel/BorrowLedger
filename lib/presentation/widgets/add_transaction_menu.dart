import 'package:borrow_ledger/core/constants/app_constants.dart';
import 'package:borrow_ledger/core/theme/app_theme.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/screens/add_transaction_screen.dart';
import 'package:flutter/material.dart';

void showAddTransactionMenu(
  BuildContext context,
  VoidCallback refreshData, {
  int? prefilledContactId,
  String? prefilledContactName,
  String? prefilledContactPhone,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final tr = AppLocalizations.of(context)!;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Text(
                    tr.addNewTransaction,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionHeader(
                context,
                tr.cash,
                Icons.currency_rupee_rounded,
              ),
              const SizedBox(height: 8),
              _buildQuickActionTile(
                context,
                icon: Icons.call_made,
                title: tr.youGaveMoney,
                subtitle: tr.directCashLent,
                color: AppTheme.moneyOutColor,
                onTap: () => _navigateToAddTransactionScreen(
                  context,
                  type: AppConstants.typeLend,
                  category: AppConstants.categoryCash,
                  prefilledContactId: prefilledContactId,
                  prefilledContactName: prefilledContactName,
                  prefilledContactPhone: prefilledContactPhone,
                  refreshData: refreshData,
                ),
              ),
              const SizedBox(height: 8),
              _buildQuickActionTile(
                context,
                icon: Icons.call_received,
                title: tr.youGotMoney,
                subtitle: tr.directCashBorrowed,
                color: AppTheme.moneyInColor,
                onTap: () => _navigateToAddTransactionScreen(
                  context,
                  type: AppConstants.typeBorrow,
                  category: AppConstants.categoryCash,
                  prefilledContactId: prefilledContactId,
                  prefilledContactName: prefilledContactName,
                  prefilledContactPhone: prefilledContactPhone,
                  refreshData: refreshData,
                ),
              ),

              const SizedBox(height: 16),

              _buildSectionHeader(
                context,
                tr.udhari,
                Icons.shopping_basket_outlined,
              ),
              const SizedBox(height: 8),
              _buildQuickActionTile(
                context,
                icon: Icons.shopping_bag_rounded,
                title: tr.youGaveOnUdhari,
                subtitle: tr.soldItemsOnCredit,
                color: AppTheme.moneyOutColor,
                onTap: () => _navigateToAddTransactionScreen(
                  context,
                  type: AppConstants.typeLend,
                  category: AppConstants.categoryUdhari,
                  prefilledContactId: prefilledContactId,
                  prefilledContactName: prefilledContactName,
                  prefilledContactPhone: prefilledContactPhone,
                  refreshData: refreshData,
                ),
              ),
              const SizedBox(height: 8),
              _buildQuickActionTile(
                context,
                icon: Icons.shopping_cart_rounded,
                title: tr.youTookOnUdhari,
                subtitle: tr.boughtItemsOnCredit,
                color: AppTheme.moneyInColor,
                onTap: () => _navigateToAddTransactionScreen(
                  context,
                  type: AppConstants.typeBorrow,
                  category: AppConstants.categoryUdhari,
                  prefilledContactId: prefilledContactId,
                  prefilledContactName: prefilledContactName,
                  prefilledContactPhone: prefilledContactPhone,
                  refreshData: refreshData,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _navigateToAddTransactionScreen(
  BuildContext context, {
  required String type,
  required String category,
  required int? prefilledContactId,
  required String? prefilledContactName,
  required String? prefilledContactPhone,
  required VoidCallback refreshData,
}) async {
  Navigator.pop(context);
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddTransactionScreen(
        transactionType: type,
        transactionCategory: category,
        prefilledContactId: prefilledContactId,
        prefilledContactName: prefilledContactName,
        prefilledContactPhone: prefilledContactPhone,
      ),
    ),
  );

  if (result == true) {
    refreshData();
  }
}

Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
  final colorScheme = Theme.of(context).colorScheme;

  return Row(
    children: [
      Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
      const SizedBox(width: 5),
      Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

Widget _buildQuickActionTile(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  return Material(
    color: colorScheme.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.07),
      ),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    ),
  );
}
