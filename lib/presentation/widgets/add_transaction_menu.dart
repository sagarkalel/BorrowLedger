import 'package:borrow_ledger/core/constants/app_constants.dart';
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
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final tr = AppLocalizations.of(context)!;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? Colors.grey[900] : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              tr.addNewTransaction,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // CASH SECTION
            _buildSectionHeader(context, tr.cashMoney, isDark),
            const SizedBox(height: 12),
            _buildQuickActionTile(
              context,
              icon: Icons.call_made,
              title: tr.youGaveMoney,
              subtitle: tr.directCashLent,
              color: Colors.green,
              isDark: isDark,
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
            const SizedBox(height: 10),
            _buildQuickActionTile(
              context,
              icon: Icons.call_received,
              title: tr.youGotMoney,
              subtitle: tr.directCashBorrowed,
              color: Colors.orange,
              isDark: isDark,
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

            const SizedBox(height: 20),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 20),

            // UDHARI SECTION
            _buildSectionHeader(context, tr.udhariItemsServices, isDark),
            const SizedBox(height: 12),
            _buildQuickActionTile(
              context,
              icon: Icons.shopping_bag_rounded,
              title: tr.youGaveOnUdhari,
              subtitle: tr.soldItemsOnCredit,
              color: Colors.orangeAccent,
              isDark: isDark,
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
            const SizedBox(height: 10),
            _buildQuickActionTile(
              context,
              icon: Icons.shopping_cart_rounded,
              title: tr.youTookOnUdhari,
              subtitle: tr.boughtItemsOnCredit,
              color: Colors.purple,
              isDark: isDark,
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

            const SizedBox(height: kToolbarHeight),
          ],
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

Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
  return Row(
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.grey[900],
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
  required bool isDark,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
        ],
      ),
    ),
  );
}
