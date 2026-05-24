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

    List<ProvinceModel> specialZones = [];

    for (var item in features) {
      final model = ProvinceModel.fromJson(item);
      // Filter only special zones (Đặc khu)
      if (model.properties['type'] == 'Đặc khu') {
        specialZones.add(model);
      }
    }

    return specialZones;
  }

  Future<List<ProvinceModel>> fetchCommunes() async {
    final String response = await rootBundle.loadString(
      'assets/geojson/communes.geojson',
    );

    String fixedJson = response.replaceAll('NaN', 'null');

    final data = jsonDecode(fixedJson);

    final features = data['features'];

    List<ProvinceModel> communes = [];

    for (var item in features) {
      communes.add(ProvinceModel.fromJson(item));
    }

    return communes;
  }
}
