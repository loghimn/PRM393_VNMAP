import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/provinceLabel.dart';

void main() {
  group('ProvinceLabel', () {
    test('should create ProvinceLabel with position and name', () {
      const position = Offset(100.0, 200.0);
      final label = ProvinceLabel(position: position, name: 'Hà Nội');

      expect(label.position, equals(position));
      expect(label.name, 'Hà Nội');
    });

    test('should allow position at origin', () {
      const position = Offset(0, 0);
      final label = ProvinceLabel(position: position, name: 'Origin');

      expect(label.position.dx, 0);
      expect(label.position.dy, 0);
    });

    test('should allow negative position', () {
      const position = Offset(-50.0, -100.0);
      final label = ProvinceLabel(position: position, name: 'Negative');

      expect(label.position.dx, -50.0);
      expect(label.position.dy, -100.0);
    });

    test('should store different names', () {
      const position = Offset(0, 0);
      final label1 = ProvinceLabel(position: position, name: 'Hà Nội');
      final label2 = ProvinceLabel(position: position, name: 'TP. Hồ Chí Minh');

      expect(label1.name, isNot(equals(label2.name)));
    });

    test('should store different positions for same name', () {
      final label1 = ProvinceLabel(
        position: const Offset(10, 20),
        name: 'Test',
      );
      final label2 = ProvinceLabel(
        position: const Offset(30, 40),
        name: 'Test',
      );

      expect(label1.position, isNot(equals(label2.position)));
    });
  });
}
