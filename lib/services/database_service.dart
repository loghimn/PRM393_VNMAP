import 'package:postgres/postgres.dart';
import '../models/province_model.dart';

class DatabaseService {
  static const String _host = 'ep-nameless-glitter-aopvc4hg-pooler.c-2.ap-southeast-1.aws.neon.tech';
  static const String _dbName = 'neondb';
  static const String _username = 'neondb_owner';
  static const String _password = 'npg_iB5FdLA6DESp';

  Future<Connection> _connect() async {
    return await Connection.open(
      Endpoint(
        host: _host,
        database: _dbName,
        username: _username,
        password: _password,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.require,
      ),
    );
  }

  String? _cleanNan(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.toLowerCase() == 'nan') return null;
    return str;
  }

  double? _cleanDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final str = value.toString().trim();
    if (str.toLowerCase() == 'nan' || str.isEmpty) return null;
    return double.tryParse(str);
  }

  int? _cleanInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    final str = value.toString().trim();
    if (str.toLowerCase() == 'nan' || str.isEmpty) return null;
    return int.tryParse(str);
  }

  ProvinceModel _mapRowToProvinceModel(Map<String, dynamic> rowMap) {
    final properties = {
      'ten': _cleanNan(rowMap['name']),
      'ma': _cleanNan(rowMap['code']),
      'type': _cleanNan(rowMap['type']),
      'area_km2': _cleanDouble(rowMap['area_km2']),
      'population': _cleanInt(rowMap['population']),
      'density': _cleanDouble(rowMap['density']),
      'capital': _cleanNan(rowMap['capital']),
      'decree': _cleanNan(rowMap['decree']),
      'macro_region': _cleanNan(rowMap['macro_region']),
      'predecessors': _cleanNan(rowMap['predecessors']),
      'parent_ma': _cleanNan(rowMap['parent_code']),
      'parent_ten': _cleanNan(rowMap['parent_name']),
    };
    final geometry = rowMap['geometry'] as Map<String, dynamic>;
    return ProvinceModel.fromJson({
      'properties': properties,
      'geometry': geometry,
    });
  }

  Future<List<ProvinceModel>> fetchProvinces() async {
    final conn = await _connect();
    try {
      final res = await conn.execute('SELECT * FROM provinces ORDER BY name ASC');
      return res.map((row) => _mapRowToProvinceModel(row.toColumnMap())).toList();
    } finally {
      await conn.close();
    }
  }

  Future<List<ProvinceModel>> fetchSpecialZones() async {
    final conn = await _connect();
    try {
      final res = await conn.execute('SELECT * FROM special_zones ORDER BY name ASC');
      return res.map((row) => _mapRowToProvinceModel(row.toColumnMap())).toList();
    } finally {
      await conn.close();
    }
  }

  Future<List<ProvinceModel>> fetchCommunesForProvince(String provinceName) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT * FROM communes WHERE parent_name = \$1 ORDER BY name ASC',
        parameters: [provinceName],
      );
      return res.map((row) => _mapRowToProvinceModel(row.toColumnMap())).toList();
    } finally {
      await conn.close();
    }
  }

  Future<List<Map<String, dynamic>>> fetchCalculatedDensities() async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT parent_name AS name, '
        'SUM(population) AS population, '
        'SUM(area_km2) AS area, '
        'SUM(population) / SUM(area_km2) AS density, '
        'parent_code AS key '
        'FROM communes '
        'WHERE parent_name IS NOT NULL AND parent_name <> \'nan\' '
        'GROUP BY parent_name, parent_code '
        'ORDER BY density DESC',
      );
      return res.map((row) {
        final map = row.toColumnMap();
        return {
          'name': _cleanNan(map['name']),
          'density': _cleanDouble(map['density']),
          'population': _cleanDouble(map['population']),
          'area': _cleanDouble(map['area']),
          'key': _cleanNan(map['key']) ?? getProvinceKey(_cleanNan(map['name']) ?? ''),
        };
      }).toList();
    } finally {
      await conn.close();
    }
  }

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

  Future<List<SearchResult>> searchLocations(String query) async {
    if (query.trim().isEmpty) return [];
    final conn = await _connect();
    try {
      final List<SearchResult> results = [];
      final escapedQuery = '%${query.trim()}%';
      
      // 1. Search provinces
      final provs = await conn.execute(
        'SELECT * FROM provinces WHERE name ILIKE \$1 LIMIT 5',
        parameters: [escapedQuery],
      );
      for (final row in provs) {
        final model = _mapRowToProvinceModel(row.toColumnMap());
        results.add(SearchResult(
          name: model.name,
          type: 'province',
          model: model,
        ));
      }

      // 2. Search special zones
      final zones = await conn.execute(
        'SELECT * FROM special_zones WHERE name ILIKE \$1 LIMIT 5',
        parameters: [escapedQuery],
      );
      for (final row in zones) {
        final model = _mapRowToProvinceModel(row.toColumnMap());
        results.add(SearchResult(
          name: model.name,
          type: 'special_zone',
          model: model,
        ));
      }

      // 3. Search communes
      final coms = await conn.execute(
        'SELECT * FROM communes WHERE name ILIKE \$1 LIMIT 10',
        parameters: [escapedQuery],
      );
      for (final row in coms) {
        final model = _mapRowToProvinceModel(row.toColumnMap());
        results.add(SearchResult(
          name: '${model.name} (${model.parentTen ?? ''})',
          type: 'commune',
          model: model,
        ));
      }

      return results;
    } finally {
      await conn.close();
    }
  }
}

class SearchResult {
  final String name;
  final String type; // 'province', 'special_zone', 'commune'
  final ProvinceModel model;

  SearchResult({
    required this.name,
    required this.type,
    required this.model,
  });
}

