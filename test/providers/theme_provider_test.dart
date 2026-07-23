import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/providers/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    late ThemeProvider provider;

    setUp(() {
      provider = ThemeProvider();
    });

    test('should start in dark mode by default', () {
      expect(provider.isDarkMode, isTrue);
    });

    test('should toggle from dark to light', () {
      provider.toggleTheme();

      expect(provider.isDarkMode, isFalse);
    });

    test('should toggle from light back to dark', () {
      provider.toggleTheme(); // dark -> light
      provider.toggleTheme(); // light -> dark

      expect(provider.isDarkMode, isTrue);
    });

    test('should set theme mode to dark', () {
      provider.setThemeMode(true);

      expect(provider.isDarkMode, isTrue);
    });

    test('should set theme mode to light', () {
      provider.setThemeMode(false);

      expect(provider.isDarkMode, isFalse);
    });

    test('should provide correct dynamic colors in dark mode', () {
      expect(provider.isDarkMode, isTrue);
      // Just check they return non-null Color values
      expect(provider.background, isNotNull);
      expect(provider.surface, isNotNull);
      expect(provider.textPrimary, isNotNull);
      expect(provider.textSecondary, isNotNull);
      expect(provider.textMuted, isNotNull);
      expect(provider.border, isNotNull);
      expect(provider.divider, isNotNull);
      expect(provider.mapBackground, isNotNull);
      expect(provider.searchBg, isNotNull);
      expect(provider.hoverBg, isNotNull);
      expect(provider.shadow, isNotNull);
      expect(provider.chipInactive, isNotNull);
      expect(provider.highlightBg, isNotNull);
      expect(provider.surfaceBackground, isNotNull);
      expect(provider.navBackground, isNotNull);
      expect(provider.panelBackground, isNotNull);
    });

    test('should provide correct dynamic colors in light mode', () {
      provider.setThemeMode(false);

      expect(provider.isDarkMode, isFalse);
      expect(provider.background, isNotNull);
      expect(provider.surface, isNotNull);
      expect(provider.textPrimary, isNotNull);
      expect(provider.textSecondary, isNotNull);
      expect(provider.textMuted, isNotNull);
      expect(provider.border, isNotNull);
      expect(provider.divider, isNotNull);
      expect(provider.mapBackground, isNotNull);
      expect(provider.searchBg, isNotNull);
      expect(provider.hoverBg, isNotNull);
      expect(provider.shadow, isNotNull);
      expect(provider.chipInactive, isNotNull);
      expect(provider.highlightBg, isNotNull);
      expect(provider.surfaceBackground, isNotNull);
      expect(provider.navBackground, isNotNull);
      expect(provider.panelBackground, isNotNull);
    });

    test('should produce different colors in dark vs light mode', () {
      final darkBackground = provider.background;
      provider.setThemeMode(false);
      final lightBackground = provider.background;

      expect(darkBackground, isNot(equals(lightBackground)));
    });

    test('should notify listeners on toggleTheme', () {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.toggleTheme();

      expect(notified, isTrue);
    });

    test('should notify listeners on setThemeMode', () {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.setThemeMode(false);

      expect(notified, isTrue);
    });

    test('should return correct themeData brightness', () {
      expect(provider.themeData.brightness, Brightness.dark);

      provider.setThemeMode(false);

      expect(provider.themeData.brightness, Brightness.light);
    });
  });
}
