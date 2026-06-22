import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/utils/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = AppTheme.lightTheme;

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData.brightness == Brightness.dark;

  void toggleTheme() {
    _themeData = isDarkMode ? AppTheme.lightTheme : AppTheme.darkTheme;
    notifyListeners();
  }

  void setThemeMode(bool isDark) {
    _themeData = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
    notifyListeners();
  }
}
