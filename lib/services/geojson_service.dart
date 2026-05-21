import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/province_model.dart';

class GeoJsonService {
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
      'assets/geojson/communes.geojson',
    );

    String fixedJson = response.replaceAll('NaN', 'null');

    final data = jsonDecode(fixedJson);

    final features = data['features'];

    List<ProvinceModel> zones = [];

    for (var item in features) {
      final props = item['properties'];

      if (props['type'] == 'Đặc khu') {
        zones.add(ProvinceModel.fromJson(item));
      }
    }

    return zones;
  }
}
