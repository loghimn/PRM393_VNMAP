import 'package:flutter/material.dart';

/// 🎨 White + Blue — 2026 Data Analytics Dashboard Theme
/// Primary: #2563EB | Secondary: #06B6D4 | Success: #10B981
/// Warning: #F59E0B | Danger: #EF4444
/// Background: #F8FAFC | Card: #FFFFFF
class AppColors {
  AppColors._();

  // ── Light Backgrounds ──
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSubtleLight = Color(0xFFF1F5F9);
  static const Color surfaceExtraLight = Color(0xFFFAFBFC);

  // ── Dark Backgrounds ──
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceDarker = Color(0xFF0F172A);
  static const Color surfaceSubtleDark = Color(0xFF334155);

  // ── Theme Palette (2026 Data Viz) ──
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ── Gradient helpers ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF22D3EE), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Light Text ──
  static const Color textPrimaryLight = Color(0xFF1E293B);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // ── Dark Text ──
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // ── Utility ──
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);

  // ── Province map colors ──
  static const Color provinceMountain = Color(0xFF22C55E);
  static const Color provinceCity = Color(0xFFF97316);
  static const Color provinceSpecial = Color(0xFF3B82F6);
  static const Color provinceHover = Color(0xFF93C5FD);
  static const Color provinceSelected = Color(0xFF2563EB);
  static const Color provinceDefault = Color(0xFFCBD5E1);
  static const Color heatmapLow = Color(0xFFBFDBFE);
  static const Color heatmapMed = Color(0xFF60A5FA);
  static const Color heatmapHigh = Color(0xFF2563EB);

  // ── Weather ──
  static const Color weatherSunny = Color(0xFFF59E0B);
  static const Color weatherCloud = Color(0xFF94A3B8);
  static const Color weatherRain = Color(0xFF3B82F6);
  static const Color weatherSnow = Color(0xFFDBEAFE);
  static const Color weatherStorm = Color(0xFF475569);
  static const Color weatherFog = Color(0xFFC8D8E8);

  // ── Map ──
  static const Color mapBackgroundLight = Color(0xFFE2E8F0);
  static const Color mapBackgroundDark = Color(0xFF1E293B);
  static const Color chipActive = Color(0xFF2563EB);
  static const Color chipInactiveLight = Color(0xFFE2E8F0);
  static const Color chipInactiveDark = Color(0xFF334155);

  // ── Rankings ──
  static const Color topRank = Color(0xFF10B981);
  static const Color bottomRank = Color(0xFFEF4444);
  static const Color highlightBgLight = Color(0xFFEFF6FF);
  static const Color highlightBgDark = Color(0xFF1E3A5F);

  // ── Search / Misc ──
  static const Color searchBgLight = Color(0xFFF1F5F9);
  static const Color searchBgDark = Color(0xFF334155);
  static const Color hoverBgLight = Color(0xFFF1F5F9);
  static const Color hoverBgDark = Color(0xFF334155);
  static const Color shadowLight = Color(0x08000000); // more subtle
  static const Color shadowDark = Color(0x40000000);

  // ── Comparison ──
  static const Color compareA = Color(0xFF2563EB);
  static const Color compareB = Color(0xFF10B981);

  // ── Backward-compatible static const (light theme defaults) ──
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceBackground = Color(0xFFFFFFFF);
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color panelBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color mapBackground = Color(0xFFE2E8F0);
  static const Color searchBg = Color(0xFFF1F5F9);
  static const Color hoverBg = Color(0xFFF1F5F9);
  static const Color shadow = Color(0x08000000);
  static const Color chipInactive = Color(0xFFE2E8F0);
  static const Color highlightBg = Color(0xFFEFF6FF);

  // ── Backward-compatible aliases (used in existing widget files) ──
  static const Color accentLight = Color(0xFF60A5FA);
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentGradient = Color(0xFF06B6D4);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        surfaceTintColor: Colors.transparent,
      ),
      cardColor: AppColors.surfaceLight,
      dividerColor: AppColors.dividerLight,
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 15,
          letterSpacing: 0.1,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondaryLight,
          fontSize: 14,
          letterSpacing: 0.1,
        ),
        bodySmall: TextStyle(color: AppColors.textMutedLight, fontSize: 12),
        labelLarge: TextStyle(
          color: AppColors.textSecondaryLight,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: AppColors.textMutedLight,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryLight,
        size: 20,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.searchBgLight,
        hintStyle: const TextStyle(
          color: AppColors.textMutedLight,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary.withValues(alpha: 0.1),
        labelStyle: const TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMutedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMutedLight,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      shadowColor: AppColors.shadowLight,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        surfaceTintColor: Colors.transparent,
      ),
      cardColor: AppColors.surfaceDark,
      dividerColor: AppColors.dividerDark,
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 15,
          letterSpacing: 0.1,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 14,
          letterSpacing: 0.1,
        ),
        bodySmall: TextStyle(color: AppColors.textMutedDark, fontSize: 12),
        labelLarge: TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: AppColors.textMutedDark,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryDark,
        size: 20,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.searchBgDark,
        hintStyle: const TextStyle(
          color: AppColors.textMutedDark,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMutedDark,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryDark,
        contentTextStyle: const TextStyle(color: Colors.black87),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimaryDark,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.black87, fontSize: 12),
      ),
      shadowColor: AppColors.shadowDark,
    );
  }
}
