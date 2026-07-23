import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/tuyen_duong_model.dart';

void main() {
  group('TuyenDuong.fromJson', () {
    test('should parse full JSON data', () {
      final json = {
        'id': 1,
        'ten': 'Đường Nguyễn Huệ',
        'loai': 'Đường phố',
        'dia_diem_bat_dau': 'Q.1',
        'dia_diem_ket_thuc': 'Q.2',
        'chieu_dai': 5.2,
        'mo_ta': 'Tuyến đường chính',
        'ghi_chu': 'Có nhiều cây xanh',
        'created_at': '2024-01-15T10:00:00.000',
      };

      final model = TuyenDuong.fromJson(json);

      expect(model.id, 1);
      expect(model.ten, 'Đường Nguyễn Huệ');
      expect(model.loai, 'Đường phố');
      expect(model.diaDiemBatDau, 'Q.1');
      expect(model.diaDiemKetThuc, 'Q.2');
      expect(model.chieuDai, 5.2);
      expect(model.moTa, 'Tuyến đường chính');
      expect(model.ghiChu, 'Có nhiều cây xanh');
      expect(model.createdAt, DateTime(2024, 1, 15, 10, 0, 0));
    });

    test('should parse int id correctly', () {
      final json = {'id': 99, 'ten': 'Test'};

      final model = TuyenDuong.fromJson(json);

      expect(model.id, 99);
    });

    test('should parse chieu_dai from int', () {
      final json = {'id': 1, 'ten': 'Test', 'chieu_dai': 10};

      final model = TuyenDuong.fromJson(json);

      expect(model.chieuDai, 10.0);
    });

    test('should default ten to empty string when not provided', () {
      final json = <String, dynamic>{};

      final model = TuyenDuong.fromJson(json);

      expect(model.ten, '');
    });

    test('should handle null optional fields', () {
      final json = {'ten': 'Test'};

      final model = TuyenDuong.fromJson(json);

      expect(model.id, isNull);
      expect(model.loai, isNull);
      expect(model.diaDiemBatDau, isNull);
      expect(model.diaDiemKetThuc, isNull);
      expect(model.chieuDai, isNull);
      expect(model.moTa, isNull);
      expect(model.ghiChu, isNull);
      expect(model.createdAt, isNull);
    });

    test('should parse date from invalid string as null', () {
      final json = {'ten': 'Test', 'created_at': 'invalid-date'};

      final model = TuyenDuong.fromJson(json);

      expect(model.createdAt, isNull);
    });
  });

  group('TuyenDuong.toJson', () {
    test('should convert to JSON correctly', () {
      final model = TuyenDuong(
        id: 1,
        ten: 'Đường Nguyễn Huệ',
        loai: 'Đường phố',
        diaDiemBatDau: 'Q.1',
        diaDiemKetThuc: 'Q.2',
        chieuDai: 5.2,
        moTa: 'Tuyến đường chính',
        ghiChu: 'Có nhiều cây xanh',
      );

      final json = model.toJson();

      expect(json['id'], 1);
      expect(json['ten'], 'Đường Nguyễn Huệ');
      expect(json['loai'], 'Đường phố');
      expect(json['dia_diem_bat_dau'], 'Q.1');
      expect(json['dia_diem_ket_thuc'], 'Q.2');
      expect(json['chieu_dai'], 5.2);
      expect(json['mo_ta'], 'Tuyến đường chính');
      expect(json['ghi_chu'], 'Có nhiều cây xanh');
    });

    test('should not include null id', () {
      final model = TuyenDuong(ten: 'Test');

      final json = model.toJson();

      expect(json.containsKey('id'), isFalse);
    });

    test('should include null optional fields as null', () {
      final model = TuyenDuong(ten: 'Test');

      final json = model.toJson();

      expect(json['loai'], isNull);
      expect(json['dia_diem_bat_dau'], isNull);
      expect(json['dia_diem_ket_thuc'], isNull);
      expect(json['chieu_dai'], isNull);
      expect(json['mo_ta'], isNull);
      expect(json['ghi_chu'], isNull);
    });

    test('should not include createdAt', () {
      final model = TuyenDuong(ten: 'Test', createdAt: DateTime(2024, 1, 15));

      final json = model.toJson();

      expect(json.containsKey('created_at'), isFalse);
    });
  });
}
