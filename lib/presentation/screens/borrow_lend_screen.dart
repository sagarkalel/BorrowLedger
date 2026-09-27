import 'dart:io';
import 'dart:developer';

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/core/services/share_message_builder.dart';
import 'package:borrow_ledger/core/utils/pdf_report_theme.dart';
import 'package:borrow_ledger/core/utils/currency_formatter.dart';
import 'package:borrow_ledger/core/utils/shared_expense_mode.dart';
import 'package:borrow_ledger/core/utils/transaction_sort_option.dart';
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
import '../../data/models/contact_activity_item.dart';
import '../../data/models/contact_settlement_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../cubit/borrow_lend_cubit.dart';
import '../widgets/app_loading_state.dart';
import '../widgets/app_list_avatar.dart';
import '../widgets/contact_summary_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/share_name_prompt.dart';
import '../widgets/settlement_details_sheet.dart';
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
  static const String _splitHistoryDescriptionPrefix = 'Split history: ';

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: const SettingsDrawer(),
      appBar: AppBar(
        title: Text(tr.home),
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
            padding: const EdgeInsets.only(right: 8),
            offset: const Offset(0, 8),
            constraints: const BoxConstraints(minWidth: 224, maxWidth: 260),
            menuPadding: const EdgeInsets.symmetric(vertical: 7),
            color: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
            onSelected: (value) {
              if (value == 'share_ledger') {
                _shareLedgerStatement();
              } else if (value.startsWith('sort:')) {
                final sortOption = _sortOptionFromMenuValue(value);
                if (sortOption != null) {
                  context.read<BorrowLendCubit>().setTransactionSortOption(
                    sortOption,
                  );
                }
              }
            },
            itemBuilder: (context) {
              final state = context.read<BorrowLendCubit>().state;
              return [
                PopupMenuItem(
                  value: 'share_ledger',
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      _buildMenuIcon(
                        Icons.ios_share_rounded,
                        Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          tr.shareLedgerPdf,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_viewMode != BorrowLendViewMode.contacts) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    enabled: false,
                    height: 30,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          tr.sortTransactions,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                      checked: state.transactionSortOption == option,
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(
                            _sortOptionIcon(option),
                            size: 18,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
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
              ];
            },
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

      final category = _statementCategoryFilter(state);
      final type = _viewMode == BorrowLendViewMode.contacts
          ? null
          : state.filterType;
      final query = _viewMode == BorrowLendViewMode.contacts
          ? null
          : state.searchQuery?.trim();
      final activities = await transactionRepo
          .getLedgerActivityItemsByDateRange(
            range.start,
            range.end,
            category: category,
            type: type,
            searchQuery: query,
          );
      final openingBalance = await transactionRepo
          .getLedgerOpeningBalanceBefore(
            range.start,
            category: category,
            type: type,
            searchQuery: query,
          );
      final file = await _createLedgerStatementPdf(
        range: range,
        ownerName: ownerName,
        activities: activities,
        openingBalance: openingBalance,
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
          text: ShareMessageBuilder.ledgerStatement(
            tr: tr,
            dateRange:
                '${_formatDate(range.start)} - ${_formatDate(range.end)}',
            ownerName: ownerName,
          ),
          subject: tr.ledgerStatementShareSubject,
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
    required List<ContactActivityItem> activities,
    required double openingBalance,
    required BorrowLendState state,
  }) async {
    final tr = AppLocalizations.of(context)!;
    final periodActivities = activities;
    final periodLent = _ledgerSumByType(
      periodActivities,
      AppConstants.typeLend,
    );
    final periodBorrowed = _ledgerSumByType(
      periodActivities,
      AppConstants.typeBorrow,
    );
    final closingBalance = openingBalance + periodLent - periodBorrowed;
    final generatedAt = DateTime.now();
    final pdfTheme = await PdfReportTheme.load();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _ledgerPageTheme(pdfTheme),
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
            ownerName: ownerName,
            tr: tr,
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            '${tr.transactions} (${periodActivities.length})',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (periodActivities.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: _ledgerBoxDecoration(PdfColors.grey200),
              child: pw.Text(tr.noTransactionsInDateRange),
            )
          else
            _ledgerTransactionTable(periodActivities, ownerName, tr),
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
                  tr.borrowLedgerFullStatement,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'HisaabMate',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Container(
            width: 220,
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

  pw.Widget _ledgerSummaryGrid({
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
          _ledgerMoney(openingBalance),
          _ledgerMoney(periodLent),
          _ledgerMoney(periodBorrowed),
          _ledgerMoney(closingBalance),
        ],
      ],
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellAlignment: pw.Alignment.center,
    );
  }

  pw.Widget _ledgerTransactionTable(
    List<ContactActivityItem> activities,
    String ownerName,
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
      data: activities.map((item) {
        if (item.kind == ContactActivityKind.settlement) {
          final settlement = item.settlement!;
          return [
            _formatDate(settlement.date),
            settlement.contactName ?? '-',
            tr.settledBadge,
            tr.settlement,
            _settlementStatementDetails(
              settlement,
              tr,
              moneyFormatter: _ledgerMoney,
            ),
            _ledgerSettlementAmountText(settlement, tr),
          ];
        }

        final transaction = item.transaction!;
        final isSplitHistory = _isSplitHistoryOnly(transaction);
        return [
          _formatDate(transaction.date),
          transaction.contactName ?? '-',
          isSplitHistory
              ? tr.settledBadge
              : transaction.type == AppConstants.typeLend
              ? tr.ownerGave(ownerName)
              : tr.ownerGot(ownerName),
          _ledgerCategoryLabel(transaction.category, tr),
          _pdfSafeText(
            _ledgerTransactionDetails(
              transaction,
              ownerName,
              tr,
              moneyFormatter: _ledgerMoney,
            ),
          ),
          isSplitHistory
              ? tr.settled
              : _ledgerMoney(
                  transaction.type == AppConstants.typeLend
                      ? transaction.amount
                      : -transaction.amount,
                ),
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 7),
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
        4: pw.Alignment.centerLeft,
        5: pw.Alignment.centerRight,
      },
      columnWidths: const {
        0: pw.FixedColumnWidth(54),
        1: pw.FixedColumnWidth(74),
        2: pw.FixedColumnWidth(50),
        3: pw.FixedColumnWidth(44),
        5: pw.FixedColumnWidth(62),
      },
    );
  }

  pw.PageTheme _ledgerPageTheme(pw.ThemeData theme) {
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

  pw.BoxDecoration _ledgerBoxDecoration(PdfColor color) {
    return pw.BoxDecoration(
      color: color,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
    );
  }

  double _ledgerSumByType(List<ContactActivityItem> activities, String type) {
    return activities.fold<double>(0, (sum, item) {
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

  bool _isSplitHistoryOnly(TransactionModel transaction) {
    return transaction.category == AppConstants.categorySplit &&
        transaction.isSettlement &&
        transaction.sourceType == AppConstants.sourceTypeSplit &&
        transaction.description?.startsWith(_splitHistoryDescriptionPrefix) ==
            true;
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
      case AppConstants.categorySharedSpend:
        return tr.sharedSpend;
      case AppConstants.categorySplit:
        return tr.split;
      default:
        return category;
    }
  }

  String _ledgerTransactionDetails(
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
    if (transaction.isSettlement) return tr.settlement;
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

  String _ledgerMoney(double amount) {
    return CurrencyFormatter.format(amount, symbol: 'Rs');
  }

  String _pdfSafeText(String value) => value.replaceAll('₹', 'Rs');

  String _ledgerSettlementAmountText(
    ContactSettlementModel settlement,
    AppLocalizations tr,
  ) {
    if (settlement.isNoCash) return tr.settled;
    return _ledgerMoney(
      settlement.isReceive ? -settlement.netAmount : settlement.netAmount,
    );
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
          return AppLoadMoreFooter(
            isLoading: state.isLoadingMoreContacts,
            hasMoreData: state.hasMoreContacts,
            hasItems: state.contactSummaries.isNotEmpty,
            itemCount: state.contactSummaries.length,
          );
        } else {
          return AppLoadMoreFooter(
            isLoading: state.isLoadingMore,
            hasMoreData: state.hasMoreData,
            hasItems: state.ledgerActivities.isNotEmpty,
            itemCount: state.ledgerActivities.length,
          );
        }
      },
    );
  }

  Widget _buildInitialLoadingSliver() {
    return const AppSliverLoadingState(compact: true);
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
                    CurrencyFormatter.format(
                      state.netBalance.abs(),
                      showSign: !isSettled,
                    ).replaceFirst(
                      '+',
                      isSettled
                          ? ''
                          : isPositive
                          ? '+'
                          : '-',
                    ),
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
                  ? tr.toReceive
                  : tr.toPay,
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
                      label: tr.sharedSpend,
                      icon: Icons.receipt_long_outlined,
                      color: AppTheme.sharedSpendColor,
                      isSelected:
                          state.filterCategory ==
                          AppConstants.categorySharedSpend,
                      onSelected: () {
                        _searchController.clear();
                        log(
                          'MergedBorrowLendScreen: Filtering ledger by Shared',
                        );
                        context.read<BorrowLendCubit>().setLedgerCategoryFilter(
                          AppConstants.categorySharedSpend,
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
        if ((state.isLoadingContacts || state.isLoading) &&
            state.contactSummaries.isEmpty) {
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
                  avatar: contactSummary.contact.avatar,
                  transactionCount: contactSummary.transactionCount,
                  netBalance: contactSummary.netBalance,
                  cashCount: contactSummary.cashCount,
                  udhariCount: contactSummary.udhariCount,
                  onBehalfCount: contactSummary.onBehalfCount,
                  sharedCostCount: contactSummary.sharedCostCount,
                  legacySharedSpendCount: contactSummary.legacySharedSpendCount,
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
        if (state.isLoading && state.ledgerActivities.isEmpty) {
          return _buildInitialLoadingSliver();
        }

        if (state.ledgerActivities.isEmpty) {
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
              final item = state.ledgerActivities[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildLedgerActivityItem(item),
              );
            }, childCount: state.ledgerActivities.length),
          ),
        );
      },
    );
  }

  Widget _buildLedgerActivityItem(ContactActivityItem item) {
    if (item.kind == ContactActivityKind.settlement) {
      final settlement = item.settlement!;
      return _LedgerSettlementListItem(
        settlement: settlement,
        onTap: () => _showSettlementDetails(settlement),
      );
    }

    final transaction = item.transaction!;
    return TransactionListItem(
      transaction: transaction,
      onTap: () async {
        log(
          'MergedBorrowLendScreen: Opening transaction details for ID: ${transaction.id}',
        );
        if (transaction.sourceType == AppConstants.sourceTypeSplit &&
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
                  log('MergedBorrowLendScreen: Transaction updated callback');
                  _refreshAllData();
                },
              ),
            ),
          );
        }
        log('MergedBorrowLendScreen: Returned from transaction details');
        _refreshAllData();
      },
    );
  }

  void _showSettlementDetails(ContactSettlementModel settlement) {
    final tr = AppLocalizations.of(context)!;
    showSettlementDetailsSheet(
      context,
      title: tr.settlementWithContact(settlement.contactName ?? tr.unknown),
      netSettlementLabel: tr.netSettlement,
      netSettlement: _settlementNetText(settlement, tr),
      directBalanceLabel: tr.directBalance,
      directBalance: CurrencyFormatter.format(settlement.directCleared),
      splitBalanceLabel: tr.splitBalance,
      splitBalance: CurrencyFormatter.format(settlement.splitCleared),
      offsetNote: settlement.offsetAmount > 0.01
          ? _settlementDetailNote(settlement, tr)
          : null,
    );
  }
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

class _LedgerSettlementListItem extends StatelessWidget {
  final ContactSettlementModel settlement;
  final VoidCallback onTap;

  const _LedgerSettlementListItem({
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
                size: 38,
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
                              fontSize: 14,
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
