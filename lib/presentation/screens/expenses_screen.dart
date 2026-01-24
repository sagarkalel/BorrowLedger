import 'dart:developer';
import 'dart:math' as math;

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/data/models/expense_model.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
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
import '../../core/theme/app_theme.dart';
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
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Total expenses card
              _buildTotalExpensesCard(),
              const SizedBox(height: 12),

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
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BuildSummaryCard(
                        title: tr.topCategory,
                        amount: topCategoryAmount,
                        isPositive: true,
                        icon: getCategoryIcon(topCategoryName),
                        color: getCategoryColor(topCategoryName),
                        subtitle: getCategoryLabel(context, topCategoryName),
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
    final primaryColor = AppTheme.primaryBlue;
    final secondaryColor = AppTheme.primaryGreen;
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor, primaryColor],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tr.totalExpenses,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${_totalExpenses.toStringAsFixed(2)}',
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  Icons.category_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_categoryData.length} ${tr.categories}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
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
    );
  }

  Widget _buildViewModeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        // Enhanced gradient background
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF5F5F5)],
        ),
        borderRadius: BorderRadius.circular(14),
        // Enhanced shadow with multiple layers
        boxShadow: [
          // Main shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          // Secondary shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
          // Highlight on top (for light mode)
          if (!isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: 8,
              offset: const Offset(0, -1),
              spreadRadius: 0,
            ),
        ],
        // Border for definition
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              label: tr.overview,
              icon: Icons.dashboard_rounded,
              mode: ExpenseViewMode.overview,
            ),
          ),
          Expanded(
            child: _buildModeButton(
              label: tr.allExpenses,
              icon: Icons.receipt_long_rounded,
              mode: ExpenseViewMode.list,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required ExpenseViewMode mode,
  }) {
    final isSelected = _viewMode == mode;

    return GestureDetector(
      onTap: () {
        if (_viewMode != mode) {
          setState(() => _viewMode = mode);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[700],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                    AppTheme.primaryGreen.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 80,
                color: AppTheme.primaryBlue.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr.startTrackingExpenses,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              tr.addYourFirstExpenseToSeeInsights,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    final tr = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.pie_chart_rounded,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                tr.spendingByCategory,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
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
                              ? Colors.grey
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
                                    ? Colors.grey
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
                                    category,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.grey[900],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${tr.monthlyTrend} ($currentYear)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
                              color: Colors.grey[600],
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
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return Text(
                          '₹${value.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
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
                      colors: [AppTheme.primaryBlue, AppTheme.primaryGreen],
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
                          strokeColor: AppTheme.primaryBlue,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withValues(alpha: 0.3),
                          AppTheme.primaryGreen.withValues(alpha: 0.1),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                tr.categoryBreakdown,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._categoryData.map((item) {
            final category = item['category'] as String;
            final total = (item['total'] as num).toDouble();
            final count = item['count'] as int;
            final percentage = (_totalExpenses > 0)
                ? (total / _totalExpenses * 100)
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: getCategoryColor(
                            category,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          getCategoryIcon(category),
                          color: getCategoryColor(category),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                            ),
                            const SizedBox(height: 2),
                            //TODO add transaction here
                            Text(
                              '$count expense${count > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
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
                              color: getCategoryColor(category),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
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
                      backgroundColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        getCategoryColor(category),
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(top: 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: tr.searchExpenses,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ExpenseCubit>().setSearchQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[850]
              : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) =>
            context.read<ExpenseCubit>().setSearchQuery(value),
        onSubmitted: (value) => context.read<ExpenseCubit>().searchExpenses(),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final tr = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.expenses.isEmpty) {
          return SliverFillRemaining(
            child: EmptyStateWidget(
              icon: Icons.receipt_outlined,
              title: _hasActiveFilters
                  ? tr.noMatchingExpenses
                  : tr.noExpensesYet,
              message: _hasActiveFilters
                  ? tr.tryAdjustingFilters
                  : tr.addFirstExpenseToStartTracking,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDescription =
        expense.description != null && expense.description!.trim().isNotEmpty;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showExpenseDetails(expense),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: getCategoryColor(
                    expense.category,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  getCategoryIcon(expense.category),
                  color: getCategoryColor(expense.category),
                  size: 24,
                ),
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
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          hasDescription
                              ? Icons.notes_outlined
                              : Icons.calendar_today_outlined,
                          size: 11,
                          color: Colors.grey[500],
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
                              color: Colors.grey[600],
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
                      fontWeight: FontWeight.bold,
                      color: getCategoryColor(expense.category),
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (hasDescription)
                    Text(
                      DateFormat('dd MMM').format(expense.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Colors.grey[400],
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
