import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/utils/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = AppTheme.darkTheme;

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData.brightness == Brightness.dark;

  // ── Dynamic colors that change with theme ──
  Color get background =>
      isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight;
  Color get surface =>
      isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get surfaceBackground =>
      isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get navBackground =>
      isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get panelBackground =>
      isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get textPrimary =>
      isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color get textSecondary =>
      isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  Color get textMuted =>
      isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight;
  Color get border => isDarkMode ? AppColors.borderDark : AppColors.borderLight;
  Color get divider =>
      isDarkMode ? AppColors.dividerDark : AppColors.dividerLight;
  Color get mapBackground =>
      isDarkMode ? AppColors.mapBackgroundDark : AppColors.mapBackgroundLight;
  Color get searchBg =>
      isDarkMode ? AppColors.searchBgDark : AppColors.searchBgLight;
  Color get hoverBg =>
      isDarkMode ? AppColors.hoverBgDark : AppColors.hoverBgLight;
  Color get shadow => isDarkMode ? AppColors.shadowDark : AppColors.shadowLight;
  Color get chipInactive =>
      isDarkMode ? AppColors.chipInactiveDark : AppColors.chipInactiveLight;
  Color get highlightBg =>
      isDarkMode ? AppColors.highlightBgDark : AppColors.highlightBgLight;

  void toggleTheme() {
    _themeData = isDarkMode ? AppTheme.lightTheme : AppTheme.darkTheme;
    AppColors.isDarkMode = isDarkMode;
    notifyListeners();
  }

  void setThemeMode(bool isDark) {
    _themeData = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
    AppColors.isDarkMode = isDark;
    notifyListeners();
  }
}
