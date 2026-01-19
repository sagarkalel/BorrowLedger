import 'package:borrow_ledger/core/theme/app_theme.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

showToast(String message) {
  Fluttertoast.cancel();
  Fluttertoast.showToast(
    msg: message,
    backgroundColor: AppTheme.lightCard,
    textColor: AppTheme.darkCard,
    toastLength: Toast.LENGTH_LONG,
  );
}

void showDialogSafely(
  BuildContext context,
  Widget Function(BuildContext) builder,
) {
  // Use addPostFrameCallback to ensure we're not in the middle of a build
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      showDialog(context: context, builder: builder);
    }
  });
}

void showSnackBarSafely(BuildContext context, SnackBar snackBar) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  });
}

void closeDialogSafely(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  });
}

String getCategoryLabel(BuildContext context, String category) {
  final tr = AppLocalizations.of(context)!;

  switch (category) {
    case 'Food & Dining':
      return tr.foodDining;
    case 'Transportation':
      return tr.transportation;
    case 'Shopping':
      return tr.shopping;
    case 'Entertainment':
      return tr.entertainment;
    case 'Bills & Utilities':
      return tr.billsUtilities;
    case 'Healthcare':
      return tr.healthcare;
    case 'Education':
      return tr.education;
    case 'Travel':
      return tr.travel;
    case 'Groceries':
      return tr.groceries;
    default:
      return tr.category;
  }
}

Color getCategoryColor(String category) {
  final colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];
  return colors[category.hashCode % colors.length];
}

IconData getCategoryIcon(String category) {
  switch (category) {
    case 'Food & Dining':
      return Icons.restaurant;
    case 'Transportation':
      return Icons.directions_car;
    case 'Shopping':
      return Icons.shopping_bag;
    case 'Entertainment':
      return Icons.movie;
    case 'Bills & Utilities':
      return Icons.receipt_long;
    case 'Healthcare':
      return Icons.local_hospital;
    case 'Education':
      return Icons.school;
    case 'Travel':
      return Icons.flight;
    case 'Groceries':
      return Icons.shopping_cart;
    default:
      return Icons.category;
  }
}
