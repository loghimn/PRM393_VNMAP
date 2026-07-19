import '../models/province_model.dart';
export 'firestore_service.dart' show SearchResult;
import '../models/high_school_model.dart';
import '../models/household_model.dart';
import '../models/incident_model.dart';
import '../models/dia_diem_lich_su_model.dart';
import '../models/khu_pho_model.dart';
import '../models/dai_dien_model.dart';
import '../models/user_model.dart';
import '../models/household_request_model.dart';
import 'firestore_service.dart';

/// DatabaseService chuyển tiếp toàn bộ sang FirestoreService.
///
/// Các Provider và Screen đều import DatabaseService,
/// nên class này hoạt động như một wrapper,
/// delegate mọi method sang FirestoreService.
/// Không cần sửa bất kỳ file nào khác.
class DatabaseService {
  final FirestoreService _firestore = FirestoreService.instance;

  // ===================================================================
  // PROVINCES / GEOGRAPHY
  // ===================================================================

  Future<List<ProvinceModel>> fetchProvinces() => _firestore.fetchProvinces();

  Future<List<ProvinceModel>> fetchSpecialZones() =>
      _firestore.fetchSpecialZones();

  Future<List<ProvinceModel>> fetchCommunesForProvince(String provinceName) =>
      _firestore.fetchCommunesForProvince(provinceName);

  Future<List<Map<String, dynamic>>> fetchCalculatedDensities() =>
      _firestore.fetchCalculatedDensities();

  Future<List<HighSchool>> fetchHighSchoolsByCommuneName(
    String communeName, {
    String? provinceName,
  }) => _firestore.fetchHighSchoolsByCommuneName(
    communeName,
    provinceName: provinceName,
  );

  Future<List<SearchResult>> searchLocations(String query) =>
      _firestore.searchLocations(query);

  // ===================================================================
  // USERS & AUTH
  // ===================================================================

  Future<UserModel?> login(String phone, String password) =>
      _firestore.login(phone, password);

  Future<UserModel?> getUserByPhone(String phone) =>
      _firestore.getUserByPhone(phone);

  Future<UserModel?> getUserById(int id) => _firestore.getUserById(id);

  Future<UserModel?> getUserByUsername(String username) =>
      _firestore.getUserByUsername(username);

  Future<UserModel> createUser(UserModel user, String password) =>
      _firestore.createUser(user, password);

  Future<UserModel> updateUser(UserModel user) => _firestore.updateUser(user);

  Future<bool> changePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) => _firestore.changePassword(userId, oldPassword, newPassword);

  Future<List<UserModel>> getAllUsers({String? searchQuery}) =>
      _firestore.getAllUsers(searchQuery: searchQuery);

  // ===================================================================
  // ADDRESS DROPDOWN DATA
  // ===================================================================

  Future<List<String>> fetchDistinctNeighborhoods() =>
      _firestore.fetchDistinctNeighborhoods();

  Future<List<String>> fetchDistinctWards() => _firestore.fetchDistinctWards();

  Future<List<String>> fetchCommunesForProvinceName(String provinceName) =>
      _firestore.fetchCommunesForProvinceName(provinceName);

  Future<List<String>> fetchDistinctDistricts() =>
      _firestore.fetchDistinctDistricts();

  Future<List<Map<String, String>>> fetchDistinctCities() =>
      _firestore.fetchDistinctCities();

  Future<List<String>> fetchCommunesForParentCode(String parentCode) =>
      _firestore.fetchCommunesForParentCode(parentCode);

  Future<List<String>> fetchNeighborhoodList() =>
      _firestore.fetchNeighborhoodList();

  // ===================================================================
  // HOUSEHOLD CRUD
  // ===================================================================

  Future<String> generateIncidentCode() => _firestore.generateIncidentCode();

  Future<String> generateHouseholdCode() => _firestore.generateHouseholdCode();

  Future<Household?> fetchHouseholdByPhone(String phone) =>
      _firestore.fetchHouseholdByPhone(phone);

  Future<List<Household>> fetchHouseholdList({
    String? searchQuery,
    String? neighborhood,
    String? ward,
    int? createdBy,
    int limit = 50,
    int offset = 0,
  }) => _firestore.fetchHouseholdList(
    searchQuery: searchQuery,
    neighborhood: neighborhood,
    ward: ward,
    createdBy: createdBy,
    limit: limit,
    offset: offset,
  );

  Future<Household?> fetchHouseholdById(int id) =>
      _firestore.fetchHouseholdById(id);

  Future<Household> createHousehold(Household household) =>
      _firestore.createHousehold(household);

  Future<Household> updateHousehold(Household household) =>
      _firestore.updateHousehold(household);

  Future<void> deleteHousehold(int id) => _firestore.deleteHousehold(id);

  Future<List<Household>> fetchHouseholdsByCommuneName(String communeName) =>
      _firestore.fetchHouseholdsByCommuneName(communeName);

  Future<List<Household>> fetchHouseholdsByWard(String ward) =>
      _firestore.fetchHouseholdsByWard(ward);

  Future<int> countHouseholds({
    String? searchQuery,
    String? neighborhood,
    String? ward,
    int? createdBy,
  }) => _firestore.countHouseholds(
    searchQuery: searchQuery,
    neighborhood: neighborhood,
    ward: ward,
    createdBy: createdBy,
  );

  // ===================================================================
  // INCIDENT CRUD
  // ===================================================================

  Future<List<Incident>> fetchIncidentList({
    String? searchQuery,
    String? status,
    String? neighborhood,
    String? ward,
    int? householdId,
    int? createdBy,
    int limit = 50,
    int offset = 0,
  }) => _firestore.fetchIncidentList(
    searchQuery: searchQuery,
    status: status,
    neighborhood: neighborhood,
    ward: ward,
    householdId: householdId,
    createdBy: createdBy,
    limit: limit,
    offset: offset,
  );

  Future<Incident?> fetchIncidentById(int id) =>
      _firestore.fetchIncidentById(id);

  Future<Incident> createIncident(Incident incident) =>
      _firestore.createIncident(incident);

  Future<Incident> updateIncident(Incident incident) =>
      _firestore.updateIncident(incident);

  Future<void> deleteIncident(int id) => _firestore.deleteIncident(id);

  Future<int> countIncidents({
    String? searchQuery,
    String? status,
    String? neighborhood,
    String? ward,
    int? householdId,
    int? createdBy,
  }) => _firestore.countIncidents(
    searchQuery: searchQuery,
    status: status,
    neighborhood: neighborhood,
    ward: ward,
    householdId: householdId,
    createdBy: createdBy,
  );

  // ===================================================================
  // DIA DIEM LICH SU CRUD
  // ===================================================================

  Future<List<DiaDiemLichSu>> fetchDiaDiemLichSuList({String? searchQuery}) =>
      _firestore.fetchDiaDiemLichSuList(searchQuery: searchQuery);

  Future<DiaDiemLichSu?> fetchDiaDiemLichSuById(int id) =>
      _firestore.fetchDiaDiemLichSuById(id);

  Future<DiaDiemLichSu> createDiaDiemLichSu(DiaDiemLichSu item) =>
      _firestore.createDiaDiemLichSu(item);

  Future<DiaDiemLichSu> updateDiaDiemLichSu(DiaDiemLichSu item) =>
      _firestore.updateDiaDiemLichSu(item);

  Future<void> deleteDiaDiemLichSu(int id) =>
      _firestore.deleteDiaDiemLichSu(id);

  // ===================================================================
  // STATISTICS
  // ===================================================================

  Future<Map<String, int>> statisticsIncidentsByMonth(int year) =>
      _firestore.statisticsIncidentsByMonth(year);

  Future<Map<String, int>> statisticsIncidentsByNeighborhood() =>
      _firestore.statisticsIncidentsByNeighborhood();

  Future<Map<String, int>> statisticsIncidentsByStatus() =>
      _firestore.statisticsIncidentsByStatus();

  // ===================================================================
  // KHU PHO CRUD
  // ===================================================================

  Future<List<KhuPhoModel>> fetchKhuPhos() => _firestore.fetchKhuPhos();

  Future<KhuPhoModel?> fetchKhuPhoById(int id) =>
      _firestore.fetchKhuPhoById(id);

  Future<KhuPhoModel> createKhuPho(KhuPhoModel model) =>
      _firestore.createKhuPho(model);

  Future<KhuPhoModel> updateKhuPho(KhuPhoModel model) =>
      _firestore.updateKhuPho(model);

  Future<void> deleteKhuPho(int id) => _firestore.deleteKhuPho(id);

  // ===================================================================
  // DAI DIEN KHU PHO CRUD
  // ===================================================================

  Future<List<DaiDienModel>> fetchDaiDiens() => _firestore.fetchDaiDiens();

  Future<List<DaiDienModel>> fetchDaiDiensByKhuPho(int khuPhoId) =>
      _firestore.fetchDaiDiensByKhuPho(khuPhoId);

  Future<DaiDienModel?> fetchDaiDienById(int id) =>
      _firestore.fetchDaiDienById(id);

  Future<DaiDienModel> createDaiDien(DaiDienModel model) =>
      _firestore.createDaiDien(model);

  Future<DaiDienModel> updateDaiDien(DaiDienModel model) =>
      _firestore.updateDaiDien(model);

  Future<void> deleteDaiDien(int id) => _firestore.deleteDaiDien(id);

  Future<List<DaiDienModel>> searchDaiDiens(String query) =>
      _firestore.searchDaiDiens(query);

  // ===================================================================
  // HOUSEHOLD REQUESTS CRUD
  // ===================================================================

  Future<HouseholdRequest> createHouseholdRequest(HouseholdRequest request) =>
      _firestore.createHouseholdRequest(request);

  Future<List<HouseholdRequest>> fetchHouseholdRequests({
    String? status,
    int? userId,
  }) => _firestore.fetchHouseholdRequests(status: status, userId: userId);

  Future<HouseholdRequest?> fetchHouseholdRequestById(int id) =>
      _firestore.fetchHouseholdRequestById(id);

  Future<HouseholdRequest> updateHouseholdRequestStatus(
    int id,
    String status, {
    int? approvedBy,
    String? adminNote,
  }) => _firestore.updateHouseholdRequestStatus(
    id,
    status,
    approvedBy: approvedBy,
    adminNote: adminNote,
  );
}
