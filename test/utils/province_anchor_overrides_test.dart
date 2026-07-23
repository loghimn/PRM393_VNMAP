import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/utils/province_anchor_overrides.dart';

void main() {
  group('ProvinceAnchorOverrides', () {
    test('should contain override for Tỉnh An Giang', () {
      expect(
        ProvinceAnchorOverrides.overrides.containsKey('Tỉnh An Giang'),
        isTrue,
      );
    });

    test('should have correct offset for Tỉnh An Giang', () {
      final offset = ProvinceAnchorOverrides.overrides['Tỉnh An Giang'];
      expect(offset, const Offset(145, 728));
    });

    test('should have exactly one override', () {
      expect(ProvinceAnchorOverrides.overrides.length, 1);
    });

    test('should return null for unknown province', () {
      expect(ProvinceAnchorOverrides.overrides['Tỉnh Hà Nội'], isNull);
    });
  });
}
