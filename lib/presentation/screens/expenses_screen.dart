import 'dart:developer';
import 'dart:math' as math;

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/data/models/expense_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/widgets/app_list_avatar.dart';
import 'package:borrow_ledger/presentation/widgets/app_pill_badge.dart';
import 'package:borrow_ledger/presentation/widgets/app_search_field.dart';
import 'package:borrow_ledger/presentation/widgets/app_segmented_control.dart';
import 'package:borrow_ledger/presentation/widgets/build_summary_card.dart';
import 'package:borrow_ledger/presentation/widgets/delete_expense_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/expense_details_bottom_sheet.dart';
import 'package:borrow_ledger/presentation/widgets/floating_tab_header_delegate.dart';
import 'package:borrow_ledger/presentation/widgets/settings_drawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../data/repositories/expense_repository.dart';
import '../cubit/expense_cubit.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/filter_chip_widget.dart';
import 'add_expense_screen.dart';

enum ExpenseViewMode { overview, list }

class MergedExpensesScreen extends StatefulWidget {
  const MergedExpensesScreen({super.key});

  @override
  State<MergedExpensesScreen> createState() => _MergedExpensesScreenState();
}

class _MergedExpensesScreenState extends State<MergedExpensesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  ExpenseViewMode _viewMode = ExpenseViewMode.overview;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  // Statistics data
  bool _isLoadingStats = true;
  List<Map<String, dynamic>> _categoryData = [];
  List<Map<String, dynamic>> _monthlyData = [];
  double _totalExpenses = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await context.read<ExpenseCubit>().loadExpenses();
    await _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    if (!mounted) return;

    setState(() => _isLoadingStats = true);

    try {
      final expenseRepo = context.read<ExpenseRepository>();
      _categoryData = await expenseRepo.getCategorySummary();
      final currentYear = DateTime.now().year;
      _monthlyData = await expenseRepo.getMonthlyTotals(currentYear);
      _totalExpenses = await expenseRepo.getTotalExpenses();

      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    } catch (e) {
      log("Error loading expense statistics: $e");
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  bool get _hasActiveFilters =>
      _selectedCategory != null || (_searchController.text.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: const SettingsDrawer(),
      appBar: AppBar(
        title: Text(tr.expenses),
        actions: [
          BlocBuilder<ExpenseCubit, ExpenseState>(
            builder: (context, state) =>
                (_viewMode == ExpenseViewMode.list && _hasActiveFilters)
                ? IconButton(
                    icon: const Icon(Icons.filter_alt_off),
                    tooltip: tr.clearFilters,
                    onPressed: () {
                      _selectedCategory = null;
                      _searchController.clear();
                      context.read<ExpenseCubit>().clearFilters();
                    },
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
      body: BlocConsumer<ExpenseCubit, ExpenseState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            _loadStatistics();
          }

          if (state.error != null) {
            showFailureSnackbar(context, state.error!);
            context.read<ExpenseCubit>().clearMessages();
          }
          if (state.successMessage != null) {
            showSuccessSnackbar(context, state.successMessage!);
            context.read<ExpenseCubit>().clearMessages();
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: CustomScrollView(
              slivers: [
                // Dashboard Summary
                SliverToBoxAdapter(child: _buildDashboardSummary()),

                // View Mode Selector
                SliverPersistentHeader(
                  pinned: true,
                  delegate: FloatingTabHeaderDelegate(
                    minHeight: 60,
                    maxHeight: 60,
                    child: _buildViewModeSelector(),
                  ),
                ),

                // Search bar (only for list view)
                if (_viewMode == ExpenseViewMode.list)
                  SliverToBoxAdapter(child: _buildSearchBar()),

                // Category filter chips (only for list view)
                if (_viewMode == ExpenseViewMode.list)
                  SliverToBoxAdapter(child: _buildCategoryFilters()),

                // Content based on view mode
                if (_viewMode == ExpenseViewMode.overview)
                  ..._buildOverviewContent()
                else ...[
                  _buildListView(),
                  SliverToBoxAdapter(
                    child: const SizedBox(height: kToolbarHeight),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expense_fab',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          _refreshData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboardSummary() {
    final tr = AppLocalizations.of(context)!;
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, state) {
        if (_isLoadingStats && state.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
            ),
          );
        }

        // if (_totalExpenses == 0 && _categoryData.isEmpty) {
        //   return const SizedBox.shrink();
        // }

        // Get top category
        final topCategory = _categoryData.isNotEmpty
            ? _categoryData.first
            : null;
        final topCategoryName = topCategory?['category'] as String? ?? tr.na;
        final topCategoryAmount = topCategory != null
            ? (topCategory['total'] as num).toDouble()
            : 0.0;

        // Get this month's total
        final thisMonth = DateTime.now().month;
        final thisMonthData = _monthlyData.firstWhere(
          (m) => m['month'] == thisMonth.toString(),
          orElse: () => {'total': 0.0},
        );
        final thisMonthTotal =
            (thisMonthData['total'] as num?)?.toDouble() ?? 0.0;

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            children: [
              // Total expenses card
              _buildTotalExpensesCard(),
              const SizedBox(height: 10),

              // Summary cards row
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: BuildSummaryCard(
                        title: tr.thisMonth,
                        amount: thisMonthTotal,
                        isPositive: true,
                        icon: Icons.calendar_month_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        isCompact: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BuildSummaryCard(
                        title: tr.topCategory,
                        amount: topCategoryAmount,
                        isPositive: true,
                        icon: getCategoryIcon(topCategoryName),
                        color: getCategoryColor(topCategoryName),
                        subtitle: getCategoryLabel(context, topCategoryName),
                        isCompact: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalExpensesCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = colorScheme.secondary;
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
                Icons.account_balance_wallet_rounded,
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
                        tr.totalExpenses,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.trending_up_rounded,
                        color: accentColor,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_totalExpenses.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            AppPillBadge(
              label: '${_categoryData.length} ${tr.categories}',
              icon: Icons.category_rounded,
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
      child: AppSegmentedControl<ExpenseViewMode>(
        selectedValue: _viewMode,
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        segmentHeight: 44,
        iconSize: 17,
        fontSize: 11,
        onChanged: (mode) {
          if (_viewMode == mode) return;
          setState(() => _viewMode = mode);
        },
        items: [
          AppSegmentedControlItem(
            value: ExpenseViewMode.overview,
            label: tr.overview,
            icon: Icons.dashboard_rounded,
          ),
          AppSegmentedControlItem(
            value: ExpenseViewMode.list,
            label: tr.allExpenses,
            icon: Icons.receipt_long_rounded,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOverviewContent() {
    if (_totalExpenses == 0 && _categoryData.isEmpty) {
      return [SliverFillRemaining(child: _buildEmptyOverview())];
    }

    return [
      // Spending by category chart
      if (_categoryData.isNotEmpty)
        SliverToBoxAdapter(child: _buildCategoryPieChart()),

      // Monthly trend chart
      if (_monthlyData.isNotEmpty)
        SliverToBoxAdapter(child: _buildMonthlyTrendChart()),

      // Category breakdown list
      if (_categoryData.isNotEmpty)
        SliverToBoxAdapter(child: _buildCategoryBreakdown()),

      // Bottom padding
      const SliverToBoxAdapter(child: SizedBox(height: 80)),
    ];
  }

  Widget _buildEmptyOverview() {
    final tr = AppLocalizations.of(context)!;

    return EmptyStateWidget(
      icon: Icons.receipt_long_rounded,
      title: tr.startTrackingExpenses,
      message: tr.addYourFirstExpenseToSeeInsights,
      compact: true,
    );
  }

  Widget _buildOverviewCard({required Widget child, double vertical = 4}) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: vertical),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }

  Widget _buildOverviewSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPieChart() {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final topCategories = _categoryData.take(5).toList();
    final othersTotal = _categoryData
        .skip(5)
        .fold<double>(
          0,
          (sum, item) => sum + (item['total'] as num).toDouble(),
        );

    if (othersTotal > 0) {
      topCategories.add({
        'category': tr.others,
        'total': othersTotal,
        'count': 0,
      });
    }

    return _buildOverviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewSectionHeader(
            icon: Icons.pie_chart_rounded,
            title: tr.spendingByCategory,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 210,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: topCategories.asMap().entries.map((entry) {
                        final item = entry.value;
                        final category = item['category'] as String;
                        final total = (item['total'] as num).toDouble();
                        final percentage = (total / _totalExpenses * 100);

                        return PieChartSectionData(
                          color: category == tr.others
                              ? colorScheme.outline
                              : getCategoryColor(category),
                          value: total,
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: topCategories.map((item) {
                      final category = item['category'] as String;
                      final categoryLabel = category == tr.others
                          ? tr.others
                          : getCategoryLabel(context, category);
                      final total = (item['total'] as num).toDouble();
                      final percentage = (total / _totalExpenses * 100);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: category == tr.others
                                    ? colorScheme.outline
                                    : getCategoryColor(category),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    categoryLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart() {
    final tr = AppLocalizations.of(context)!;

    final colorScheme = Theme.of(context).colorScheme;
    final currentYear = DateTime.now().year;

    // Create a complete 12-month data structure
    final Map<int, double> monthlyDataMap = {};
    for (var item in _monthlyData) {
      final month = int.parse(item['month'] as String);
      final total = (item['total'] as num).toDouble();
      monthlyDataMap[month] = total;
    }

    // Fill in all 12 months with 0 for months without data
    final List<Map<String, dynamic>> allMonthsData = [];
    for (int month = 1; month <= 12; month++) {
      allMonthsData.add({
        'month': month,
        'total': monthlyDataMap[month] ?? 0.0,
      });
    }

    if (allMonthsData.isEmpty) return const SizedBox.shrink();

    final maxY = allMonthsData.fold<double>(
      0,
      (max, item) => math.max(max, item['total'] as double),
    );

    // If all values are 0, set a minimum maxY to avoid division by zero
    final effectiveMaxY = maxY > 0 ? maxY : 1000;

    return _buildOverviewCard(
      vertical: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewSectionHeader(
            icon: Icons.trending_up_rounded,
            title: '${tr.monthlyTrend} ($currentYear)',
            color: colorScheme.secondary,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: effectiveMaxY > 0
                      ? effectiveMaxY / 4
                      : 250,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colorScheme.outline.withValues(alpha: 0.16),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final monthIndex = value.toInt();
                        if (monthIndex < 0 || monthIndex >= 12) {
                          return const SizedBox.shrink();
                        }
                        // Show every month
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat(
                              'MMM',
                            ).format(DateTime(currentYear, monthIndex + 1)),
                            style: TextStyle(
                              fontSize: 9,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: effectiveMaxY > 0 ? effectiveMaxY / 4 : 250,
                      getTitlesWidget: (value, meta) {
                        if (value < 0) return const SizedBox.shrink();
                        if (value >= 1000) {
                          return Text(
                            '₹${(value / 1000).toStringAsFixed(0)}k',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return Text(
                          '₹${value.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 11,
                minY: 0,
                maxY: effectiveMaxY * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: allMonthsData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['total'] as double,
                      );
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: colorScheme.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.22),
                          colorScheme.secondary.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return _buildOverviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewSectionHeader(
            icon: Icons.analytics_rounded,
            title: tr.categoryBreakdown,
            color: colorScheme.tertiary,
          ),
          const SizedBox(height: 14),
          ..._categoryData.asMap().entries.map((entry) {
            final item = entry.value;
            final category = item['category'] as String;
            final categoryLabel = getCategoryLabel(context, category);
            final categoryColor = getCategoryColor(category);
            final total = (item['total'] as num).toDouble();
            final count = item['count'] as int;
            final percentage = (_totalExpenses > 0)
                ? (total / _totalExpenses * 100)
                : 0.0;

            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == _categoryData.length - 1 ? 0 : 14,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AppListAvatar(
                        label: categoryLabel,
                        centerIcon: getCategoryIcon(category),
                        indicatorIcon: Icons.currency_rupee,
                        indicatorColor: categoryColor,
                        size: 38,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AppPillBadge(
                              label: '$count expense${count > 1 ? 's' : ''}',
                              icon: Icons.receipt_long_rounded,
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: categoryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: colorScheme.outline.withValues(
                        alpha: 0.14,
                      ),
                      valueColor: AlwaysStoppedAnimation(categoryColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
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
        hintText: tr.searchExpenses,
        onClear: () {
          _searchController.clear();
          context.read<ExpenseCubit>().setSearchQuery('');
        },
        onChanged: (value) =>
            context.read<ExpenseCubit>().setSearchQuery(value),
        onSubmitted: (_) => context.read<ExpenseCubit>().searchExpenses(),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final tr = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          FilterChipWidget(
            label: tr.all,
            isSelected: _selectedCategory == null,
            onSelected: () {
              _selectedCategory = null;
              _searchController.clear();
              context.read<ExpenseCubit>().clearFilters();
            },
          ),
          const SizedBox(width: 8),
          ...AppConstants.expenseCategories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChipWidget(
                label: getCategoryLabel(context, category),
                icon: getCategoryIcon(category),
                color: getCategoryColor(category),
                isSelected: _selectedCategory == category,
                onSelected: () {
                  _selectedCategory = category;
                  _searchController.clear();
                  context.read<ExpenseCubit>().setFilterCategory(category);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<ExpenseCubit, ExpenseState>(
      buildWhen: (previous, current) =>
          previous.expenses != current.expenses ||
          previous.isLoading != current.isLoading,
      builder: (context, state) {
        if (state.isLoading) {
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

        if (state.expenses.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              icon: Icons.receipt_outlined,
              title: _hasActiveFilters
                  ? tr.noMatchingExpenses
                  : tr.noExpensesYet,
              message: _hasActiveFilters
                  ? tr.tryAdjustingFilters
                  : tr.addFirstExpenseToStartTracking,
              compact: true,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final expense = state.expenses[index];
              return _buildExpenseCard(expense);
            }, childCount: state.expenses.length),
          ),
        );
      },
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = getCategoryColor(expense.category);
    final hasDescription =
        expense.description != null && expense.description!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showExpenseDetails(expense),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              AppListAvatar(
                label: getCategoryLabel(context, expense.category),
                centerIcon: getCategoryIcon(expense.category),
                indicatorIcon: Icons.currency_rupee,
                indicatorColor: categoryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getCategoryLabel(context, expense.category),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          hasDescription
                              ? Icons.notes_outlined
                              : Icons.calendar_today_outlined,
                          size: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hasDescription
                                ? expense.description!
                                : DateFormat(
                                    AppConstants.dateFormat,
                                  ).format(expense.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (hasDescription)
                    AppPillBadge(
                      label: DateFormat('dd MMM').format(expense.date),
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 9,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpenseDetails(expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseDetailsBottomSheet(
        expense: expense,
        onEdit: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(expense: expense),
            ),
          ).then((_) => _refreshData());
        },
        onDelete: () {
          Navigator.pop(context);
          _showDeleteConfirmation(expense);
        },
      ),
    );
  }

  void _showDeleteConfirmation(expense) {
    showDialog(
      context: context,
      builder: (context) => DeleteExpenseDialog(
        onConfirm: () {
          context.read<ExpenseCubit>().deleteExpense(expense.id!);
          _refreshData();
        },
      ),
    );
  }
}
