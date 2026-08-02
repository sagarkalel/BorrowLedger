import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/add_transaction_menu.dart';
import 'package:borrow_ledger/presentation/widgets/app_dialog_components.dart';
import 'package:borrow_ledger/presentation/widgets/build_summary_card.dart';
import 'package:borrow_ledger/presentation/widgets/floating_tab_header_delegate.dart';
import 'package:borrow_ledger/presentation/widgets/settle_txn_dialog_with_partial_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/split_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../cubit/borrow_lend_cubit.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/transaction_list_item.dart';
import 'transaction_details_screen.dart';
import 'split_detail_screen.dart';

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
  double _normalNetBalance = 0;
  double _splitNetBalance = 0;

  // Category filtering
  String? _filterCategory; // null, 'cash', 'udhari', or 'split'
  int _cashCount = 0;
  int _udhariCount = 0;
  int _splitCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final splitRepo = context.read<SplitRepository>();
      final repo = context.read<TransactionRepository>();
      await splitRepo.syncAllSplitTransactions();

      if (widget.contactId != null) {
        _transactions = await repo.getTransactionsByContact(widget.contactId!);
      } else {
        _transactions = await repo.getAllTransactions();
      }

      _totalLent = 0;
      _totalBorrowed = 0;
      _cashCount = 0;
      _udhariCount = 0;
      _splitCount = 0;
      var normalLent = 0.0;
      var normalBorrowed = 0.0;
      var splitLent = 0.0;
      var splitBorrowed = 0.0;

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
        } else if (transaction.category == AppConstants.categorySplit) {
          _splitCount++;
        }

        if (transaction.category == AppConstants.categorySplit) {
          if (transaction.type == AppConstants.typeLend) {
            splitLent += transaction.amount;
          } else {
            splitBorrowed += transaction.amount;
          }
        } else if (transaction.type == AppConstants.typeLend) {
          normalLent += transaction.amount;
        } else {
          normalBorrowed += transaction.amount;
        }
      }

      _netBalance = _totalLent - _totalBorrowed;
      _normalNetBalance = normalLent - normalBorrowed;
      _splitNetBalance = splitLent - splitBorrowed;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final tr = AppLocalizations.of(context);
        showFailureSnackbar(context, '${tr?.failedToLoad}: $e');
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                            height: 1,
                            thickness: 1,
                            color: colorScheme.outline.withValues(alpha: 0.08),
                            indent: 12,
                            endIndent: 12,
                          ),
                        ),

                        // Category filter chips
                        if (_cashCount > 0 ||
                            _udhariCount > 0 ||
                            _splitCount > 0)
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
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '${_filteredTransactions.length} ${_selectedFilterLabel(tr)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Transactions list (filtered)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final transaction = _filteredTransactions[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
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
  String _selectedFilterLabel(AppLocalizations tr) {
    switch (_filterCategory) {
      case AppConstants.categoryCash:
        return tr.cash.toLowerCase();
      case AppConstants.categoryUdhari:
        return tr.udhari.toLowerCase();
      case AppConstants.categorySplit:
        return tr.split.toLowerCase();
      default:
        return 'total';
    }
  }

  Widget _buildCategoryFilters(bool isDark) {
    final theme = Theme.of(context);
    final tr = AppLocalizations.of(context)!;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          children: [
            FilterChipWidget(
              label: '${tr.all} (${_transactions.length})',
              isSelected: _filterCategory == null,
              onSelected: () => setState(() => _filterCategory = null),
            ),
            const SizedBox(width: 8),
            if (_cashCount > 0) ...[
              FilterChipWidget(
                label: '${tr.cash} ($_cashCount)',
                icon: Icons.currency_rupee,
                color: AppTheme.successColor,
                isSelected: _filterCategory == AppConstants.categoryCash,
                onSelected: () =>
                    setState(() => _filterCategory = AppConstants.categoryCash),
              ),
              const SizedBox(width: 8),
            ],
            if (_udhariCount > 0) ...[
              FilterChipWidget(
                label: '${tr.udhari} ($_udhariCount)',
                icon: Icons.shopping_basket,
                color: AppTheme.infoColor,
                isSelected: _filterCategory == AppConstants.categoryUdhari,
                onSelected: () => setState(
                  () => _filterCategory = AppConstants.categoryUdhari,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (_splitCount > 0)
              FilterChipWidget(
                label: '${tr.split} ($_splitCount)',
                icon: Icons.call_split_rounded,
                color: AppTheme.splitColor,
                isSelected: _filterCategory == AppConstants.categorySplit,
                onSelected: () => setState(
                  () => _filterCategory = AppConstants.categorySplit,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSummarySection(bool isDark) {
    final isPositive = _netBalance > 0;
    final tr = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        children: [
          _buildNetBalanceCard(context, isPositive, isDark),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: BuildSummaryCard(
                  title: tr.youGave,
                  amount: _totalLent,
                  icon: Icons.call_made,
                  color: AppTheme.moneyOutColor,
                  isPositive: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BuildSummaryCard(
                  title: tr.youGot,
                  amount: _totalBorrowed,
                  icon: Icons.call_received,
                  color: AppTheme.moneyInColor,
                  isPositive: true,
                ),
              ),
            ],
          ),

          if (_cashCount > 0 && _udhariCount > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildCategoryBreakdownCard(
                    tr.cash,
                    _cashCount,
                    AppTheme.cashColor,
                    isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCategoryBreakdownCard(
                    tr.udhari,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              label.contains(tr.cash)
                  ? Icons.currency_rupee
                  : Icons.shopping_basket,
              color: color,
              size: 15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$count txn${count > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSettled = _netBalance.abs() < 0.01;
    final Color statusColor = isSettled
        ? colorScheme.secondary
        : isPositive
        ? AppTheme.moneyInColor
        : AppTheme.moneyOutColor;
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.07),
        ),
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
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isSettled
                              ? Icons.check_circle_outline_rounded
                              : isPositive
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: statusColor,
                          size: 15,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isSettled
                          ? ''
                          : isPositive
                          ? '+'
                          : '-'}₹${_netBalance.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSettled
                          ? Icons.done_all_rounded
                          : isPositive
                          ? Icons.call_received
                          : Icons.call_made,
                      color: statusColor,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSettled
                          ? tr.settled
                          : isPositive
                          ? tr.youWillGet
                          : tr.youWillGive,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (widget.contactId != null && _normalNetBalance.abs() >= 0.01) ...[
            const SizedBox(height: 12),
            _buildSettleButton(_normalNetBalance > 0),
          ],
          if (widget.contactId != null && _splitNetBalance.abs() >= 0.01) ...[
            const SizedBox(height: 8),
            _buildSplitSettlementNotice(),
          ],
        ],
      ),
    );
  }

  Widget _buildSplitSettlementNotice() {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() {
          _filterCategory = AppConstants.categorySplit;
        }),
        borderRadius: BorderRadius.circular(10),
        child: AppDialogNotice(
          color: AppTheme.splitColor,
          child: Row(
            children: [
              Icon(
                Icons.call_split_rounded,
                size: 18,
                color: AppTheme.splitColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${tr.split} balance is settled from ${tr.splitDetails}.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.filter_list_rounded,
                size: 16,
                color: AppTheme.splitColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettleButton(bool isPositive) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = isPositive
        ? AppTheme.moneyInColor
        : AppTheme.moneyOutColor;
    final tr = AppLocalizations.of(context)!;

    return Material(
      color: statusColor.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.18 : 0.1,
      ),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: _showSettleDialog,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor.withValues(alpha: 0.24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.done_all_rounded,
                  color: statusColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr.settleUp,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    tr.clearThisBalance,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_rounded, color: statusColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(TransactionModel transaction) async {
    if (transaction.sourceType == AppConstants.sourceTypeSplit &&
        transaction.sourceId != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SplitDetailScreen(splitId: transaction.sourceId!),
        ),
      );
      await _loadTransactions();
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailsScreen(
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
    final isPositive = _normalNetBalance > 0;
    final settleType = isPositive
        ? AppConstants.typeBorrow
        : AppConstants.typeLend;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => SettleDialog(
        netBalance: _normalNetBalance,
        isPositive: isPositive,
        isDark: isDark,
        onFullSettle: () {
          Navigator.pop(context);
          _settleBalance(settleType, _normalNetBalance.abs());
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
        showSuccessSnackbar(context, tr.balanceSettledSuccessfully);
        _loadTransactions();
      }
    } catch (e) {
      if (mounted) showFailureSnackbar(context, '${tr.failedToUpdate}: $e');
    }
  }
}
