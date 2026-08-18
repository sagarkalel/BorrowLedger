import 'package:flutter/material.dart';

class AppTheme {
  // Colors from logo
  static const Color primaryGreen = Color(0xFF8BC34A);
  static const Color primaryBlue = Color.fromARGB(247, 92, 180, 243);
  static const Color lightGreen = Color(0xFFA8D76F);
  static const Color darkBlue = Color(0xFF2874A6);

  // Semantic colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color.fromARGB(237, 82, 174, 249);

  // Light theme colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkNavigationSurface = Color(0xFF242826);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);

  // Transaction type colors (legacy)
  static const Color lendColor = Color(0xFF4CAF50);
  static const Color borrowColor = Color(0xFFFF9800);
  static const Color expenseColor = Color(0xFF2196F3);
  static const Color splitColor = Color.fromARGB(255, 214, 97, 234);

  // Intuitive Transaction Colors (Softer, Professional)
  // Money Coming In (You'll Get Back) - Soft Green
  static const Color moneyInColor = Color(0xFF66BB6A); // Soft green - receiving
  static const Color moneyInDark = Color(0xFF43A047);

  // Money Going Out (You Need to Give) - Soft Orange
  static const Color moneyOutColor = Color(0xFFFF8A65); // Soft orange - giving
  static const Color moneyOutDark = Color(0xFFFF7043);

  // Cash Category - Teal (neutral, professional)
  static const Color cashColor = Color(0xFF26A69A);
  static const Color cashLight = Color(0xFF4DB6AC);
  static const Color cashDark = Color(0xFF00897B);

  // Udhari Category - Amber (warm, familiar)
  static const Color udhariColor = Color(0xFFFFB74D);
  static const Color udhariLight = Color(0xFFFFCC80);
  static const Color udhariDark = Color(0xFFFFA726);
  static const Color sharedSpendColor = Color(0xFF7E57C2);

  // Get transaction direction color (what will happen in future)
  static Color getTransactionDirectionColor(String type) {
    // type: 'lend' = you gave money/items -> they will give back (you'll GET)
    // type: 'borrow' = you got money/items -> you will give back (you'll GIVE)
    switch (type) {
      case 'lend':
        return moneyInColor;
      case 'borrow':
        return moneyOutColor;
      default:
        return infoColor;
    }
  }

  // Get transaction action color (what happened now)
  static Color getTransactionActionColor(String type) {
    switch (type) {
      case 'lend':
        return moneyOutColor;
      case 'borrow':
        return moneyInColor;
      default:
        return infoColor;
    }
  }

  // Get category color (softer shades)
  static Color getCategoryColor(String category, {bool isDark = false}) {
    switch (category) {
      case 'cash':
        return isDark ? const Color.fromARGB(255, 39, 189, 174) : cashColor;
      case 'udhari':
        return isDark ? udhariDark : udhariColor;
      case 'split':
        return splitColor;
      case 'shared_spend':
        return sharedSpendColor;
      default:
        return infoColor;
    }
  }

  // Get category background color (very subtle)
  static Color getCategoryBgColor(String category, bool isDark) {
    switch (category) {
      case 'cash':
        return isDark
            ? cashDark.withValues(alpha: 0.15)
            : cashLight.withValues(alpha: 0.15);
      case 'udhari':
        return isDark
            ? udhariDark.withValues(alpha: 0.15)
            : udhariLight.withValues(alpha: 0.15);
      case 'split':
        return splitColor.withValues(alpha: isDark ? 0.18 : 0.12);
      case 'shared_spend':
        return sharedSpendColor.withValues(alpha: isDark ? 0.18 : 0.12);
      default:
        return Colors.grey.withValues(alpha: 0.1);
    }
  }

  // Legacy method (kept for compatibility)
  static Color getTransactionColor(String type) {
    switch (type) {
      case 'lend':
        return lendColor;
      case 'borrow':
        return borrowColor;
      case 'expense':
        return expenseColor;
      case 'split':
        return splitColor;
      default:
        return infoColor;
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'paid':
      case 'settled':
        return success;
      case 'pending':
        return warning;
      case 'partial':
        return infoColor;
      default:
        return infoColor;
    }
  }

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryGreen,
      secondary: primaryBlue,
      tertiary: lightGreen,
      error: errorColor,
      surface: lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: lightBackground,
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.07)),
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: lightBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(18)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: Colors.black87,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
      iconTheme: IconThemeData(color: Colors.black87, size: 22),
      actionsIconTheme: IconThemeData(color: Colors.black87, size: 22),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 1,
      focusElevation: 1,
      hoverElevation: 2,
      highlightElevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryGreen, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: Colors.grey[400]),
      labelStyle: TextStyle(color: Colors.grey[700]),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: Colors.black26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGreen,
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[200],
      selectedColor: primaryGreen.withValues(alpha: 0.2),
      labelStyle: TextStyle(fontSize: 13),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    radioTheme: RadioThemeData(fillColor: WidgetStatePropertyAll(primaryGreen)),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: lightSurface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: lightSurface,
      modalBarrierColor: Colors.black38,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: lightSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
      contentTextStyle: TextStyle(
        fontSize: 14,
        color: Colors.grey[700],
        height: 1.4,
      ),
    ),
    listTileTheme: ListTileThemeData(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      iconColor: Colors.grey[700],
      textColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: lightSurface,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primaryGreen,
      secondary: primaryBlue,
      tertiary: lightGreen,
      error: errorColor,
      surface: darkSurface,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: darkBackground,
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: darkBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(18)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white, size: 22),
      actionsIconTheme: IconThemeData(color: Colors.white, size: 22),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.black,
      elevation: 1,
      focusElevation: 1,
      hoverElevation: 2,
      highlightElevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryGreen, width: 2),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: Colors.grey[600]),
      labelStyle: TextStyle(color: Colors.grey[400]),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGreen,
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[800],
      selectedColor: primaryGreen.withValues(alpha: 0.3),
      labelStyle: TextStyle(fontSize: 13),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: darkSurface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: darkSurface,
      modalBarrierColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      contentTextStyle: TextStyle(
        fontSize: 14,
        color: Colors.grey[300],
        height: 1.4,
      ),
    ),
    listTileTheme: ListTileThemeData(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      iconColor: Colors.grey[400],
      textColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkNavigationSurface,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey[400],
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
