import 'package:flutter/material.dart';
import '../models/khu_pho_model.dart';
import '../services/database_service.dart';

class KhuPhoProvider extends ChangeNotifier {
  final DatabaseService _service;

  KhuPhoProvider({DatabaseService? databaseService})
    : _service = databaseService ?? DatabaseService();
  List<KhuPhoModel> _danhSach = [];
  bool _isLoading = false;
  String? _error;

  List<KhuPhoModel> get danhSach => _danhSach;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _danhSach = await _service.fetchKhuPhos();
    } catch (e) {
      _error = 'Lỗi tải dữ liệu khu phố: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addKhuPho(KhuPhoModel model) async {
    try {
      final created = await _service.createKhuPho(model);
      _danhSach.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Lỗi thêm khu phố: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateKhuPho(KhuPhoModel model) async {
    try {
      final updated = await _service.updateKhuPho(model);
      final index = _danhSach.indexWhere((k) => k.id == updated.id);
      if (index >= 0) {
        _danhSach[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Lỗi cập nhật khu phố: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteKhuPho(int id) async {
    try {
      await _service.deleteKhuPho(id);
      _danhSach.removeWhere((k) => k.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Lỗi xóa khu phố: $e';
      notifyListeners();
      return false;
    }
  }

  KhuPhoModel? getById(int id) {
    try {
      return _danhSach.firstWhere((k) => k.id == id);
    } catch (_) {
      return null;
    }
  }
}
