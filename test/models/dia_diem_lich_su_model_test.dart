import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/dia_diem_lich_su_model.dart';

void main() {
  group('DiaDiemLichSu.fromJson', () {
    test('should parse full JSON data', () {
      final json = {
        'id': 1,
        'ten': 'Chùa Một Cột',
        'loai_di_tich': 'Chùa',
        'dia_chi': 'Hà Nội',
        'kinh_do': 105.846,
        'vi_do': 21.035,
        'mo_ta': 'Ngôi chùa cổ',
        'thoi_ky': 'Thời Lý',
        'image_url': 'https://example.com/chua.jpg',
        'ghi_chu': 'Di tích quốc gia',
        'created_at': '2024-01-15T10:00:00.000',
      };

      final model = DiaDiemLichSu.fromJson(json);

      expect(model.id, 1);
      expect(model.ten, 'Chùa Một Cột');
      expect(model.loaiDiTich, 'Chùa');
      expect(model.diaChi, 'Hà Nội');
      expect(model.kinhDo, 105.846);
      expect(model.viDo, 21.035);
      expect(model.moTa, 'Ngôi chùa cổ');
      expect(model.thoiKy, 'Thời Lý');
      expect(model.imageUrl, 'https://example.com/chua.jpg');
      expect(model.ghiChu, 'Di tích quốc gia');
      expect(model.createdAt, DateTime(2024, 1, 15, 10, 0, 0));
    });

    test('should parse int id correctly', () {
      final json = {'id': 99, 'ten': 'Test'};

      final model = DiaDiemLichSu.fromJson(json);

      expect(model.id, 99);
    });

    test('should parse kinh_do and vi_do from int', () {
      final json = {'id': 1, 'ten': 'Test', 'kinh_do': 106, 'vi_do': 20};

      final model = DiaDiemLichSu.fromJson(json);

      expect(model.kinhDo, 106.0);
      expect(model.viDo, 20.0);
    });

    test('should default ten to empty string when not provided', () {
      final json = <String, dynamic>{};

      final model = DiaDiemLichSu.fromJson(json);

      expect(model.ten, '');
    });

    test('should handle null optional fields', () {
      final json = {'ten': 'Test'};

      final model = DiaDiemLichSu.fromJson(json);

      expect(model.id, isNull);
      expect(model.loaiDiTich, isNull);
      expect(model.diaChi, isNull);
      expect(model.kinhDo, isNull);
      expect(model.viDo, isNull);
      expect(model.moTa, isNull);
      expect(model.thoiKy, isNull);
      expect(model.imageUrl, isNull);
      expect(model.ghiChu, isNull);
      expect(model.createdAt, isNull);
    });

    test('should parse date from invalid string as null', () {
      final json = {'ten': 'Test', 'created_at': 'invalid-date'};

      final model = DiaDiemLichSu.fromJson(json);

      expect(model.createdAt, isNull);
    });
  });

  group('DiaDiemLichSu.toJson', () {
    test('should convert to JSON correctly', () {
      final model = DiaDiemLichSu(
        id: 1,
        ten: 'Chùa Một Cột',
        loaiDiTich: 'Chùa',
        diaChi: 'Hà Nội',
        kinhDo: 105.846,
        viDo: 21.035,
        moTa: 'Ngôi chùa cổ',
        thoiKy: 'Thời Lý',
        imageUrl: 'https://example.com/chua.jpg',
        ghiChu: 'Di tích quốc gia',
      );

      final json = model.toJson();

      expect(json['id'], 1);
      expect(json['ten'], 'Chùa Một Cột');
      expect(json['loai_di_tich'], 'Chùa');
      expect(json['dia_chi'], 'Hà Nội');
      expect(json['kinh_do'], 105.846);
      expect(json['vi_do'], 21.035);
      expect(json['mo_ta'], 'Ngôi chùa cổ');
      expect(json['thoi_ky'], 'Thời Lý');
      expect(json['image_url'], 'https://example.com/chua.jpg');
      expect(json['ghi_chu'], 'Di tích quốc gia');
    });

    test('should not include null id', () {
      final model = DiaDiemLichSu(ten: 'Test');

      final json = model.toJson();

      expect(json.containsKey('id'), isFalse);
    });

    test('should include null optional fields as null', () {
      final model = DiaDiemLichSu(ten: 'Test');

      final json = model.toJson();

      expect(json['loai_di_tich'], isNull);
      expect(json['dia_chi'], isNull);
      expect(json['kinh_do'], isNull);
      expect(json['vi_do'], isNull);
      expect(json['mo_ta'], isNull);
      expect(json['thoi_ky'], isNull);
      expect(json['image_url'], isNull);
      expect(json['ghi_chu'], isNull);
    });

    test('should not include createdAt', () {
      final model = DiaDiemLichSu(
        ten: 'Test',
        createdAt: DateTime(2024, 1, 15),
      );

      final json = model.toJson();

      expect(json.containsKey('created_at'), isFalse);
    });
  });
}
