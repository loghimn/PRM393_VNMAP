import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/dia_diem_cong_cong_model.dart';

void main() {
  group('DiaDiemCongCong.fromJson', () {
    test('should parse full JSON data', () {
      final json = {
        'id': 1,
        'ten': 'Công viên Tao Đàn',
        'loai': 'Công viên',
        'dia_chi': 'Q.1, TP.HCM',
        'kinh_do': 106.695,
        'vi_do': 10.777,
        'mo_ta': 'Công viên trung tâm',
        'ghi_chu': 'Có nhiều cây xanh',
        'created_at': '2024-01-15T10:00:00.000',
      };

      final model = DiaDiemCongCong.fromJson(json);

      expect(model.id, 1);
      expect(model.ten, 'Công viên Tao Đàn');
      expect(model.loai, 'Công viên');
      expect(model.diaChi, 'Q.1, TP.HCM');
      expect(model.kinhDo, 106.695);
      expect(model.viDo, 10.777);
      expect(model.moTa, 'Công viên trung tâm');
      expect(model.ghiChu, 'Có nhiều cây xanh');
      expect(model.createdAt, DateTime(2024, 1, 15, 10, 0, 0));
    });

    test('should parse int id correctly', () {
      final json = {'id': 99, 'ten': 'Test'};

      final model = DiaDiemCongCong.fromJson(json);

      expect(model.id, 99);
    });

    test('should parse kinh_do and vi_do from int', () {
      final json = {'id': 1, 'ten': 'Test', 'kinh_do': 106, 'vi_do': 20};

      final model = DiaDiemCongCong.fromJson(json);

      expect(model.kinhDo, 106.0);
      expect(model.viDo, 20.0);
    });

    test('should default ten to empty string when not provided', () {
      final json = <String, dynamic>{};

      final model = DiaDiemCongCong.fromJson(json);

      expect(model.ten, '');
    });

    test('should handle null optional fields', () {
      final json = {'ten': 'Test'};

      final model = DiaDiemCongCong.fromJson(json);

      expect(model.id, isNull);
      expect(model.loai, isNull);
      expect(model.diaChi, isNull);
      expect(model.kinhDo, isNull);
      expect(model.viDo, isNull);
      expect(model.moTa, isNull);
      expect(model.ghiChu, isNull);
      expect(model.createdAt, isNull);
    });

    test('should parse date from invalid string as null', () {
      final json = {'ten': 'Test', 'created_at': 'invalid-date'};

      final model = DiaDiemCongCong.fromJson(json);

      expect(model.createdAt, isNull);
    });
  });

  group('DiaDiemCongCong.toJson', () {
    test('should convert to JSON correctly', () {
      final model = DiaDiemCongCong(
        id: 1,
        ten: 'Công viên Tao Đàn',
        loai: 'Công viên',
        diaChi: 'Q.1, TP.HCM',
        kinhDo: 106.695,
        viDo: 10.777,
        moTa: 'Công viên trung tâm',
        ghiChu: 'Có nhiều cây xanh',
      );

      final json = model.toJson();

      expect(json['id'], 1);
      expect(json['ten'], 'Công viên Tao Đàn');
      expect(json['loai'], 'Công viên');
      expect(json['dia_chi'], 'Q.1, TP.HCM');
      expect(json['kinh_do'], 106.695);
      expect(json['vi_do'], 10.777);
      expect(json['mo_ta'], 'Công viên trung tâm');
      expect(json['ghi_chu'], 'Có nhiều cây xanh');
    });

    test('should not include null id', () {
      final model = DiaDiemCongCong(ten: 'Test');

      final json = model.toJson();

      expect(json.containsKey('id'), isFalse);
    });

    test('should include null optional fields as null', () {
      final model = DiaDiemCongCong(ten: 'Test');

      final json = model.toJson();

      expect(json['loai'], isNull);
      expect(json['dia_chi'], isNull);
      expect(json['kinh_do'], isNull);
      expect(json['vi_do'], isNull);
      expect(json['mo_ta'], isNull);
      expect(json['ghi_chu'], isNull);
    });

    test('should not include createdAt', () {
      final model = DiaDiemCongCong(
        ten: 'Test',
        createdAt: DateTime(2024, 1, 15),
      );

      final json = model.toJson();

      expect(json.containsKey('created_at'), isFalse);
    });
  });
}
