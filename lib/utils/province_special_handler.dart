import '../models/province_model.dart';

/// Special handling for provinces that have known issues
/// Add province names here that need special handling
class ProvinceSpecialHandler {
  // Provinces that should skip commune rendering due to data issues
  static const Set<String> skipCommuneRender = {
    // 'Tỉnh An Giang', // Temporarily removed to test commune rendering
    // Add other problematic provinces here
  };

  // Provinces that should use alternative rendering methods
  static const Set<String> useAlternativeRender = {
    // Add provinces that need alternative rendering here
  };

  /// Check if a province should skip commune rendering
  static bool shouldSkipCommuneRender(ProvinceModel province) {
    return skipCommuneRender.contains(province.name);
  }

  /// Check if a province should use alternative rendering
  static bool shouldUseAlternativeRender(ProvinceModel province) {
    return useAlternativeRender.contains(province.name);
  }

  /// Validate if a province has valid geometry for rendering
  static bool isValidGeometry(ProvinceModel province) {
    try {
      final geometry = province.geometry;
      // if (geometry == null) return false;

      final coordinates = geometry['coordinates'];
      if (coordinates == null || coordinates.isEmpty) return false;

      final type = geometry['type'];
      return type == 'Polygon' || type == 'MultiPolygon';
    } catch (e) {
      return false;
    }
  }

  /// Get safe coordinates from province, returns empty list if invalid
  static List<dynamic> getSafeCoordinates(ProvinceModel province) {
    try {
      final geometry = province.geometry;
      // if (geometry == null) return [];

      final coordinates = geometry['coordinates'];
      if (coordinates is! List) return [];

      return coordinates;
    } catch (e) {
      return [];
    }
  }
}
