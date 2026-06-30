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
    int limit = 50,
    int offset = 0,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (searchQuery != null) _searchQuery = searchQuery;
      if (status != null) _filterStatus = status;
      if (neighborhood != null) _filterNeighborhood = neighborhood;

      _items = await _db.fetchIncidentList(
        searchQuery: _searchQuery,
        status: _filterStatus,
        neighborhood: _filterNeighborhood,
        householdId: householdId,
        limit: limit,
        offset: offset,
      );
      _totalCount = await _db.countIncidents(
        searchQuery: _searchQuery,
        status: _filterStatus,
        neighborhood: _filterNeighborhood,
        householdId: householdId,
      );
    } catch (e) {
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
      await loadItems();
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
      await loadItems();
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
      await loadItems();
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
}
