import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vietnam_geo_dashboard/models/user_model.dart';
import 'package:vietnam_geo_dashboard/models/household_model.dart';
import 'package:vietnam_geo_dashboard/models/incident_model.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/models/high_school_model.dart';
import 'package:vietnam_geo_dashboard/models/dia_diem_lich_su_model.dart';
import 'package:vietnam_geo_dashboard/models/khu_pho_model.dart';
import 'package:vietnam_geo_dashboard/models/dai_dien_model.dart';
import 'package:vietnam_geo_dashboard/models/household_request_model.dart';
import 'package:vietnam_geo_dashboard/services/firestore_service.dart';
import 'package:vietnam_geo_dashboard/services/storage_service.dart';

// ============================================================
// MOCK CLASSES — dùng với mocktail
// ============================================================

class MockFirebaseAuth extends Mock implements auth.FirebaseAuth {}

class MockUserCredential extends Mock implements auth.UserCredential {}

class MockUser extends Mock implements auth.User {}

// ============================================================
// FIREBASE STORAGE MOCKS
// ============================================================

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

class MockReference extends Mock implements Reference {}

class MockUploadTask extends Mock implements UploadTask {}

class MockTaskSnapshot extends Mock implements TaskSnapshot {}

class MockListResult extends Mock implements ListResult {}

// ============================================================
// FAKE FIRESTORE FACTORY
// ============================================================

/// Tạo [FakeFirebaseFirestore] với dữ liệu khởi tạo sẵn.
/// Nếu không truyền gì, trả về một instance rỗng.
FakeFirebaseFirestore createFakeFirestore({
  Map<String, Map<String, Map<String, dynamic>>>? initialData,
}) {
  return FakeFirebaseFirestore();
}

// ============================================================
// FIRESTORE SERVICE FACTORY — tạo service test với fake/mock
// ============================================================

/// Tạo [FirestoreService] dùng [FakeFirebaseFirestore] và mock [FirebaseAuth].
FirestoreService createTestFirestoreService({
  FakeFirebaseFirestore? firestore,
  auth.FirebaseAuth? firebaseAuth,
}) {
  return FirestoreService.createTestInstance(
    firestore: firestore ?? createFakeFirestore(),
    firebaseAuth: firebaseAuth ?? MockFirebaseAuth(),
  );
}

/// Helper: setup counter document với giá trị khởi tạo.
Future<void> initCounter(
  FakeFirebaseFirestore fakeFirestore,
  String collection,
  int currentId,
) async {
  await fakeFirestore.collection('counters').doc(collection).set({
    'current_id': currentId,
  });
}

// ============================================================
// FACTORY FUNCTIONS — dữ liệu mẫu cho test
// ============================================================

UserModel createTestUser({
  int id = 1,
  String? uid = 'firebase-uid-1',
  String username = 'testuser',
  String email = 'test@example.com',
  String fullName = 'Test User',
  String role = 'user',
  bool isActive = true,
}) {
  return UserModel(
    id: id,
    uid: uid,
    username: username,
    email: email,
    fullName: fullName,
    phone: '0909123456',
    role: role,
    avatarUrl: null,
    isActive: isActive,
  );
}

Household createTestHousehold({
  int id = 1,
  String householdCode = 'HGD-0001',
  String headOfHousehold = 'Nguyễn Văn A',
  String phone = '0909123456',
  String neighborhood = 'Khu phố 1',
  String ward = 'Phường 1',
  String district = 'Quận 1',
  String city = 'TP. Hồ Chí Minh',
  int createdBy = 1,
}) {
  return Household(
    id: id,
    householdCode: householdCode,
    headOfHousehold: headOfHousehold,
    phone: phone,
    neighborhood: neighborhood,
    ward: ward,
    district: district,
    city: city,
    createdBy: createdBy,
    houseNumber: '123',
    street: 'Đường ABC',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

Incident createTestIncident({
  int id = 1,
  String incidentCode = 'SV-0001',
  String title = 'Test Incident',
  String status = 'received',
  int householdId = 1,
  int createdBy = 1,
}) {
  return Incident(
    id: id,
    incidentCode: incidentCode,
    title: title,
    description: 'Test description',
    status: IncidentStatus.fromString(status),
    householdId: householdId,
    headOfHousehold: 'Nguyễn Văn A',
    phone: '0909123456',
    address: '123 Đường ABC',
    neighborhood: 'Khu phố 1',
    ward: 'Phường 1',
    district: 'Quận 1',
    city: 'TP. Hồ Chí Minh',
    createdBy: createdBy,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

ProvinceModel createTestProvince({
  String name = 'TP. Hồ Chí Minh',
  String code = '79',
  double areaKm2 = 2061,
  int population = 8993000,
}) {
  return ProvinceModel.fromJson({
    'name': name,
    'code': code,
    'type': 'Thành phố',
    'area_km2': areaKm2,
    'population': population,
    'density': population / areaKm2,
    'capital': 'Quận 1',
    'macro_region': 'Đông Nam Bộ',
    'parent_code': null,
    'parent_name': null,
    'geometry': null,
    'geometry_json': null,
    'properties': {'ten': name, 'ma': code, 'type': 'Thành phố'},
  });
}

HighSchool createTestHighSchool({
  String tenTruong = 'THPT Chuyên Lê Hồng Phong',
  String tenXaPhuong = 'Phường 1',
  String tenTinhTp = 'TP. Hồ Chí Minh',
}) {
  return HighSchool.fromJson({
    'ten_truong': tenTruong,
    'ten_xa_phuong': tenXaPhuong,
    'ten_tinh_tp': tenTinhTp,
    'dia_chi': '123 Đường ABC',
    'loai_hinh': 'Công lập',
  });
}

DiaDiemLichSu createTestDiaDiemLichSu({
  int id = 1,
  String ten = 'Địa đạo Củ Chi',
  String loaiDiTich = 'Di tích lịch sử',
}) {
  return DiaDiemLichSu(
    id: id,
    ten: ten,
    loaiDiTich: loaiDiTich,
    diaChi: 'Củ Chi, TP. Hồ Chí Minh',
    kinhDo: 106.6167,
    viDo: 10.9833,
    thoiKy: 'Kháng chiến chống Mỹ',
    moTa: 'Một địa điểm lịch sử nổi tiếng',
    createdAt: DateTime(2025, 1, 1),
  );
}

KhuPhoModel createTestKhuPho({int id = 1, String tenKhuPho = 'Khu phố 1'}) {
  return KhuPhoModel(
    id: id,
    tenKhuPho: tenKhuPho,
    createdAt: DateTime(2025, 1, 1),
  );
}

DaiDienModel createTestDaiDien({
  int? id = 1,
  int khuPhoId = 1,
  String hoTen = 'Nguyễn Văn A',
  String soDienThoai = '0909123456',
}) {
  return DaiDienModel(
    id: id,
    khuPhoId: khuPhoId,
    hoTen: hoTen,
    soDienThoai: soDienThoai,
    email: 'test@example.com',
    createdAt: DateTime(2025, 1, 1),
  );
}

HouseholdRequest createTestHouseholdRequest({
  int id = 1,
  int userId = 1,
  String status = 'pending',
}) {
  return HouseholdRequest(
    id: id,
    userId: userId,
    status: status,
    headOfHousehold: 'Nguyễn Văn A',
    phone: '0909123456',
    houseNumber: '123',
    street: 'Đường ABC',
    neighborhood: 'Khu phố 1',
    ward: 'Phường 1',
    district: 'Quận 1',
    city: 'TP. Hồ Chí Minh',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

// ============================================================
// STORAGE SERVICE FACTORY — tạo service test với mock
// ============================================================

/// Tạo [StorageService] dùng [MockFirebaseStorage].
StorageService createTestStorageService({FirebaseStorage? storage}) {
  return StorageService.createTestInstance(storage ?? MockFirebaseStorage());
}

// ============================================================
// FALLBACK VALUES FOR MOCKTAIL
// ============================================================

/// Đăng ký fallback values cho mocktail. Gọi trong setUpAll().
void registerServiceFallbackValues() {
  registerFallbackValue(createTestUser());
  registerFallbackValue(createTestHousehold());
  registerFallbackValue(createTestIncident());
  registerFallbackValue(createTestProvince());
  registerFallbackValue(createTestHighSchool());
  registerFallbackValue(createTestDiaDiemLichSu());
  registerFallbackValue(createTestKhuPho());
  registerFallbackValue(createTestDaiDien());
  registerFallbackValue(createTestHouseholdRequest());
  registerFallbackValue(IncidentStatus.received);
  registerFallbackValue(MockFirebaseAuth());

  // Mocks for firebase_auth
  registerFallbackValue(MockUserCredential());
  registerFallbackValue(MockUser());

  // Fallback for File (dùng trong Storage upload tests)
  registerFallbackValue(File(''));

  // Mocks for firebase_storage
  registerFallbackValue(MockFirebaseStorage());
  registerFallbackValue(MockReference());
  registerFallbackValue(MockUploadTask());
  registerFallbackValue(MockTaskSnapshot());
  registerFallbackValue(MockListResult());
}
