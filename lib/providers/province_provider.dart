import 'package:flutter/material.dart';

import '../models/province_model.dart';
import '../services/database_service.dart';

class ProvinceProvider extends ChangeNotifier {
  final DatabaseService _service = DatabaseService();
  ProvinceModel? hoveredProvince;
  List<ProvinceModel> communes = [];
  ProvinceModel? focusedProvince;

  bool isCalculatingDensity = false;
  List<Map<String, dynamic>> calculatedDensities = [];

  Future<void> calculateCommuneDensities() async {
    if (calculatedDensities.isNotEmpty) return;
    isCalculatingDensity = true;
    notifyListeners();

    try {
      calculatedDensities = await _service.fetchCalculatedDensities();
    } catch (e) {
      print("Error calculating commune densities: $e");
    } finally {
      isCalculatingDensity = false;
      notifyListeners();
    }
  }

  final Map<String, List<ProvinceModel>> _provinceCommunesCache = {};
  List<ProvinceModel> focusedCommunes = [];

  ProvinceModel? selectedCommune;

  void setHoveredProvince(ProvinceModel? province) {
    hoveredProvince = province;
    notifyListeners();
  }

  List<ProvinceModel> provinces = [];
  List<ProvinceModel> specialZones = [];
  ProvinceModel? selectedProvince;

  Future<void> loadData() async {
    provinces = await _service.fetchProvinces();
    specialZones = await _service.fetchSpecialZones();
    notifyListeners();
  }

  Future<void> focusProvince(ProvinceModel province) async {
    selectedProvince = province;
    final String cacheKey = province.name;

    // Load communes first (from cache or network) before updating UI
    if (!_provinceCommunesCache.containsKey(cacheKey)) {
      print('Loading communes for province: ${province.name}...');
      try {
        final loaded = await _service.fetchCommunesForProvince(province.name);
        _provinceCommunesCache[cacheKey] = loaded;
        print('Loaded ${loaded.length} communes for province: ${province.name}');
      } catch (e) {
        print('Error loading communes for ${province.name}: $e');
        _provinceCommunesCache[cacheKey] = [];
      }
    }

    // Set focusedProvince and focusedCommunes atomically so the painter
    // always sees them in sync (prevents drawing focused mode with empty communes)
    focusedProvince = province;
    focusedCommunes = _provinceCommunesCache[cacheKey]!;

    print('Focus province: ${province.name}');
    print('Focused communes count: ${focusedCommunes.length}');
    if (focusedCommunes.isNotEmpty) {
      print('First commune: ${focusedCommunes.first.name}');

      // Debug: Check first 5 communes
      print('First 5 communes:');
      for (int i = 0; i < focusedCommunes.take(5).length; i++) {
        final c = focusedCommunes[i];
        print(
          // ignore: unnecessary_null_comparison
          '  ${i + 1}. ${c.name} - type: ${c.properties['type']}, has geometry: ${c.geometry != null}',
        );
      }
    }

    notifyListeners();
  }

  void selectProvince(ProvinceModel province) {
    print("SELECT PROVINCE: ${province.name}");
    selectedProvince = province;
    selectedCommune = null;
    notifyListeners();
  }

  void selectCommune(ProvinceModel commune) {
    print("SELECT COMMUNE: ${commune.name}");
    selectedCommune = commune;
    selectedProvince = null;
    notifyListeners();
  }

  void clearFocus() {
    focusedProvince = null;
    focusedCommunes = [];
    notifyListeners();
  }

  void clearSelection() {
    selectedCommune = null;
    selectedProvince = null;
    notifyListeners();
  }

  Future<List<SearchResult>> searchLocations(String query) async {
    return await _service.searchLocations(query);
  }

  Future<void> selectSearchResult(SearchResult result) async {
    if (result.type == 'province' || result.type == 'special_zone') {
      clearFocus();
      selectProvince(result.model);
    } else if (result.type == 'commune') {
      final ProvinceModel commune = result.model;
      final parentName = commune.parentTen;
      if (parentName != null) {
        try {
          final parentProvince = provinces.firstWhere(
            (p) => p.name.trim().toLowerCase() == parentName.trim().toLowerCase(),
            orElse: () => specialZones.firstWhere(
              (z) => z.name.trim().toLowerCase() == parentName.trim().toLowerCase(),
            ),
          );
          await focusProvince(parentProvince);
        } catch (e) {
          print('Parent province not found in cache for commune search: $e');
        }
      }
      selectCommune(commune);
    }
  }
}
