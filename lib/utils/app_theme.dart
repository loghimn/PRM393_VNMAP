import 'package:flutter/material.dart';

/// 🎨 White + Blue — 2026 Data Analytics Dashboard Theme
/// Primary: #2563EB | Accent: #8B5CF6 (Purple) | Secondary: #06B6D4
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

  // ── Theme Palette ──
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color accentPurple = Color(0xFF8B5CF6); // ✨ NEW accent
  static const Color accentPurpleLight = Color(0xFFA78BFA);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ── Gradient helpers ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
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

  // ── Unified border radius ──
  static const double cardRadius = 16.0; // ✨ NEW: 16px uniform radius
  static const double smallRadius = 12.0;
  static const double chipRadius = 20.0;

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
  static const Color shadowLight = Color(0x08000000);
  static const Color shadowDark = Color(0x40000000);

  // ── Comparison ──
  static const Color compareA = Color(0xFF2563EB);
  static const Color compareB = Color(0xFF10B981);

  // ── Dynamic theme mode switch (set by ThemeProvider) ──
  static bool _isDarkMode = true;

  static bool get isDarkMode => _isDarkMode;
  static set isDarkMode(bool v) => _isDarkMode = v;

  // ── Shadow helpers ──
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: _isDarkMode
          ? Colors.black.withValues(alpha: 0.25)
          : Colors.black.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: _isDarkMode
          ? Colors.black.withValues(alpha: 0.35)
          : Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  // ── Backward-compatible dynamic colors (follow current theme mode) ──
  static Color get background => _isDarkMode ? backgroundDark : backgroundLight;
  static Color get surface => _isDarkMode ? surfaceDark : surfaceLight;
  static Color get surfaceBackground =>
      _isDarkMode ? surfaceDark : surfaceLight;
  static Color get navBackground => _isDarkMode ? surfaceDark : surfaceLight;
  static Color get panelBackground => _isDarkMode ? surfaceDark : surfaceLight;
  static Color get textPrimary =>
      _isDarkMode ? textPrimaryDark : textPrimaryLight;
  static Color get textSecondary =>
      _isDarkMode ? textSecondaryDark : textSecondaryLight;
  static Color get textMuted => _isDarkMode ? textMutedDark : textMutedLight;
  static Color get border => _isDarkMode ? borderDark : borderLight;
  static Color get divider => _isDarkMode ? dividerDark : dividerLight;
  static Color get mapBackground =>
      _isDarkMode ? mapBackgroundDark : mapBackgroundLight;
  static Color get searchBg => _isDarkMode ? searchBgDark : searchBgLight;
  static Color get hoverBg => _isDarkMode ? hoverBgDark : hoverBgLight;
  static Color get shadow => _isDarkMode ? shadowDark : shadowLight;
  static Color get chipInactive =>
      _isDarkMode ? chipInactiveDark : chipInactiveLight;
  static Color get highlightBg =>
      _isDarkMode ? highlightBgDark : highlightBgLight;

  // ── Backward-compatible aliases (used in existing widget files) ──
  static const Color accentLight = Color(0xFF60A5FA);
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentGradient = Color(0xFF06B6D4);
}

/// Typography scale for consistent hierarchy
class AppTypography {
  AppTypography._();

  /// H1: 42px — Page titles
  static const TextStyle h1 = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.1,
  );

  /// H2: 32px — Section headers
  static const TextStyle h2 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.15,
  );

  /// H3: 24px — Card titles
  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.2,
  );

  /// Body: 16px — Regular text
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.4,
  );

  /// Caption: 13px — Secondary labels
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.3,
  );

  /// Small: 11px — Muted / badges
  static const TextStyle small = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    height: 1.2,
  );
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
          fontSize: 16,
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
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
