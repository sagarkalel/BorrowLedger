import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../widgets/settings_drawer.dart';
import 'borrow_lend_screen.dart';
import 'expenses_screen.dart';
import 'splits_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MergedBorrowLendScreen(),
    const SplitsScreen(),
    const MergedExpensesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: const SettingsDrawer(),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 28,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.swap_horiz_rounded),
            activeIcon: const Icon(Icons.swap_horiz_rounded, size: 28),
            label: tr.borrowLend,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.pie_chart_rounded),
            activeIcon: const Icon(Icons.pie_chart_rounded, size: 28),
            label: tr.splits,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_rounded),
            activeIcon: const Icon(Icons.receipt_long_rounded, size: 28),
            label: tr.expenses,
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   heroTag: 'main_fab_$_currentIndex',
      //   onPressed: () {
      //     _showAddTransactionMenu(context);
      //   },
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
