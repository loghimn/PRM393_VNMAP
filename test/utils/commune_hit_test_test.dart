import 'dart:ui' show Offset;
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/utils/commune_hit_test.dart';

void main() {
  final focusedProvince = ProvinceModel(
    name: 'Tỉnh Hà Nội',
    geometry: {
      'type': 'Polygon',
      'coordinates': [
        [
          [105.0, 21.0],
          [106.0, 21.0],
          [106.0, 22.0],
          [105.0, 22.0],
          [105.0, 21.0],
        ],
      ],
    },
    properties: {'type': 'province'},
  );

  group('getCommuneFromPositionRaw', () {
    test('should return null when communes list is empty', () {
      final result = getCommuneFromPositionRaw(
        const Offset(400, 300),
        [],
        focusedProvince,
      );
      expect(result, isNull);
    });

    test('should return null when position is outside any commune', () {
      final communes = [
        ProvinceModel(
          name: 'Xã A',
          geometry: {
            'type': 'Polygon',
            'coordinates': [
              [
                [105.1, 21.1],
                [105.2, 21.1],
                [105.2, 21.2],
                [105.1, 21.2],
                [105.1, 21.1],
              ],
            ],
          },
          properties: {'type': 'commune'},
        ),
      ];
      // Position in projected space that is far from the commune's projected polygon
      // Commune projects to roughly (155..160, 190..195), so (0, 0) is far away
      final result = getCommuneFromPositionRaw(
        const Offset(0, 0),
        communes,
        focusedProvince,
      );
      expect(result, isNull);
    });

    test(
      'should return commune when position is inside it (projected space)',
      () {
        final targetCommune = ProvinceModel(
          name: 'Xã Trung tâm',
          geometry: {
            'type': 'Polygon',
            'coordinates': [
              [
                [105.3, 21.3],
                [105.5, 21.3],
                [105.5, 21.5],
                [105.3, 21.5],
                [105.3, 21.3],
              ],
            ],
          },
          properties: {'type': 'commune'},
        );
        // Projected space: lon→(lon-102)*50, lat→(25-lat)*50
        // Polygon projects to x∈[165,175], y∈[175,185]
        // Position (170, 180) is inside
        final result = getCommuneFromPositionRaw(const Offset(170, 180), [
          targetCommune,
        ], focusedProvince);
        expect(result, isNotNull);
        expect(result!.name, 'Xã Trung tâm');
      },
    );

    test('should handle MultiPolygon commune geometry', () {
      final communes = [
        ProvinceModel(
          name: 'Xã Đa giác',
          geometry: {
            'type': 'MultiPolygon',
            'coordinates': [
              [
                [
                  [107.0, 10.5],
                  [107.5, 10.5],
                  [107.5, 11.0],
                  [107.0, 11.0],
                  [107.0, 10.5],
                ],
              ],
            ],
          },
          properties: {'type': 'commune'},
        ),
      ];
      // Projected: x∈[250,275], y∈[700,725]
      final result = getCommuneFromPositionRaw(
        const Offset(262.5, 712.5),
        communes,
        focusedProvince,
      );
      expect(result, isNotNull);
      expect(result!.name, 'Xã Đa giác');
    });

    test('should find correct commune among multiple communes', () {
      final communes = [
        ProvinceModel(
          name: 'Xã A',
          geometry: {
            'type': 'Polygon',
            'coordinates': [
              [
                [105.0, 21.0],
                [105.1, 21.0],
                [105.1, 21.1],
                [105.0, 21.1],
                [105.0, 21.0],
              ],
            ],
          },
          properties: {'type': 'commune'},
        ),
        ProvinceModel(
          name: 'Xã B',
          geometry: {
            'type': 'Polygon',
            'coordinates': [
              [
                [105.3, 21.3],
                [105.5, 21.3],
                [105.5, 21.5],
                [105.3, 21.5],
                [105.3, 21.3],
              ],
            ],
          },
          properties: {'type': 'commune'},
        ),
      ];
      // Xã B projects to x∈[165,175], y∈[175,185]; position (170, 180) is inside Xã B
      final result = getCommuneFromPositionRaw(
        const Offset(170, 180),
        communes,
        focusedProvince,
      );
      expect(result, isNotNull);
      expect(result!.name, 'Xã B');
    });

    test('should skip commune with null coordinates', () {
      final communes = [
        ProvinceModel(
          name: 'Xã Null',
          geometry: {'type': 'Polygon', 'coordinates': null},
          properties: {'type': 'commune'},
        ),
      ];
      final result = getCommuneFromPositionRaw(
        const Offset(170, 180),
        communes,
        focusedProvince,
      );
      expect(result, isNull);
    });

    test('should skip commune with empty coordinates', () {
      final communes = [
        ProvinceModel(
          name: 'Xã Rỗng',
          geometry: {'type': 'Polygon', 'coordinates': []},
          properties: {'type': 'commune'},
        ),
      ];
      final result = getCommuneFromPositionRaw(
        const Offset(170, 180),
        communes,
        focusedProvince,
      );
      expect(result, isNull);
    });
  });
}
