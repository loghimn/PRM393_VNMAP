import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/providers/auth_provider.dart';
import 'package:vietnam_geo_dashboard/providers/household_provider.dart';
import 'package:vietnam_geo_dashboard/providers/incident_provider.dart';
import 'package:vietnam_geo_dashboard/providers/khu_pho_provider.dart';
import 'package:vietnam_geo_dashboard/providers/dai_dien_provider.dart';
import 'package:vietnam_geo_dashboard/providers/dia_diem_lich_su_provider.dart';
import 'package:vietnam_geo_dashboard/providers/theme_provider.dart';
import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/providers/statistics_provider.dart';
import 'package:vietnam_geo_dashboard/providers/notification_provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/providers/household_request_provider.dart';
import 'package:vietnam_geo_dashboard/models/app_notification_model.dart';
import 'package:vietnam_geo_dashboard/models/user_model.dart';
import 'package:vietnam_geo_dashboard/models/household_model.dart';
import 'package:vietnam_geo_dashboard/models/household_request_model.dart';
import 'package:vietnam_geo_dashboard/models/incident_model.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/models/high_school_model.dart';
import 'package:vietnam_geo_dashboard/models/weather_model.dart';
import 'package:vietnam_geo_dashboard/models/khu_pho_model.dart';
import 'package:vietnam_geo_dashboard/models/dai_dien_model.dart';
import 'package:vietnam_geo_dashboard/models/dia_diem_lich_su_model.dart';
import 'package:vietnam_geo_dashboard/services/database_service.dart';

// ============================================================
// MOCKTAIL MOCKS — dùng cho các test cũ dùng when() / verify()
// ============================================================

class MockAuthProvider extends Mock implements AuthProvider {}

class MockHouseholdProvider extends Mock implements HouseholdProvider {}

class MockIncidentProvider extends Mock implements IncidentProvider {}

class MockProvinceProvider extends Mock implements ProvinceProvider {}

class MockKhuPhoProvider extends Mock implements KhuPhoProvider {}

class MockDaiDienProvider extends Mock implements DaiDienProvider {}

class MockDiaDiemLichSuProvider extends Mock implements DiaDiemLichSuProvider {}

class MockNotificationProvider extends Mock implements NotificationProvider {}

class MockWeatherProvider extends Mock implements WeatherProvider {}

class MockThemeProvider extends Mock implements ThemeProvider {}

class MockHouseholdRequestProvider extends Mock
    implements HouseholdRequestProvider {}

// ============================================================
// FAKE PROVIDERS — dùng cho các test mới (điều khiển state trực tiếp)
// - Định nghĩa đầy đủ tất cả getter/method theo interface thật
// ============================================================

// ==================== AUTH ========================

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  UserModel? currentUser;

  @override
  bool isLoading = false;

  @override
  String? error;

  bool? _isLoggedIn;
  @override
  bool get isLoggedIn => _isLoggedIn ?? currentUser != null;
  set isLoggedIn(bool value) => _isLoggedIn = value;

  @override
  bool isInitialized = true;

  bool? _isAdmin;
  @override
  bool get isAdmin => _isAdmin ?? currentUser?.role == 'admin';
  set isAdmin(bool value) => _isAdmin = value;

  bool mockRegisterResult = true;
  bool mockChangePasswordResult = true;
  Future<bool> Function({
    String? fullName,
    String? email,
    String? phone,
    File? avatarFile,
    void Function(double progress)? onUploadProgress,
  })?
  mockUpdateProfile;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> login(String email, String password) async {
    return true;
  }

  @override
  Future<void> logout() async {
    currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  @override
  Future<bool> changePassword(String newPassword) async {
    return mockChangePasswordResult;
  }

  @override
  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? phone,
    File? avatarFile,
    void Function(double progress)? onUploadProgress,
  }) async {
    if (mockUpdateProfile != null) {
      return await mockUpdateProfile!(
        fullName: fullName,
        email: email,
        phone: phone,
        avatarFile: avatarFile,
        onUploadProgress: onUploadProgress,
      );
    }
    return true;
  }

  @override
  Future<bool> register(
    String username,
    String password, {
    required String email,
    String? fullName,
    String? phone,
  }) async {
    return mockRegisterResult;
  }

  @override
  @visibleForTesting
  void setCurrentUserForTesting(UserModel? user) {
    currentUser = user;
    notifyListeners();
  }

  @override
  void clearError() {
    error = null;
    notifyListeners();
  }
}

// ==================== THEME ========================

class FakeThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  bool isDarkMode = false;

  @override
  ThemeData get themeData => isDarkMode ? ThemeData.dark() : ThemeData.light();

  @override
  Color get background => isDarkMode ? Colors.grey[900]! : Colors.white;
  @override
  Color get surface => isDarkMode ? Colors.grey[850]! : Colors.grey[100]!;
  @override
  Color get surfaceBackground =>
      isDarkMode ? Colors.grey[850]! : Colors.grey[100]!;
  @override
  Color get navBackground => isDarkMode ? Colors.grey[850]! : Colors.grey[100]!;
  @override
  Color get panelBackground =>
      isDarkMode ? Colors.grey[850]! : Colors.grey[100]!;
  @override
  Color get textPrimary => isDarkMode ? Colors.white : Colors.black;
  @override
  Color get textSecondary => isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
  @override
  Color get textMuted => isDarkMode ? Colors.grey[500]! : Colors.grey[400]!;
  @override
  Color get border => isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
  @override
  Color get divider => isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
  @override
  Color get mapBackground => isDarkMode ? Colors.grey[900]! : Colors.grey[200]!;
  @override
  Color get searchBg => isDarkMode ? Colors.grey[800]! : Colors.grey[100]!;
  @override
  Color get hoverBg => isDarkMode ? Colors.grey[700]! : Colors.grey[200]!;
  @override
  Color get shadow => isDarkMode ? Colors.black26 : Colors.black12;
  @override
  Color get chipInactive => isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
  @override
  Color get highlightBg => isDarkMode ? Colors.blue[900]! : Colors.blue[50]!;

  @override
  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  @override
  void setThemeMode(bool isDark) {
    isDarkMode = isDark;
    notifyListeners();
  }
}

// ==================== NOTIFICATION ========================

class FakeNotificationProvider extends ChangeNotifier
    implements NotificationProvider {
  @override
  List<AppNotification> notifications = [];

  @override
  bool isLoading = false;

  @override
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  List<AppNotification> get recentNotifications {
    final sorted = List<AppNotification>.from(notifications);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).toList();
  }

  @override
  void initialize(int userId) {}

  @override
  void disposeListener() {
    notifications = [];
    isLoading = false;
    notifyListeners();
  }

  @override
  Future<void> loadNotifications() async {}

  @override
  Future<void> markAsRead(int notificationId) async {}

  @override
  Future<void> markAllAsRead() async {
    // isRead là final, không set được. Tạo list mới với isRead=true
    final updated = notifications
        .map(
          (n) => AppNotification(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            isRead: true,
            targetUserId: n.targetUserId,
            actorUserId: n.actorUserId,
            relatedId: n.relatedId,
            relatedCode: n.relatedCode,
            createdAt: n.createdAt,
            updatedAt: n.updatedAt,
          ),
        )
        .toList();
    notifications = updated;
    notifyListeners();
  }

  @override
  Future<void> deleteNotification(int notificationId) async {
    notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  @override
  void addNotification(AppNotification notification) {
    notifications.insert(0, notification);
    notifyListeners();
  }
}

// ==================== WEATHER ========================

class FakeWeatherProvider extends ChangeNotifier implements WeatherProvider {
  @override
  WeatherModel? nationalWeatherSummary;

  @override
  String nationalTextSummary = '';

  @override
  final Map<String, RegionWeatherSummary> regionalSummaries = {};

  @override
  bool isLoading = false;

  @override
  String? error;

  @override
  WeatherModel? getWeatherForKey(String key) => null;

  @override
  Future<WeatherModel?> fetchWeatherForCoords(double lat, double lon) async {
    return null;
  }

  @override
  Future<void> loadRegionalSummaries(List<ProvinceModel> provinces) async {}

  @override
  Future<void> loadNationalWeatherSummary(
    List<ProvinceModel> provinces,
  ) async {}

  @override
  WeatherModel? getCachedWeatherForProvince(ProvinceModel province) => null;

  @override
  Future<WeatherModel?> fetchWeatherForProvince(ProvinceModel province) async {
    return null;
  }
}

// ==================== HOUSEHOLD ========================

class FakeHouseholdProvider extends ChangeNotifier
    implements HouseholdProvider {
  @override
  List<Household> items = [];

  @override
  Household? selected;

  @override
  bool isLoading = false;

  @override
  String? error;

  @override
  int totalCount = 0;

  @override
  String searchQuery = '';

  @override
  String? filterNeighborhood;

  @override
  bool isLoadingGeo = false;

  @override
  Future<void> loadItems({
    String? searchQuery,
    String? neighborhood,
    int? createdBy,
    int limit = 50,
    int offset = 0,
  }) async {
    if (searchQuery != null) this.searchQuery = searchQuery;
    if (neighborhood != null) filterNeighborhood = neighborhood;
  }

  @override
  Future<Household?> loadById(int id) async => null;

  @override
  Future<bool> create(Household household) async => true;

  @override
  Future<bool> update(Household household) async => true;

  @override
  Future<bool> delete(int id) async => true;

  @override
  void setSearchQuery(String query) {
    searchQuery = query;
  }

  @override
  void setFilterNeighborhood(String? neighborhood) {
    filterNeighborhood = neighborhood;
  }

  @override
  void clearSelected() {
    selected = null;
    notifyListeners();
  }

  Future<Household?> Function(String phone)? mockSearchByPhone;

  @override
  Future<Household?> searchByPhone(String phone) async {
    if (mockSearchByPhone != null) {
      return await mockSearchByPhone!(phone);
    }
    return null;
  }
}

// ==================== HOUSEHOLD REQUEST ========================

class FakeHouseholdRequestProvider extends ChangeNotifier
    implements HouseholdRequestProvider {
  @override
  List<HouseholdRequest> requests = [];

  @override
  bool isLoading = false;

  @override
  String? error;

  @override
  List<HouseholdRequest> get pendingRequests =>
      requests.where((r) => r.status == 'pending').toList();

  @override
  List<HouseholdRequest> get approvedRequests =>
      requests.where((r) => r.status == 'approved').toList();

  @override
  List<HouseholdRequest> get rejectedRequests =>
      requests.where((r) => r.status == 'rejected').toList();

  @override
  Future<void> loadRequests({String? status, int? userId}) async {}

  @override
  Future<bool> approveRequest(
    int requestId, {
    String? adminNote,
    required int approvedBy,
  }) async => true;

  @override
  Future<bool> rejectRequest(
    int requestId, {
    String? adminNote,
    required int approvedBy,
  }) async => true;

  @override
  Future<bool> createRequest(HouseholdRequest request) async => true;

  @override
  Future<List<HouseholdRequest>> fetchAllRequests() async => [];

  @override
  Future<List<HouseholdRequest>> fetchUserRequests(int userId) async => [];

  Future<HouseholdRequest?> Function(int userId)? mockGetUserPendingRequest;

  @override
  Future<HouseholdRequest?> getUserPendingRequest(int userId) async {
    if (mockGetUserPendingRequest != null) {
      return await mockGetUserPendingRequest!(userId);
    }
    return null;
  }

  @override
  void setRequestsForTesting(List<HouseholdRequest> testRequests) {
    requests = testRequests;
    notifyListeners();
  }
}

// ==================== KHU PHO ========================

class FakeKhuPhoProvider extends ChangeNotifier implements KhuPhoProvider {
  @override
  List<KhuPhoModel> danhSach = [];

  @override
  bool isLoading = false;

  @override
  String? error;

  @override
  Future<void> loadData() async {}

  @override
  Future<bool> addKhuPho(KhuPhoModel model) async {
    danhSach.add(model);
    notifyListeners();
    return true;
  }

  @override
  Future<bool> updateKhuPho(KhuPhoModel model) async => true;

  @override
  Future<bool> deleteKhuPho(int id) async {
    danhSach.removeWhere((k) => k.id == id);
    notifyListeners();
    return true;
  }

  @override
  KhuPhoModel? getById(int id) {
    try {
      return danhSach.firstWhere((k) => k.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ==================== DAI DIEN ========================

class FakeDaiDienProvider extends ChangeNotifier implements DaiDienProvider {
  @override
  List<DaiDienModel> danhSach = [];

  @override
  List<DaiDienModel> ketQuaTimKiem = [];

  @override
  bool isLoading = false;

  @override
  bool isSearching = false;

  @override
  String? error;

  @override
  Future<void> loadData() async {}

  @override
  Future<bool> addDaiDien(DaiDienModel model) async {
    danhSach.add(model);
    notifyListeners();
    return true;
  }

  @override
  Future<bool> updateDaiDien(DaiDienModel model) async => true;

  @override
  Future<bool> deleteDaiDien(int id) async {
    danhSach.removeWhere((d) => d.id == id);
    notifyListeners();
    return true;
  }

  @override
  Future<void> search(String query) async {}

  @override
  void clearSearch() {
    ketQuaTimKiem = [];
    isSearching = false;
    notifyListeners();
  }

  @override
  void setDanhSachForTesting(List<DaiDienModel> danhSachTest) {
    danhSach = danhSachTest;
    notifyListeners();
  }

  @override
  DaiDienModel? getById(int id) {
    try {
      return danhSach.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ==================== DIA DIEM LICH SU ========================

class FakeDiaDiemLichSuProvider extends ChangeNotifier
    implements DiaDiemLichSuProvider {
  @override
  List<DiaDiemLichSu> items = [];

  @override
  DiaDiemLichSu? selected;

  @override
  bool isLoading = false;

  @override
  String? error;

  @override
  String searchQuery = '';

  @override
  Future<void> loadItems({String? searchQuery}) async {}

  @override
  Future<DiaDiemLichSu?> loadById(int id) async => selected;

  @override
  Future<bool> create(DiaDiemLichSu item) async {
    items.add(item);
    notifyListeners();
    return true;
  }

  @override
  Future<bool> update(DiaDiemLichSu item) async => true;

  @override
  Future<bool> delete(int id) async {
    items.removeWhere((i) => i.id == id);
    notifyListeners();
    return true;
  }

  @override
  void setItemsForTesting(List<DiaDiemLichSu> testItems) {
    items = testItems;
    notifyListeners();
  }

  @override
  void clearSelected() {
    selected = null;
    notifyListeners();
  }
}

// ==================== INCIDENT ========================

class FakeIncidentProvider extends ChangeNotifier implements IncidentProvider {
  @override
  List<Incident> items = [];

  @override
  Incident? selected;

  @override
  bool isLoading = false;

  @override
  String? error;

  @override
  int totalCount = 0;

  @override
  String searchQuery = '';

  @override
  String? filterStatus;

  @override
  String? filterNeighborhood;

  @override
  List<String> neighborhoodList = [];

  @override
  Future<void> loadItems({
    String? searchQuery,
    String? status,
    String? neighborhood,
    int? householdId,
    int? createdBy,
    int limit = 50,
    int offset = 0,
  }) async {}

  @override
  Future<void> loadNeighborhoodList() async {}

  @override
  Future<Incident?> loadById(int id) async => null;

  @override
  Future<bool> create(Incident incident) async => true;

  @override
  Future<bool> update(Incident incident, {int? updatedBy}) async => true;

  @override
  Future<bool> updateStatus(
    int id,
    IncidentStatus status, {
    int? updatedBy,
  }) async => true;

  @override
  Future<bool> assignHandler(int id, String handler, {int? updatedBy}) async =>
      true;

  @override
  Future<bool> delete(int id, {int? deletedBy}) async => true;

  @override
  void setSearchQuery(String query) {
    searchQuery = query;
  }

  @override
  void setFilterStatus(String? status) {
    filterStatus = status;
  }

  @override
  void setFilterNeighborhood(String? neighborhood) {
    filterNeighborhood = neighborhood;
  }

  @override
  void clearSelected() {
    selected = null;
    notifyListeners();
  }

  @override
  void reset() {
    items = [];
    selected = null;
    isLoading = false;
    error = null;
    totalCount = 0;
    searchQuery = '';
    filterStatus = null;
    filterNeighborhood = null;
    neighborhoodList = [];
    notifyListeners();
  }
}

// ==================== PROVINCE ========================

class FakeProvinceProvider extends ChangeNotifier implements ProvinceProvider {
  @override
  bool isLoading = false;

  @override
  List<ProvinceModel> provinces = [];

  @override
  List<ProvinceModel> specialZones = [];

  @override
  ProvinceModel? selectedProvince;

  @override
  ProvinceModel? selectedCommune;

  @override
  ProvinceModel? focusedProvince;

  @override
  ProvinceModel? hoveredProvince;

  @override
  List<ProvinceModel> focusedCommunes = [];

  @override
  List<ProvinceModel> communes = [];

  @override
  List<Map<String, dynamic>> calculatedDensities = [];

  @override
  bool isCalculatingDensity = false;

  @override
  bool isLoadingHighSchools = false;

  @override
  bool isLoadingHouseholds = false;

  @override
  List<HighSchool> selectedCommuneHighSchools = [];

  @override
  List<Household> selectedCommuneHouseholds = [];

  @override
  Future<void> loadData() async {}

  @override
  Future<void> focusProvince(ProvinceModel province) async {}

  @override
  void selectProvince(ProvinceModel province) {
    selectedProvince = province;
    notifyListeners();
  }

  @override
  void selectCommune(ProvinceModel commune) {
    selectedCommune = commune;
    notifyListeners();
  }

  @override
  void clearFocus() {
    focusedProvince = null;
    focusedCommunes = [];
    notifyListeners();
  }

  @override
  void clearSelection() {
    selectedCommune = null;
    selectedProvince = null;
    notifyListeners();
  }

  @override
  void setHoveredProvince(ProvinceModel? province) {
    hoveredProvince = province;
    notifyListeners();
  }

  @override
  Future<void> calculateCommuneDensities() async {}

  @override
  Future<void> loadHighSchoolsForCommune(
    ProvinceModel commune, {
    String? provinceName,
  }) async {}

  @override
  Future<void> loadHouseholdsForCommune(ProvinceModel commune) async {}

  @override
  Future<List<SearchResult>> searchLocations(String query) async => [];

  @override
  Future<void> selectSearchResult(SearchResult result) async {}
}

// ==================== STATISTICS ========================

class FakeStatisticsProvider extends ChangeNotifier
    implements StatisticsProvider {
  @override
  Map<String, int> incidentsByMonth = {};

  @override
  Map<String, int> incidentsByNeighborhood = {};

  @override
  Map<String, int> incidentsByStatus = {};

  @override
  bool isLoading = false;

  @override
  String? error;

  @override
  int selectedYear = DateTime.now().year;

  @override
  void setSelectedYear(int year) {
    selectedYear = year;
    notifyListeners();
  }

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> loadByMonth() async {}

  @override
  Future<void> loadByNeighborhood() async {}

  @override
  Future<void> loadByStatus() async {}
}
