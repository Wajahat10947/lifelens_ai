import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,

    scaffoldBackgroundColor: AppColors.background,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.purple,
      secondary: AppColors.cyan,
      surface: AppColors.card,
    ),

    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,

    scaffoldBackgroundColor: const Color(0xFFF4F5FA),

    colorScheme: const ColorScheme.light(
      primary: AppColors.purple,
      secondary: AppColors.cyan,
      surface: Colors.white,
    ),

    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
  );
}
