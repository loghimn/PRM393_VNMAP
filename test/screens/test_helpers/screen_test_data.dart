import 'package:vietnam_geo_dashboard/models/household_model.dart';
import 'package:vietnam_geo_dashboard/models/incident_model.dart';
import 'package:vietnam_geo_dashboard/models/user_model.dart';
import 'package:vietnam_geo_dashboard/models/household_request_model.dart';
import 'package:vietnam_geo_dashboard/models/khu_pho_model.dart';
import 'package:vietnam_geo_dashboard/models/dai_dien_model.dart';
import 'package:vietnam_geo_dashboard/models/dia_diem_lich_su_model.dart';

// ============================================================
// SAMPLE DATA - dùng chung cho tất cả screen tests
// ============================================================

final _now = DateTime.now();
final _baseDate = DateTime(2024, 1, 1);

/// Public reference for tests that need the base date.
final DateTime baseDate = _baseDate;

// --- User ---
final testUser = UserModel(
  id: 1,
  uid: 'firebase-uid-123',
  username: 'testuser',
  email: 'test@example.com',
  fullName: 'Test User',
  phone: '0909123456',
  role: 'user',
  avatarUrl: 'https://example.com/avatar.png',
  isActive: true,
);

final adminUser = UserModel(
  id: 2,
  uid: 'firebase-uid-admin',
  username: 'admin',
  email: 'admin@example.com',
  fullName: 'Admin User',
  phone: '0909123457',
  role: 'admin',
  avatarUrl: 'https://example.com/admin-avatar.png',
  isActive: true,
);

// --- Household ---
final testHousehold = Household(
  id: 1,
  householdCode: 'HH001',
  headOfHousehold: 'Nguyễn Văn A',
  houseNumber: '123',
  street: 'Đường Lê Lợi',
  neighborhood: 'P.Bến Thành',
  ward: 'Q.1',
  city: 'TP.HCM',
  phone: '0909123456',
  email: 'nguyenvana@example.com',
  population: 4,
  notes: 'Hộ gia đình mẫu',
  longitude: 106.6297,
  latitude: 10.8231,
  createdBy: 1,
  createdAt: _baseDate,
  updatedAt: _baseDate,
);

final householdList = [
  testHousehold,
  Household(
    id: 2,
    householdCode: 'HH002',
    headOfHousehold: 'Trần Thị B',
    houseNumber: '456',
    street: 'Đường Nguyễn Huệ',
    neighborhood: 'P.Bến Nghé',
    ward: 'Q.1',
    city: 'TP.HCM',
    phone: '0909123457',
    population: 3,
    longitude: 106.7042,
    latitude: 10.7756,
    createdBy: 1,
    createdAt: _baseDate.add(const Duration(days: 1)),
    updatedAt: _baseDate.add(const Duration(days: 1)),
  ),
];

// --- Incident ---
final testIncident = Incident(
  id: 1,
  incidentCode: 'INC001',
  title: 'Hỏa hoạn tại khu dân cư',
  description: 'Cháy nhà tại khu dân cư',
  address: '123 Đường Lê Lợi',
  neighborhood: 'P.Bến Thành',
  ward: 'Q.1',
  city: 'TP.HCM',
  longitude: 106.6297,
  latitude: 10.8231,
  householdId: 1,
  headOfHousehold: 'Nguyễn Văn A',
  phone: '0909123456',
  status: IncidentStatus.completed,
  createdAt: _baseDate.add(const Duration(days: 15)),
  updatedAt: _baseDate.add(const Duration(days: 16)),
);

final incidentList = [
  testIncident,
  Incident(
    id: 2,
    incidentCode: 'INC002',
    title: 'Ngập lụt sau mưa lớn',
    description: 'Ngập đường sau mưa lớn',
    address: '456 Đường Nguyễn Huệ',
    neighborhood: 'P.Bến Nghé',
    ward: 'Q.1',
    city: 'TP.HCM',
    longitude: 106.7042,
    latitude: 10.7756,
    householdId: 2,
    headOfHousehold: 'Trần Thị B',
    phone: '0909123457',
    status: IncidentStatus.processing,
    createdAt: _baseDate.add(const Duration(days: 32)),
    updatedAt: _baseDate.add(const Duration(days: 32)),
    imageUrls: ['https://example.com/flood.jpg'],
  ),
];

// --- HouseholdRequest ---
final testRequest = HouseholdRequest(
  id: 1,
  userId: 1,
  headOfHousehold: 'Nguyễn Văn A',
  phone: '0909123456',
  houseNumber: '123',
  street: 'Đường Lê Lợi',
  neighborhood: 'P.Bến Thành',
  ward: 'Q.1',
  city: 'TP.HCM',
  population: 4,
  email: 'nguyenvana@example.com',
  status: 'pending',
  notes: 'Thay đổi thông tin: Cập nhật số điện thoại mới',
  createdAt: _baseDate.add(const Duration(days: 60)),
  updatedAt: _baseDate.add(const Duration(days: 60)),
);

final requestList = [
  testRequest,
  HouseholdRequest(
    id: 2,
    userId: 2,
    headOfHousehold: 'Trần Thị B',
    phone: '0909123457',
    houseNumber: '456',
    street: 'Đường Nguyễn Huệ',
    neighborhood: 'P.Bến Nghé',
    ward: 'Q.1',
    city: 'TP.HCM',
    population: 3,
    status: 'approved',
    adminNote: 'Đã duyệt hồ sơ',
    createdAt: _baseDate.add(const Duration(days: 69)),
    updatedAt: _baseDate.add(const Duration(days: 70)),
  ),
];

// --- KhuPhoModel ---
final testKhuPho = KhuPhoModel(
  id: 1,
  tenKhuPho: 'Khu phố 1',
  moTa: 'Khu vực trung tâm',
  diaChi: 'Q.1',
  createdAt: _baseDate,
  updatedAt: _baseDate,
);

final khuPhoList = [
  testKhuPho,
  KhuPhoModel(
    id: 2,
    tenKhuPho: 'Khu phố 2',
    moTa: 'Khu vực ngoại ô',
    diaChi: 'Q.2',
    createdAt: _baseDate,
    updatedAt: _baseDate,
  ),
];

// --- DaiDienModel ---
final testDaiDien = DaiDienModel(
  id: 1,
  hoTen: 'Nguyễn Văn C',
  soDienThoai: '0912345678',
  email: 'c.nguyen@example.com',
  diaChi: '123 Đường Lê Lợi, Q.1',
  khuPhoId: 1,
  tenKhuPho: 'Khu phố 1',
  createdAt: _baseDate,
  updatedAt: _baseDate,
);

// --- DiaDiemLichSu ---
final testDiaDiemLichSu = DiaDiemLichSu(
  id: 1,
  ten: 'Chợ Bến Thành',
  moTa: 'Biểu tượng của Sài Gòn',
  diaChi: 'P.Bến Thành, Q.1, TP.HCM',
  kinhDo: 106.6983,
  viDo: 10.7724,
  loaiDiTich: 'Chợ',
  ghiChu: null,
  imageUrl: 'https://example.com/cho-benh-thanh.jpg',
  createdAt: _baseDate,
);
