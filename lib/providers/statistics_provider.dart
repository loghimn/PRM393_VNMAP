import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class StatisticsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  Map<String, int> _incidentsByMonth = {};
  Map<String, int> _incidentsByNeighborhood = {};
  Map<String, int> _incidentsByStatus = {};
  bool _isLoading = false;
  String? _error;
  int _selectedYear = DateTime.now().year;

  Map<String, int> get incidentsByMonth => _incidentsByMonth;
  Map<String, int> get incidentsByNeighborhood => _incidentsByNeighborhood;
  Map<String, int> get incidentsByStatus => _incidentsByStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedYear => _selectedYear;

  void setSelectedYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _db.statisticsIncidentsByMonth(_selectedYear),
        _db.statisticsIncidentsByNeighborhood(),
        _db.statisticsIncidentsByStatus(),
      ]);

      _incidentsByMonth = results[0];
      _incidentsByNeighborhood = results[1];
      _incidentsByStatus = results[2];
    } catch (e) {
      _error = 'Error loading statistics: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadByMonth() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _incidentsByMonth = await _db.statisticsIncidentsByMonth(_selectedYear);
    } catch (e) {
      _error = 'Error loading monthly stats: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadByNeighborhood() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _incidentsByNeighborhood = await _db.statisticsIncidentsByNeighborhood();
    } catch (e) {
      _error = 'Error loading neighborhood stats: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadByStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _incidentsByStatus = await _db.statisticsIncidentsByStatus();
    } catch (e) {
      _error = 'Error loading status stats: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
