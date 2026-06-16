import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/province_model.dart';
import '../services/geojson_service.dart';

class ProvinceProvider extends ChangeNotifier {
  final GeoJsonService _service = GeoJsonService();
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
      final List<String> communeKeys = [
        'thanh_pho_can_tho',
        'thanh_pho_da_nang',
        'thanh_pho_dong_nai',
        'thanh_pho_hai_phong',
        'thanh_pho_ho_chi_minh',
        'thanh_pho_hue',
        'thu_do_ha_noi',
        'tinh_an_giang',
        'tinh_bac_ninh',
        'tinh_ca_mau',
        'tinh_cao_bang',
        'tinh_dak_lak',
        'tinh_dien_bien',
        'tinh_dong_thap',
        'tinh_gia_lai',
        'tinh_ha_tinh',
        'tinh_hung_yen',
        'tinh_khanh_hoa',
        'tinh_lai_chau',
        'tinh_lam_dong',
        'tinh_lang_son',
        'tinh_lao_cai',
        'tinh_nghe_an',
        'tinh_ninh_binh',
        'tinh_phu_tho',
        'tinh_quang_ngai',
        'tinh_quang_ninh',
        'tinh_quang_tri',
        'tinh_son_la',
        'tinh_tay_ninh',
        'tinh_thai_nguyen',
        'tinh_thanh_hoa',
        'tinh_tuyen_quang',
        'tinh_vinh_long',
      ];

      final List<Map<String, dynamic>> results = [];

      for (final key in communeKeys) {
        try {
          final String response = await rootBundle.loadString(
            'assets/geojson/communes/$key.json',
          );
          final String fixedJson = response.replaceAll('NaN', 'null');
          final data = jsonDecode(fixedJson);
          final features = data['features'] as List;

          double totalArea = 0.0;
          double totalPopulation = 0.0;
          String provinceName = '';

          for (final feature in features) {
            final props = feature['properties'];
            if (props != null) {
              if (provinceName.isEmpty && props['parent_ten'] != null) {
                provinceName = props['parent_ten'];
              }
              final area = props['area_km2'];
              final pop = props['population'];
              if (area != null) {
                totalArea += (area as num).toDouble();
              }
              if (pop != null) {
                totalPopulation += (pop as num).toDouble();
              }
            }
          }

          if (provinceName.isEmpty) {
            provinceName = key.replaceAll('_', ' ');
          }

          final density = totalArea > 0 ? totalPopulation / totalArea : 0.0;

          results.add({
            'name': provinceName,
            'density': density,
            'population': totalPopulation,
            'area': totalArea,
            'key': key,
          });
        } catch (e) {
          print("Error calculating density for key $key: $e");
        }
        await Future.delayed(Duration.zero); // yield to prevent UI freeze
      }

      results.sort((a, b) => (b['density'] as double).compareTo(a['density'] as double));
      calculatedDensities = results;
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
}
