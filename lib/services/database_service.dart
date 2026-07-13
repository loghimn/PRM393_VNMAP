import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import '../models/province_model.dart';
import '../models/high_school_model.dart';
import '../models/household_model.dart';
import '../models/incident_model.dart';
import '../models/khu_pho_model.dart';
import '../models/dai_dien_model.dart';
import '../models/user_model.dart';

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
      // GIS tables (Phase 2/3)
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS dia_diem_cong_cong (
          id SERIAL PRIMARY KEY,
          ten VARCHAR(255) NOT NULL,
          loai VARCHAR(100),
          dia_chi TEXT,
          kinh_do DECIMAL(10, 7),
          vi_do DECIMAL(10, 7),
          mo_ta TEXT,
          ghi_chu TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS dia_diem_lich_su (
          id SERIAL PRIMARY KEY,
          ten VARCHAR(255) NOT NULL,
          loai_di_tich VARCHAR(100),
          dia_chi TEXT,
          kinh_do DECIMAL(10, 7),
          vi_do DECIMAL(10, 7),
          mo_ta TEXT,
          thoi_ky VARCHAR(100),
          ghi_chu TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS tuyen_duong (
          id SERIAL PRIMARY KEY,
          ten VARCHAR(255) NOT NULL,
          loai VARCHAR(100),
          dia_diem_bat_dau TEXT,
          dia_diem_ket_thuc TEXT,
          chieu_dai DECIMAL(8, 2),
          mo_ta TEXT,
          ghi_chu TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
      final res = await conn.execute('''
      SELECT incident_code
      FROM incidents
      WHERE incident_code IS NOT NULL
      ORDER BY id DESC
      LIMIT 1
      ''');

      if (res.isEmpty) {
        return 'SV-0001';
      }

      final lastCode =
          res.first.toColumnMap()['incident_code']?.toString() ?? 'SV-0000';

      // SV-0001 -> lấy phần số 0001
      final match = RegExp(r'^SV-(\d+)$').firstMatch(lastCode);

      if (match == null) {
        throw FormatException('Mã sự vụ không đúng định dạng: $lastCode');
      }

      final lastNumber = int.parse(match.group(1)!);
      final nextNumber = lastNumber + 1;

      return 'SV-${nextNumber.toString().padLeft(4, '0')}';
    } finally {
      await conn.close();
    }
  }

  // ===================================================================

  Future<List<Household>> fetchHouseholdList({
    String? searchQuery,
    String? neighborhood,
    String? ward,
    int? createdBy,
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
      if (createdBy != null) {
        params.add(createdBy);
        sql += ' AND created_by = \$${params.length}';
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
    int? createdBy,
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
      if (createdBy != null) {
        params.add(createdBy);
        sql += ' AND created_by = \$${params.length}';
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
    int? createdBy,
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
      if (createdBy != null) {
        params.add(createdBy);
        sql += ' AND sv.created_by = \$${params.length}';
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
      final id = incident.id;

      if (id == null) {
        throw ArgumentError('Không thể cập nhật sự vụ vì id bị null');
      }

      final map = Map<String, dynamic>.from(incident.toDbMap());

      // Những trường không được thay đổi khi cập nhật
      map.remove('id');
      map.remove('incident_code');
      map.remove('created_by');
      map.remove('created_at');
      map.remove('updated_at');

      final entries = map.entries.toList();

      final setClause = [
        for (int i = 0; i < entries.length; i++)
          '${entries[i].key} = \$${i + 1}',

        // Cho database tự cập nhật thời gian
        'updated_at = NOW()',
      ].join(', ');

      final values = entries.map((entry) => entry.value).toList();

      // id là parameter cuối cùng
      values.add(id);

      final result = await conn.execute('''
      UPDATE incidents
      SET $setClause
      WHERE id = \$${values.length}
      RETURNING *
      ''', parameters: values);

      if (result.isEmpty) {
        throw StateError('Không tìm thấy sự vụ có id = $id');
      }

      return Incident.fromJson(result.first.toColumnMap());
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
    int? createdBy,
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
      if (createdBy != null) {
        params.add(createdBy);
        sql += ' AND created_by = \$${params.length}';
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

  // ========================
  // Khu phố (Neighborhood) CRUD
  // ========================

  Future<List<KhuPhoModel>> fetchKhuPhos() async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT id, ten_khu_pho, mo_ta, dia_chi, parent_ten, created_at, updated_at FROM khu_pho ORDER BY ten_khu_pho ASC',
      );
      return res.map((row) => KhuPhoModel.fromJson(row.toColumnMap())).toList();
    } finally {
      await conn.close();
    }
  }

  Future<KhuPhoModel?> fetchKhuPhoById(int id) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT id, ten_khu_pho, mo_ta, dia_chi, parent_ten, created_at, updated_at FROM khu_pho WHERE id = \$1',
        parameters: [id],
      );
      if (res.isEmpty) return null;
      return KhuPhoModel.fromJson(res.first.toColumnMap());
    } finally {
      await conn.close();
    }
  }

  Future<KhuPhoModel> createKhuPho(KhuPhoModel model) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'INSERT INTO khu_pho (ten_khu_pho, mo_ta, dia_chi, parent_ten) VALUES (\$1, \$2, \$3, \$4) RETURNING *',
        parameters: [
          model.tenKhuPho,
          model.moTa,
          model.diaChi,
          model.parentTen,
        ],
      );
      return KhuPhoModel.fromJson(res.first.toColumnMap());
    } finally {
      await conn.close();
    }
  }

  Future<KhuPhoModel> updateKhuPho(KhuPhoModel model) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'UPDATE khu_pho SET ten_khu_pho = \$1, mo_ta = \$2, dia_chi = \$3, parent_ten = \$4, updated_at = NOW() WHERE id = \$5 RETURNING *',
        parameters: [
          model.tenKhuPho,
          model.moTa,
          model.diaChi,
          model.parentTen,
          model.id,
        ],
      );
      return KhuPhoModel.fromJson(res.first.toColumnMap());
    } finally {
      await conn.close();
    }
  }

  Future<void> deleteKhuPho(int id) async {
    final conn = await _connect();
    try {
      // Xóa các đại diện thuộc khu phố trước
      await conn.execute(
        'DELETE FROM dai_dien_khu_pho WHERE khu_pho_id = \$1',
        parameters: [id],
      );
      await conn.execute(
        'DELETE FROM khu_pho WHERE id = \$1',
        parameters: [id],
      );
    } finally {
      await conn.close();
    }
  }

  // ========================
  // Đại diện khu phố CRUD
  // ========================

  Future<List<DaiDienModel>> fetchDaiDiens() async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT d.*, k.ten_khu_pho FROM dai_dien_khu_pho d LEFT JOIN khu_pho k ON d.khu_pho_id = k.id ORDER BY d.ho_ten ASC',
      );
      return res
          .map((row) => DaiDienModel.fromJson(row.toColumnMap()))
          .toList();
    } finally {
      await conn.close();
    }
  }

  Future<List<DaiDienModel>> fetchDaiDiensByKhuPho(int khuPhoId) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT d.*, k.ten_khu_pho FROM dai_dien_khu_pho d LEFT JOIN khu_pho k ON d.khu_pho_id = k.id WHERE d.khu_pho_id = \$1 ORDER BY d.ho_ten ASC',
        parameters: [khuPhoId],
      );
      return res
          .map((row) => DaiDienModel.fromJson(row.toColumnMap()))
          .toList();
    } finally {
      await conn.close();
    }
  }

  Future<DaiDienModel?> fetchDaiDienById(int id) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT d.*, k.ten_khu_pho FROM dai_dien_khu_pho d LEFT JOIN khu_pho k ON d.khu_pho_id = k.id WHERE d.id = \$1',
        parameters: [id],
      );
      if (res.isEmpty) return null;
      return DaiDienModel.fromJson(res.first.toColumnMap());
    } finally {
      await conn.close();
    }
  }

  Future<DaiDienModel> createDaiDien(DaiDienModel model) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'INSERT INTO dai_dien_khu_pho (ho_ten, so_dien_thoai, email, dia_chi, khu_pho_id) VALUES (\$1, \$2, \$3, \$4, \$5) RETURNING *',
        parameters: [
          model.hoTen,
          model.soDienThoai,
          model.email,
          model.diaChi,
          model.khuPhoId,
        ],
      );
      final created = DaiDienModel.fromJson(res.first.toColumnMap());
      // Fetch lại với tên khu phố
      if (created.id != null) {
        return (await fetchDaiDienById(created.id!))!;
      }
      return created;
    } finally {
      await conn.close();
    }
  }

  Future<DaiDienModel> updateDaiDien(DaiDienModel model) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'UPDATE dai_dien_khu_pho SET ho_ten = \$1, so_dien_thoai = \$2, email = \$3, dia_chi = \$4, khu_pho_id = \$5, updated_at = NOW() WHERE id = \$6 RETURNING *',
        parameters: [
          model.hoTen,
          model.soDienThoai,
          model.email,
          model.diaChi,
          model.khuPhoId,
          model.id,
        ],
      );
      final updated = DaiDienModel.fromJson(res.first.toColumnMap());
      if (updated.id != null) {
        return (await fetchDaiDienById(updated.id!))!;
      }
      return updated;
    } finally {
      await conn.close();
    }
  }

  Future<void> deleteDaiDien(int id) async {
    final conn = await _connect();
    try {
      await conn.execute(
        'DELETE FROM dai_dien_khu_pho WHERE id = \$1',
        parameters: [id],
      );
    } finally {
      await conn.close();
    }
  }

  Future<List<DaiDienModel>> searchDaiDiens(String query) async {
    if (query.trim().isEmpty) return [];
    final conn = await _connect();
    try {
      final escapedQuery = '%${query.trim()}%';
      final res = await conn.execute(
        'SELECT d.*, k.ten_khu_pho FROM dai_dien_khu_pho d LEFT JOIN khu_pho k ON d.khu_pho_id = k.id WHERE d.ho_ten ILIKE \$1 OR d.so_dien_thoai ILIKE \$1 OR d.email ILIKE \$1 ORDER BY d.ho_ten ASC',
        parameters: [escapedQuery],
      );
      return res
          .map((row) => DaiDienModel.fromJson(row.toColumnMap()))
          .toList();
    } finally {
      await conn.close();
    }
  }

  // ===================================================================
  // USERS CRUD
  // ===================================================================

  String _hashPassword(String password) {
    print('_hashPassword input: password="$password"');
    print('_hashPassword input bytes: ${password.codeUnits}');
    final bytes = utf8.encode(password);
    print('_hashPassword utf8 bytes: $bytes');
    final digest = sha256.convert(bytes);
    print('_hashPassword output: ${digest.toString()}');
    return digest.toString();
  }

  Future<void> _ensureUsersTable(Connection conn) async {
    try {
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id SERIAL PRIMARY KEY,
          username VARCHAR(100) UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          email VARCHAR(255),
          full_name VARCHAR(255),
          phone VARCHAR(20),
          role VARCHAR(50) DEFAULT 'user',
          avatar_url TEXT,
          is_active BOOLEAN DEFAULT TRUE,
          last_login TIMESTAMP,
          created_at TIMESTAMP DEFAULT NOW(),
          updated_at TIMESTAMP DEFAULT NOW()
        )
      ''');
    } catch (_) {}
  }

  Future<UserModel?> login(String username, String password) async {
    print('=== LOGIN ATTEMPT ===');
    print('Username input: "$username"');
    print('Password length: ${password.length}');

    final conn = await _connect();
    try {
      await _ensureUsersTable(conn);

      final trimmedUsername = username.trim();
      print('Querying DB for username: "$trimmedUsername"');

      final res = await conn.execute(
        'SELECT * FROM users WHERE username = \$1 AND is_active = TRUE',
        parameters: [trimmedUsername],
      );

      print('DB returned ${res.length} row(s)');

      if (res.isEmpty) {
        print('ERROR: No user found in database');
        return null;
      }

      final userMap = res.first.toColumnMap();
      print(
        'User data from DB: id=${userMap['id']}, username=${userMap['username']}, role=${userMap['role']}',
      );

      final user = UserModel.fromJson(userMap);
      final trimmedPassword = password.trim();
      final hash = _hashPassword(trimmedPassword);

      print('Password hash comparison:');
      print('  Stored: ${user.passwordHash}');
      print('  Input:  $hash');
      print('  Match: ${user.passwordHash == hash}');

      if (user.passwordHash != hash) {
        print('ERROR: Password mismatch');
        return null;
      }

      print('SUCCESS: Login passed');

      // Update last login
      await conn.execute(
        'UPDATE users SET last_login = NOW() WHERE id = \$1',
        parameters: [user.id],
      );

      return user;
    } catch (e) {
      print('LOGIN EXCEPTION: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  Future<UserModel?> getUserById(int id) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT * FROM users WHERE id = \$1',
        parameters: [id],
      );
      if (res.isEmpty) return null;
      return UserModel.fromJson(res.first.toColumnMap());
    } finally {
      await conn.close();
    }
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT * FROM users WHERE username = \$1',
        parameters: [username],
      );
      if (res.isEmpty) return null;
      return UserModel.fromJson(res.first.toColumnMap());
    } finally {
      await conn.close();
    }
  }

  Future<UserModel> createUser(UserModel user, String password) async {
    final conn = await _connect();
    try {
      await _ensureUsersTable(conn);
      final hash = _hashPassword(password);
      final res = await conn.execute(
        'INSERT INTO users (username, password_hash, email, full_name, phone, role) VALUES (\$1, \$2, \$3, \$4, \$5, \$6) RETURNING *',
        parameters: [
          user.username,
          hash,
          user.email,
          user.fullName,
          user.phone,
          user.role,
        ],
      );
      return UserModel.fromJson(res.first.toColumnMap());
    } finally {
      await conn.close();
    }
  }

  Future<UserModel> updateUser(UserModel user) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'UPDATE users SET email = \$1, full_name = \$2, phone = \$3, role = \$4, avatar_url = \$5, updated_at = NOW() WHERE id = \$6 RETURNING *',
        parameters: [
          user.email,
          user.fullName,
          user.phone,
          user.role,
          user.avatarUrl,
          user.id,
        ],
      );
      return UserModel.fromJson(res.first.toColumnMap());
    } finally {
      await conn.close();
    }
  }

  Future<bool> changePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
    final conn = await _connect();
    try {
      final res = await conn.execute(
        'SELECT * FROM users WHERE id = \$1',
        parameters: [userId],
      );
      if (res.isEmpty) return false;

      final user = UserModel.fromJson(res.first.toColumnMap());
      final oldHash = _hashPassword(oldPassword);
      if (user.passwordHash != oldHash) return false;

      final newHash = _hashPassword(newPassword);
      await conn.execute(
        'UPDATE users SET password_hash = \$1, updated_at = NOW() WHERE id = \$2',
        parameters: [newHash, userId],
      );
      return true;
    } finally {
      await conn.close();
    }
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

  Future<List<UserModel>> getAllUsers({String? searchQuery}) async {
    final conn = await _connect();
    try {
      String sql = 'SELECT * FROM users ORDER BY created_at DESC';
      final params = <dynamic>[];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        params.add('%${searchQuery.trim()}%');
        sql =
            'SELECT * FROM users WHERE username ILIKE \$1 OR email ILIKE \$1 ORDER BY created_at DESC';
      }

      final res = await conn.execute(sql, parameters: params);
      return res.map((row) => UserModel.fromJson(row.toColumnMap())).toList();
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
