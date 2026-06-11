import 'package:flutter/material.dart';

import '../models/province_model.dart';
import '../services/geojson_service.dart';

class ProvinceProvider extends ChangeNotifier {
  final GeoJsonService _service = GeoJsonService();
  ProvinceModel? hoveredProvince;
  List<ProvinceModel> communes = [];
  ProvinceModel? focusedProvince;

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
    focusedProvince = province;
    selectedProvince = province;
    final String cacheKey = province.name;
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
    selectedProvince = province;

    notifyListeners();
  }

  void selectCommune(ProvinceModel commune) {
    print("SELECT COMMUNE: ${commune.name}");
    selectedCommune = commune;
    selectedProvince = null; // 👈 tránh conflict panel

    selectedCommune = commune;
    notifyListeners();
  }

  void clearFocus() {
    focusedProvince = null;

    focusedCommunes.clear();

    selectedCommune = null; // 👈 thêm dòng này
    selectedProvince = null;

    notifyListeners();
  }
}
