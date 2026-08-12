import 'dart:io';

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/core/utils/app_loading_delay.dart';
import 'package:borrow_ledger/core/utils/pdf_report_theme.dart';
import 'package:borrow_ledger/data/models/split_model.dart';
import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/add_transaction_menu.dart';
import 'package:borrow_ledger/presentation/widgets/app_dialog_components.dart';
import 'package:borrow_ledger/presentation/widgets/app_loading_state.dart';
import 'package:borrow_ledger/presentation/widgets/build_summary_card.dart';
import 'package:borrow_ledger/presentation/widgets/floating_tab_header_delegate.dart';
import 'package:borrow_ledger/presentation/widgets/settle_txn_dialog_with_partial_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/split_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../cubit/borrow_lend_cubit.dart';
import '../widgets/app_pill_badge.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/share_name_prompt.dart';
import 'transaction_details_screen.dart';
import 'split_detail_screen.dart';

class _StatementRangeOption {
  final String label;
  final DateTimeRange? range;
  final bool isCustom;

  const _StatementRangeOption({
    required this.label,
    this.range,
    this.isCustom = false,
  });
}

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
  static const int _pageSize = 20;
  static const String _splitHistoryDescriptionPrefix = 'Split history: ';

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  int _filteredTotalCount = 0;
  final ScrollController _scrollController = ScrollController();
  List<TransactionModel> _allTransactions = [];
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
    _scrollController.addListener(_onScroll);
    _loadTransactions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || _isLoadingMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadTransactions({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final loadingDelay = _transactions.isEmpty
          ? AppLoadingDelay.initial()
          : AppLoadingDelay.refresh();
      final splitRepo = context.read<SplitRepository>();
      final repo = context.read<TransactionRepository>();
      await splitRepo.syncAllSplitTransactions();

      if (widget.contactId != null) {
        final directTransactions = await repo.getTransactionsByContact(
          widget.contactId!,
        );
        final contactSplits = await splitRepo.getSplitsByContact(
          widget.contactId!,
          limit: 100000,
          offset: 0,
        );
        _allTransactions = _mergeContactTransactionsWithSplitHistory(
          directTransactions,
          contactSplits,
        );
      } else {
        _allTransactions = await repo.getAllTransactions();
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

      for (var transaction in _allTransactions) {
        final affectsBalance = !_isSplitHistoryOnly(transaction);

        if (affectsBalance) {
          if (transaction.type == AppConstants.typeLend) {
            _totalLent += transaction.amount;
          } else {
            _totalBorrowed += transaction.amount;
          }
        }

        // Count by category
        if (transaction.category == AppConstants.categoryCash) {
          _cashCount++;
        } else if (transaction.category == AppConstants.categoryUdhari) {
          _udhariCount++;
        } else if (transaction.category == AppConstants.categorySplit) {
          _splitCount++;
        }

        if (!affectsBalance) {
          continue;
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

      final page = await _loadTransactionsPage(0);
      final totalCount = await _getTransactionCount();

      await loadingDelay;

      if (!mounted) return;
      setState(() {
        _transactions = page;
        _filteredTotalCount = totalCount;
        _currentPage = 0;
        _hasMoreData = page.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        final tr = AppLocalizations.of(context);
        showFailureSnackbar(context, '${tr?.failedToLoad}: $e');
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final loadingDelay = AppLoadingDelay.loadMore();
      final newTransactions = await _loadTransactionsPage(nextPage);
      await loadingDelay;

      if (!mounted) return;
      setState(() {
        _transactions = [..._transactions, ...newTransactions];
        _currentPage = nextPage;
        _hasMoreData = newTransactions.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      final tr = AppLocalizations.of(context);
      showFailureSnackbar(context, '${tr?.failedToLoad}: $e');
    }
  }

  Future<List<TransactionModel>> _loadTransactionsPage(int page) async {
    final repo = context.read<TransactionRepository>();
    final offset = page * _pageSize;

    if (widget.contactId != null) {
      final filtered = _filterCategory == null
          ? _allTransactions
          : _allTransactions
                .where((transaction) => transaction.category == _filterCategory)
                .toList();
      return filtered.skip(offset).take(_pageSize).toList();
    }

    if (_filterCategory != null) {
      return repo.getTransactionsByCategory(
        _filterCategory!,
        limit: _pageSize,
        offset: offset,
      );
    }

    return repo.getAllTransactions(limit: _pageSize, offset: offset);
  }

  Future<int> _getTransactionCount() {
    if (widget.contactId != null) {
      if (_filterCategory == null) return Future.value(_allTransactions.length);
      return Future.value(
        _allTransactions
            .where((transaction) => transaction.category == _filterCategory)
            .length,
      );
    }

    return context.read<TransactionRepository>().getTransactionCount(
      contactId: widget.contactId,
      category: _filterCategory,
    );
  }

  List<TransactionModel> _mergeContactTransactionsWithSplitHistory(
    List<TransactionModel> directTransactions,
    List<SplitExpenseModel> contactSplits,
  ) {
    final existingSplitIds = directTransactions
        .where(
          (transaction) =>
              transaction.category == AppConstants.categorySplit &&
              transaction.sourceType == AppConstants.sourceTypeSplit &&
              transaction.sourceId != null,
        )
        .map((transaction) => transaction.sourceId!)
        .toSet();

    final splitHistoryRows = <TransactionModel>[];
    for (final split in contactSplits) {
      final splitId = split.id;
      if (splitId == null || existingSplitIds.contains(splitId)) continue;

      final participants = split.participants ?? [];
      SplitParticipantModel? contactParticipant;
      for (final participant in participants) {
        if (participant.contactId == widget.contactId) {
          contactParticipant = participant;
          break;
        }
      }
      if (contactParticipant == null) continue;

      final netAmount =
          contactParticipant.shareAmount - contactParticipant.expensePaid;
      final displayAmount = netAmount.abs() >= 0.01
          ? netAmount.abs()
          : contactParticipant.shareAmount;

      splitHistoryRows.add(
        TransactionModel(
          type: netAmount >= 0
              ? AppConstants.typeLend
              : AppConstants.typeBorrow,
          category: AppConstants.categorySplit,
          contactId: widget.contactId!,
          amount: displayAmount,
          description: '$_splitHistoryDescriptionPrefix${split.title}',
          date: split.date,
          isSettlement: true,
          sourceType: AppConstants.sourceTypeSplit,
          sourceId: splitId,
          contactName: widget.contactName,
          contactPhone: widget.contactPhone,
        ),
      );
    }

    return [...directTransactions, ...splitHistoryRows]..sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      return (b.id ?? 0).compareTo(a.id ?? 0);
    });
  }

  bool _isSplitHistoryOnly(TransactionModel transaction) {
    return transaction.category == AppConstants.categorySplit &&
        transaction.isSettlement &&
        transaction.sourceType == AppConstants.sourceTypeSplit &&
        transaction.description?.startsWith(_splitHistoryDescriptionPrefix) ==
            true;
  }

  void _setCategoryFilter(String? category) {
    if (_filterCategory == category) return;

    setState(() {
      _filterCategory = category;
      _transactions = [];
      _filteredTotalCount = 0;
      _hasMoreData = true;
      _currentPage = 0;
    });
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.contactName ?? tr.allContacts),
        actions: [
          if (widget.contactId != null && _allTransactions.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: tr.moreOptions,
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'share_statement') {
                  _shareContactStatement();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'share_statement',
                  child: Row(
                    children: [
                      const Icon(Icons.ios_share_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text(tr.sharePdfStatement),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading && _allTransactions.isEmpty
          ? const AppPageLoadingState(compact: true)
          : RefreshIndicator(
              onRefresh: () => _loadTransactions(showLoading: false),
              child: _allTransactions.isEmpty && !_isLoading
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
                          compact: true,
                        ),
                      ),
                    )
                  : CustomScrollView(
                      controller: _scrollController,
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
                                  '$_filteredTotalCount ${_selectedFilterLabel(tr)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_isLoading)
                          _buildRecordsLoadingSliver()
                        else if (_transactions.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: EmptyStateWidget(
                              icon: Icons.receipt_long_outlined,
                              title: tr.noMatchingTransactions,
                              message: tr.tryAdjustingFilters,
                              compact: true,
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                if (index == _transactions.length) {
                                  return AppLoadMoreFooter(
                                    isLoading: _isLoadingMore,
                                    hasMoreData: _hasMoreData,
                                    hasItems: _transactions.isNotEmpty,
                                    itemCount: _transactions.length,
                                  );
                                }

                                final transaction = _transactions[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: _CompactContactTransactionCard(
                                    transaction: transaction,
                                    onTap: () => _navigateToDetail(transaction),
                                  ),
                                );
                              }, childCount: _transactions.length + 1),
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
              label: '${tr.all} (${_allTransactions.length})',
              isSelected: _filterCategory == null,
              onSelected: () => _setCategoryFilter(null),
            ),
            const SizedBox(width: 8),
            if (_cashCount > 0) ...[
              FilterChipWidget(
                label: '${tr.cash} ($_cashCount)',
                icon: Icons.currency_rupee,
                color: AppTheme.successColor,
                isSelected: _filterCategory == AppConstants.categoryCash,
                onSelected: () => _setCategoryFilter(AppConstants.categoryCash),
              ),
              const SizedBox(width: 8),
            ],
            if (_udhariCount > 0) ...[
              FilterChipWidget(
                label: '${tr.udhari} ($_udhariCount)',
                icon: Icons.shopping_basket,
                color: AppTheme.infoColor,
                isSelected: _filterCategory == AppConstants.categoryUdhari,
                onSelected: () =>
                    _setCategoryFilter(AppConstants.categoryUdhari),
              ),
              const SizedBox(width: 8),
            ],
            if (_splitCount > 0)
              FilterChipWidget(
                label: '${tr.split} ($_splitCount)',
                icon: Icons.call_split_rounded,
                color: AppTheme.splitColor,
                isSelected: _filterCategory == AppConstants.categorySplit,
                onSelected: () =>
                    _setCategoryFilter(AppConstants.categorySplit),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsLoadingSliver() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: AppPageLoadingState(compact: true),
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
                  isCompact: true,
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
                  isCompact: true,
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
                      isSettled
                          ? '₹0'
                          : '${isPositive ? '+' : '-'}₹${_netBalance.abs().toStringAsFixed(2)}',
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
        onTap: () => _setCategoryFilter(AppConstants.categorySplit),
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

  Future<void> _shareContactStatement() async {
    final range = await _pickStatementRange();
    if (range == null || !mounted) return;

    final tr = AppLocalizations.of(context)!;
    var loadingShown = false;

    try {
      final ownerName = await ensureShareOwnerName(context);
      if (ownerName == null || !mounted) return;

      loadingShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AppLoadingDialog(message: tr.preparingStatement),
      );

      final file = await _createContactStatementPdf(range, ownerName);

      if (!mounted) return;
      if (loadingShown) {
        Navigator.pop(context);
        loadingShown = false;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              '${tr.borrowLedgerStatement}: ${widget.contactName ?? tr.allContacts} (${_formatDate(range.start)} - ${_formatDate(range.end)})',
          subject:
              '${tr.borrowLedgerStatement} - ${widget.contactName ?? tr.allContacts}',
        ),
      );
    } catch (e) {
      if (mounted && loadingShown) {
        Navigator.pop(context);
      }
      if (mounted) {
        showFailureSnackbar(context, '${tr.shareFailed} $e');
      }
    }
  }

  Future<DateTimeRange?> _pickStatementRange() async {
    final tr = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final options = [
      _StatementRangeOption(
        label: tr.thisWeek,
        range: DateTimeRange(
          start: today.subtract(Duration(days: today.weekday - 1)),
          end: _endOfDay(today),
        ),
      ),
      _StatementRangeOption(
        label: tr.last15Days,
        range: DateTimeRange(
          start: today.subtract(const Duration(days: 14)),
          end: _endOfDay(today),
        ),
      ),
      _StatementRangeOption(
        label: tr.thisMonth,
        range: DateTimeRange(
          start: DateTime(today.year, today.month),
          end: _endOfDay(today),
        ),
      ),
      _StatementRangeOption(
        label: tr.last3Months,
        range: DateTimeRange(
          start: DateTime(today.year, today.month - 2),
          end: _endOfDay(today),
        ),
      ),
      _StatementRangeOption(
        label: tr.last6Months,
        range: DateTimeRange(
          start: DateTime(today.year, today.month - 5),
          end: _endOfDay(today),
        ),
      ),
      _StatementRangeOption(
        label: tr.last1Year,
        range: DateTimeRange(
          start: DateTime(today.year - 1, today.month, today.day),
          end: _endOfDay(today),
        ),
      ),
      _StatementRangeOption(label: tr.customRange, isCustom: true),
    ];

    final selected = await showModalBottomSheet<_StatementRangeOption>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final option = options[index];
              return ListTile(
                leading: Icon(
                  option.isCustom
                      ? Icons.date_range_rounded
                      : Icons.calendar_month_rounded,
                ),
                title: Text(option.label),
                subtitle: option.range == null
                    ? null
                    : Text(
                        '${_formatDate(option.range!.start)} - ${_formatDate(option.range!.end)}',
                      ),
                onTap: () => Navigator.pop(context, option),
              );
            },
          ),
        );
      },
    );

    if (selected == null) return null;
    if (!selected.isCustom) return selected.range;
    if (!mounted) return null;

    final customRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: today.subtract(const Duration(days: 29)),
        end: today,
      ),
    );

    if (customRange == null) return null;
    return DateTimeRange(
      start: DateTime(
        customRange.start.year,
        customRange.start.month,
        customRange.start.day,
      ),
      end: _endOfDay(customRange.end),
    );
  }

  Future<File> _createContactStatementPdf(
    DateTimeRange range,
    String ownerName,
  ) async {
    final tr = AppLocalizations.of(context)!;
    final contactName = widget.contactName ?? tr.allContacts;
    final contactPhone = widget.contactPhone;
    final periodTransactions = _allTransactions
        .where((transaction) => _matchesStatementFilter(transaction))
        .where(
          (transaction) =>
              !transaction.date.isBefore(range.start) &&
              !transaction.date.isAfter(range.end),
        )
        .toList();
    final openingTransactions = _allTransactions
        .where((transaction) => _matchesStatementFilter(transaction))
        .where((transaction) => transaction.date.isBefore(range.start))
        .toList();

    final openingBalance = _netForTransactions(openingTransactions);
    final periodLent = _sumByType(periodTransactions, AppConstants.typeLend);
    final periodBorrowed = _sumByType(
      periodTransactions,
      AppConstants.typeBorrow,
    );
    final closingBalance = openingBalance + periodLent - periodBorrowed;
    final statementFilter = _statementFilterLabel(tr);
    final generatedAt = DateTime.now();
    final pdfTheme = await PdfReportTheme.load();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _statementPageTheme(pdfTheme),
        build: (context) => [
          _statementHeader(
            ownerName: ownerName,
            contactName: contactName,
            contactPhone: contactPhone,
            range: range,
            filterLabel: statementFilter,
            generatedAt: generatedAt,
            tr: tr,
          ),
          pw.SizedBox(height: 16),
          _statementSummaryGrid(
            openingBalance: openingBalance,
            periodLent: periodLent,
            periodBorrowed: periodBorrowed,
            closingBalance: closingBalance,
            tr: tr,
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            '${tr.transactions} (${periodTransactions.length})',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (periodTransactions.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: _statementBoxDecoration(PdfColors.grey200),
              child: pw.Text(tr.noTransactionsInDateRange),
            )
          else
            _statementTransactionTable(periodTransactions, tr),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final safeName = _safeFilePart(contactName);
    final start = _fileDatePart(range.start);
    final end = _fileDatePart(range.end);
    final file = File(
      '${dir.path}/HisaabMate_Statement_${safeName}_${start}_to_$end.pdf',
    );
    await file.writeAsBytes(await pdf.save(), flush: true);
    return file;
  }

  pw.Widget _statementHeader({
    required String ownerName,
    required String contactName,
    required String? contactPhone,
    required DateTimeRange range,
    required String filterLabel,
    required DateTime generatedAt,
    required AppLocalizations tr,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(bottom: 14),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  tr.borrowLedgerStatement,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  contactName,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (contactPhone != null && contactPhone.trim().isNotEmpty)
                  pw.Text('${tr.phone}: $contactPhone'),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Container(
            width: 210,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('${tr.generatedBy}: $ownerName'),
                pw.SizedBox(height: 3),
                pw.Text('${tr.generatedOn}: ${_formatDateTime(generatedAt)}'),
                pw.SizedBox(height: 3),
                pw.Text(
                  '${tr.period}: ${_formatDate(range.start)} - ${_formatDate(range.end)}',
                  textAlign: pw.TextAlign.right,
                ),
                pw.SizedBox(height: 3),
                pw.Text('${tr.filter}: $filterLabel'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _statementSummaryGrid({
    required double openingBalance,
    required double periodLent,
    required double periodBorrowed,
    required double closingBalance,
    required AppLocalizations tr,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: [tr.opening, tr.youGave, tr.youGot, tr.closing],
      data: [
        [
          _statementMoney(openingBalance),
          _statementMoney(periodLent),
          _statementMoney(periodBorrowed),
          _statementMoney(closingBalance),
        ],
      ],
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellAlignment: pw.Alignment.center,
    );
  }

  pw.Widget _statementTransactionTable(
    List<TransactionModel> transactions,
    AppLocalizations tr,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: [tr.date, tr.type, tr.category, tr.details, tr.amount],
      data: transactions.map((transaction) {
        final isSplitHistory = _isSplitHistoryOnly(transaction);
        return [
          _formatDate(transaction.date),
          isSplitHistory
              ? tr.settledBadge
              : transaction.type == AppConstants.typeLend
              ? tr.youGave
              : tr.youGot,
          _categoryLabel(transaction.category, tr),
          _transactionDetails(transaction, tr),
          isSplitHistory
              ? tr.settled
              : _statementMoney(
                  transaction.type == AppConstants.typeLend
                      ? transaction.amount
                      : -transaction.amount,
                ),
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 7.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerRight,
      },
      columnWidths: const {
        0: pw.FixedColumnWidth(56),
        1: pw.FixedColumnWidth(50),
        2: pw.FixedColumnWidth(48),
        4: pw.FixedColumnWidth(64),
      },
    );
  }

  pw.PageTheme _statementPageTheme(pw.ThemeData theme) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      theme: theme,
      buildBackground: (_) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Container(color: PdfColors.white),
      ),
    );
  }

  pw.BoxDecoration _statementBoxDecoration(PdfColor color) {
    return pw.BoxDecoration(
      color: color,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
    );
  }

  bool _matchesStatementFilter(TransactionModel transaction) {
    return _filterCategory == null || transaction.category == _filterCategory;
  }

  double _netForTransactions(List<TransactionModel> transactions) {
    return transactions.fold<double>(0, (sum, transaction) {
      if (_isSplitHistoryOnly(transaction)) return sum;
      return sum +
          (transaction.type == AppConstants.typeLend
              ? transaction.amount
              : -transaction.amount);
    });
  }

  double _sumByType(List<TransactionModel> transactions, String type) {
    return transactions
        .where(
          (transaction) =>
              !_isSplitHistoryOnly(transaction) && transaction.type == type,
        )
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  String _statementFilterLabel(AppLocalizations tr) {
    if (_filterCategory == null) return tr.all;
    return _categoryLabel(_filterCategory!, tr);
  }

  String _categoryLabel(String category, AppLocalizations tr) {
    switch (category) {
      case AppConstants.categoryCash:
        return tr.cash;
      case AppConstants.categoryUdhari:
        return tr.udhari;
      case AppConstants.categorySplit:
        return tr.split;
      default:
        return category;
    }
  }

  String _transactionDetails(
    TransactionModel transaction,
    AppLocalizations tr,
  ) {
    if (_isSplitHistoryOnly(transaction)) {
      final splitTitle = transaction.description
          ?.replaceFirst(_splitHistoryDescriptionPrefix, '')
          .trim();
      return splitTitle?.isNotEmpty == true ? splitTitle! : tr.split;
    }
    if (transaction.isSettlement) return 'Settlement';
    final parts = [
      if (transaction.description?.trim().isNotEmpty == true)
        transaction.description!.trim(),
      if (transaction.itemName?.trim().isNotEmpty == true)
        transaction.itemName!.trim(),
      if (transaction.quantity?.trim().isNotEmpty == true)
        transaction.quantity!.trim(),
    ];
    return parts.isEmpty ? '-' : parts.join(' | ');
  }

  String _statementMoney(double amount) {
    final sign = amount < 0 ? '-' : '';
    return '${sign}INR ${amount.abs().toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  String _formatDateTime(DateTime date) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(date);

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  String _safeFilePart(String value) {
    final safe = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return safe.isEmpty ? 'contact' : safe;
  }

  String _fileDatePart(DateTime date) => DateFormat('ddMMMyyyy').format(date);

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

class _CompactContactTransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;

  const _CompactContactTransactionCard({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLend = transaction.type == AppConstants.typeLend;
    final isSplit = transaction.category == AppConstants.categorySplit;
    final directionColor = AppTheme.getTransactionDirectionColor(
      transaction.type,
    );
    final categoryColor = AppTheme.getCategoryColor(
      transaction.category,
      isDark: theme.brightness == Brightness.dark,
    );
    final title = _title(context);
    final subtitle = _subtitle(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSplit
                      ? Icons.call_split_rounded
                      : transaction.isSettlement
                      ? Icons.done_all_rounded
                      : transaction.category == AppConstants.categoryCash
                      ? Icons.currency_rupee_rounded
                      : Icons.shopping_bag_rounded,
                  size: 18,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15.5,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                            color: directionColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AppPillBadge(
                          label: _categoryLabel(context),
                          icon: isSplit ? Icons.call_split_rounded : null,
                          color: categoryColor,
                          fontSize: 8.5,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          DateFormat(
                            AppConstants.dateMonthFormat,
                          ).format(transaction.date),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (transaction.expectedDate != null) ...[
                          const SizedBox(width: 6),
                          Icon(
                            transaction.isOverdue
                                ? Icons.warning_rounded
                                : Icons.event_rounded,
                            size: 10,
                            color: transaction.isOverdue
                                ? Colors.red
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            DateFormat(
                              AppConstants.dateMonthFormat,
                            ).format(transaction.expectedDate!),
                            style: TextStyle(
                              fontSize: 10,
                              color: transaction.isOverdue
                                  ? Colors.red
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          transaction.isSettlement
                              ? tr.settledBadge
                              : isLend
                              ? tr.youWillGet
                              : tr.youWillGive,
                          style: TextStyle(
                            fontSize: 10,
                            color: directionColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.15,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _title(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    if (transaction.category == AppConstants.categorySplit) {
      final splitTitle = transaction.description
          ?.replaceFirst(RegExp(r'^(Split|Split history):\s*'), '')
          .trim();
      return splitTitle?.isNotEmpty == true ? splitTitle! : tr.split;
    }
    if (transaction.isSettlement) return tr.settlementTransaction;
    if (transaction.category == AppConstants.categoryUdhari &&
        transaction.itemName?.trim().isNotEmpty == true) {
      return transaction.itemName!.trim();
    }
    if (transaction.description?.trim().isNotEmpty == true) {
      return transaction.description!.trim();
    }
    return transaction.category == AppConstants.categoryCash
        ? tr.cash
        : tr.udhari;
  }

  String? _subtitle(BuildContext context) {
    if (transaction.category == AppConstants.categorySplit ||
        transaction.isSettlement) {
      return null;
    }
    final parts = [
      if (transaction.itemName?.trim().isNotEmpty == true &&
          _title(context) != transaction.itemName!.trim())
        transaction.itemName!.trim(),
      if (transaction.quantity?.trim().isNotEmpty == true)
        transaction.quantity!.trim(),
      if (transaction.description?.trim().isNotEmpty == true &&
          _title(context) != transaction.description!.trim())
        transaction.description!.trim(),
    ];
    return parts.isEmpty ? null : parts.join(' • ');
  }

  String _categoryLabel(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    switch (transaction.category) {
      case AppConstants.categoryCash:
        return tr.cashBadge;
      case AppConstants.categoryUdhari:
        return tr.udhariBadge;
      case AppConstants.categorySplit:
        return tr.split;
      default:
        return transaction.category;
    }
  }
}
