import 'dart:io';
import 'dart:developer';

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/add_transaction_menu.dart';
import 'package:borrow_ledger/presentation/widgets/app_dialog_components.dart';
import 'package:borrow_ledger/presentation/widgets/app_pill_badge.dart';
import 'package:borrow_ledger/presentation/widgets/app_segmented_control.dart';
import 'package:borrow_ledger/presentation/widgets/app_search_field.dart';
import 'package:borrow_ledger/presentation/widgets/build_summary_card.dart';
import 'package:borrow_ledger/presentation/widgets/floating_tab_header_delegate.dart';
import 'package:borrow_ledger/presentation/widgets/settings_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../cubit/borrow_lend_cubit.dart';
import '../widgets/contact_summary_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/transaction_list_item.dart';
import 'transaction_details_screen.dart';
import 'contact_wise_transactions_screen.dart';
import 'split_detail_screen.dart';

enum BorrowLendViewMode { contacts, cash, udhari, transactions }

class _LedgerRangeOption {
  final String label;
  final DateTimeRange? range;
  final bool isCustom;

  const _LedgerRangeOption({
    required this.label,
    this.range,
    this.isCustom = false,
  });
}

class MergedBorrowLendScreen extends StatefulWidget {
  const MergedBorrowLendScreen({super.key});

  @override
  State<MergedBorrowLendScreen> createState() => _MergedBorrowLendScreenState();
}

class _MergedBorrowLendScreenState extends State<MergedBorrowLendScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _animationController;
  late ScrollController _scrollController;
  late ScrollController _contactScrollController;

  BorrowLendViewMode _viewMode = BorrowLendViewMode.contacts;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _contactSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scrollController = ScrollController();
    _contactScrollController = ScrollController();

    // Add scroll listeners for pagination
    _scrollController.addListener(_onTransactionScroll);
    _contactScrollController.addListener(_onContactScroll);

    log('MergedBorrowLendScreen: Initialized');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    log('MergedBorrowLendScreen: Loading initial data');
    final cubit = context.read<BorrowLendCubit>();
    cubit.loadAllData();
    cubit.loadContactSummaries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _contactSearchController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    _contactScrollController.dispose();
    log('MergedBorrowLendScreen: Disposed');
    super.dispose();
  }

  // Pagination: Load more transactions when scrolled to bottom
  void _onTransactionScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<BorrowLendCubit>().loadMoreTransactions();
    }
  }

  // Pagination: Load more contacts when scrolled to bottom
  void _onContactScroll() {
    if (!_contactScrollController.hasClients) return;
    if (_contactScrollController.position.pixels >=
        _contactScrollController.position.maxScrollExtent - 200) {
      context.read<BorrowLendCubit>().loadMoreContactSummaries();
    }
  }

  Future<void> _refreshAllData() async {
    log('MergedBorrowLendScreen: Refreshing all data');
    final cubit = context.read<BorrowLendCubit>();
    await cubit.loadAllData();
    if (_viewMode == BorrowLendViewMode.contacts) {
      await cubit.loadContactSummaries();
    }
  }

  bool _hasActiveFilters(BorrowLendState state) {
    if (_viewMode == BorrowLendViewMode.contacts) {
      return (state.contactSearchQuery != null &&
              state.contactSearchQuery!.isNotEmpty) ||
          (state.contactBalanceFilter != null &&
              state.contactBalanceFilter != 'all');
    } else {
      return (state.filterType != null) ||
          (state.filterCategory != null &&
              state.filterCategory != 'cash_udhari') ||
          (state.searchQuery != null && state.searchQuery!.isNotEmpty);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: const SettingsDrawer(),
      appBar: AppBar(
        title: Text(tr.people),
        actions: [
          BlocBuilder<BorrowLendCubit, BorrowLendState>(
            builder: (context, state) {
              if (_hasActiveFilters(state)) {
                return IconButton(
                  icon: const Icon(Icons.filter_alt_off),
                  tooltip: 'Clear filters',
                  onPressed: () {
                    log('MergedBorrowLendScreen: Clearing filters');
                    final cubit = context.read<BorrowLendCubit>();

                    if (_viewMode == BorrowLendViewMode.contacts) {
                      _contactSearchController.clear();
                      cubit.clearContactFilters();
                    } else {
                      _searchController.clear();
                      cubit.clearFilters();
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          PopupMenuButton<String>(
            tooltip: tr.moreOptions,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'share_ledger') {
                _shareLedgerStatement();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share_ledger',
                child: Row(
                  children: [
                    const Icon(Icons.ios_share_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(tr.shareLedgerPdf),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocListener<BorrowLendCubit, BorrowLendState>(
        listener: (context, state) {
          // Handle messages
          if (state.error != null) {
            log('MergedBorrowLendScreen: Error - ${state.error}');
            showFailureSnackbar(context, state.error!);
            context.read<BorrowLendCubit>().clearMessages();
          }
          if (state.successMessage != null) {
            log('MergedBorrowLendScreen: Success - ${state.successMessage}');
            showSuccessSnackbar(context, state.successMessage!);
            context.read<BorrowLendCubit>().clearMessages();
          }
        },
        child: RefreshIndicator(
          onRefresh: _refreshAllData,
          child: CustomScrollView(
            controller: _viewMode == BorrowLendViewMode.contacts
                ? _contactScrollController
                : _scrollController,
            slivers: [
              // Dashboard Summary Section (Always visible)
              SliverToBoxAdapter(child: _buildDashboardSummary()),

              // View Mode Selector (Floating/Sticky)
              SliverPersistentHeader(
                pinned: true,
                // floating: true,
                delegate: FloatingTabHeaderDelegate(
                  minHeight: 60,
                  maxHeight: 60,
                  child: _buildViewModeSelector(),
                ),
              ),

              SliverToBoxAdapter(child: _buildActiveControlsSection()),

              // Content based on view mode
              _buildContent(),

              // Loading more indicator
              SliverToBoxAdapter(child: _buildLoadingMoreIndicator()),

              SliverToBoxAdapter(child: const SizedBox(height: kToolbarHeight)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'borrow_lend_fab',
        onPressed: () => showAddTransactionMenu(context, _refreshAllData),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _shareLedgerStatement() async {
    final range = await _pickLedgerRange();
    if (range == null || !mounted) return;

    final tr = AppLocalizations.of(context)!;
    final state = context.read<BorrowLendCubit>().state;
    final transactionRepo = context.read<TransactionRepository>();
    final profileRepo = context.read<UserProfileRepository>();
    var loadingShown = false;

    try {
      loadingShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AppLoadingDialog(message: tr.preparingStatement),
      );

      final profile = await profileRepo.getProfile();
      final ownerName = profile.name.trim().isEmpty
          ? tr.appName
          : profile.name.trim();
      final transactions = await _loadLedgerStatementTransactions(
        transactionRepo,
        state,
      );
      final file = await _createLedgerStatementPdf(
        range: range,
        ownerName: ownerName,
        transactions: transactions,
        state: state,
      );

      if (!mounted) return;
      if (loadingShown) {
        Navigator.pop(context);
        loadingShown = false;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              '${tr.borrowLedgerFullStatement} (${_formatDate(range.start)} - ${_formatDate(range.end)})',
          subject: tr.borrowLedgerFullStatement,
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

  Future<List<TransactionModel>> _loadLedgerStatementTransactions(
    TransactionRepository repo,
    BorrowLendState state,
  ) async {
    final category = _statementCategoryFilter(state);
    final type = _viewMode == BorrowLendViewMode.contacts
        ? null
        : state.filterType;
    final query = _viewMode == BorrowLendViewMode.contacts
        ? null
        : state.searchQuery?.trim();

    if (query != null && query.isNotEmpty) {
      return repo.searchTransactions(query, category: category, type: type);
    }
    if (category != null && type != null) {
      return repo.getTransactionsByCategoryAndType(category, type);
    }
    if (category != null) {
      return repo.getTransactionsByCategory(category);
    }
    if (type != null) {
      return repo.getTransactionsByType(type);
    }
    return repo.getAllTransactions();
  }

  String? _statementCategoryFilter(BorrowLendState state) {
    switch (_viewMode) {
      case BorrowLendViewMode.cash:
        return AppConstants.categoryCash;
      case BorrowLendViewMode.udhari:
        return AppConstants.categoryUdhari;
      case BorrowLendViewMode.contacts:
      case BorrowLendViewMode.transactions:
        return state.filterCategory == 'cash_udhari'
            ? null
            : state.filterCategory;
    }
  }

  Future<DateTimeRange?> _pickLedgerRange() async {
    final tr = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final options = [
      _LedgerRangeOption(
        label: tr.thisWeek,
        range: DateTimeRange(
          start: today.subtract(Duration(days: today.weekday - 1)),
          end: _endOfDay(today),
        ),
      ),
      _LedgerRangeOption(
        label: tr.last15Days,
        range: DateTimeRange(
          start: today.subtract(const Duration(days: 14)),
          end: _endOfDay(today),
        ),
      ),
      _LedgerRangeOption(
        label: tr.thisMonth,
        range: DateTimeRange(
          start: DateTime(today.year, today.month),
          end: _endOfDay(today),
        ),
      ),
      _LedgerRangeOption(
        label: tr.last3Months,
        range: DateTimeRange(
          start: DateTime(today.year, today.month - 2),
          end: _endOfDay(today),
        ),
      ),
      _LedgerRangeOption(
        label: tr.last6Months,
        range: DateTimeRange(
          start: DateTime(today.year, today.month - 5),
          end: _endOfDay(today),
        ),
      ),
      _LedgerRangeOption(
        label: tr.last1Year,
        range: DateTimeRange(
          start: DateTime(today.year - 1, today.month, today.day),
          end: _endOfDay(today),
        ),
      ),
      _LedgerRangeOption(label: tr.customRange, isCustom: true),
    ];

    final selected = await showModalBottomSheet<_LedgerRangeOption>(
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

  Future<File> _createLedgerStatementPdf({
    required DateTimeRange range,
    required String ownerName,
    required List<TransactionModel> transactions,
    required BorrowLendState state,
  }) async {
    final tr = AppLocalizations.of(context)!;
    final periodTransactions = transactions
        .where(
          (transaction) =>
              !transaction.date.isBefore(range.start) &&
              !transaction.date.isAfter(range.end),
        )
        .toList();
    final openingTransactions = transactions
        .where((transaction) => transaction.date.isBefore(range.start))
        .toList();
    final openingBalance = _ledgerNet(openingTransactions);
    final periodLent = _ledgerSumByType(
      periodTransactions,
      AppConstants.typeLend,
    );
    final periodBorrowed = _ledgerSumByType(
      periodTransactions,
      AppConstants.typeBorrow,
    );
    final closingBalance = openingBalance + periodLent - periodBorrowed;
    final generatedAt = DateTime.now();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _ledgerPageTheme(),
        build: (context) => [
          _ledgerStatementHeader(
            ownerName: ownerName,
            range: range,
            filterLabel: _ledgerFilterLabel(state, tr),
            generatedAt: generatedAt,
            tr: tr,
          ),
          pw.SizedBox(height: 16),
          _ledgerSummaryGrid(
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
              decoration: _ledgerBoxDecoration(PdfColors.grey200),
              child: pw.Text(tr.noTransactionsInDateRange),
            )
          else
            _ledgerTransactionTable(periodTransactions, tr),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final start = _fileDatePart(range.start);
    final end = _fileDatePart(range.end);
    final filter = _safeFilePart(_ledgerFilterLabel(state, tr));
    final file = File(
      '${dir.path}/HisaabMate_Ledger_${filter}_${start}_to_$end.pdf',
    );
    await file.writeAsBytes(await pdf.save(), flush: true);
    return file;
  }

  pw.Widget _ledgerStatementHeader({
    required String ownerName,
    required DateTimeRange range,
    required String filterLabel,
    required DateTime generatedAt,
    required AppLocalizations tr,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18),
      decoration: _ledgerBoxDecoration(PdfColors.lightGreen100),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            tr.borrowLedgerFullStatement,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${tr.period}: ${_formatDate(range.start)} - ${_formatDate(range.end)}',
          ),
          pw.Text('${tr.filter}: $filterLabel'),
          pw.Text('${tr.generatedBy}: $ownerName'),
          pw.Text('${tr.generatedOn}: ${_formatDateTime(generatedAt)}'),
        ],
      ),
    );
  }

  pw.Widget _ledgerSummaryGrid({
    required double openingBalance,
    required double periodLent,
    required double periodBorrowed,
    required double closingBalance,
    required AppLocalizations tr,
  }) {
    return pw.Row(
      children: [
        _ledgerMetric(tr.opening, openingBalance),
        pw.SizedBox(width: 8),
        _ledgerMetric(tr.youGave, periodLent),
        pw.SizedBox(width: 8),
        _ledgerMetric(tr.youGot, periodBorrowed),
        pw.SizedBox(width: 8),
        _ledgerMetric(tr.closing, closingBalance),
      ],
    );
  }

  pw.Widget _ledgerMetric(String label, double amount) {
    final color = amount >= 0 ? PdfColors.green700 : PdfColors.deepOrange700;
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: _ledgerBoxDecoration(PdfColors.grey100),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _ledgerMoney(amount),
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _ledgerTransactionTable(
    List<TransactionModel> transactions,
    AppLocalizations tr,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: [
        tr.date,
        tr.contact,
        tr.type,
        tr.category,
        tr.details,
        tr.amount,
      ],
      data: transactions.map((transaction) {
        return [
          _formatDate(transaction.date),
          transaction.contactName ?? '-',
          transaction.type == AppConstants.typeLend ? tr.youGave : tr.youGot,
          _ledgerCategoryLabel(transaction.category, tr),
          _ledgerTransactionDetails(transaction),
          _ledgerMoney(
            transaction.type == AppConstants.typeLend
                ? transaction.amount
                : -transaction.amount,
          ),
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 7.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: const {5: pw.Alignment.centerRight},
      columnWidths: const {
        0: pw.FixedColumnWidth(56),
        2: pw.FixedColumnWidth(36),
        3: pw.FixedColumnWidth(44),
        5: pw.FixedColumnWidth(58),
      },
    );
  }

  pw.PageTheme _ledgerPageTheme() {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      buildBackground: (_) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Container(color: PdfColors.white),
      ),
    );
  }

  pw.BoxDecoration _ledgerBoxDecoration(PdfColor color) {
    return pw.BoxDecoration(
      color: color,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
    );
  }

  double _ledgerNet(List<TransactionModel> transactions) {
    return transactions.fold<double>(0, (sum, transaction) {
      return sum +
          (transaction.type == AppConstants.typeLend
              ? transaction.amount
              : -transaction.amount);
    });
  }

  double _ledgerSumByType(List<TransactionModel> transactions, String type) {
    return transactions
        .where((transaction) => transaction.type == type)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  String _ledgerFilterLabel(BorrowLendState state, AppLocalizations tr) {
    final labels = <String>[];
    switch (_viewMode) {
      case BorrowLendViewMode.contacts:
        labels.add(tr.allTransactions);
      case BorrowLendViewMode.transactions:
        labels.add(tr.allCategories);
      case BorrowLendViewMode.cash:
        labels.add(tr.cash);
      case BorrowLendViewMode.udhari:
        labels.add(tr.udhari);
    }

    if (_viewMode == BorrowLendViewMode.transactions) {
      if (state.filterCategory == AppConstants.categoryCash) {
        labels
          ..clear()
          ..add(tr.cash);
      } else if (state.filterCategory == AppConstants.categoryUdhari) {
        labels
          ..clear()
          ..add(tr.udhari);
      }
    }

    if (_viewMode != BorrowLendViewMode.contacts) {
      if (state.filterType == AppConstants.typeLend) labels.add(tr.gaveOnly);
      if (state.filterType == AppConstants.typeBorrow) labels.add(tr.gotOnly);
      if (state.searchQuery?.trim().isNotEmpty == true) {
        labels.add('${tr.searchLabel}: ${state.searchQuery!.trim()}');
      }
    }

    return labels.join(' | ');
  }

  String _ledgerCategoryLabel(String category, AppLocalizations tr) {
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

  String _ledgerTransactionDetails(TransactionModel transaction) {
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

  String _ledgerMoney(double amount) {
    final sign = amount < 0 ? '-' : '';
    return '${sign}INR ${amount.abs().toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  String _formatDateTime(DateTime date) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(date);

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  String _fileDatePart(DateTime date) => DateFormat('ddMMMyyyy').format(date);

  String _safeFilePart(String value) {
    final safe = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return safe.isEmpty ? 'ledger' : safe;
  }

  Widget _buildLoadingMoreIndicator() {
    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        if (_viewMode == BorrowLendViewMode.contacts) {
          if (state.isLoadingMoreContacts) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
        } else {
          if (state.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInitialLoadingSliver() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      ),
    );
  }

  Widget _buildDashboardSummary() {
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Net balance card
              _buildNetBalanceCard(state),
              const SizedBox(height: 10),

              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: BuildSummaryCard(
                      title: tr.receivable,
                      amount: state.totalReceivable,
                      icon: Icons.call_received,
                      color: AppTheme.moneyInColor,
                      isPositive: true,
                      isCompact: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BuildSummaryCard(
                      title: tr.payable,
                      amount: state.totalPayable,
                      icon: Icons.call_made,
                      color: AppTheme.moneyOutColor,
                      isPositive: false,
                      isCompact: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNetBalanceCard(BorrowLendState state) {
    final isSettled = state.netBalance.abs() < 0.01;
    final isPositive = state.netBalance > 0;
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = isSettled
        ? colorScheme.secondary
        : isPositive
        ? AppTheme.moneyInColor
        : AppTheme.moneyOutColor;
    final tr = AppLocalizations.of(context)!;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSettled
                    ? Icons.done_all_rounded
                    : isPositive
                    ? Icons.account_balance_wallet_rounded
                    : Icons.account_balance_outlined,
                color: accentColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),

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
                        color: accentColor,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Text(
                    '${isSettled
                        ? ''
                        : isPositive
                        ? '+'
                        : '-'}₹${state.netBalance.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isSettled ? colorScheme.onSurface : accentColor,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            AppPillBadge(
              label: isSettled
                  ? tr.settled
                  : isPositive
                  ? tr.youWillGet
                  : tr.youWillGive,
              icon: isSettled
                  ? Icons.done_all_rounded
                  : isPositive
                  ? Icons.call_received
                  : Icons.call_made,
              color: accentColor,
              fontSize: 11,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeSelector() {
    final tr = AppLocalizations.of(context)!;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AppSegmentedControl<BorrowLendViewMode>(
        selectedValue: _viewMode,
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        segmentHeight: 44,
        iconSize: 17,
        fontSize: 10.5,
        onChanged: _changeViewMode,
        items: [
          AppSegmentedControlItem(
            value: BorrowLendViewMode.contacts,
            label: tr.people,
            icon: Icons.people_outline_rounded,
          ),
          AppSegmentedControlItem(
            value: BorrowLendViewMode.transactions,
            label: tr.ledger,
            icon: Icons.receipt_long,
          ),
        ],
      ),
    );
  }

  void _changeViewMode(BorrowLendViewMode mode) {
    if (_viewMode == mode) return;

    setState(() {
      _viewMode = mode;
      _searchController.clear();
      _contactSearchController.clear();
    });

    log('MergedBorrowLendScreen: Switching to ${mode.name} mode');

    final cubit = context.read<BorrowLendCubit>();
    switch (mode) {
      case BorrowLendViewMode.contacts:
        cubit.setViewMode('contacts');
      case BorrowLendViewMode.transactions:
        cubit.setViewMode('cash_udhari');
      case BorrowLendViewMode.cash:
        cubit.setViewMode('cash');
      case BorrowLendViewMode.udhari:
        cubit.setViewMode('udhari');
    }
  }

  Widget _buildActiveControlsSection() {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_viewMode == BorrowLendViewMode.contacts) ...[
            _buildContactSearchBar(),
            _buildContactFilterChips(),
          ] else ...[
            _buildSearchBar(),
            _buildFilterChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildContactFilterChips() {
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Row(
            children: [
              FilterChipWidget(
                label: tr.allContacts,
                icon: Icons.people,
                isSelected:
                    state.contactBalanceFilter == null ||
                    state.contactBalanceFilter == 'all',
                onSelected: () {
                  _contactSearchController.clear();
                  log('MergedBorrowLendScreen: Setting contact filter to All');
                  context.read<BorrowLendCubit>().setContactBalanceFilter(
                    'all',
                  );
                },
              ),
              const SizedBox(width: 8),
              FilterChipWidget(
                label: tr.settled,
                icon: Icons.done_all,
                color: Colors.blue,
                isSelected: state.contactBalanceFilter == 'settled',
                onSelected: () {
                  _contactSearchController.clear();
                  log(
                    'MergedBorrowLendScreen: Setting contact filter to Settled',
                  );
                  context.read<BorrowLendCubit>().setContactBalanceFilter(
                    'settled',
                  );
                },
              ),
              const SizedBox(width: 8),
              FilterChipWidget(
                label: tr.pending,
                icon: Icons.pending_actions,
                color: Colors.orange,
                isSelected: state.contactBalanceFilter == 'pending',
                onSelected: () {
                  _contactSearchController.clear();
                  log(
                    'MergedBorrowLendScreen: Setting contact filter to Pending',
                  );
                  context.read<BorrowLendCubit>().setContactBalanceFilter(
                    'pending',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactSearchBar() {
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.only(top: 4),
      child: AppSearchField(
        controller: _contactSearchController,
        hintText: tr.searchContactsByNameOrPhone,
        onClear: () {
          _contactSearchController.clear();
          context.read<BorrowLendCubit>().setContactSearchQuery('');
        },
        onChanged: (value) {
          context.read<BorrowLendCubit>().setContactSearchQuery(value);
        },
        onSubmitted: (_) {
          context.read<BorrowLendCubit>().searchContactSummaries();
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.only(top: 4),
      child: AppSearchField(
        controller: _searchController,
        hintText: tr.searchTransactionsByNameOrPhone,
        onClear: () {
          _searchController.clear();
          context.read<BorrowLendCubit>().setSearchQuery('');
        },
        onChanged: (value) {
          context.read<BorrowLendCubit>().setSearchQuery(value);
        },
        onSubmitted: (_) =>
            context.read<BorrowLendCubit>().searchTransactions(),
      ),
    );
  }

  Widget _buildFilterChips() {
    final tr = AppLocalizations.of(context)!;
    final isAllTransactionsView = _viewMode == BorrowLendViewMode.transactions;

    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterGroup(
                  label: tr.category,
                  children: [
                    FilterChipWidget(
                      label: tr.all,
                      icon: Icons.category_outlined,
                      isSelected:
                          state.filterCategory == null ||
                          state.filterCategory == 'cash_udhari',
                      onSelected: () {
                        _searchController.clear();
                        log('MergedBorrowLendScreen: Clearing category filter');
                        context.read<BorrowLendCubit>().setLedgerCategoryFilter(
                          null,
                        );
                      },
                    ),
                    FilterChipWidget(
                      label: tr.cash,
                      icon: Icons.currency_rupee_rounded,
                      color: AppTheme.cashColor,
                      isSelected:
                          state.filterCategory == AppConstants.categoryCash,
                      onSelected: () {
                        _searchController.clear();
                        log('MergedBorrowLendScreen: Filtering ledger by Cash');
                        context.read<BorrowLendCubit>().setLedgerCategoryFilter(
                          AppConstants.categoryCash,
                        );
                      },
                    ),
                    FilterChipWidget(
                      label: tr.udhari,
                      icon: Icons.shopping_basket_outlined,
                      color: AppTheme.udhariColor,
                      isSelected:
                          state.filterCategory == AppConstants.categoryUdhari,
                      onSelected: () {
                        _searchController.clear();
                        log(
                          'MergedBorrowLendScreen: Filtering ledger by Udhari',
                        );
                        context.read<BorrowLendCubit>().setLedgerCategoryFilter(
                          AppConstants.categoryUdhari,
                        );
                      },
                    ),
                    FilterChipWidget(
                      label: tr.split,
                      icon: Icons.call_split_rounded,
                      color: AppTheme.splitColor,
                      isSelected:
                          state.filterCategory == AppConstants.categorySplit,
                      onSelected: () {
                        _searchController.clear();
                        log(
                          'MergedBorrowLendScreen: Filtering ledger by Split',
                        );
                        context.read<BorrowLendCubit>().setLedgerCategoryFilter(
                          AppConstants.categorySplit,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                _buildFilterGroup(
                  label: tr.direction,
                  children: [
                    FilterChipWidget(
                      label: tr.all,
                      isSelected: state.filterType == null,
                      onSelected: () {
                        _searchController.clear();
                        log('MergedBorrowLendScreen: Clearing type filter');
                        context.read<BorrowLendCubit>().setFilterType(null);
                      },
                    ),
                    FilterChipWidget(
                      label: isAllTransactionsView ? tr.receivable : tr.youGave,
                      icon: isAllTransactionsView
                          ? Icons.call_received
                          : Icons.call_made,
                      color: isAllTransactionsView
                          ? AppTheme.moneyInColor
                          : AppTheme.moneyOutColor,
                      isSelected: state.filterType == AppConstants.typeLend,
                      onSelected: () {
                        _searchController.clear();
                        log('MergedBorrowLendScreen: Setting filter to Lend');
                        context.read<BorrowLendCubit>().setFilterType(
                          AppConstants.typeLend,
                        );
                      },
                    ),
                    FilterChipWidget(
                      label: isAllTransactionsView ? tr.payable : tr.youGot,
                      icon: isAllTransactionsView
                          ? Icons.call_made
                          : Icons.call_received,
                      color: isAllTransactionsView
                          ? AppTheme.moneyOutColor
                          : AppTheme.moneyInColor,
                      isSelected: state.filterType == AppConstants.typeBorrow,
                      onSelected: () {
                        _searchController.clear();
                        log('MergedBorrowLendScreen: Setting filter to Borrow');
                        context.read<BorrowLendCubit>().setFilterType(
                          AppConstants.typeBorrow,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterGroup({
    required String label,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.18 : 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 7),
          Container(
            width: 1,
            height: 20,
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
          const SizedBox(width: 7),
          Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                children[i],
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_viewMode) {
      case BorrowLendViewMode.contacts:
        return _buildContactsView();
      case BorrowLendViewMode.cash:
      case BorrowLendViewMode.udhari:
      case BorrowLendViewMode.transactions:
        return _buildTransactionsView();
    }
  }

  Widget _buildContactsView() {
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        if (state.isLoadingContacts && state.contactSummaries.isEmpty) {
          return _buildInitialLoadingSliver();
        }

        if (state.contactSummaries.isEmpty) {
          final String emptyTitle;
          final String emptyMessage;

          if (state.contactSearchQuery != null &&
              state.contactSearchQuery!.isNotEmpty) {
            emptyTitle = tr.noContactsFound;
            emptyMessage =
                '${tr.noContactsFound} "${state.contactSearchQuery}"';
          } else if (state.contactBalanceFilter == 'settled') {
            emptyTitle = tr.noSettledContacts;
            emptyMessage = tr.noContactsWithZeroBalance;
          } else if (state.contactBalanceFilter == 'pending') {
            emptyTitle = tr.noPendingContacts;
            emptyMessage = tr.noContactsWithPendingBalance;
          } else {
            emptyTitle = tr.noContactsYet;
            emptyMessage = tr.startTrackingYourMoney;
          }

          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              icon: Icons.people_outline,
              title: emptyTitle,
              message: emptyMessage,
              compact: true,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 16,
            top: 6,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final contactSummary = state.contactSummaries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ContactSummaryCard(
                  contactName: contactSummary.contact.name,
                  phoneNumber: contactSummary.contact.phone,
                  transactionCount: contactSummary.transactionCount,
                  netBalance: contactSummary.netBalance,
                  cashCount: contactSummary.cashCount,
                  udhariCount: contactSummary.udhariCount,
                  splitCount: contactSummary.splitCount,
                  splitNet: contactSummary.splitNet,
                  onTap: () async {
                    log(
                      'MergedBorrowLendScreen: Opening contact details for ${contactSummary.contact.name}',
                    );
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContactWiseTransactionsScreen(
                          contactId: contactSummary.contact.id,
                          contactName: contactSummary.contact.name,
                        ),
                      ),
                    );
                    log(
                      'MergedBorrowLendScreen: Returned from contact details',
                    );
                    _refreshAllData();
                  },
                ),
              );
            }, childCount: state.contactSummaries.length),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsView() {
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<BorrowLendCubit, BorrowLendState>(
      builder: (context, state) {
        if (state.isLoading && state.transactions.isEmpty) {
          return _buildInitialLoadingSliver();
        }

        if (state.transactions.isEmpty) {
          final String emptyTitle;
          final String emptyMessage;

          final hasFilters = _hasActiveFilters(state);
          final categoryFilter = state.filterCategory;

          if (_viewMode == BorrowLendViewMode.cash ||
              categoryFilter == AppConstants.categoryCash) {
            emptyTitle = hasFilters
                ? tr.noMatchingCashTransactions
                : tr.noCashTransactions;
            emptyMessage = hasFilters
                ? tr.tryAdjustingFilters
                : tr.addYourFirstCashTransaction;
          } else if (_viewMode == BorrowLendViewMode.udhari ||
              categoryFilter == AppConstants.categoryUdhari) {
            emptyTitle = hasFilters
                ? tr.noMatchingUdhariTransactions
                : tr.noUdhariTransactions;
            emptyMessage = hasFilters
                ? tr.tryAdjustingFilters
                : tr.addYourFirstUdhariTransaction;
          } else {
            emptyTitle = hasFilters
                ? tr.noMatchingTransactions
                : tr.noTransactionsYet;
            emptyMessage = hasFilters
                ? tr.tryAdjustingFilters
                : tr.addFirstTransaction;
          }

          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              icon:
                  _viewMode == BorrowLendViewMode.cash ||
                      categoryFilter == AppConstants.categoryCash
                  ? Icons.currency_rupee
                  : _viewMode == BorrowLendViewMode.udhari ||
                        categoryFilter == AppConstants.categoryUdhari
                  ? Icons.shopping_basket
                  : Icons.receipt_long,
              title: emptyTitle,
              message: emptyMessage,
              compact: true,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 16,
            top: 6,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final transaction = state.transactions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: TransactionListItem(
                  transaction: transaction,
                  onTap: () async {
                    log(
                      'MergedBorrowLendScreen: Opening transaction details for ID: ${transaction.id}',
                    );
                    if (transaction.sourceType ==
                            AppConstants.sourceTypeSplit &&
                        transaction.sourceId != null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SplitDetailScreen(splitId: transaction.sourceId!),
                        ),
                      );
                    } else {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionDetailsScreen(
                            transaction: transaction,
                            onUpdate: () {
                              log(
                                'MergedBorrowLendScreen: Transaction updated callback',
                              );
                              _refreshAllData();
                            },
                          ),
                        ),
                      );
                    }
                    log(
                      'MergedBorrowLendScreen: Returned from transaction details',
                    );
                    _refreshAllData();
                  },
                ),
              );
            }, childCount: state.transactions.length),
          ),
        );
      },
    );
  }
}
