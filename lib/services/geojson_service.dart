import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/province_model.dart';

class GeoJsonService {
  String getProvinceKey(String name) {
    var str = name.toLowerCase();
    
    const accentMap = {
      'á': 'a', 'à': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'â': 'a', 'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'ă': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'é': 'e', 'è': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ế': 'e', 'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'í': 'i', 'ì': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ó': 'o', 'ò': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ú': 'u', 'ù': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ứ': 'u', 'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ý': 'y', 'ỳ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'đ': 'd',
    };
    
    accentMap.forEach((key, value) {
      str = str.replaceAll(key, value);
    });
    
    str = str.replaceAll(RegExp(r'\s+'), '_');
    str = str.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    
    return str;
  }

  Future<List<ProvinceModel>> fetchProvinces() async {
    final String response = await rootBundle.loadString(
      'assets/geojson/provinces.geojson',
    );

    String fixedJson = response.replaceAll('NaN', 'null');

    final data = jsonDecode(fixedJson);

    final features = data['features'];

    List<ProvinceModel> provinces = [];

    for (var item in features) {
      provinces.add(ProvinceModel.fromJson(item));
    }

    return provinces;
  }

  Future<List<ProvinceModel>> fetchSpecialZones() async {
    final String response = await rootBundle.loadString(
      'assets/geojson/special_zones.geojson',
    );

    String fixedJson = response.replaceAll('NaN', 'null');

    final data = jsonDecode(fixedJson);

    final features = data['features'];

    List<ProvinceModel> specialZones = [];

    for (var item in features) {
      specialZones.add(ProvinceModel.fromJson(item));
    }

    return specialZones;
  }

  Future<List<ProvinceModel>> fetchCommunesForProvince(String provinceName) async {
    final String fileKey = getProvinceKey(provinceName);
    try {
      final String response = await rootBundle.loadString(
        'assets/geojson/communes/$fileKey.json',
      );

      String fixedJson = response.replaceAll('NaN', 'null');

      final data = jsonDecode(fixedJson);

      final features = data['features'];

      List<ProvinceModel> communes = [];

      for (var item in features) {
        communes.add(ProvinceModel.fromJson(item));
      }

      return communes;
    } catch (e) {
      print("Error loading communes for province '$provinceName' (key: $fileKey): $e");
      return [];
    }
  }

  // Deprecated, keeping as a fallback/compatibility method
  Future<List<ProvinceModel>> fetchCommunes() async {
    return [];
  }
}
