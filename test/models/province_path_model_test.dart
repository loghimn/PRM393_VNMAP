import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/models/province_path.dart';
import 'dart:ui' as ui;

void main() {
  group('ProvincePath', () {
    final province = ProvinceModel(
      name: 'Hà Nội',
      geometry: {'type': 'Polygon', 'coordinates': []},
      properties: {'type': 'province'},
    );

    test('should create ProvincePath with province and path', () {
      final path = ui.Path();
      path.moveTo(0, 0);
      path.lineTo(100, 0);
      path.lineTo(100, 100);
      path.close();

      final pp = ProvincePath(province: province, path: path);

      expect(pp.province, equals(province));
      expect(pp.path, equals(path));
    });

    test('should accept empty path', () {
      final emptyPath = ui.Path();
      final pp = ProvincePath(province: province, path: emptyPath);

      expect(pp.path, equals(emptyPath));
    });

    test('should store different province instances', () {
      final province2 = ProvinceModel(
        name: 'TP. Hồ Chí Minh',
        geometry: {'type': 'Polygon', 'coordinates': []},
        properties: {'type': 'province'},
      );
      final path = ui.Path();
      final pp = ProvincePath(province: province2, path: path);

      expect(pp.province.name, 'TP. Hồ Chí Minh');
      expect(pp.province, isNot(equals(province)));
    });

    test('should compute path bounds', () {
      final path = ui.Path();
      path.addRect(const ui.Rect.fromLTWH(0, 0, 100, 100));
      final pp = ProvincePath(province: province, path: path);

      final bounds = pp.path.getBounds();
      expect(bounds.width, 100);
      expect(bounds.height, 100);
    });

    test('should contain point inside path', () {
      final path = ui.Path();
      path.addRect(const ui.Rect.fromLTWH(0, 0, 100, 100));
      final pp = ProvincePath(province: province, path: path);

      expect(pp.path.contains(const ui.Offset(50, 50)), isTrue);
      expect(pp.path.contains(const ui.Offset(150, 150)), isFalse);
    });
  });
}
