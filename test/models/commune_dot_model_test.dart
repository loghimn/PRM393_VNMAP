import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/commune_dot.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';

void main() {
  group('CommuneDot', () {
    final commune = ProvinceModel(
      name: 'Phường Tràng Tiền',
      geometry: {
        'type': 'Point',
        'coordinates': [105.0, 21.0],
      },
      properties: {'type': 'commune'},
    );

    test('should create CommuneDot with commune and position', () {
      const position = Offset(100.0, 200.0);
      final dot = CommuneDot(commune, position);

      expect(dot.commune, equals(commune));
      expect(dot.position, equals(position));
    });

    test('should allow position at origin', () {
      const position = Offset(0, 0);
      final dot = CommuneDot(commune, position);

      expect(dot.position.dx, 0);
      expect(dot.position.dy, 0);
    });

    test('should allow negative position', () {
      const position = Offset(-50.0, -100.0);
      final dot = CommuneDot(commune, position);

      expect(dot.position.dx, -50.0);
      expect(dot.position.dy, -100.0);
    });

    test('should store different commune instances', () {
      final commune2 = ProvinceModel(
        name: 'Phường Láng Hạ',
        geometry: {
          'type': 'Point',
          'coordinates': [105.5, 21.5],
        },
        properties: {'type': 'commune'},
      );
      const position = Offset(150.0, 250.0);
      final dot2 = CommuneDot(commune2, position);

      expect(dot2.commune.name, 'Phường Láng Hạ');
      expect(dot2.commune, isNot(equals(commune)));
    });
  });
}
