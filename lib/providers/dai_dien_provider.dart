import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/dai_dien_model.dart';
import '../services/database_service.dart';

class DaiDienProvider extends ChangeNotifier {
  final DatabaseService _service;

  DaiDienProvider({DatabaseService? service})
    : _service = service ?? DatabaseService();
  List<DaiDienModel> _danhSach = [];
  List<DaiDienModel> _ketQuaTimKiem = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  List<DaiDienModel> get danhSach => _danhSach;
  List<DaiDienModel> get ketQuaTimKiem => _ketQuaTimKiem;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _danhSach = await _service.fetchDaiDiens();
    } catch (e) {
      _error = 'Lỗi tải dữ liệu đại diện: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addDaiDien(DaiDienModel model) async {
    try {
      final created = await _service.createDaiDien(model);
      _danhSach.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Lỗi thêm đại diện: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDaiDien(DaiDienModel model) async {
    try {
      final updated = await _service.updateDaiDien(model);
      final index = _danhSach.indexWhere((d) => d.id == updated.id);
      if (index >= 0) {
        _danhSach[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Lỗi cập nhật đại diện: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDaiDien(int id) async {
    try {
      await _service.deleteDaiDien(id);
      _danhSach.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Lỗi xóa đại diện: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _ketQuaTimKiem = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _ketQuaTimKiem = await _service.searchDaiDiens(query);
    } catch (e) {
      _error = 'Lỗi tìm kiếm đại diện: $e';
      print(_error);
      _ketQuaTimKiem = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _ketQuaTimKiem = [];
    _isSearching = false;
    notifyListeners();
  }

  @visibleForTesting
  void setDanhSachForTesting(List<DaiDienModel> danhSach) {
    _danhSach = danhSach;
  }

  DaiDienModel? getById(int id) {
    try {
      return _danhSach.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
