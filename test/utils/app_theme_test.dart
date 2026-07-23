import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/utils/app_theme.dart';

void main() {
  group('AppColors', () {
    test('should have correct primary color', () {
      expect(AppColors.primary, const Color(0xFF3B82F6));
    });

    test('should have correct dark background', () {
      expect(AppColors.backgroundDark, const Color(0xFF0F172A));
    });

    test('should have correct success color', () {
      expect(AppColors.success, const Color(0xFF22C55E));
    });

    test('should have correct error color', () {
      expect(AppColors.error, const Color(0xFFEF4444));
    });

    test('should have correct warning color', () {
      expect(AppColors.warning, const Color(0xFFF59E0B));
    });

    test('should have correct card radius', () {
      expect(AppColors.cardRadius, 16.0);
    });

    test('should have correct small radius', () {
      expect(AppColors.smallRadius, 12.0);
    });

    test('should have gradients defined', () {
      expect(AppColors.primaryGradient, isA<LinearGradient>());
      expect(AppColors.cyanGradient, isA<LinearGradient>());
      expect(AppColors.greenGradient, isA<LinearGradient>());
      expect(AppColors.orangeGradient, isA<LinearGradient>());
      expect(AppColors.redGradient, isA<LinearGradient>());
      expect(AppColors.tealGradient, isA<LinearGradient>());
      expect(AppColors.purpleGradient, isA<LinearGradient>());
    });

    test('should return dark mode colors by default', () {
      expect(AppColors.isDarkMode, isTrue);
    });

    test('should toggle dark mode', () {
      AppColors.isDarkMode = false;
      expect(AppColors.isDarkMode, isFalse);

      AppColors.isDarkMode = true;
      expect(AppColors.isDarkMode, isTrue);
    });

    test('should have card shadow defined', () {
      final shadows = AppColors.cardShadow;
      expect(shadows.length, 1);
      expect(shadows[0].blurRadius, 20);
    });

    test('should have elevated shadow defined', () {
      final shadows = AppColors.elevatedShadow;
      expect(shadows.length, 1);
      expect(shadows[0].blurRadius, 24);
    });

    test('should have province colors defined', () {
      expect(AppColors.provinceMountain, const Color(0xFF22C55E));
      expect(AppColors.provinceCity, const Color(0xFFF97316));
      expect(AppColors.provinceSpecial, const Color(0xFF3B82F6));
      expect(AppColors.provinceDefault, const Color(0xFFCBD5E1));
    });
  });

  group('AppTypography', () {
    test('should have title style with correct fontSize', () {
      expect(AppTypography.title.fontSize, 30);
      expect(AppTypography.title.fontWeight, FontWeight.w700);
    });

    test('should have section style with correct fontSize', () {
      expect(AppTypography.section.fontSize, 26);
    });

    test('should have cardNumber style with correct fontSize', () {
      expect(AppTypography.cardNumber.fontSize, 30);
      expect(AppTypography.cardNumber.fontWeight, FontWeight.w800);
    });

    test('should have normal style with correct fontSize', () {
      expect(AppTypography.normal.fontSize, 16);
    });

    test('should have caption style with correct fontSize', () {
      expect(AppTypography.caption.fontSize, 13);
    });

    test('should have small style with correct fontSize', () {
      expect(AppTypography.small.fontSize, 11);
    });
  });

  group('AppTheme', () {
    test('should create dark theme', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.backgroundDark);
    });

    test('should create light theme', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppColors.backgroundLight);
    });
  });
}
