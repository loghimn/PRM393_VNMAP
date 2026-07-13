import 'package:flutter/foundation.dart';
import '../models/household_model.dart';
import '../services/database_service.dart';

class HouseholdProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Household> _items = [];
  Household? _selected;
  bool _isLoading = false;
  String? _error;
  int _totalCount = 0;
  String _searchQuery = '';
  String? _filterNeighborhood;
  int? _createdByFilter;

  List<Household> get items => _items;
  Household? get selected => _selected;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _totalCount;
  String get searchQuery => _searchQuery;
  String? get filterNeighborhood => _filterNeighborhood;

  Future<void> loadItems({
    String? searchQuery,
    String? neighborhood,
    int? createdBy,
    int limit = 50,
    int offset = 0,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (searchQuery != null) _searchQuery = searchQuery;
      if (neighborhood != null) _filterNeighborhood = neighborhood;
      _createdByFilter = createdBy;

      _items = await _db.fetchHouseholdList(
        searchQuery: _searchQuery,
        neighborhood: _filterNeighborhood,
        ward: null,
        createdBy: _createdByFilter,
        limit: limit,
        offset: offset,
      );
      _totalCount = await _db.countHouseholds(
        searchQuery: _searchQuery,
        neighborhood: _filterNeighborhood,
        ward: null,
        createdBy: _createdByFilter,
      );
    } catch (e) {
      _error = 'Error loading households: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Household?> loadById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selected = await _db.fetchHouseholdById(id);
      return _selected;
    } catch (e) {
      _error = 'Error loading household info: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create(Household household) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.createHousehold(household);
      await loadItems(createdBy: _createdByFilter);
      return true;
    } catch (e) {
      _error = 'Error creating household: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(Household household) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.updateHousehold(household);
      _selected = household;
      await loadItems(createdBy: _createdByFilter);
      return true;
    } catch (e) {
      _error = 'Error updating household: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.deleteHousehold(id);
      if (_selected?.id == id) _selected = null;
      await loadItems(createdBy: _createdByFilter);
      return true;
    } catch (e) {
      _error = 'Error deleting household: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
  }

  void setFilterNeighborhood(String? neighborhood) {
    _filterNeighborhood = neighborhood;
  }

  void clearSelected() {
    _selected = null;
    notifyListeners();
  }

  /// Tìm kiếm hộ gia đình theo số điện thoại
  Future<Household?> searchByPhone(String phone) async {
    try {
      final results = await _db.fetchHouseholdList(
        searchQuery: phone,
        createdBy: _createdByFilter,
        limit: 10,
      );
      if (results.isNotEmpty) {
        return results.firstWhere(
          (h) => h.phone == phone,
          orElse: () => results.first,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
