import 'package:flutter/material.dart';

import '../models/province_model.dart';
import '../services/geojson_service.dart';

class ProvinceProvider extends ChangeNotifier {
  final GeoJsonService _service = GeoJsonService();
  ProvinceModel? hoveredProvince;
  List<ProvinceModel> communes = [];
  ProvinceModel? focusedProvince;

  List<ProvinceModel> allCommunes = [];
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

  Future<void> loadCommunes() async {
    if (allCommunes.isNotEmpty) return;

    print('Loading communes...');
    allCommunes = await _service.fetchCommunes();
    print('Total communes loaded: ${allCommunes.length}');

    if (allCommunes.isNotEmpty) {
      print(
        'Sample commune: ${allCommunes.first.name}, parent: ${allCommunes.first.properties['parent_ten']}',
      );
    }
  }

  Future<void> focusProvince(ProvinceModel province) async {
    try {
      await loadCommunes();
    } catch (e) {
      print('Error loading communes: $e');
      // Continue without communes data
    }

    focusedProvince = province;
    selectedProvince = province;

    focusedCommunes = allCommunes.where((c) {
      final isSameProvince = c.properties['parent_ten'] == province.name;
      final notSpecialZone = c.properties['type'] != 'Đặc khu';
      return isSameProvince && notSpecialZone;
    }).toList();

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

    notifyListeners();
  }
}
