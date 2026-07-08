import 'package:postgres/postgres.dart';
import '../models/province_model.dart';
import '../models/high_school_model.dart';
import '../models/household_model.dart';
import '../models/incident_model.dart';

class DatabaseService {
  static const String _host =
      'ep-nameless-glitter-aopvc4hg-pooler.c-2.ap-southeast-1.aws.neon.tech';
  static const String _dbName = 'neondb';
  static const String _username = 'neondb_owner';
  static const String _password = 'npg_iB5FdLA6DESp';

  Future<Connection> _connect() async {
    final conn = await Connection.open(
      Endpoint(
        host: _host,
        database: _dbName,
        username: _username,
        password: _password,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.require),
    );
    await _ensureTables(conn);
    return conn;
  }

  bool _tablesCreated = false;

  Future<void> _ensureTables(Connection conn) async {
    if (_tablesCreated) return;
    try {
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS households (
          id SERIAL PRIMARY KEY,
          household_code VARCHAR(20) UNIQUE NOT NULL,
          head_of_household TEXT NOT NULL,
          house_number TEXT,
          street TEXT,
          neighborhood TEXT,
          ward TEXT,
          district TEXT,
          city TEXT,
          phone TEXT,
          email TEXT,
          population INT,
          notes TEXT,
          longitude DOUBLE PRECISION,
          latitude DOUBLE PRECISION,
          created_at TIMESTAMP DEFAULT NOW(),
          updated_at TIMESTAMP DEFAULT NOW()
        )
      ''');
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS incidents (
          id SERIAL PRIMARY KEY,
          incident_code VARCHAR(20) UNIQUE NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          address TEXT,
          neighborhood TEXT,
          ward TEXT,
          district TEXT,
          city TEXT,
          longitude DOUBLE PRECISION,
          latitude DOUBLE PRECISION,
          household_id INT REFERENCES households(id),
          head_of_household TEXT,
          phone TEXT,
          status VARCHAR(20) DEFAULT 'received',
          handler TEXT,
          notes TEXT,
          created_at TIMESTAMP DEFAULT NOW(),
          updated_at TIMESTAMP DEFAULT NOW(),
          completed_date TIMESTAMP
        )
      ''');
      _tablesCreated = true;
    } catch (_) {}
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
      final res = await conn.execute(
        'SELECT * FROM provinces ORDER BY name ASC',
      );
      return res
          .map((row) => _mapRowToProvinceModel(row.toColumnMap()))
          .toList();
    } finally {
      await conn.close();
    }
  }

  Future<List<ProvinceModel>> fetchSpecialZones() async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT * FROM special_zones ORDER BY name ASC',
      );
      return res
          .map((row) => _mapRowToProvinceModel(row.toColumnMap()))
          .toList();
    } finally {
      await conn.close();
    }
  }

  Future<List<ProvinceModel>> fetchCommunesForProvince(
    String provinceName,
  ) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT * FROM communes WHERE parent_name = \$1 ORDER BY name ASC',
        parameters: [provinceName],
      );
      return res
          .map((row) => _mapRowToProvinceModel(row.toColumnMap()))
          .toList();
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
          'key':
              _cleanNan(map['key']) ??
              getProvinceKey(_cleanNan(map['name']) ?? ''),
        };
      }).toList();
    } finally {
      await conn.close();
    }
  }

  Future<List<HighSchool>> fetchHighSchoolsByCommuneName(
    String communeName,
  ) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT * FROM truong_thpt WHERE ten_xa_phuong = \$1 ORDER BY ten_truong ASC',
        parameters: [communeName],
      );
      return res.map((row) {
        final map = row.toColumnMap();
        return HighSchool.fromJson({
          'stt': map['stt'],
          'ma_tinh_tp': map['ma_tinh_tp'],
          'ten_tinh_tp': map['ten_tinh_tp'],
          'ma_xa_phuong': map['ma_xa_phuong'],
          'ten_xa_phuong': map['ten_xa_phuong'],
          'ma_truong': map['ma_truong'],
          'ten_truong': map['ten_truong'],
          'address': map['address'],
          'khu_vuc': map['khu_vuc'],
        });
      }).toList();
    } finally {
      await conn.close();
    }
  }

  // ===================================================================
  // HOUSEHOLD CRUD
  Future<String> generateIncidentCode() async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        "SELECT incident_code FROM incidents ORDER BY id DESC LIMIT 1",
      );
      if (res.isEmpty) return 'SV-0001';
      final lastCode =
          res.first.toColumnMap()['incident_code']?.toString() ?? 'SV-0000';
      final match = RegExp(r'SV-(\\d+)').firstMatch(lastCode);
      if (match != null) {
        final num = int.parse(match.group(1)!) + 1;
        return 'SV-' + num.toString().padLeft(4, '0');
      }
      return 'SV-0001';
    } finally {
      await conn.close();
    }
  }

  // ===================================================================

  Future<List<Household>> fetchHouseholdList({
    String? searchQuery,
    String? neighborhood,
    String? ward,
    int limit = 50,
    int offset = 0,
  }) async {
    final conn = await _connect();
    try {
      String sql = 'SELECT * FROM households WHERE 1=1';
      final params = <dynamic>[];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        params.add('%${searchQuery.trim()}%');
        sql +=
            ' AND (head_of_household ILIKE \$${params.length} OR household_code ILIKE \$${params.length} OR phone ILIKE \$${params.length})';
      }
      if (neighborhood != null && neighborhood.isNotEmpty) {
        params.add(neighborhood.trim());
        sql += ' AND neighborhood = \$${params.length}';
      }
      if (ward != null && ward.isNotEmpty) {
        params.add(ward.trim());
        sql += ' AND ward = \$${params.length}';
      }

      sql += ' ORDER BY created_at DESC';
      params.add(limit);
      sql += ' LIMIT \$${params.length}';
      params.add(offset);
      sql += ' OFFSET \$${params.length}';

      final res = await conn.execute(sql, parameters: params);
      return res.map((row) => Household.fromJson(row.toColumnMap())).toList();
    } finally {
      await conn.close();
    }
  }

  Future<Household?> fetchHouseholdById(int id) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT * FROM households WHERE id = \$1',
        parameters: [id],
      );
      if (res.isEmpty) return null;
      return Household.fromJson(res.first.toColumnMap());
    } finally {
      await conn.close();
    }
  }

  Future<Household> createHousehold(Household household) async {
    const maxRetries = 5;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final conn = await _connect();
      try {
        // Generate a fresh code on the *same* connection to reduce race condition
        final code = await generateHouseholdCode(conn: conn);
        final map = household.toDbMap();
        map.remove('id');
        map['household_code'] = code;
        map['created_at'] = DateTime.now().toIso8601String();
        map['updated_at'] = DateTime.now().toIso8601String();

        final columns = map.keys.join(', ');
        final placeholders = map.keys
            .toList()
            .asMap()
            .entries
            .map((e) {
              return '\$${e.key + 1}';
            })
            .join(', ');
        final values = map.values.toList();

        final res = await conn.execute(
          'INSERT INTO households ($columns) VALUES ($placeholders) RETURNING *',
          parameters: values,
        );
        return Household.fromJson(res.first.toColumnMap());
      } catch (e) {
        // If unique_violation on household_code, retry with a new code
        final isDuplicateCode =
            e.toString().contains('unique_violation') &&
            e.toString().contains('household_code');
        if (isDuplicateCode && attempt < maxRetries - 1) {
          continue; // Retry with a new code
        }
        rethrow;
      } finally {
        await conn.close();
      }
    }
    throw Exception('Failed to create household after $maxRetries attempts');
  }

  Future<Household> updateHousehold(Household household) async {
    final conn = await _connect();
    try {
      final map = household.toDbMap();
      final id = map.remove('id');
      map['updated_at'] = DateTime.now().toIso8601String();

      final setClause = map.keys
          .toList()
          .asMap()
          .entries
          .map((e) => '${e.value} = \$${e.key + 1}')
          .join(', ');
      final values = map.values.toList();
      values.add(id);

      final res = await conn.execute(
        'UPDATE households SET $setClause WHERE id = \$${values.length} RETURNING *',
        parameters: values,
      );
      return Household.fromJson(res.first.toColumnMap());
    } finally {
      await conn.close();
    }
  }

  Future<void> deleteHousehold(int id) async {
    final conn = await _connect();
    try {
      await conn.execute(
        'DELETE FROM households WHERE id = \$1',
        parameters: [id],
      );
    } finally {
      await conn.close();
    }
  }

  // ADDRESS DROPDOWN DATA

  Future<List<String>> fetchDistinctNeighborhoods() async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        "SELECT DISTINCT neighborhood FROM households WHERE neighborhood IS NOT NULL AND neighborhood != '' ORDER BY neighborhood",
      );
      return res
          .map((r) => r.toColumnMap()['neighborhood'].toString())
          .toList();
    } finally {
      await conn.close();
    }
  }

  Future<List<String>> fetchDistinctWards() async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        "SELECT DISTINCT name FROM communes WHERE name IS NOT NULL AND name != '' AND name <> 'nan' ORDER BY name",
      );
      return res.map((r) => r.toColumnMap()['name'].toString()).toList();
    } finally {
      await conn.close();
    }
  }

  Future<List<String>> fetchCommunesForProvinceName(String provinceName) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        "SELECT DISTINCT name FROM communes WHERE parent_name = \$1 AND name IS NOT NULL AND name != '' AND name <> 'nan' ORDER BY name",
        parameters: [provinceName],
      );
      return res.map((r) => r.toColumnMap()['name'].toString()).toList();
    } finally {
      await conn.close();
    }
  }

  Future<List<String>> fetchDistinctDistricts() async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        "SELECT DISTINCT district FROM households WHERE district IS NOT NULL AND district != '' ORDER BY district",
      );
      return res.map((r) => r.toColumnMap()['district'].toString()).toList();
    } finally {
      await conn.close();
    }
  }

  Future<List<Map<String, String>>> fetchDistinctCities() async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        "SELECT code, name FROM provinces WHERE name IS NOT NULL AND name != '' AND name <> 'nan' ORDER BY name",
      );
      return res
          .map(
            (r) => {
              'code': r.toColumnMap()['code'].toString(),
              'name': r.toColumnMap()['name'].toString(),
            },
          )
          .toList();
    } finally {
      await conn.close();
    }
  }

  Future<List<String>> fetchCommunesForParentCode(String parentCode) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        "SELECT DISTINCT name FROM communes WHERE parent_code = \$1 AND name IS NOT NULL AND name != '' AND name <> 'nan' ORDER BY name",
        parameters: [parentCode],
      );
      return res.map((r) => r.toColumnMap()['name'].toString()).toList();
    } finally {
      await conn.close();
    }
  }

  Future<String> generateHouseholdCode({Connection? conn}) async {
    final c = conn ?? await _connect();
    bool closeConn = conn == null;
    try {
      final res = await c.execute(
        "SELECT MAX(CAST(SUBSTRING(household_code, 5) AS INTEGER)) AS max_num "
        "FROM households WHERE household_code LIKE 'HGD-%'",
      );
      if (res.isEmpty || res.first.toColumnMap()['max_num'] == null) {
        return 'HGD-0001';
      }
      final maxNum = int.parse(res.first.toColumnMap()['max_num'].toString());
      return 'HGD-${(maxNum + 1).toString().padLeft(4, '0')}';
    } finally {
      if (closeConn) await c.close();
    }
  }

  Future<List<Household>> fetchHouseholdsByCommuneName(
    String communeName,
  ) async {
    final conn = await _connect();
    try {
      // ward column stores commune name directly (from household form dropdown)
      final res = await conn.execute(
        'SELECT h.* FROM households h '
        'WHERE h.ward = \$1 '
        'ORDER BY h.household_code ASC',
        parameters: [communeName],
      );
      return res.map((row) => Household.fromJson(row.toColumnMap())).toList();
    } finally {
      await conn.close();
    }
  }

  Future<List<Household>> fetchHouseholdsByWard(String ward) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT * FROM households WHERE ward = \$1 ORDER BY household_code ASC',
        parameters: [ward],
      );
      return res.map((row) => Household.fromJson(row.toColumnMap())).toList();
    } finally {
      await conn.close();
    }
  }

  Future<int> countHouseholds({
    String? searchQuery,
    String? neighborhood,
    String? ward,
  }) async {
    final conn = await _connect();
    try {
      String sql = 'SELECT COUNT(*) FROM households WHERE 1=1';
      final params = <dynamic>[];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        params.add('%${searchQuery.trim()}%');
        sql +=
            ' AND (head_of_household ILIKE \$${params.length} OR household_code ILIKE \$${params.length} OR phone ILIKE \$${params.length})';
      }
      if (neighborhood != null && neighborhood.isNotEmpty) {
        params.add(neighborhood.trim());
        sql += ' AND neighborhood = \$${params.length}';
      }
      if (ward != null && ward.isNotEmpty) {
        params.add(ward.trim());
        sql += ' AND ward = \$${params.length}';
      }

      final res = await conn.execute(sql, parameters: params);
      final count = res.first.toColumnMap()['count'];
      return count is int ? count : int.tryParse('$count') ?? 0;
    } finally {
      await conn.close();
    }
  }

  // ===================================================================
  // INCIDENT CRUD
  // ===================================================================

  Future<List<Incident>> fetchIncidentList({
    String? searchQuery,
    String? status,
    String? neighborhood,
    String? ward,
    int? householdId,
    int limit = 50,
    int offset = 0,
  }) async {
    final conn = await _connect();
    try {
      String sql =
          'SELECT sv.*, hgd.head_of_household AS household_name, hgd.phone AS household_phone FROM incidents sv LEFT JOIN households hgd ON sv.household_id = hgd.id WHERE 1=1';
      final params = <dynamic>[];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        params.add('%${searchQuery.trim()}%');
        sql +=
            ' AND (sv.title ILIKE \$${params.length} OR sv.incident_code ILIKE \$${params.length} OR sv.head_of_household ILIKE \$${params.length})';
      }
      if (status != null && status.isNotEmpty) {
        params.add(status.trim());
        sql += ' AND sv.status = \$${params.length}';
      }
      if (neighborhood != null && neighborhood.isNotEmpty) {
        params.add(neighborhood.trim());
        sql += ' AND sv.neighborhood = \$${params.length}';
      }
      if (ward != null && ward.isNotEmpty) {
        params.add(ward.trim());
        sql += ' AND sv.ward = \$${params.length}';
      }
      if (householdId != null) {
        params.add(householdId);
        sql += ' AND sv.household_id = \$${params.length}';
      }

      sql += ' ORDER BY sv.created_at DESC';
      params.add(limit);
      sql += ' LIMIT \$${params.length}';
      params.add(offset);
      sql += ' OFFSET \$${params.length}';

      final res = await conn.execute(sql, parameters: params);
      return res.map((row) => Incident.fromJson(row.toColumnMap())).toList();
    } finally {
      await conn.close();
    }
  }

  Future<Incident?> fetchIncidentById(int id) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT sv.*, hgd.head_of_household AS household_name, hgd.phone AS household_phone FROM incidents sv LEFT JOIN households hgd ON sv.household_id = hgd.id WHERE sv.id = \$1',
        parameters: [id],
      );
      if (res.isEmpty) return null;
      return Incident.fromJson(res.first.toColumnMap());
    } finally {
      await conn.close();
    }
  }

  Future<Incident> createIncident(Incident incident) async {
    final conn = await _connect();
    try {
      final map = incident.toDbMap();
      map.remove('id');
      map['created_at'] = DateTime.now().toIso8601String();
      map['updated_at'] = DateTime.now().toIso8601String();

      final columns = map.keys.join(', ');
      final placeholders = map.keys
          .toList()
          .asMap()
          .entries
          .map((e) {
            return '\$${e.key + 1}';
          })
          .join(', ');
      final values = map.values.toList();

      final res = await conn.execute(
        'INSERT INTO incidents ($columns) VALUES ($placeholders) RETURNING *',
        parameters: values,
      );
      return Incident.fromJson(res.first.toColumnMap());
    } finally {
      await conn.close();
    }
  }

  Future<Incident> updateIncident(Incident incident) async {
    final conn = await _connect();
    try {
      final map = incident.toDbMap();
      final id = map.remove('id');
      map['updated_at'] = DateTime.now().toIso8601String();

      final setClause = map.keys
          .toList()
          .asMap()
          .entries
          .map((e) => '${e.value} = \$${e.key + 1}')
          .join(', ');
      final values = map.values.toList();
      values.add(id);

      final res = await conn.execute(
        'UPDATE incidents SET $setClause WHERE id = \$${values.length} RETURNING *',
        parameters: values,
      );
      return Incident.fromJson(res.first.toColumnMap());
    } finally {
      await conn.close();
    }
  }

  Future<void> deleteIncident(int id) async {
    final conn = await _connect();
    try {
      await conn.execute(
        'DELETE FROM incidents WHERE id = \$1',
        parameters: [id],
      );
    } finally {
      await conn.close();
    }
  }

  Future<int> countIncidents({
    String? searchQuery,
    String? status,
    String? neighborhood,
    String? ward,
    int? householdId,
  }) async {
    final conn = await _connect();
    try {
      String sql = 'SELECT COUNT(*) FROM incidents WHERE 1=1';
      final params = <dynamic>[];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        params.add('%${searchQuery.trim()}%');
        sql +=
            ' AND (tieu_de ILIKE \$${params.length} OR ma_su_vu ILIKE \$${params.length})';
      }
      if (status != null && status.isNotEmpty) {
        params.add(status.trim());
        sql += ' AND trang_thai = \$${params.length}';
      }
      if (neighborhood != null && neighborhood.isNotEmpty) {
        params.add(neighborhood.trim());
        sql += ' AND neighborhood = \$${params.length}';
      }
      if (ward != null && ward.isNotEmpty) {
        params.add(ward.trim());
        sql += ' AND ward = \$${params.length}';
      }
      if (householdId != null) {
        params.add(householdId);
        sql += ' AND ho_gia_dinh_id = \$${params.length}';
      }

      final res = await conn.execute(sql, parameters: params);
      final count = res.first.toColumnMap()['count'];
      return count is int ? count : int.tryParse('$count') ?? 0;
    } finally {
      await conn.close();
    }
  }

  // ===================================================================
  // STATISTICS
  // ===================================================================

  Future<Map<String, int>> statisticsIncidentsByMonth(int year) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT EXTRACT(MONTH FROM created_at)::int AS month_val, COUNT(*)::int AS count_val '
        'FROM incidents WHERE EXTRACT(YEAR FROM created_at) = \$1 '
        'GROUP BY month_val ORDER BY month_val',
        parameters: [year],
      );
      final Map<String, int> result = {};
      for (int i = 1; i <= 12; i++) {
        result['Month $i'] = 0;
      }
      for (final row in res) {
        final map = row.toColumnMap();
        final month = map['month_val'] is int
            ? map['month_val']
            : int.tryParse('${map['month_val']}') ?? 1;
        final countVal = map['count_val'] is int
            ? map['count_val']
            : int.tryParse('${map['count_val']}') ?? 0;
        result['Month $month'] = countVal;
      }
      return result;
    } finally {
      await conn.close();
    }
  }

  Future<Map<String, int>> statisticsIncidentsByNeighborhood() async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        "SELECT COALESCE(neighborhood, 'Unknown') AS neighborhood, COUNT(*)::int AS count_val "
        'FROM incidents GROUP BY neighborhood ORDER BY count_val DESC',
      );
      final Map<String, int> result = {};
      for (final row in res) {
        final map = row.toColumnMap();
        final neighborhood = map['neighborhood']?.toString() ?? 'Unknown';
        final countVal = map['count_val'] is int
            ? map['count_val']
            : int.tryParse('${map['count_val']}') ?? 0;
        result[neighborhood] = countVal;
      }
      return result;
    } finally {
      await conn.close();
    }
  }

  Future<Map<String, int>> statisticsIncidentsByStatus() async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        "SELECT COALESCE(status, 'received') AS status, COUNT(*)::int AS count_val "
        'FROM incidents GROUP BY status ORDER BY count_val DESC',
      );
      final Map<String, int> result = {};
      for (final row in res) {
        final map = row.toColumnMap();
        final statusDb = map['status']?.toString() ?? 'received';
        final countVal = map['count_val'] is int
            ? map['count_val']
            : int.tryParse('${map['count_val']}') ?? 0;
        final statusName = IncidentStatus.fromString(statusDb).displayName;
        result[statusName] = countVal;
      }
      return result;
    } finally {
      await conn.close();
    }
  }

  Future<List<String>> fetchNeighborhoodList() async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        "SELECT DISTINCT neighborhood FROM households WHERE neighborhood IS NOT NULL AND neighborhood <> '' ORDER BY neighborhood",
      );
      return res
          .map((row) => row.toColumnMap()['neighborhood']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } finally {
      await conn.close();
    }
  }

  String getProvinceKey(String name) {
    var str = name.toLowerCase();
    const accentMap = {
      'á': 'a',
      'à': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'â': 'a',
      'ấ': 'a',
      'ầ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'ă': 'a',
      'ắ': 'a',
      'ằ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'é': 'e',
      'è': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ế': 'e',
      'ề': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'í': 'i',
      'ì': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ó': 'o',
      'ò': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ố': 'o',
      'ồ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ớ': 'o',
      'ờ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ứ': 'u',
      'ừ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ý': 'y',
      'ỳ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
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
        results.add(
          SearchResult(name: model.name, type: 'province', model: model),
        );
      }

      // 2. Search special zones
      final zones = await conn.execute(
        'SELECT * FROM special_zones WHERE name ILIKE \$1 LIMIT 5',
        parameters: [escapedQuery],
      );
      for (final row in zones) {
        final model = _mapRowToProvinceModel(row.toColumnMap());
        results.add(
          SearchResult(name: model.name, type: 'special_zone', model: model),
        );
      }

      // 3. Search communes
      final coms = await conn.execute(
        'SELECT * FROM communes WHERE name ILIKE \$1 LIMIT 10',
        parameters: [escapedQuery],
      );
      for (final row in coms) {
        final model = _mapRowToProvinceModel(row.toColumnMap());
        results.add(
          SearchResult(
            name: '${model.name} (${model.parentTen ?? ''})',
            type: 'commune',
            model: model,
          ),
        );
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

  SearchResult({required this.name, required this.type, required this.model});
}
