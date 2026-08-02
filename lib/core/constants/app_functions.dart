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

void showSuccessSnackbar(
  BuildContext context,
  String msg, {
  SnackBarAction? action,
}) async {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg, maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      action: action,
    ),
  );
}

void showWarningSnackbar(
  BuildContext context,
  String msg, {
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg, maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      backgroundColor: AppTheme.warning,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      action: action,
    ),
  );
}

void showFailureSnackbar(
  BuildContext context,
  String msg, {
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.cancel, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg, maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      backgroundColor: AppTheme.errorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      action: action,
    ),
  );
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
