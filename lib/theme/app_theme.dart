// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const teal        = Color(0xFF0D9488);
  static const tealLight   = Color(0xFF14B8A6);
  static const tealDark    = Color(0xFF0F766E);
  static const tealBg      = Color(0xFFCCFBF1);
  static const slate900    = Color(0xFF0F172A);
  static const slate800    = Color(0xFF1E293B);
  static const slate700    = Color(0xFF334155);
  static const slate600    = Color(0xFF475569);
  static const slate400    = Color(0xFF94A3B8);
  static const slate200    = Color(0xFFE2E8F0);
  static const slate100    = Color(0xFFF1F5F9);
  static const white       = Color(0xFFFFFFFF);
  static const success     = Color(0xFF22C55E);
  static const warning     = Color(0xFFF59E0B);
  static const error       = Color(0xFFEF4444);
  static const info        = Color(0xFF3B82F6);
  static const catFood     = Color(0xFFFF6B6B);
  static const catTransport = Color(0xFF4ECDC4);
  static const catInventory = Color(0xFF45B7D1);
  static const catUtilities = Color(0xFF96CEB4);
  static const catLabour   = Color(0xFFFECEA8);
  static const catOther    = Color(0xFFDDA0DD);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.slate100,
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.slate800,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.slate800),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: AppColors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.slate100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.slate200)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.slate200)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.teal, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

class AppConstants {
  static const geminiEndpointText =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  static const geminiEndpointVision =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent';
  static const geminiApiKey = 'AIzaSyD9yxm0J34Tcx-k3_wRDrDfzGdKh7TX3hU';

  static const List<String> categories = [
    'Food & Ingredients', 'Transport', 'Inventory', 'Labour',
    'Utilities', 'Equipment', 'Packaging', 'Other',
  ];

  static const Map<String, Color> categoryColors = {
    'Food & Ingredients': AppColors.catFood,
    'Transport':          AppColors.catTransport,
    'Inventory':          AppColors.catInventory,
    'Labour':             AppColors.catLabour,
    'Utilities':          AppColors.catUtilities,
    'Equipment':          AppColors.info,
    'Packaging':          AppColors.catOther,
    'Other':              AppColors.slate400,
  };

  static const Map<String, IconData> categoryIcons = {
    'Food & Ingredients': Icons.restaurant,
    'Transport':          Icons.directions_car,
    'Inventory':          Icons.inventory_2,
    'Labour':             Icons.people,
    'Utilities':          Icons.bolt,
    'Equipment':          Icons.build,
    'Packaging':          Icons.inventory,
    'Other':              Icons.more_horiz,
  };
}
