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

  // Get transaction direction color (what will happen in future)
  static Color getTransactionDirectionColor(String type) {
    // type: 'lend' = you gave money/items -> they will give back (you'll GET)
    // type: 'borrow' = you got money/items -> you will give back (you'll GIVE)
    switch (type) {
      case 'lend':
        return moneyOutColor; // Orange - you'll give back
      case 'borrow':
        return moneyInColor; // Green - you'll receive back
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
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
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGreen,
        textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
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
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGreen,
        textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[800],
      selectedColor: primaryGreen.withValues(alpha: 0.3),
      labelStyle: TextStyle(fontSize: 13),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey[500],
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}
