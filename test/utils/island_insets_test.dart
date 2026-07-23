import 'dart:ui' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/utils/island_insets.dart';

void main() {
  group('getHoangSaInsetRect', () {
    test('should return correct Rect for given size', () {
      const size = Size(800, 600);
      final rect = getHoangSaInsetRect(size);

      // width = 100, height = 85
      // x = 800 - 100 - 10 = 690
      // y = 600 - (85*2) - 10 - 10 = 600 - 170 - 10 - 10 = 410
      expect(rect.left, 690.0);
      expect(rect.top, 410.0);
      expect(rect.width, 100.0);
      expect(rect.height, 85.0);
    });

    test('should handle zero size', () {
      const size = Size(0, 0);
      final rect = getHoangSaInsetRect(size);

      expect(rect.left, -110.0); // 0 - 100 - 10 = -110
      expect(rect.top, -190.0); // 0 - 170 - 10 - 10 = -190
    });

    test('should handle small size', () {
      const size = Size(50, 50);
      final rect = getHoangSaInsetRect(size);

      expect(rect.left, -60.0); // 50 - 100 - 10 = -60
      expect(rect.top, -140.0); // 50 - 170 - 10 - 10 = -140
    });
  });

  group('getTruongSaInsetRect', () {
    test('should return correct Rect for given size', () {
      const size = Size(800, 600);
      final rect = getTruongSaInsetRect(size);

      // width = 100, height = 85
      // x = 800 - 100 - 10 = 690
      // y = 600 - 85 - 10 = 505
      expect(rect.left, 690.0);
      expect(rect.top, 505.0);
      expect(rect.width, 100.0);
      expect(rect.height, 85.0);
    });

    test('should handle zero size', () {
      const size = Size(0, 0);
      final rect = getTruongSaInsetRect(size);

      expect(rect.left, -110.0); // 0 - 100 - 10 = -110
      expect(rect.top, -95.0); // 0 - 85 - 10 = -95
    });

    test('should handle small size', () {
      const size = Size(50, 50);
      final rect = getTruongSaInsetRect(size);

      expect(rect.left, -60.0); // 50 - 100 - 10 = -60
      expect(rect.top, -45.0); // 50 - 85 - 10 = -45
    });
  });
}
