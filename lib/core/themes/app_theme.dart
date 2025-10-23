// ✅ core/themes/app_theme.dart (ENHANCED FOR LIGHT & DARK MODE)
import 'package:flutter/material.dart';

class AppTheme {
  // ✅ LIGHT THEME - Professional & Clean
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
        primary: Colors.blue.shade600,
        secondary: Colors.blue.shade400,
        surface: Colors.white,
        background: Colors.grey.shade50,
        error: Colors.red.shade600,
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue.shade800,
        titleTextStyle: TextStyle(
          color: Colors.blue.shade800,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.blue.shade800),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 2,
        margin: EdgeInsets.all(8),
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue.shade600,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),

      // Data Table
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
        headingTextStyle: TextStyle(
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        dataTextStyle: TextStyle(
          color: Colors.grey.shade800,
          fontSize: 14,
        ),
        dataRowColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.blue.shade50;
          }
          if (states.contains(MaterialState.hovered)) {
            return Colors.grey.shade100;
          }
          return Colors.white;
        }),
        dividerThickness: 1,
        horizontalMargin: 12,
        columnSpacing: 12,
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: Colors.grey.shade700,
        size: 24,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.w600),
        displaySmall: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Colors.grey.shade800),
        bodyMedium: TextStyle(color: Colors.grey.shade700),
        bodySmall: TextStyle(color: Colors.grey.shade600),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
        space: 1,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        deleteIconColor: Colors.grey.shade600,
        labelStyle: TextStyle(color: Colors.grey.shade800),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Scaffold
      scaffoldBackgroundColor: Colors.grey.shade50,
    );
  }

  // ✅ DARK THEME - Modern & Elegant
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
        primary: Colors.blue.shade400,
        secondary: Colors.blue.shade300,
        surface: Colors.grey.shade900,
        background: Colors.grey.shade900,
        error: Colors.red.shade400,
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.blue.shade300,
        titleTextStyle: TextStyle(
          color: Colors.blue.shade300,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.blue.shade300),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 4,
        margin: EdgeInsets.all(8),
        color: Colors.grey.shade800,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue.shade300,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),

      // Data Table
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade800),
        headingTextStyle: TextStyle(
          color: Colors.grey.shade300,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        dataTextStyle: TextStyle(
          color: Colors.grey.shade300,
          fontSize: 14,
        ),
        dataRowColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.blue.shade900.withOpacity(0.3);
          }
          if (states.contains(MaterialState.hovered)) {
            return Colors.grey.shade800;
          }
          return Colors.grey.shade900;
        }),
        dividerThickness: 1,
        horizontalMargin: 12,
        columnSpacing: 12,
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: Colors.grey.shade400,
        size: 24,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(color: Colors.grey.shade100, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.grey.shade100, fontWeight: FontWeight.w600),
        displaySmall: TextStyle(color: Colors.grey.shade100, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Colors.grey.shade200, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Colors.grey.shade200, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Colors.grey.shade200, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Colors.grey.shade300),
        bodyMedium: TextStyle(color: Colors.grey.shade400),
        bodySmall: TextStyle(color: Colors.grey.shade500),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade700,
        thickness: 1,
        space: 1,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade800,
        deleteIconColor: Colors.grey.shade400,
        labelStyle: TextStyle(color: Colors.grey.shade300),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Scaffold
      scaffoldBackgroundColor: Colors.grey.shade900,
    );
  }
}
