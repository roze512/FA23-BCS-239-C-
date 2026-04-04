import 'package:flutter/material.dart';

/// App theme configuration with POS-themed colors (blues and greens for business/money)
class AppTheme {
  // Primary Colors - New Velocity POS Theme from requirements
  static const Color primaryGreen = Color(0xFF00E676); // Neon Green
  static const Color primaryBlue = Color(0xFF2979FF); // Electric Blue
  
  // Background Colors (Dark theme) - Updated per requirements
  static const Color backgroundDark = Color(0xFF121212); // Matte Black
  static const Color surfaceDark = Color(0xFF1E1E1E); // Dark Grey
  static const Color surfaceLight = Color(0xFF2C2C2C); // Lighter surface
  static const Color surfaceHighlight = Color(0xFF233648);
  static const Color surfaceDark2 = Color(0xFF1E1E1E);
  
  // Alert Colors
  static const Color alertRed = Color(0xFFFF5252); // Soft Red
  static const Color warningOrange = Color(0xFFFF9800);
  
  // Border Colors
  static const Color borderDark = Color(0xFF326747);
  
  // Text Colors
  static const Color textSecondary = Color(0xFF9E9E9E); // Light Grey
  static const Color textPrimary = Colors.white;
  
  // Legacy colors (kept for compatibility)
  static const Color primaryColor = primaryGreen;
  static const Color primaryDarkColor = Color(0xFF0D47A1);
  static const Color primaryLightColor = Color(0xFF42A5F5);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color accentDarkColor = Color(0xFF388E3C);
  static const Color accentLightColor = Color(0xFF81C784);
  static const Color backgroundColor = backgroundDark;
  static const Color surfaceColor = surfaceDark;
  static const Color errorColor = Color(0xFFE53935);
  static const Color textPrimaryColor = textPrimary;
  static const Color textSecondaryColor = textSecondary;
  static const Color textDisabledColor = Color(0xFF6B7280);
  static const Color borderColor = borderDark;
  static const Color dividerColor = borderDark;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: primaryBlue,
        error: errorColor,
        surface: surfaceDark,
        background: backgroundDark,
      ),
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textDisabledColor),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: backgroundDark,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Card theme
      cardTheme:  const CardThemeData(
        elevation: 2,
        margin: EdgeInsets. all(8),
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
    );
  }
}
