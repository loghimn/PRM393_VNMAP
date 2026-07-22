import 'package:flutter/foundation.dart';
import '../models/incident_model.dart';
import '../services/database_service.dart';

class IncidentProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Incident> _items = [];
  Incident? _selected;
  bool _isLoading = false;
  String? _error;
  int _totalCount = 0;
  String _searchQuery = '';
  String? _filterStatus;
  String? _filterNeighborhood;
  int? _createdByFilter;
  List<String> _neighborhoodList = [];

  List<Incident> get items => _items;
  Incident? get selected => _selected;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _totalCount;
  String get searchQuery => _searchQuery;
  String? get filterStatus => _filterStatus;
  String? get filterNeighborhood => _filterNeighborhood;
  List<String> get neighborhoodList => _neighborhoodList;

  Future<void> loadItems({
    String? searchQuery,
    String? status,
    String? neighborhood,
    int? householdId,
    int? createdBy,
    int limit = 50,
    int offset = 0,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchQuery = searchQuery ?? '';

      // null nghĩa là xem tất cả trạng thái
      _filterStatus = status;

      // null nghĩa là xem tất cả khu phố
      _filterNeighborhood = neighborhood;

      // null nghĩa là admin xem tất cả người tạo
      _createdByFilter = createdBy;

      debugPrint(
        'LOAD INCIDENTS: '
        'createdBy=$_createdByFilter, '
        'status=$_filterStatus, '
        'householdId=$householdId',
      );

      _items = await _db.fetchIncidentList(
        searchQuery: _searchQuery,
        status: _filterStatus,
        neighborhood: _filterNeighborhood,
        householdId: householdId,
        createdBy: _createdByFilter,
        limit: limit,
        offset: offset,
      );

      _totalCount = await _db.countIncidents(
        searchQuery: _searchQuery,
        status: _filterStatus,
        neighborhood: _filterNeighborhood,
        householdId: householdId,
        createdBy: _createdByFilter,
      );
    } catch (e, stackTrace) {
      debugPrint('Lỗi load sự vụ: $e');
      debugPrintStack(stackTrace: stackTrace);

      _error = 'Error loading incidents: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNeighborhoodList() async {
    try {
      _neighborhoodList = await _db.fetchNeighborhoodList();
    } catch (_) {}
  }

  Future<Incident?> loadById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selected = await _db.fetchIncidentById(id);
      return _selected;
    } catch (e) {
      _error = 'Error loading incident info: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create(Incident incident) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.createIncident(incident);
      await loadItems(createdBy: _createdByFilter);
      return true;
    } catch (e) {
      _error = 'Error creating incident: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(Incident incident) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.updateIncident(incident);
      _selected = incident;
      await loadItems(createdBy: _createdByFilter);
      return true;
    } catch (e) {
      _error = 'Error updating incident: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(int id, IncidentStatus status) async {
    final current = _items.firstWhere((s) => s.id == id);
    final updated = Incident(
      id: current.id,
      incidentCode: current.incidentCode,
      title: current.title,
      description: current.description,
      address: current.address,
      neighborhood: current.neighborhood,
      ward: current.ward,
      district: current.district,
      city: current.city,
      longitude: current.longitude,
      latitude: current.latitude,
      householdId: current.householdId,
      headOfHousehold: current.headOfHousehold,
      phone: current.phone,
      status: status,
      handler: current.handler,
      notes: current.notes,
      createdBy: current.createdBy,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
      completedDate: status == IncidentStatus.completed
          ? DateTime.now()
          : current.completedDate,
    );
    return update(updated);
  }

  Future<bool> assignHandler(int id, String handler) async {
    final current = _items.firstWhere((s) => s.id == id);
    final updated = Incident(
      id: current.id,
      incidentCode: current.incidentCode,
      title: current.title,
      description: current.description,
      address: current.address,
      neighborhood: current.neighborhood,
      ward: current.ward,
      district: current.district,
      city: current.city,
      longitude: current.longitude,
      latitude: current.latitude,
      householdId: current.householdId,
      headOfHousehold: current.headOfHousehold,
      phone: current.phone,
      status: current.status,
      handler: handler,
      notes: current.notes,
      createdBy: current.createdBy,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
      completedDate: current.completedDate,
    );
    return update(updated);
  }

  Future<bool> delete(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.deleteIncident(id);
      if (_selected?.id == id) _selected = null;
      await loadItems(createdBy: _createdByFilter);
      return true;
    } catch (e) {
      _error = 'Error deleting incident: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
  }

  void setFilterStatus(String? status) {
    _filterStatus = status;
  }

  void setFilterNeighborhood(String? neighborhood) {
    _filterNeighborhood = neighborhood;
  }

  void clearSelected() {
    _selected = null;
    notifyListeners();
  }

  void reset() {
    _items = [];
    _selected = null;
    _isLoading = false;
    _error = null;
    _totalCount = 0;

    _searchQuery = '';
    _filterStatus = null;
    _filterNeighborhood = null;
    _createdByFilter = null;
    _neighborhoodList = [];

    notifyListeners();
  }
}
