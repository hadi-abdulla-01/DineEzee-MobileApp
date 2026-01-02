import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Color Scheme
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryRed,
      secondary: AppColors.primaryYellow,
      surface: Colors.white,
      background: Colors.grey[50]!,
      error: Colors.red[700]!,
      onPrimary: Colors.white,
      onSecondary: Colors.black87,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
    ),
    
    // Scaffold
    scaffoldBackgroundColor: Colors.grey[50],
    
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryRed,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    
    // Card
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // Text Theme
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
      displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
      displaySmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
      headlineLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
      headlineMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
      headlineSmall: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
      titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
      titleMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
      titleSmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
      bodyLarge: GoogleFonts.mulish(fontSize: 16, color: Colors.black87),
      bodyMedium: GoogleFonts.mulish(fontSize: 14, color: Colors.black87),
      bodySmall: GoogleFonts.mulish(fontSize: 12, color: Colors.black87),
      labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
      labelMedium: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
      labelSmall: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.black87),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFE0E2E9), width: 1.6),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFE0E2E9), width: 1.6),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: GoogleFonts.poppins(color: Color(0xFF969AB8), fontSize: 14),
    ),
    
    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Icon Theme
    iconTheme: IconThemeData(
      color: Colors.black87,
      size: 24,
    ),
  );
  
  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Color Scheme
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryRed,
      secondary: AppColors.primaryYellow,
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      error: Colors.red[400]!,
      onPrimary: Colors.white,
      onSecondary: Colors.black87,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    
    // Scaffold
    scaffoldBackgroundColor: Color(0xFF121212),
    
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    
    // Card
    cardTheme: CardThemeData(
      color: Color(0xFF1E1E1E),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // Text Theme
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
      displaySmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      headlineLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      headlineMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      headlineSmall: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
      titleMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      titleSmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
      bodyLarge: GoogleFonts.mulish(fontSize: 16, color: Colors.white70),
      bodyMedium: GoogleFonts.mulish(fontSize: 14, color: Colors.white70),
      bodySmall: GoogleFonts.mulish(fontSize: 12, color: Colors.white70),
      labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      labelMedium: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
      labelSmall: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF404040), width: 1.6),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF404040), width: 1.6),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
    ),
    
    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Icon Theme
    iconTheme: IconThemeData(
      color: Colors.white,
      size: 24,
    ),
  );
}
