import 'dart:io';
import 'dart:typed_data';

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/core/services/contact_avatar_service.dart';
import 'package:borrow_ledger/core/services/share_message_builder.dart';
import 'package:borrow_ledger/core/services/upi_service.dart';
import 'package:borrow_ledger/core/utils/app_loading_delay.dart';
import 'package:borrow_ledger/core/utils/currency_formatter.dart';
import 'package:borrow_ledger/core/utils/pdf_report_theme.dart';
import 'package:borrow_ledger/core/utils/shared_expense_mode.dart';
import 'package:borrow_ledger/core/utils/transaction_sort_option.dart';
import 'package:borrow_ledger/data/models/contact_activity_item.dart';
import 'package:borrow_ledger/data/models/contact_model.dart';
import 'package:borrow_ledger/data/models/contact_settlement_model.dart';
import 'package:borrow_ledger/data/models/transaction_model.dart';
import 'package:borrow_ledger/data/models/user_profile_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/add_transaction_menu.dart';
import 'package:borrow_ledger/presentation/widgets/app_dialog_components.dart';
import 'package:borrow_ledger/presentation/widgets/app_loading_state.dart';
import 'package:borrow_ledger/presentation/widgets/build_summary_card.dart';
import 'package:borrow_ledger/presentation/widgets/floating_tab_header_delegate.dart';
import 'package:borrow_ledger/presentation/widgets/settle_txn_dialog_with_partial_payment.dart';
import 'package:borrow_ledger/presentation/widgets/upi_settlement_action_sheet.dart';
import 'package:borrow_ledger/presentation/widgets/upi_id_setup_sheet.dart';
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
import '../../data/repositories/contact_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../cubit/borrow_lend_cubit.dart';
import '../widgets/app_list_avatar.dart';
import '../widgets/app_pill_badge.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/share_name_prompt.dart';
import '../widgets/settlement_details_sheet.dart';
import 'transaction_details_screen.dart';
import 'split_detail_screen.dart';
import 'contact_edit_screen.dart';

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
  int _totalActivityCount = 0;
  int _filteredTotalCount = 0;
  final ScrollController _scrollController = ScrollController();
  List<TransactionModel> _allTransactions = [];
  List<ContactActivityItem> _transactions = [];
  double _totalLent = 0;
  double _totalBorrowed = 0;
  double _netBalance = 0;
  double _normalNetBalance = 0;
  double _splitNetBalance = 0;
  ContactModel? _contact;
  TransactionSortOption _sortOption = TransactionSortOption.transactionDateDesc;

  // Category filtering
  String? _filterCategory; // null, 'cash', 'udhari', 'shared_spend', or 'split'
  int _cashCount = 0;
  int _udhariCount = 0;
  int _sharedSpendCount = 0;
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
      final contactRepo = context.read<ContactRepository>();
      await splitRepo.syncAllSplitTransactions();

      if (widget.contactId != null) {
        _contact = (await contactRepo.getContactById(
          widget.contactId!,
        ))?.contact;
        final stats = await repo.getContactActivityStats(widget.contactId!);
        _allTransactions = [];
        _totalActivityCount = stats['total_transactions'] as int? ?? 0;
        _totalLent = (stats['total_lent'] as num?)?.toDouble() ?? 0.0;
        _totalBorrowed = (stats['total_borrowed'] as num?)?.toDouble() ?? 0.0;
        _netBalance = (stats['net_balance'] as num?)?.toDouble() ?? 0.0;
        _normalNetBalance =
            (stats['normal_net_balance'] as num?)?.toDouble() ?? 0.0;
        _splitNetBalance =
            (stats['split_net_balance'] as num?)?.toDouble() ?? 0.0;
        _cashCount = stats['cash_count'] as int? ?? 0;
        _udhariCount = stats['udhari_count'] as int? ?? 0;
        _sharedSpendCount = stats['shared_spend_count'] as int? ?? 0;
        _splitCount = stats['split_count'] as int? ?? 0;
      } else {
        _allTransactions = await repo.getAllTransactions();
        _totalActivityCount = _allTransactions.length;
        _totalLent = 0;
        _totalBorrowed = 0;
        _cashCount = 0;
        _udhariCount = 0;
        _sharedSpendCount = 0;
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

          if (transaction.category == AppConstants.categoryCash) {
            _cashCount++;
          } else if (transaction.category == AppConstants.categoryUdhari) {
            _udhariCount++;
          } else if (transaction.category == AppConstants.categorySharedSpend) {
            _sharedSpendCount++;
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
      }

      final page = await _loadTransactionsPage(0);
      final totalCount = await _getTransactionCount();

      await loadingDelay;

      if (!mounted) return;
      setState(() {
        _transactions = page;
        _filteredTotalCount = totalCount;
        _currentPage = 0;
        _hasMoreData = page.length < totalCount;
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
        _hasMoreData = _transactions.length < _filteredTotalCount;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      final tr = AppLocalizations.of(context);
      showFailureSnackbar(context, '${tr?.failedToLoad}: $e');
    }
  }

  Future<List<ContactActivityItem>> _loadTransactionsPage(int page) async {
    final repo = context.read<TransactionRepository>();
    final offset = page * _pageSize;

    if (widget.contactId != null) {
      return repo.getContactActivityItems(
        widget.contactId!,
        limit: _pageSize,
        offset: offset,
        category: _filterCategory,
        sortOption: _sortOption,
      );
    }

    if (_filterCategory != null) {
      final transactions = await repo.getTransactionsByCategory(
        _filterCategory!,
        limit: _pageSize,
        offset: offset,
        sortOption: _sortOption,
      );
      return transactions.map(ContactActivityItem.transaction).toList();
    }

    final transactions = await repo.getAllTransactions(
      limit: _pageSize,
      offset: offset,
      sortOption: _sortOption,
    );
    return transactions.map(ContactActivityItem.transaction).toList();
  }

  Future<int> _getTransactionCount() {
    if (widget.contactId != null) {
      return context.read<TransactionRepository>().getContactActivityCount(
        widget.contactId!,
        category: _filterCategory,
      );
    }

    return context.read<TransactionRepository>().getTransactionCount(
      contactId: widget.contactId,
      category: _filterCategory,
    );
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

  void _setSortOption(TransactionSortOption option) {
    if (_sortOption == option) return;

    setState(() {
      _sortOption = option;
      _transactions = [];
      _filteredTotalCount = 0;
      _hasMoreData = true;
      _currentPage = 0;
    });
    _loadTransactions();
  }

  String _sortMenuValue(TransactionSortOption option) => 'sort:${option.name}';

  TransactionSortOption? _sortOptionFromMenuValue(String value) {
    final name = value.replaceFirst('sort:', '');
    for (final option in TransactionSortOption.values) {
      if (option.name == name) return option;
    }
    return null;
  }

  String _sortOptionLabel(TransactionSortOption option, AppLocalizations tr) {
    return switch (option) {
      TransactionSortOption.transactionDateDesc => tr.transactionDateNewest,
      TransactionSortOption.transactionDateAsc => tr.transactionDateOldest,
      TransactionSortOption.createdDateDesc => tr.addedDateNewest,
      TransactionSortOption.createdDateAsc => tr.addedDateOldest,
    };
  }

  IconData _sortOptionIcon(TransactionSortOption option) {
    return switch (option) {
      TransactionSortOption.transactionDateDesc ||
      TransactionSortOption.transactionDateAsc => Icons.event_outlined,
      TransactionSortOption.createdDateDesc ||
      TransactionSortOption.createdDateAsc => Icons.schedule_outlined,
    };
  }

  Widget _buildMenuIcon(IconData icon, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }

  String _signedMoney(double amount) {
    final isPositive = amount >= 0;
    return CurrencyFormatter.format(
      amount.abs(),
      showSign: true,
    ).replaceFirst('+', isPositive ? '+' : '-');
  }

  Future<Uint8List?> _loadContactAvatarBytes(String? avatar) async {
    final legacyBytes = ContactAvatarService.instance.decodeLegacyBase64(
      avatar,
    );
    if (legacyBytes != null) return legacyBytes;

    final file = await ContactAvatarService.instance.resolveAvatarFile(avatar);
    return file?.readAsBytes();
  }

  Future<void> _openContactProfile() async {
    if (widget.contactId == null) return;

    final tr = AppLocalizations.of(context)!;
    final contactRepo = context.read<ContactRepository>();
    final contact =
        _contact ??
        (await contactRepo.getContactById(widget.contactId!))?.contact;
    if (contact == null || !mounted) return;

    final photo = await _loadContactAvatarBytes(contact.avatar);
    if (!mounted) return;

    final updatedContact = await Navigator.push<ContactModel>(
      context,
      MaterialPageRoute(
        builder: (_) => ContactEditScreen(
          name: contact.name,
          phone: contact.phone ?? '',
          email: contact.email,
          photo: photo,
          avatar: contact.avatar,
          existingContact: contact,
        ),
      ),
    );
    if (updatedContact == null || !mounted) return;

    try {
      await contactRepo.updateContact(updatedContact);
      if (!mounted) return;
      setState(() => _contact = updatedContact);
      await _loadTransactions(showLoading: false);
      if (mounted) showSuccessSnackbar(context, tr.contactUpdated);
    } catch (e) {
      if (mounted) {
        showFailureSnackbar(context, '${tr.failedToUpdateContact}: $e');
      }
    }
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
        titleSpacing: 0,
        title: widget.contactId == null
            ? Text(widget.contactName ?? tr.allContacts)
            : _buildContactAppBarTitle(tr),
        actions: [
          if (_totalActivityCount > 0)
            PopupMenuButton<String>(
              tooltip: tr.moreOptions,
              icon: const Icon(Icons.more_vert_rounded),
              padding: const EdgeInsets.only(right: 8),
              offset: const Offset(0, 8),
              constraints: const BoxConstraints(minWidth: 224, maxWidth: 260),
              menuPadding: const EdgeInsets.symmetric(vertical: 7),
              color: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
              onSelected: (value) {
                if (value == 'share_statement') {
                  _shareContactStatement();
                } else if (value.startsWith('sort:')) {
                  final sortOption = _sortOptionFromMenuValue(value);
                  if (sortOption != null) {
                    _setSortOption(sortOption);
                  }
                }
              },
              itemBuilder: (context) => [
                if (widget.contactId != null)
                  PopupMenuItem(
                    value: 'share_statement',
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        _buildMenuIcon(
                          Icons.ios_share_rounded,
                          colorScheme.primary,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            tr.sharePdfStatement,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.contactId != null) const PopupMenuDivider(),
                PopupMenuItem(
                  enabled: false,
                  height: 30,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        tr.sortTransactions,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                      ),
                    ],
                  ),
                ),
                ...TransactionSortOption.values.map(
                  (option) => CheckedPopupMenuItem<String>(
                    value: _sortMenuValue(option),
                    checked: _sortOption == option,
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(
                          _sortOptionIcon(option),
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _sortOptionLabel(option, tr),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading && _totalActivityCount == 0
          ? const AppPageLoadingState(compact: true)
          : RefreshIndicator(
              onRefresh: () => _loadTransactions(showLoading: false),
              child: _totalActivityCount == 0 && !_isLoading
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
                            _sharedSpendCount > 0 ||
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

                                final item = _transactions[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child:
                                      item.kind ==
                                          ContactActivityKind.settlement
                                      ? _CompactContactSettlementCard(
                                          settlement: item.settlement!,
                                          onTap: () => _showSettlementDetails(
                                            item.settlement!,
                                          ),
                                        )
                                      : _CompactContactTransactionCard(
                                          transaction: item.transaction!,
                                          onTap: () => _navigateToDetail(
                                            item.transaction!,
                                          ),
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
      case AppConstants.categorySharedSpend:
        return tr.sharedSpend.toLowerCase();
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
              label: '${tr.all} ($_totalActivityCount)',
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
            if (_sharedSpendCount > 0) ...[
              FilterChipWidget(
                label: '${tr.sharedSpend} ($_sharedSpendCount)',
                icon: Icons.receipt_long_outlined,
                color: AppTheme.sharedSpendColor,
                isSelected: _filterCategory == AppConstants.categorySharedSpend,
                onSelected: () =>
                    _setCategoryFilter(AppConstants.categorySharedSpend),
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

  Widget _buildContactAppBarTitle(AppLocalizations tr) {
    final contactName = _contact?.name ?? widget.contactName ?? tr.unknown;
    final phone = _contact?.phone ?? widget.contactPhone;

    return InkWell(
      onTap: _openContactProfile,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            AppListAvatar(
              label: contactName,
              avatar: _contact?.avatar,
              size: 34,
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contactName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (phone?.trim().isNotEmpty == true)
                    Text(
                      phone!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5),
                    ),
                ],
              ),
            ),
          ],
        ),
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
    final hasDirectBalance = _normalNetBalance.abs() >= 0.01;
    final hasSplitBalance = _splitNetBalance.abs() >= 0.01;
    final hasOutstandingBalance = hasDirectBalance || hasSplitBalance;
    final isNetZero = _netBalance.abs() < 0.01;
    final isSettled = !hasOutstandingBalance;
    final Color statusColor = isSettled || isNetZero
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
                          isSettled || isNetZero
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
                      isNetZero
                          ? CurrencyFormatter.format(0)
                          : CurrencyFormatter.format(
                              _netBalance.abs(),
                              showSign: true,
                            ).replaceFirst('+', isPositive ? '+' : '-'),
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
                      isSettled || isNetZero
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
                          : isNetZero
                          ? tr.offsettingBalances
                          : isPositive
                          ? tr.toReceive
                          : tr.toPay,
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

          if (widget.contactId != null &&
              hasDirectBalance &&
              hasSplitBalance) ...[
            const SizedBox(height: 12),
            _buildBalanceBreakdown(isDark),
          ],
          if (widget.contactId != null && hasOutstandingBalance) ...[
            const SizedBox(height: 12),
            _buildSettleButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceBreakdown(bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: isDark ? 0.07 : 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.07),
        ),
      ),
      child: Column(
        children: [
          _buildBalanceBreakdownRow(
            tr.cashBorrowBalance,
            _normalNetBalance,
            _normalNetBalance >= 0
                ? AppTheme.moneyInColor
                : AppTheme.moneyOutColor,
          ),
          const SizedBox(height: 6),
          _buildBalanceBreakdownRow(
            tr.splits,
            _splitNetBalance,
            _splitNetBalance >= 0
                ? AppTheme.moneyInColor
                : AppTheme.moneyOutColor,
          ),
          const SizedBox(height: 8),
          Divider(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
            height: 1,
          ),
          const SizedBox(height: 8),
          _buildBalanceBreakdownRow(
            tr.netBalance,
            _netBalance,
            _netBalance >= 0 ? AppTheme.moneyInColor : AppTheme.moneyOutColor,
            isStrong: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceBreakdownRow(
    String label,
    double amount,
    Color color, {
    bool isStrong = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: isStrong ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          _signedMoney(amount),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: isStrong ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSettleButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isNetZero = _netBalance.abs() < 0.01;
    final isPositive = _netBalance > 0;
    final statusColor = isNetZero
        ? colorScheme.secondary
        : isPositive
        ? AppTheme.moneyInColor
        : AppTheme.moneyOutColor;
    final tr = AppLocalizations.of(context)!;

    final settleCard = Material(
      color: statusColor.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.18 : 0.1,
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusColor.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _showSettleDialog,
                borderRadius: BorderRadius.circular(8),
                child: Row(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isNetZero
                                ? tr.clearOffsettingBalances
                                : tr.settleUp,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            isNetZero
                                ? tr.noCashPaymentNeeded
                                : tr.netSettlementAmount(
                                    CurrencyFormatter.format(_netBalance.abs()),
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: statusColor,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isNetZero || widget.contactId == null) return settleCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        settleCard,
        const SizedBox(height: 8),
        Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: _showUpiActions,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withValues(alpha: 0.28)),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, color: statusColor, size: 19),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.upiOptions,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          tr.payOrRequestThroughUpi,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 19,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
          text: ShareMessageBuilder.contactStatement(
            tr: tr,
            contactName: widget.contactName ?? tr.allContacts,
            dateRange:
                '${_formatDate(range.start)} - ${_formatDate(range.end)}',
            ownerName: ownerName,
          ),
          subject: tr.contactStatementShareSubject(
            widget.contactName ?? tr.allContacts,
          ),
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
    final repo = context.read<TransactionRepository>();
    final periodItems = widget.contactId == null
        ? _allTransactions
              .where((transaction) => _matchesStatementFilter(transaction))
              .where(
                (transaction) =>
                    !transaction.date.isBefore(range.start) &&
                    !transaction.date.isAfter(range.end),
              )
              .map(ContactActivityItem.transaction)
              .toList()
        : await repo.getContactActivityItemsByDateRange(
            widget.contactId!,
            range.start,
            range.end,
            category: _filterCategory,
          );
    final openingBalance = widget.contactId == null
        ? _netForTransactions(
            _allTransactions
                .where((transaction) => _matchesStatementFilter(transaction))
                .where((transaction) => transaction.date.isBefore(range.start))
                .toList(),
          )
        : await repo.getContactOpeningBalanceBefore(
            widget.contactId!,
            range.start,
            category: _filterCategory,
          );
    final periodLent = _sumByType(periodItems, AppConstants.typeLend);
    final periodBorrowed = _sumByType(periodItems, AppConstants.typeBorrow);
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
            ownerName: ownerName,
            tr: tr,
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            '${tr.transactions} (${periodItems.length})',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (periodItems.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: _statementBoxDecoration(PdfColors.grey200),
              child: pw.Text(tr.noTransactionsInDateRange),
            )
          else
            _statementTransactionTable(periodItems, ownerName, tr),
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
    required String ownerName,
    required AppLocalizations tr,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: [
        tr.opening,
        tr.ownerGave(ownerName),
        tr.ownerGot(ownerName),
        tr.closing,
      ],
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
    List<ContactActivityItem> items,
    String ownerName,
    AppLocalizations tr,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: [tr.date, tr.type, tr.category, tr.details, tr.amount],
      data: items.map((item) {
        if (item.kind == ContactActivityKind.settlement) {
          final settlement = item.settlement!;
          return [
            _formatDate(settlement.date),
            tr.settledBadge,
            tr.settlement,
            _settlementStatementDetails(
              settlement,
              tr,
              moneyFormatter: _statementMoney,
            ),
            settlement.isNoCash
                ? tr.settled
                : _statementMoney(
                    settlement.isReceive
                        ? -settlement.netAmount
                        : settlement.netAmount,
                  ),
          ];
        }

        final transaction = item.transaction!;
        final isSplitHistory = _isSplitHistoryOnly(transaction);
        final isSettlement = transaction.isSettlement;
        return [
          _formatDate(transaction.date),
          isSplitHistory
              ? tr.settledBadge
              : isSettlement
              ? tr.settledBadge
              : transaction.type == AppConstants.typeLend
              ? tr.ownerGave(ownerName)
              : tr.ownerGot(ownerName),
          _categoryLabel(transaction.category, tr),
          _pdfSafeText(
            _transactionDetails(
              transaction,
              ownerName,
              tr,
              moneyFormatter: _statementMoney,
            ),
          ),
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

  double _sumByType(List<ContactActivityItem> items, String type) {
    return items.fold<double>(0, (sum, item) {
      if (item.kind == ContactActivityKind.settlement) {
        final settlement = item.settlement!;
        if (settlement.isNoCash) return sum;
        if (type == AppConstants.typeBorrow && settlement.isReceive) {
          return sum + settlement.netAmount;
        }
        if (type == AppConstants.typeLend && settlement.isPay) {
          return sum + settlement.netAmount;
        }
        return sum;
      }

      final transaction = item.transaction!;
      if (_isSplitHistoryOnly(transaction) || transaction.type != type) {
        return sum;
      }
      return sum + transaction.amount;
    });
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
      case AppConstants.categorySharedSpend:
        return tr.sharedSpend;
      case AppConstants.categorySplit:
        return tr.split;
      default:
        return category;
    }
  }

  String _transactionDetails(
    TransactionModel transaction,
    String ownerName,
    AppLocalizations tr, {
    String Function(double amount)? moneyFormatter,
  }) {
    final formatMoney =
        moneyFormatter ?? (double amount) => CurrencyFormatter.format(amount);
    if (_isSplitHistoryOnly(transaction)) {
      final splitTitle = transaction.description
          ?.replaceFirst(_splitHistoryDescriptionPrefix, '')
          .trim();
      return splitTitle?.isNotEmpty == true ? splitTitle! : tr.split;
    }
    if (transaction.isSettlement) {
      final subtitle = _settlementSubtitleFor(transaction, tr);
      final title = _settlementTitleFor(transaction, tr);
      return subtitle == null ? title : '$title | $subtitle';
    }
    if (transaction.category == AppConstants.categorySharedSpend) {
      final contactName = transaction.contactName ?? tr.unknown;
      final amount = formatMoney(transaction.amount);
      if (SharedExpenseModeResolver.forTransaction(transaction) ==
          SharedExpenseMode.paidOnBehalf) {
        final contextText = transaction.sharedPaidByUser == true
            ? tr.ownerPaidForPerson(ownerName, contactName)
            : tr.personPaidForMe(contactName);
        final outcome = transaction.sharedPaidByUser == true
            ? tr.personOwesCounterparty(contactName, ownerName, amount)
            : tr.youOwePerson(contactName, amount);
        return [
          if (transaction.description?.trim().isNotEmpty == true)
            transaction.description!.trim(),
          contextText,
          outcome,
        ].join(' | ');
      }

      final payer = transaction.sharedPaidByUser == true
          ? tr.ownerPaid(ownerName)
          : tr.personPaidForMe(contactName);
      final total = transaction.sharedTotalAmount;
      final shareLabel = transaction.sharedPaidByUser == true
          ? tr.personShare(contactName)
          : tr.ownerShare(ownerName);
      return [
        if (transaction.description?.trim().isNotEmpty == true)
          transaction.description!.trim(),
        total == null ? payer : '$payer ${formatMoney(total)}',
        '$shareLabel ${formatMoney(transaction.amount)}',
      ].join(' | ');
    }
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
    return CurrencyFormatter.format(amount, symbol: 'Rs');
  }

  String _pdfSafeText(String value) => value.replaceAll('₹', 'Rs');

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
    final isNetZero = _netBalance.abs() < 0.01;
    final isPositive = isNetZero || _netBalance > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => SettleDialog(
        netBalance: _netBalance,
        isPositive: isPositive,
        isDark: isDark,
        balanceLabel: tr.netSettlement,
        contactName: widget.contactName,
        directBalance: _normalNetBalance,
        splitBalance: _splitNetBalance,
        isZeroSettlement: isNetZero,
        onFullSettle: () {
          Navigator.pop(context);
          _settleContactBalance(settleFull: true, amount: _netBalance.abs());
        },
        onPartialSettle: (amount) {
          Navigator.pop(context);
          _settleContactBalance(settleFull: false, amount: amount);
        },
      ),
    );
  }

  Future<void> _showUpiActions() async {
    if (widget.contactId == null || _netBalance.abs() < 0.01) return;

    final contactName = _contact?.name ?? widget.contactName ?? 'Contact';
    final action = await showUpiSettlementActionSheet(
      context,
      isPayable: _netBalance < 0,
      contactName: contactName,
      amount: _netBalance.abs(),
    );
    if (!mounted || action == null) return;

    await _continueUpiAction(action);
  }

  Future<void> _continueUpiAction(
    UpiSettlementAction action, {
    bool allowSetup = true,
  }) async {
    if (!mounted || widget.contactId == null) return;

    final isPayable = _netBalance < 0;
    final contactName = _contact?.name ?? widget.contactName ?? 'Contact';
    final contactUpiId = UpiService.normalizeUpiId(_contact?.upiId);
    final profile = await context.read<UserProfileRepository>().getProfile();
    if (!mounted) return;
    final userUpiId = UpiService.normalizeUpiId(profile.upiId);

    if (isPayable && contactUpiId == null) {
      if (!allowSetup || _contact == null) return;
      final saved = await showUpiIdSetupSheet(
        context,
        owner: UpiIdSetupOwner.contact,
        displayName: contactName,
        initialUpiId: _contact!.upiId,
        onSave: _saveContactUpiId,
      );
      if (saved == true && mounted) {
        await _continueUpiAction(action, allowSetup: false);
      }
      return;
    }
    if (!isPayable && userUpiId == null) {
      if (!allowSetup) return;
      final saved = await showUpiIdSetupSheet(
        context,
        owner: UpiIdSetupOwner.profile,
        displayName: profile.name,
        initialUpiId: profile.upiId,
        onSave: (upiId) => _saveProfileUpiId(profile, upiId),
      );
      if (saved == true && mounted) {
        await _continueUpiAction(action, allowSetup: false);
      }
      return;
    }

    String? ownerName = profile.name.trim().isEmpty
        ? null
        : profile.name.trim();
    if (action != UpiSettlementAction.pay && ownerName == null) {
      ownerName = await ensureShareOwnerName(context, requirePhone: false);
      if (!mounted || ownerName == null) return;
    }

    _showUpiAmountDialog(
      action: action,
      isPayable: isPayable,
      payeeUpiId: isPayable ? contactUpiId! : userUpiId!,
      payeeName: isPayable ? contactName : ownerName ?? profile.name,
      ownerName: ownerName,
    );
  }

  Future<bool> _saveContactUpiId(String upiId) async {
    final contact = _contact;
    final contactId = contact?.id;
    if (contact == null || contactId == null) return false;

    final tr = AppLocalizations.of(context)!;
    try {
      final updatedContact = contact.copyWith(
        upiId: upiId,
        updatedAt: DateTime.now(),
      );
      await context.read<ContactRepository>().updateContact(updatedContact);
      if (!mounted) return false;
      setState(() => _contact = updatedContact);
      return true;
    } catch (e) {
      if (mounted) showFailureSnackbar(context, '${tr.failedToUpdate}: $e');
      return false;
    }
  }

  Future<bool> _saveProfileUpiId(UserProfileModel profile, String upiId) async {
    final tr = AppLocalizations.of(context)!;
    try {
      await context.read<UserProfileRepository>().saveProfile(
        UserProfileModel(
          name: profile.name,
          phone: profile.phone,
          upiId: upiId,
        ),
      );
      return true;
    } catch (e) {
      if (mounted) showFailureSnackbar(context, '${tr.failedToUpdate}: $e');
      return false;
    }
  }

  void _showUpiAmountDialog({
    required UpiSettlementAction action,
    required bool isPayable,
    required String payeeUpiId,
    required String payeeName,
    String? ownerName,
  }) {
    final isNetZero = _netBalance.abs() < 0.01;
    final isPositive = isNetZero || _netBalance > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;
    final actionLabel = action == UpiSettlementAction.pay
        ? tr.payByUpi
        : action == UpiSettlementAction.request
        ? tr.requestViaUpi
        : isPayable
        ? tr.sharePaymentDetails
        : tr.shareRequest;

    showDialog(
      context: context,
      builder: (context) => SettleDialog(
        netBalance: _netBalance,
        isPositive: isPositive,
        isDark: isDark,
        balanceLabel: tr.netSettlement,
        contactName: _contact?.name ?? widget.contactName,
        directBalance: _normalNetBalance,
        splitBalance: _splitNetBalance,
        isZeroSettlement: isNetZero,
        actionLabel: actionLabel,
        onFullSettle: () {
          Navigator.pop(context);
          _performUpiAction(
            action: action,
            isPayable: isPayable,
            payeeUpiId: payeeUpiId,
            payeeName: payeeName,
            ownerName: ownerName,
            settleFull: true,
            amount: _netBalance.abs(),
          );
        },
        onPartialSettle: (amount) {
          Navigator.pop(context);
          _performUpiAction(
            action: action,
            isPayable: isPayable,
            payeeUpiId: payeeUpiId,
            payeeName: payeeName,
            ownerName: ownerName,
            settleFull: false,
            amount: amount,
          );
        },
      ),
    );
  }

  Future<void> _performUpiAction({
    required UpiSettlementAction action,
    required bool isPayable,
    required String payeeUpiId,
    required String payeeName,
    required String? ownerName,
    required bool settleFull,
    required double amount,
  }) async {
    final tr = AppLocalizations.of(context)!;
    final contactName = _contact?.name ?? widget.contactName ?? tr.unknown;
    final note = 'HisaabMate settlement with $contactName';
    final uri = UpiService.buildPaymentUri(
      payeeUpiId: payeeUpiId,
      payeeName: payeeName,
      amount: amount,
      note: note,
    );
    final upiService = const UpiService();

    if (action == UpiSettlementAction.pay) {
      try {
        final launched = await upiService.launchPayment(uri);
        if (!mounted) return;
        if (!launched) {
          await _showUpiFallback(
            uri: uri,
            isPayable: isPayable,
            amount: amount,
            contactName: contactName,
            ownerName: ownerName,
          );
          return;
        }
        await _confirmAndRecordUpiPayment(
          settleFull: settleFull,
          amount: amount,
        );
      } catch (e) {
        if (mounted) {
          await _showUpiFallback(
            uri: uri,
            isPayable: isPayable,
            amount: amount,
            contactName: contactName,
            ownerName: ownerName,
          );
        }
      }
      return;
    }

    final message = _buildUpiShareMessage(
      isPayable: isPayable,
      amount: amount,
      contactName: contactName,
      uri: uri,
      ownerName: ownerName!,
    );
    try {
      await upiService.shareText(
        text: message,
        subject: isPayable
            ? tr.upiPaymentDetailsShareSubject
            : tr.upiRequestShareSubject,
      );
      if (!mounted) return;
      showSuccessSnackbar(
        context,
        isPayable
            ? tr.paymentDetailsSharedSuccessfully
            : tr.requestSharedSuccessfully,
      );
    } catch (e) {
      if (mounted) showFailureSnackbar(context, '${tr.shareFailed} $e');
    }
  }

  String _buildUpiShareMessage({
    required bool isPayable,
    required double amount,
    required String contactName,
    required Uri uri,
    required String ownerName,
  }) {
    final amountText = CurrencyFormatter.format(amount);
    return isPayable
        ? ShareMessageBuilder.upiPaymentDetails(
            tr: AppLocalizations.of(context)!,
            contactName: contactName,
            amount: amountText,
            ownerName: ownerName,
            upiUri: uri.toString(),
          )
        : ShareMessageBuilder.upiRequest(
            tr: AppLocalizations.of(context)!,
            contactName: contactName,
            amount: amountText,
            ownerName: ownerName,
            upiUri: uri.toString(),
          );
  }

  Future<void> _showUpiFallback({
    required Uri uri,
    required bool isPayable,
    required double amount,
    required String contactName,
    required String? ownerName,
  }) async {
    final tr = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(tr.copyUpiLink),
              onTap: () => Navigator.pop(sheetContext, 'copy'),
            ),
            ListTile(
              leading: const Icon(Icons.ios_share_outlined),
              title: Text(tr.sharePaymentDetails),
              onTap: () => Navigator.pop(sheetContext, 'share'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;

    final upiService = const UpiService();
    if (action == 'copy') {
      await upiService.copyToClipboard(uri.toString());
      if (mounted) showSuccessSnackbar(context, tr.copyUpiLink);
    } else if (action == 'share') {
      var resolvedOwnerName = ownerName;
      if (resolvedOwnerName == null || resolvedOwnerName.trim().isEmpty) {
        resolvedOwnerName = await ensureShareOwnerName(
          context,
          requirePhone: false,
        );
        if (!mounted || resolvedOwnerName == null) return;
      }
      final message = _buildUpiShareMessage(
        isPayable: isPayable,
        amount: amount,
        contactName: contactName,
        uri: uri,
        ownerName: resolvedOwnerName,
      );
      await upiService.shareText(
        text: message,
        subject: tr.upiPaymentDetailsShareSubject,
      );
    }
  }

  Future<void> _confirmAndRecordUpiPayment({
    required bool settleFull,
    required double amount,
  }) async {
    final tr = AppLocalizations.of(context)!;
    final referenceController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr.paymentCompleted),
        content: TextField(
          controller: referenceController,
          decoration: InputDecoration(
            labelText: tr.paymentReference,
            prefixIcon: const Icon(Icons.receipt_long_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr.no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr.recordUpiSettlement),
          ),
        ],
      ),
    );
    final reference = referenceController.text.trim();
    referenceController.dispose();
    if (confirmed != true || !mounted) return;

    await _settleContactBalance(
      settleFull: settleFull,
      amount: amount,
      settlementMethod: AppConstants.settlementMethodUpi,
      paymentReference: reference.isEmpty ? null : reference,
    );
  }

  Future<void> _settleContactBalance({
    required bool settleFull,
    required double amount,
    String settlementMethod = AppConstants.settlementMethodManual,
    String? paymentReference,
  }) async {
    final tr = AppLocalizations.of(context)!;
    try {
      await context.read<TransactionRepository>().settleContactBalance(
        contactId: widget.contactId!,
        settleFull: settleFull,
        amount: amount,
        paymentDescription: tr.directBalanceSettlement,
        offsetDescription: tr.directAndSplitBalanceOffset,
        settlementMethod: settlementMethod,
        paymentReference: paymentReference,
      );

      if (mounted) {
        showSuccessSnackbar(context, tr.balanceSettledSuccessfully);
        context.read<BorrowLendCubit>().loadAllData();
        _loadTransactions();
      }
    } catch (e) {
      if (mounted) showFailureSnackbar(context, '${tr.failedToUpdate}: $e');
    }
  }

  void _showSettlementDetails(ContactSettlementModel settlement) {
    final tr = AppLocalizations.of(context)!;
    showSettlementDetailsSheet(
      context,
      title: tr.settlementWithContact(
        settlement.contactName ?? widget.contactName ?? tr.unknown,
      ),
      netSettlementLabel: tr.netSettlement,
      netSettlement: _settlementNetText(settlement, tr),
      directBalanceLabel: tr.directBalance,
      directBalance: CurrencyFormatter.format(settlement.directCleared),
      splitBalanceLabel: tr.splitBalance,
      splitBalance: CurrencyFormatter.format(settlement.splitCleared),
      settlementMethodLabel: tr.upi,
      settlementMethod:
          settlement.settlementMethod == AppConstants.settlementMethodUpi
          ? tr.upi
          : null,
      paymentReferenceLabel: tr.paymentReference,
      paymentReference: settlement.paymentReference,
      offsetNote: settlement.offsetAmount > 0.01
          ? _settlementDetailNote(settlement, tr)
          : null,
    );
  }
}

bool _isContactSettlementDirect(TransactionModel transaction) {
  return transaction.sourceType == AppConstants.sourceTypeContactSettlement ||
      transaction.sourceType == AppConstants.sourceTypeContactSettlementLegacy;
}

bool _isContactSettlementOffset(TransactionModel transaction) {
  return transaction.sourceType ==
          AppConstants.sourceTypeContactSettlementOffset ||
      transaction.sourceType ==
          AppConstants.sourceTypeContactSettlementOffsetLegacy;
}

String _settlementTitleFor(TransactionModel transaction, AppLocalizations tr) {
  if (_isContactSettlementOffset(transaction)) {
    return tr.directAndSplitBalanceOffset;
  }
  if (_isContactSettlementDirect(transaction)) {
    return tr.directBalanceSettlement;
  }
  final description = transaction.description?.trim();
  return description?.isNotEmpty == true
      ? description!
      : tr.settlementTransaction;
}

String? _settlementSubtitleFor(
  TransactionModel transaction,
  AppLocalizations tr,
) {
  if (_isContactSettlementOffset(transaction)) {
    return tr.internalBalanceAdjustment;
  }
  if (_isContactSettlementDirect(transaction)) {
    return tr.cashBorrowBalance;
  }
  return null;
}

String _settlementNetText(
  ContactSettlementModel settlement,
  AppLocalizations tr, {
  String Function(double amount)? moneyFormatter,
}) {
  final formatMoney =
      moneyFormatter ?? (double amount) => CurrencyFormatter.format(amount);
  final contactName = settlement.contactName ?? tr.unknown;
  final amount = formatMoney(settlement.netAmount);
  if (settlement.isNoCash) return tr.noCashPaymentNeeded;
  return settlement.isReceive
      ? tr.contactPaysYou(contactName, amount)
      : tr.youPayContact(contactName, amount);
}

String _settlementBreakdownText(
  ContactSettlementModel settlement,
  AppLocalizations tr, {
  String Function(double amount)? moneyFormatter,
}) {
  final formatMoney =
      moneyFormatter ?? (double amount) => CurrencyFormatter.format(amount);
  final parts = <String>[];
  if (settlement.directCleared > 0.01) {
    parts.add('${tr.directBalance} ${formatMoney(settlement.directCleared)}');
  }
  if (settlement.splitCleared > 0.01) {
    parts.add('${tr.splitBalance} ${formatMoney(settlement.splitCleared)}');
  }
  if (parts.isEmpty) return '';
  return '${tr.clearedBreakdown}: ${parts.join(' • ')}';
}

String _settlementStatementDetails(
  ContactSettlementModel settlement,
  AppLocalizations tr, {
  String Function(double amount)? moneyFormatter,
}) {
  final main = _settlementNetText(
    settlement,
    tr,
    moneyFormatter: moneyFormatter,
  );
  final breakdown = _settlementBreakdownText(
    settlement,
    tr,
    moneyFormatter: moneyFormatter,
  );
  final parts = [
    main,
    if (breakdown.isNotEmpty) breakdown,
    if (settlement.offsetAmount > 0.01) tr.balancesClearedTogetherReportNote,
  ];
  return parts.join(' | ');
}

String _settlementDetailNote(
  ContactSettlementModel settlement,
  AppLocalizations tr,
) {
  return settlement.isNoCash
      ? tr.balancesCancelledNoPaymentNote
      : tr.balancesClearedTogetherNote;
}

class _CompactContactSettlementCard extends StatelessWidget {
  final ContactSettlementModel settlement;
  final VoidCallback onTap;

  const _CompactContactSettlementCard({
    required this.settlement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = settlement.isNoCash
        ? AppTheme.infoColor
        : settlement.isReceive
        ? AppTheme.moneyInColor
        : AppTheme.moneyOutColor;
    final contactName = settlement.contactName ?? tr.unknown;
    final breakdown = _settlementBreakdownText(settlement, tr);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
          child: Row(
            children: [
              AppListAvatar(
                label: contactName,
                avatar: settlement.contactAvatar,
                indicatorIcon: Icons.done_all_rounded,
                indicatorColor: color,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr.settlementWithContact(contactName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          settlement.isNoCash
                              ? CurrencyFormatter.format(0)
                              : CurrencyFormatter.format(settlement.netAmount),
                          style: TextStyle(
                            fontSize: 15.5,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AppPillBadge(
                          label: tr.settlement,
                          icon: Icons.done_all_rounded,
                          color: color,
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
                          ).format(settlement.date),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          settlement.isNoCash
                              ? tr.noCashPaymentNeeded
                              : settlement.isReceive
                              ? tr.toReceive
                              : tr.toPay,
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
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
                    if (breakdown.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        breakdown,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.15,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSplit = transaction.category == AppConstants.categorySplit;
    final isShared = transaction.category == AppConstants.categorySharedSpend;
    final amountColor = _amountColor();
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
                      : isShared
                      ? Icons.receipt_long_outlined
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
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 112),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              CurrencyFormatter.format(transaction.amount),
                              style: TextStyle(
                                fontSize: 15.5,
                                height: 1.08,
                                fontWeight: FontWeight.w800,
                                color: amountColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: AppPillBadge(
                            label: _categoryLabel(context),
                            icon: isSplit
                                ? Icons.call_split_rounded
                                : isShared
                                ? Icons.receipt_long_outlined
                                : null,
                            color: categoryColor,
                            fontSize: 8.5,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
                        const SizedBox(width: 6),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _directionLabel(context),
                              style: TextStyle(
                                fontSize: 10,
                                color: amountColor,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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

  Color _amountColor() {
    if (_isContactSettlementOffset(transaction)) {
      return AppTheme.infoColor;
    }
    if (transaction.category == AppConstants.categorySplit) {
      return AppTheme.getTransactionDirectionColor(transaction.type);
    }
    return AppTheme.getTransactionActionColor(transaction.type);
  }

  String _directionLabel(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    if (transaction.isSettlement) return tr.settledBadge;

    final isLend = transaction.type == AppConstants.typeLend;
    if (transaction.category == AppConstants.categorySplit) {
      return isLend ? tr.owesYou : tr.youOwe;
    }
    if (transaction.isSharedSpend) {
      final sharedMode = SharedExpenseModeResolver.forTransaction(transaction);
      if (sharedMode != SharedExpenseMode.legacy) {
        return _sharedOutcomeLabel(tr);
      }
    }

    return isLend ? tr.youGave : tr.youGot;
  }

  String _title(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    if (transaction.category == AppConstants.categorySplit) {
      final splitTitle = transaction.description
          ?.replaceFirst(RegExp(r'^(Split|Split history):\s*'), '')
          .trim();
      return splitTitle?.isNotEmpty == true ? splitTitle! : tr.split;
    }
    if (transaction.category == AppConstants.categorySharedSpend) {
      if (transaction.description?.trim().isNotEmpty == true) {
        return transaction.description!.trim();
      }
      return tr.sharedSpend;
    }
    if (transaction.isSettlement) return _settlementTitleFor(transaction, tr);
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
        transaction.category == AppConstants.categorySharedSpend ||
        transaction.isSettlement) {
      if (transaction.isSettlement) {
        return _settlementSubtitleFor(
          transaction,
          AppLocalizations.of(context)!,
        );
      }
      return transaction.category == AppConstants.categorySharedSpend
          ? _sharedSpendSubtitle(context)
          : null;
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
      case AppConstants.categorySharedSpend:
        switch (SharedExpenseModeResolver.forTransaction(transaction)) {
          case SharedExpenseMode.paidOnBehalf:
            return tr.onBehalf;
          case SharedExpenseMode.sharedCost:
            return tr.sharedCost;
          case SharedExpenseMode.legacy:
            return tr.sharedSpend;
        }
      case AppConstants.categorySplit:
        return tr.split;
      default:
        return transaction.category;
    }
  }

  String _sharedSpendSubtitle(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final contactName = transaction.contactName ?? tr.unknown;
    if (SharedExpenseModeResolver.forTransaction(transaction) ==
        SharedExpenseMode.paidOnBehalf) {
      final contextText = transaction.sharedPaidByUser == true
          ? tr.paidForPerson(contactName)
          : tr.personPaidForYou(contactName);
      return contextText;
    }

    final payer = transaction.sharedPaidByUser == true
        ? tr.youPaidLabel
        : tr.personPaid(contactName);
    final total = transaction.sharedTotalAmount;
    final totalText = total == null
        ? ''
        : ' ${CurrencyFormatter.format(total)}';
    final shareLabel = transaction.sharedPaidByUser == true
        ? tr.personShare(contactName)
        : tr.yourShare;
    return '$payer$totalText • $shareLabel ${CurrencyFormatter.format(transaction.amount)}';
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
}
