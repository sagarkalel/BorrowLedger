import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/add_transaction_menu.dart';
import 'package:borrow_ledger/presentation/widgets/build_summary_card.dart';
import 'package:borrow_ledger/presentation/widgets/floating_tab_header_delegate.dart';
import 'package:borrow_ledger/presentation/widgets/settle_txn_dialog_with_partial_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/transaction_repository.dart';
import '../cubit/borrow_lend_cubit.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/transaction_list_item.dart';
import 'contact_transaction_detail_screen.dart';

class ContactWiseTransactionsScreen extends StatefulWidget {
  final int? contactId;
  final String? contactName;
  final String? contactPhone;

  const ContactWiseTransactionsScreen({
    super.key,
    this.contactId,
    this.contactName,
    this.contactPhone,
  });

  @override
  State<ContactWiseTransactionsScreen> createState() =>
      _ContactWiseTransactionsScreenState();
}

class _ContactWiseTransactionsScreenState
    extends State<ContactWiseTransactionsScreen> {
  bool _isLoading = true;
  List<TransactionModel> _transactions = [];
  double _totalLent = 0;
  double _totalBorrowed = 0;
  double _netBalance = 0;

  // Category filtering
  String? _filterCategory; // null, 'cash', or 'udhari'
  int _cashCount = 0;
  int _udhariCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final repo = context.read<TransactionRepository>();

      if (widget.contactId != null) {
        _transactions = await repo.getTransactionsByContact(widget.contactId!);
      } else {
        _transactions = await repo.getAllTransactions();
      }

      _totalLent = 0;
      _totalBorrowed = 0;
      _cashCount = 0;
      _udhariCount = 0;

      for (var transaction in _transactions) {
        if (transaction.type == AppConstants.typeLend) {
          _totalLent += transaction.amount;
        } else {
          _totalBorrowed += transaction.amount;
        }

        // Count by category
        if (transaction.category == AppConstants.categoryCash) {
          _cashCount++;
        } else if (transaction.category == AppConstants.categoryUdhari) {
          _udhariCount++;
        }
      }

      _netBalance = _totalLent - _totalBorrowed;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final tr = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr?.failedToLoad}: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Get filtered transactions
  List<TransactionModel> get _filteredTransactions {
    if (_filterCategory == null) {
      return _transactions;
    }
    return _transactions.where((t) => t.category == _filterCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(widget.contactName ?? tr.allContacts)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: _transactions.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: EmptyStateWidget(
                          icon: Icons.receipt_long_outlined,
                          title: widget.contactId != null
                              ? '${tr.noMatchingTransactions} ${widget.contactName}'
                              : tr.noTransactionsYet,
                          message: widget.contactId != null
                              ? '${tr.startTrackingYourMoneyWith} ${widget.contactName}'
                              : tr.addFirstTransaction,
                        ),
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        // Summary section
                        SliverToBoxAdapter(
                          child: _buildModernSummarySection(isDark),
                        ),

                        SliverToBoxAdapter(
                          child: Divider(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                            indent: 8,
                            endIndent: 8,
                          ),
                        ),

                        // Category filter chips
                        if (_cashCount > 0 || _udhariCount > 0)
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: FloatingTabHeaderDelegate(
                              minHeight: 45,
                              maxHeight: 45,
                              child: _buildCategoryFilters(isDark),
                            ),
                          ),

                        // Transactions header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tr.transactionHistory,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${_filteredTransactions.length} ${_filterCategory != null ? (_filterCategory == 'cash' ? 'cash' : 'udhari') : 'total'}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Transactions list (filtered)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final transaction = _filteredTransactions[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TransactionListItem(
                                  transaction: transaction,
                                  onTap: () => _navigateToDetail(transaction),
                                ),
                              );
                            }, childCount: _filteredTransactions.length),
                          ),
                        ),

                        // Bottom padding for FAB
                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      ],
                    ),
            ),
      floatingActionButton: widget.contactId != null
          ? FloatingActionButton.extended(
              onPressed: () => showAddTransactionMenu(
                context,
                _loadTransactions,
                prefilledContactId: widget.contactId,
                prefilledContactName: widget.contactName,
                prefilledContactPhone: widget.contactPhone,
              ),
              icon: const Icon(Icons.add),
              label: Text(tr.addTransaction),
            )
          : null,
    );
  }

  // Category filter chips widget
  Widget _buildCategoryFilters(bool isDark) {
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChipWidget(
              label: '${tr.all} (${_transactions.length})',
              isSelected: _filterCategory == null,
              onSelected: () => setState(() => _filterCategory = null),
            ),
            const SizedBox(width: 8),
            if (_cashCount > 0)
              FilterChipWidget(
                label: '${tr.cash} ($_cashCount)',
                icon: Icons.currency_rupee,
                color: AppTheme.successColor,
                isSelected: _filterCategory == AppConstants.categoryCash,
                onSelected: () =>
                    setState(() => _filterCategory = AppConstants.categoryCash),
              ),
            const SizedBox(width: 8),
            if (_udhariCount > 0)
              FilterChipWidget(
                label: '${tr.udhari} ($_udhariCount)',
                icon: Icons.shopping_basket,
                color: AppTheme.infoColor,
                isSelected: _filterCategory == AppConstants.categoryUdhari,
                onSelected: () => setState(
                  () => _filterCategory = AppConstants.categoryUdhari,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSummarySection(bool isDark) {
    final isPositive = _netBalance >= 0;
    final tr = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Net balance card with settle button
          _buildNetBalanceCard(context, isPositive, isDark),
          const SizedBox(height: 12),

          // Summary cards row
          Row(
            children: [
              Expanded(
                child: BuildSummaryCard(
                  title: tr.youGave,
                  amount: _totalLent,
                  icon: Icons.call_made,
                  color: AppTheme.successColor,
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BuildSummaryCard(
                  title: tr.youGot,
                  amount: _totalBorrowed,
                  icon: Icons.call_received,
                  color: AppTheme.warningColor,
                  isPositive: false,
                ),
              ),
            ],
          ),

          // Category breakdown if both exist
          if (_cashCount > 0 && _udhariCount > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCategoryBreakdownCard(
                    '💵 ${tr.cash}',
                    _cashCount,
                    AppTheme.successColor,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCategoryBreakdownCard(
                    '🛍️ ${tr.udhari}',
                    _udhariCount,
                    AppTheme.infoColor,
                    isDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Category breakdown card
  Widget _buildCategoryBreakdownCard(
    String label,
    int count,
    Color color,
    bool isDark,
  ) {
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              label.contains(tr.cash)
                  ? Icons.currency_rupee
                  : Icons.shopping_basket,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$count txn${count > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetBalanceCard(
    BuildContext context,
    bool isPositive,
    bool isDark,
  ) {
    final Color primaryColor = isPositive
        ? AppTheme.primaryGreen
        : AppTheme.warningColor;
    final Color secondaryColor = isPositive
        ? AppTheme.lightGreen
        : const Color(0xFFFFB74D);
    final Color accentColor = isPositive
        ? AppTheme.primaryBlue
        : const Color(0xFFEF6C00);
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor, accentColor],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tr.netBalance,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isPositive
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${isPositive ? '+' : '-'}₹${_netBalance.abs().toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.call_received : Icons.call_made,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPositive ? tr.youWillGet : tr.youWillGive,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Settle button - Only show if there's a balance
          if (widget.contactId != null && _netBalance != 0) ...[
            const SizedBox(height: 20),
            _buildSettleButton(isPositive),
          ],
        ],
      ),
    );
  }

  Widget _buildSettleButton(bool isPositive) {
    final tr = AppLocalizations.of(context)!;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      child: InkWell(
        onTap: _showSettleDialog,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                      : AppTheme.warningColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.done_all_rounded,
                  color: isPositive
                      ? AppTheme.primaryGreen
                      : AppTheme.warningColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr.settleUp,
                    style: TextStyle(
                      color: isPositive
                          ? AppTheme.primaryGreen
                          : AppTheme.warningColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    tr.clearThisBalance,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_rounded,
                color: isPositive
                    ? AppTheme.primaryGreen
                    : AppTheme.warningColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(TransactionModel transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactTransactionDetailScreen(
          transaction: transaction,
          onUpdate: _loadTransactions,
        ),
      ),
    );

    if (result == true) {
      _loadTransactions();
    }
  }

  void _showSettleDialog() {
    final isPositive = _netBalance >= 0;
    final settleType = isPositive
        ? AppConstants.typeBorrow
        : AppConstants.typeLend;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => SettleDialog(
        netBalance: _netBalance,
        isPositive: isPositive,
        isDark: isDark,
        onFullSettle: () {
          Navigator.pop(context);
          _settleBalance(settleType, _netBalance.abs());
        },
        onPartialSettle: (amount) {
          Navigator.pop(context);
          _settleBalance(settleType, amount);
        },
      ),
    );
  }

  Future<void> _settleBalance(String settleType, double amount) async {
    final tr = AppLocalizations.of(context)!;
    try {
      final settleTransaction = TransactionModel(
        type: settleType,
        category: AppConstants.categoryCash,
        contactId: widget.contactId!,
        amount: amount,
        description: tr.settlementTransaction,
        isSettlement: true,
        date: DateTime.now(),
        contactName: widget.contactName,
      );

      await context.read<BorrowLendCubit>().createTransaction(
        settleTransaction,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(tr.balanceSettledSuccessfully),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadTransactions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr.failedToUpdate}: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
