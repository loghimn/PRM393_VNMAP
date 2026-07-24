import 'dart:ui'
    show
        Canvas,
        Size,
        Offset,
        Rect,
        RRect,
        Path,
        Paint,
        TextPainter,
        PictureRecorder;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map_painter.dart';

/// Helper để tạo ProvinceModel với Polygon geometry
ProvinceModel createPolygonProvince({
  required String name,
  required String type,
  List<List<List<double>>>? rings,
  double? density,
  int? population,
  double? areaKm2,
}) {
  final coords =
      rings ??
      [
        [
          [105.0, 21.0],
          [106.0, 21.0],
          [106.0, 22.0],
          [105.0, 22.0],
          [105.0, 21.0],
        ],
      ];
  return ProvinceModel(
    name: name,
    geometry: {'type': 'Polygon', 'coordinates': coords},
    properties: {'type': type},
    density: density,
    population: population,
    areaKm2: areaKm2,
  );
}

/// Helper để tạo ProvinceModel với MultiPolygon geometry
ProvinceModel createMultiPolygonProvince({
  required String name,
  required String type,
}) {
  return ProvinceModel(
    name: name,
    geometry: {
      'type': 'MultiPolygon',
      'coordinates': [
        [
          [
            [105.0, 20.0],
            [106.0, 20.0],
            [106.0, 21.0],
            [105.0, 21.0],
            [105.0, 20.0],
          ],
        ],
      ],
    },
    properties: {'type': type},
  );
}

/// Special zone với tên có Hoàng Sa
ProvinceModel createHoangSa() {
  return ProvinceModel(
    name: 'Quần đảo Hoàng Sa',
    geometry: {
      'type': 'Polygon',
      'coordinates': [
        [
          [111.0, 16.0],
          [112.0, 16.0],
          [112.0, 17.0],
          [111.0, 17.0],
          [111.0, 16.0],
        ],
      ],
    },
    properties: {'type': 'special_zone'},
  );
}

/// Special zone với tên có Trường Sa
ProvinceModel createTruongSa() {
  return ProvinceModel(
    name: 'Quần đảo Trường Sa',
    geometry: {
      'type': 'Polygon',
      'coordinates': [
        [
          [113.0, 8.0],
          [114.0, 8.0],
          [114.0, 9.0],
          [113.0, 9.0],
          [113.0, 8.0],
        ],
      ],
    },
    properties: {'type': 'special_zone'},
  );
}

/// Special zone bình thường (không phải Hoàng Sa / Trường Sa)
ProvinceModel createNormalSpecialZone() {
  return ProvinceModel(
    name: 'Vịnh Bắc Bộ',
    geometry: {
      'type': 'Polygon',
      'coordinates': [
        [
          [107.0, 20.0],
          [108.0, 20.0],
          [108.0, 21.0],
          [107.0, 21.0],
          [107.0, 20.0],
        ],
      ],
    },
    properties: {'type': 'special_zone'},
  );
}

/// Tạo communes mẫu
List<ProvinceModel> createSampleCommunes() {
  return [
    createPolygonProvince(
      name: 'Xã A',
      type: 'commune',
      rings: [
        [
          [105.2, 21.2],
          [105.5, 21.2],
          [105.5, 21.5],
          [105.2, 21.5],
          [105.2, 21.2],
        ],
      ],
    ),
    createPolygonProvince(
      name: 'Xã B',
      type: 'commune',
      rings: [
        [
          [105.5, 21.2],
          [105.8, 21.2],
          [105.8, 21.5],
          [105.5, 21.5],
          [105.5, 21.2],
        ],
      ],
    ),
  ];
}

void main() {
  const viewportSize = Size(800, 600);

  final sampleProvinces = [
    createPolygonProvince(name: 'Hà Nội', type: 'Thành phố'),
    createPolygonProvince(name: 'Hải Phòng', type: 'Tỉnh'),
    createMultiPolygonProvince(name: 'Đồng Nai', type: 'Tỉnh'),
  ];

  final sampleSpecialZones = [
    createHoangSa(),
    createTruongSa(),
    createNormalSpecialZone(),
  ];

  group('VietnamMapPainter - paint()', () {
    test('paint() không throw exception khi provinces trống', () {
      final painter = VietnamMapPainter(
        provinces: [],
        specialZones: [],
        mousePosition: Offset.zero,
        communes: [],
        focusedProvince: null,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      // Canvas và size tối thiểu
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
      recorder.endRecording();
    });

    test('paint() không throw exception khi có dữ liệu provinces', () {
      final painter = VietnamMapPainter(
        provinces: sampleProvinces,
        specialZones: [],
        mousePosition: const Offset(400, 300),
        communes: [],
        focusedProvince: null,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
      recorder.endRecording();
    });

    test('paint() không throw với specialZones', () {
      final painter = VietnamMapPainter(
        provinces: sampleProvinces,
        specialZones: sampleSpecialZones,
        mousePosition: const Offset(400, 300),
        communes: [],
        focusedProvince: null,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
      recorder.endRecording();
    });

    test('paint() ở chế độ focusedProvince không throw', () {
      final focusedProvince = sampleProvinces.first;

      final painter = VietnamMapPainter(
        provinces: sampleProvinces,
        specialZones: sampleSpecialZones,
        mousePosition: const Offset(400, 300),
        communes: createSampleCommunes(),
        focusedProvince: focusedProvince,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
      recorder.endRecording();
    });

    test(
      'paint() ở chế độ focusedProvince với selectedCommune không throw',
      () {
        final focusedProvince = sampleProvinces.first;
        final communes = createSampleCommunes();
        final selectedCommune = communes.first;

        final painter = VietnamMapPainter(
          provinces: sampleProvinces,
          specialZones: sampleSpecialZones,
          mousePosition: const Offset(400, 300),
          communes: communes,
          focusedProvince: focusedProvince,
          selectedProvince: null,
          selectedCommune: selectedCommune,
          viewportSize: viewportSize,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(800, 600);

        expect(() => painter.paint(canvas, size), returnsNormally);
        recorder.endRecording();
      },
    );

    test('paint() với hoveredProvince không throw', () {
      final painter = VietnamMapPainter(
        provinces: sampleProvinces,
        specialZones: [],
        mousePosition: const Offset(400, 300),
        communes: [],
        focusedProvince: null,
        hoveredProvince: sampleProvinces.first,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
      recorder.endRecording();
    });

    test('paint() với selectedProvince không throw', () {
      final painter = VietnamMapPainter(
        provinces: sampleProvinces,
        specialZones: [],
        mousePosition: const Offset(400, 300),
        communes: [],
        focusedProvince: null,
        hoveredProvince: null,
        selectedProvince: sampleProvinces.first,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
      recorder.endRecording();
    });

    test('paint() với Hoàng Sa trong specialZones kéo focusedProvince', () {
      // Mở rộng: dùng province Hoàng Sa làm focusedProvince
      // coordinates nằm trong vùng > 109.6 lon, nên tính transform cần pass 2
      final hoangSa = createHoangSa();

      final painter = VietnamMapPainter(
        provinces: [],
        specialZones: [hoangSa],
        mousePosition: const Offset(400, 300),
        communes: [],
        focusedProvince: hoangSa,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
      recorder.endRecording();
    });
  });

  group('VietnamMapPainter - shouldRepaint', () {
    test('shouldRepaint luôn trả về true', () {
      final painter = VietnamMapPainter(
        provinces: [],
        specialZones: [],
        mousePosition: Offset.zero,
        communes: [],
        focusedProvince: null,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      // Dùng chính nó làm oldDelegate
      expect(painter.shouldRepaint(painter), isTrue);
    });
  });

  group('VietnamMapPainter - getProvinceColor', () {
    test('trả về orange khi hovered', () {
      final painter = VietnamMapPainter(
        provinces: sampleProvinces,
        specialZones: [],
        mousePosition: const Offset(400, 300),
        communes: [],
        focusedProvince: null,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      final province = sampleProvinces.first;
      final color = painter.getProvinceColor(province, true);

      expect(color, Colors.orange);
    });

    test('trả về orange khi selected', () {
      final selectedProvince = sampleProvinces.first;
      final painter = VietnamMapPainter(
        provinces: sampleProvinces,
        specialZones: [],
        mousePosition: const Offset(400, 300),
        communes: [],
        focusedProvince: null,
        selectedProvince: selectedProvince,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      final color = painter.getProvinceColor(selectedProvince, false);

      expect(color, Colors.orange);
    });

    test('trả về purple cho Thành phố khi không hovered/selected', () {
      final painter = VietnamMapPainter(
        provinces: sampleProvinces,
        specialZones: [],
        mousePosition: const Offset(400, 300),
        communes: [],
        focusedProvince: null,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      final province = sampleProvinces[0]; // type: 'Thành phố'
      final color = painter.getProvinceColor(province, false);

      expect(color, Colors.purple);
    });

    test('trả về green cho Tỉnh khi không hovered/selected', () {
      final painter = VietnamMapPainter(
        provinces: sampleProvinces,
        specialZones: [],
        mousePosition: const Offset(400, 300),
        communes: [],
        focusedProvince: null,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      final province = sampleProvinces[1]; // type: 'Tỉnh'
      final color = painter.getProvinceColor(province, false);

      expect(color, Colors.green);
    });

    test('trả về blueAccent cho Đặc khu khi không hovered/selected', () {
      final provinces = [
        createPolygonProvince(name: 'Đặc khu A', type: 'Đặc khu'),
      ];

      final painter = VietnamMapPainter(
        provinces: provinces,
        specialZones: [],
        mousePosition: const Offset(400, 300),
        communes: [],
        focusedProvince: null,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      final color = painter.getProvinceColor(provinces.first, false);

      expect(color, Colors.blueAccent);
    });

    test('trả về grey cho type không xác định', () {
      final provinces = [
        createPolygonProvince(name: 'Unknown', type: 'unknown'),
      ];

      final painter = VietnamMapPainter(
        provinces: provinces,
        specialZones: [],
        mousePosition: const Offset(400, 300),
        communes: [],
        focusedProvince: null,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      final color = painter.getProvinceColor(provinces.first, false);

      expect(color, Colors.grey);
    });
  });

  group('VietnamMapPainter - coordinates edge cases', () {
    test('paint() với geometry coordinates null không throw', () {
      final provinces = [
        ProvinceModel(
          name: 'Invalid',
          geometry: <String, dynamic>{},
          properties: {},
        ),
      ];

      final painter = VietnamMapPainter(
        provinces: provinces,
        specialZones: [],
        mousePosition: Offset.zero,
        communes: [],
        focusedProvince: null,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
      recorder.endRecording();
    });

    test('paint() với coordinates rỗng throw RangeError (index [0] fail)', () {
      final provinces = [
        ProvinceModel(
          name: 'Empty',
          geometry: {'type': 'Polygon', 'coordinates': []},
          properties: {},
        ),
      ];

      final painter = VietnamMapPainter(
        provinces: provinces,
        specialZones: [],
        mousePosition: Offset.zero,
        communes: [],
        focusedProvince: null,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), throwsA(isA<RangeError>()));
      recorder.endRecording();
    });

    test('paint() với MultiPolygon coordinates rỗng throw RangeError', () {
      final provinces = [
        ProvinceModel(
          name: 'Empty Multi',
          geometry: {
            'type': 'MultiPolygon',
            'coordinates': [[], []],
          },
          properties: {},
        ),
      ];

      final painter = VietnamMapPainter(
        provinces: provinces,
        specialZones: [],
        mousePosition: Offset.zero,
        communes: [],
        focusedProvince: null,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: viewportSize,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), throwsA(isA<RangeError>()));
      recorder.endRecording();
    });

    test('paint() với viewportSize zero không throw', () {
      final painter = VietnamMapPainter(
        provinces: sampleProvinces,
        specialZones: [],
        mousePosition: Offset.zero,
        communes: [],
        focusedProvince: null,
        selectedProvince: null,
        selectedCommune: null,
        viewportSize: Size.zero,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(1, 1);

      expect(() => painter.paint(canvas, size), returnsNormally);
      recorder.endRecording();
    });
  });
}
