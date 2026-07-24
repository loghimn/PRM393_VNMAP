import 'package:vietnam_geo_dashboard/models/user_model.dart';
import 'package:vietnam_geo_dashboard/models/household_model.dart';
import 'package:vietnam_geo_dashboard/models/incident_model.dart';
import 'package:vietnam_geo_dashboard/models/dia_diem_lich_su_model.dart';
import 'package:vietnam_geo_dashboard/models/khu_pho_model.dart';
import 'package:vietnam_geo_dashboard/models/dai_dien_model.dart';
import 'package:vietnam_geo_dashboard/models/household_request_model.dart';
import 'package:vietnam_geo_dashboard/services/database_service.dart';
import 'package:vietnam_geo_dashboard/services/firestore_service.dart';
import 'package:mocktail/mocktail.dart';

/// [FakeDatabaseService] mở rộng [DatabaseService] để inject vào screen test
/// mà không cần Firebase.
///
/// Dùng mocktail's [Fake] làm FirestoreService để tránh lỗi thiếu implementation.
class FakeDatabaseService extends DatabaseService {
  FakeDatabaseService() : super.withService(_FakeFirestoreService());

  // ===================================================================
  // General settings
  // ===================================================================

  /// Simulate async delay. Set to [Duration.zero] (default) for fast tests,
  /// or a longer duration if you need to observe intermediate loading state.
  Duration asyncDelay = Duration.zero;

  // ===================================================================
  // USERS
  // ===================================================================

  /// Mock data cho getAllUsers
  List<UserModel> mockUsers = [];

  /// Mock error cho getAllUsers
  Exception? mockGetAllUsersError;

  /// Mock error cho updateUser
  Exception? mockUpdateUserError;

  @override
  Future<List<UserModel>> getAllUsers({String? searchQuery}) async {
    await Future<void>.delayed(asyncDelay);
    if (mockGetAllUsersError != null) throw mockGetAllUsersError!;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      return mockUsers
          .where(
            (u) =>
                u.username.contains(searchQuery) ||
                (u.email?.contains(searchQuery) ?? false),
          )
          .toList();
    }
    return mockUsers;
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    await Future<void>.delayed(asyncDelay);
    if (mockUpdateUserError != null) throw mockUpdateUserError!;
    final index = mockUsers.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      mockUsers[index] = user;
    }
    return user;
  }

  // ===================================================================
  // ADDRESS DROPDOWN DATA
  // ===================================================================

  /// Mock data cho fetchDistinctNeighborhoods
  List<String> mockNeighborhoods = [];

  /// Mock data cho fetchDistinctWards
  List<String> mockWards = [];

  /// Mock data cho fetchDistinctDistricts
  List<String> mockDistricts = [];

  /// Mock data cho fetchDistinctCities — list of {name, code}
  List<Map<String, String>> mockCities = [];

  /// Mock data cho fetchCommunesForParentCode
  List<String> mockCommunes = [];

  /// Mock data cho fetchNeighborhoodList
  List<String> mockNeighborhoodList = [];

  @override
  Future<List<String>> fetchDistinctNeighborhoods() async {
    await Future<void>.delayed(asyncDelay);
    return mockNeighborhoods;
  }

  @override
  Future<List<String>> fetchDistinctWards() async {
    await Future<void>.delayed(asyncDelay);
    return mockWards;
  }

  @override
  Future<List<String>> fetchDistinctDistricts() async {
    await Future<void>.delayed(asyncDelay);
    return mockDistricts;
  }

  @override
  Future<List<Map<String, String>>> fetchDistinctCities() async {
    await Future<void>.delayed(asyncDelay);
    return mockCities;
  }

  @override
  Future<List<String>> fetchCommunesForParentCode(String parentCode) async {
    await Future<void>.delayed(asyncDelay);
    return mockCommunes;
  }

  @override
  Future<List<String>> fetchNeighborhoodList() async {
    await Future<void>.delayed(asyncDelay);
    return mockNeighborhoodList;
  }

  // ===================================================================
  // HOUSEHOLD CRUD
  // ===================================================================

  /// Mock data cho fetchHouseholdList
  List<Household> mockHouseholds = [];

  /// Mock error cho fetchHouseholdList
  Exception? mockFetchHouseholdListError;

  /// Mock data cho fetchHouseholdById
  Household? mockHouseholdById;

  /// Mock result cho createHousehold
  Household? mockCreatedHousehold;

  /// Mock result cho updateHousehold
  Household? mockUpdatedHousehold;

  /// Mock error cho deleteHousehold
  Exception? mockDeleteHouseholdError;

  /// Mock result cho generateHouseholdCode
  String mockHouseholdCode = 'HH-TEST-001';

  /// Mock data cho fetchHouseholdByPhone
  Household? mockHouseholdByPhone;

  @override
  Future<List<Household>> fetchHouseholdList({
    String? searchQuery,
    String? neighborhood,
    String? ward,
    int? createdBy,
    int limit = 50,
    int offset = 0,
  }) async {
    await Future<void>.delayed(asyncDelay);
    if (mockFetchHouseholdListError != null) throw mockFetchHouseholdListError!;
    return mockHouseholds;
  }

  @override
  Future<Household?> fetchHouseholdById(int id) async {
    await Future<void>.delayed(asyncDelay);
    return mockHouseholdById;
  }

  @override
  Future<Household> createHousehold(Household household) async {
    await Future<void>.delayed(asyncDelay);
    return mockCreatedHousehold ?? household;
  }

  @override
  Future<Household> updateHousehold(Household household) async {
    await Future<void>.delayed(asyncDelay);
    return mockUpdatedHousehold ?? household;
  }

  @override
  Future<void> deleteHousehold(int id) async {
    await Future<void>.delayed(asyncDelay);
    if (mockDeleteHouseholdError != null) throw mockDeleteHouseholdError!;
  }

  @override
  Future<String> generateHouseholdCode() async {
    await Future<void>.delayed(asyncDelay);
    return mockHouseholdCode;
  }

  @override
  Future<Household?> fetchHouseholdByPhone(String phone) async {
    await Future<void>.delayed(asyncDelay);
    return mockHouseholdByPhone;
  }

  @override
  Future<int> countHouseholds({
    String? searchQuery,
    String? neighborhood,
    String? ward,
    int? createdBy,
  }) async {
    await Future<void>.delayed(asyncDelay);
    return mockHouseholds.length;
  }

  @override
  Future<List<Household>> fetchHouseholdsByCommuneName(
    String communeName,
  ) async {
    await Future<void>.delayed(asyncDelay);
    return mockHouseholds;
  }

  @override
  Future<List<Household>> fetchHouseholdsByWard(String ward) async {
    await Future<void>.delayed(asyncDelay);
    return mockHouseholds;
  }

  // ===================================================================
  // INCIDENT CRUD
  // ===================================================================

  /// Mock data cho fetchIncidentList
  List<Incident> mockIncidents = [];

  /// Mock error cho fetchIncidentList
  Exception? mockFetchIncidentListError;

  /// Mock data cho fetchIncidentById
  Incident? mockIncidentById;

  /// Mock result cho createIncident
  Incident? mockCreatedIncident;

  /// Mock result cho updateIncident
  Incident? mockUpdatedIncident;

  /// Mock error cho deleteIncident
  Exception? mockDeleteIncidentError;

  /// Mock result cho generateIncidentCode
  String mockIncidentCode = 'INC-TEST-001';

  @override
  Future<List<Incident>> fetchIncidentList({
    String? searchQuery,
    String? status,
    String? neighborhood,
    String? ward,
    int? householdId,
    int? createdBy,
    int limit = 50,
    int offset = 0,
  }) async {
    await Future<void>.delayed(asyncDelay);
    if (mockFetchIncidentListError != null) throw mockFetchIncidentListError!;
    return mockIncidents;
  }

  @override
  Future<Incident?> fetchIncidentById(int id) async {
    await Future<void>.delayed(asyncDelay);
    return mockIncidentById;
  }

  @override
  Future<Incident> createIncident(Incident incident) async {
    await Future<void>.delayed(asyncDelay);
    return mockCreatedIncident ?? incident;
  }

  @override
  Future<Incident> updateIncident(Incident incident, {int? updatedBy}) async {
    await Future<void>.delayed(asyncDelay);
    return mockUpdatedIncident ?? incident;
  }

  @override
  Future<void> deleteIncident(int id, {int? deletedBy}) async {
    await Future<void>.delayed(asyncDelay);
    if (mockDeleteIncidentError != null) throw mockDeleteIncidentError!;
  }

  @override
  Future<String> generateIncidentCode() async {
    await Future<void>.delayed(asyncDelay);
    return mockIncidentCode;
  }

  @override
  Future<int> countIncidents({
    String? searchQuery,
    String? status,
    String? neighborhood,
    String? ward,
    int? householdId,
    int? createdBy,
  }) async {
    await Future<void>.delayed(asyncDelay);
    return mockIncidents.length;
  }

  // ===================================================================
  // DIA DIEM LICH SU CRUD
  // ===================================================================

  /// Mock data cho fetchDiaDiemLichSuList
  List<DiaDiemLichSu> mockDiaDiemLichSuList = [];

  /// Mock data cho fetchDiaDiemLichSuById
  DiaDiemLichSu? mockDiaDiemLichSuById;

  @override
  Future<List<DiaDiemLichSu>> fetchDiaDiemLichSuList({
    String? searchQuery,
  }) async {
    await Future<void>.delayed(asyncDelay);
    return mockDiaDiemLichSuList;
  }

  @override
  Future<DiaDiemLichSu?> fetchDiaDiemLichSuById(int id) async {
    await Future<void>.delayed(asyncDelay);
    return mockDiaDiemLichSuById;
  }

  @override
  Future<DiaDiemLichSu> createDiaDiemLichSu(DiaDiemLichSu item) async {
    await Future<void>.delayed(asyncDelay);
    return item;
  }

  @override
  Future<DiaDiemLichSu> updateDiaDiemLichSu(DiaDiemLichSu item) async {
    await Future<void>.delayed(asyncDelay);
    return item;
  }

  @override
  Future<void> deleteDiaDiemLichSu(int id) async {
    await Future<void>.delayed(asyncDelay);
  }

  // ===================================================================
  // KHU PHO CRUD
  // ===================================================================

  /// Mock data cho fetchKhuPhos
  List<KhuPhoModel> mockKhuPhos = [];

  /// Mock data cho fetchKhuPhoById
  KhuPhoModel? mockKhuPhoById;

  @override
  Future<List<KhuPhoModel>> fetchKhuPhos() async {
    await Future<void>.delayed(asyncDelay);
    return mockKhuPhos;
  }

  @override
  Future<KhuPhoModel?> fetchKhuPhoById(int id) async {
    await Future<void>.delayed(asyncDelay);
    return mockKhuPhoById;
  }

  @override
  Future<KhuPhoModel> createKhuPho(KhuPhoModel model) async {
    await Future<void>.delayed(asyncDelay);
    return model;
  }

  @override
  Future<KhuPhoModel> updateKhuPho(KhuPhoModel model) async {
    await Future<void>.delayed(asyncDelay);
    return model;
  }

  @override
  Future<void> deleteKhuPho(int id) async {
    await Future<void>.delayed(asyncDelay);
  }

  // ===================================================================
  // DAI DIEN KHU PHO CRUD
  // ===================================================================

  /// Mock data cho fetchDaiDiens
  List<DaiDienModel> mockDaiDiens = [];

  /// Mock data cho fetchDaiDiensByKhuPho
  List<DaiDienModel> mockDaiDiensByKhuPho = [];

  /// Mock data cho fetchDaiDienById
  DaiDienModel? mockDaiDienById;

  @override
  Future<List<DaiDienModel>> fetchDaiDiens() async {
    await Future<void>.delayed(asyncDelay);
    return mockDaiDiens;
  }

  @override
  Future<List<DaiDienModel>> fetchDaiDiensByKhuPho(int khuPhoId) async {
    await Future<void>.delayed(asyncDelay);
    return mockDaiDiensByKhuPho;
  }

  @override
  Future<DaiDienModel?> fetchDaiDienById(int id) async {
    await Future<void>.delayed(asyncDelay);
    return mockDaiDienById;
  }

  @override
  Future<DaiDienModel> createDaiDien(DaiDienModel model) async {
    await Future<void>.delayed(asyncDelay);
    return model;
  }

  @override
  Future<DaiDienModel> updateDaiDien(DaiDienModel model) async {
    await Future<void>.delayed(asyncDelay);
    return model;
  }

  @override
  Future<void> deleteDaiDien(int id) async {
    await Future<void>.delayed(asyncDelay);
  }

  @override
  Future<List<DaiDienModel>> searchDaiDiens(String query) async {
    await Future<void>.delayed(asyncDelay);
    return mockDaiDiens;
  }

  // ===================================================================
  // HOUSEHOLD REQUESTS CRUD
  // ===================================================================

  /// Mock data cho fetchHouseholdRequests
  List<HouseholdRequest> mockHouseholdRequests = [];

  /// Mock data cho fetchHouseholdRequestById
  HouseholdRequest? mockHouseholdRequestById;

  @override
  Future<HouseholdRequest> createHouseholdRequest(
    HouseholdRequest request,
  ) async {
    await Future<void>.delayed(asyncDelay);
    return request;
  }

  @override
  Future<List<HouseholdRequest>> fetchHouseholdRequests({
    String? status,
    int? userId,
  }) async {
    await Future<void>.delayed(asyncDelay);
    if (status != null) {
      return mockHouseholdRequests.where((r) => r.status == status).toList();
    }
    if (userId != null) {
      return mockHouseholdRequests.where((r) => r.userId == userId).toList();
    }
    return mockHouseholdRequests;
  }

  @override
  Future<HouseholdRequest?> fetchHouseholdRequestById(int id) async {
    await Future<void>.delayed(asyncDelay);
    return mockHouseholdRequestById;
  }

  @override
  Future<HouseholdRequest> updateHouseholdRequestStatus(
    int id,
    String status, {
    int? approvedBy,
    String? adminNote,
  }) async {
    await Future<void>.delayed(asyncDelay);
    return mockHouseholdRequestById ??
        HouseholdRequest(
          id: id,
          userId: 1,
          headOfHousehold: 'Test',
          phone: '0909123456',
          houseNumber: '123',
          street: 'Test',
          neighborhood: 'Test',
          ward: 'Test',
          city: 'Test',
          population: 1,
          status: status,
          adminNote: adminNote,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
  }

  // ===================================================================
  // STATISTICS
  // ===================================================================

  /// Mock data cho statistics
  Map<String, int> mockStatisticsByMonth = {};
  Map<String, int> mockStatisticsByNeighborhood = {};
  Map<String, int> mockStatisticsByStatus = {};

  @override
  Future<Map<String, int>> statisticsIncidentsByMonth(int year) async {
    await Future<void>.delayed(asyncDelay);
    return mockStatisticsByMonth;
  }

  @override
  Future<Map<String, int>> statisticsIncidentsByNeighborhood() async {
    await Future<void>.delayed(asyncDelay);
    return mockStatisticsByNeighborhood;
  }

  @override
  Future<Map<String, int>> statisticsIncidentsByStatus() async {
    await Future<void>.delayed(asyncDelay);
    return mockStatisticsByStatus;
  }

  // ===================================================================
  // NOTIFICATION
  // ===================================================================

  @override
  Future<void> addNotification({
    required String type,
    required String title,
    required String body,
    int? targetUserId,
    int? actorUserId,
    int? relatedId,
    String? relatedCode,
  }) async {
    await Future<void>.delayed(asyncDelay);
  }

  @override
  Future<List<int>> fetchAdminUserIds() async {
    await Future<void>.delayed(asyncDelay);
    return [1, 2];
  }

  // ===================================================================
  // PROVINCES / GEOGRAPHY
  // ===================================================================

  @override
  Future<List<String>> fetchCommunesForProvinceName(String provinceName) async {
    await Future<void>.delayed(asyncDelay);
    return mockCommunes;
  }
}

/// FirestoreService fake tối giản dùng mocktail's Fake.
/// Fake đã override noSuchMethod nên không cần implement toàn bộ method.
class _FakeFirestoreService extends Fake implements FirestoreService {}
