import 'package:flutter/foundation.dart';
import '../models/dia_diem_lich_su_model.dart';
import '../services/database_service.dart';

class DiaDiemLichSuProvider extends ChangeNotifier {
  final DatabaseService _db;

  DiaDiemLichSuProvider({DatabaseService? db}) : _db = db ?? DatabaseService();

  List<DiaDiemLichSu> _items = [];
  DiaDiemLichSu? _selected;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<DiaDiemLichSu> get items => _items;
  DiaDiemLichSu? get selected => _selected;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> loadItems({String? searchQuery}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchQuery = searchQuery?.trim() ?? '';

      debugPrint('Tìm kiếm địa điểm: "$_searchQuery"');

      final result = await _db.fetchDiaDiemLichSuList(
        searchQuery: _searchQuery,
      );

      debugPrint('Provider nhận được ${result.length} địa điểm');

      _items = result;
    } catch (e, stackTrace) {
      debugPrint('Lỗi tải địa điểm lịch sử: $e');
      debugPrintStack(stackTrace: stackTrace);

      _error = 'Lỗi tải danh sách địa điểm lịch sử: $e';

      // Không giữ lại danh sách cũ gây hiểu nhầm
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DiaDiemLichSu?> loadById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selected = await _db.fetchDiaDiemLichSuById(id);
      return _selected;
    } catch (e) {
      _error = 'Lỗi tải chi tiết địa điểm lịch sử: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create(DiaDiemLichSu item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.createDiaDiemLichSu(item);
      await loadItems(searchQuery: _searchQuery);
      return true;
    } catch (e) {
      _error = 'Lỗi tạo địa điểm lịch sử: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> update(DiaDiemLichSu item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.updateDiaDiemLichSu(item);
      if (_selected?.id == item.id) {
        _selected = item;
      }
      await loadItems(searchQuery: _searchQuery);
      return true;
    } catch (e) {
      _error = 'Lỗi cập nhật địa điểm lịch sử: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> delete(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.deleteDiaDiemLichSu(id);
      if (_selected?.id == id) _selected = null;
      await loadItems(searchQuery: _searchQuery);
      return true;
    } catch (e) {
      _error = 'Lỗi xóa địa điểm lịch sử: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  void setItemsForTesting(List<DiaDiemLichSu> items) {
    _items = items;
  }

  void clearSelected() {
    _selected = null;
    notifyListeners();
  }
}
