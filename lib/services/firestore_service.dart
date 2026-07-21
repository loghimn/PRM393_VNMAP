import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/province_model.dart';
import '../models/high_school_model.dart';
import '../models/household_model.dart';
import '../models/incident_model.dart';
import '../models/dia_diem_lich_su_model.dart';
import '../models/khu_pho_model.dart';
import '../models/dai_dien_model.dart';
import '../models/user_model.dart';
import '../models/household_request_model.dart';

/// Service thay thế DatabaseService (PostgreSQL) bằng Firebase Firestore.
///
/// - Dùng Firestore collections thay cho bảng SQL
/// - Dùng FirebaseAuth thay cho password hash tự quản
/// - Dùng auto-increment ID qua document counters
class FirestoreService {
  // Singleton
  FirestoreService._internal();
  static final FirestoreService instance = FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===================================================================
  // HELPERS - ID generation (thay thế SERIAL trong PostgreSQL)
  // ===================================================================

  /// Lấy ID tiếp theo từ counter collection
  Future<int> _nextId(String collection) async {
    final docRef = _db.collection('counters').doc(collection);
    return _db.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) {
        transaction.set(docRef, {'current_id': 1});
        return 1;
      }
      final currentId = (doc.data()?['current_id'] as num?)?.toInt() ?? 0;
      final nextId = currentId + 1;
      transaction.update(docRef, {'current_id': nextId});
      return nextId;
    });
  }

  /// Đồng bộ hoá tài liệu với Firestore, thêm id dạng số
  Future<void> _setWithId(
    String collection,
    int id,
    Map<String, dynamic> data,
  ) async {
    await _db.collection(collection).doc(id.toString()).set(data);
  }

  // ===================================================================
  // AUTH — Firebase Auth
  // ===================================================================

  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  /// Đăng nhập bằng email + password qua Firebase Auth
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user?.uid;
      if (uid == null) return null;
      return await getUserByUid(uid);
    } on auth.FirebaseAuthException catch (e) {
      print('FirestoreService.signInWithEmail error: ${e.code}');
      return null;
    } catch (e) {
      print('FirestoreService.signInWithEmail error: $e');
      return null;
    }
  }

  /// Tạo user với Firebase Auth + lưu profile vào Firestore
  Future<UserModel> createUserWithAuth(
    String email,
    String password,
    UserModel user,
  ) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = userCredential.user!.uid;

    // Tạo id số nguyên cho user mới
    final newId = await _nextId('users');

    // Gửi email xác thực (tuỳ chọn)
    await userCredential.user?.sendEmailVerification();

    // Lưu profile vào Firestore với document ID = uid
    final data = user.toJson();
    data['id'] = newId;
    data['uid'] = uid;
    data['email'] = email;
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();

    await _db.collection('users').doc(uid).set(data);

    return UserModel.fromJson(data);
  }

  /// Đổi mật khẩu dùng Firebase Auth của user hiện tại
  Future<bool> changePasswordFirebase(String newPassword) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) return false;
      await currentUser.updatePassword(newPassword);
      return true;
    } on auth.FirebaseAuthException catch (e) {
      print('FirestoreService.changePasswordFirebase error: ${e.code}');
      return false;
    } catch (e) {
      print('FirestoreService.changePasswordFirebase error: $e');
      return false;
    }
  }

  /// Gửi email reset mật khẩu
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('FirestoreService.sendPasswordResetEmail error: $e');
      return false;
    }
  }

  /// Lấy user profile từ Firestore theo Firebase UID
  Future<UserModel?> getUserByUid(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;

      // Nếu user chưa có id (số nguyên), tự động sinh id mới
      if (data['id'] == null) {
        final newId = await _nextId('users');
        data['id'] = newId;
        await _db.collection('users').doc(uid).update({'id': newId});
      }

      return UserModel.fromJson(data);
    } catch (e) {
      print('FirestoreService.getUserByUid error: $e');
      return null;
    }
  }

  // ===================================================================
  // USERS — Firestore CRUD (giữ nguyên cho admin)
  // ===================================================================

  Future<UserModel?> getUserById(int id) async {
    // Document ID trong collection 'users' là Firebase uid (không phải id số nguyên)
    // Nên phải query theo trường 'id'
    final snap = await _db
        .collection('users')
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return UserModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final snap = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return UserModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
  }

  Future<UserModel> updateUser(UserModel user) async {
    final data = user.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();
    // Nếu có uid, dùng uid làm document ID (cách chuẩn)
    if (user.uid != null && user.uid!.isNotEmpty) {
      await _db.collection('users').doc(user.uid).update(data);
    } else {
      // Fallback: tìm theo trường 'id'
      final snap = await _db
          .collection('users')
          .where('id', isEqualTo: user.id)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update(data);
      }
    }
    return user;
  }

  Future<List<UserModel>> getAllUsers({String? searchQuery}) async {
    Query query = _db
        .collection('users')
        .orderBy('created_at', descending: true);
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = _db
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: searchQuery)
          .where('username', isLessThanOrEqualTo: '$searchQuery\uf8ff')
          .orderBy('created_at', descending: true);
    }
    final snap = await query.get();
    return snap.docs
        .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // ===================================================================
  // PROVINCES / GEOGRAPHY
  // ===================================================================

  Future<List<ProvinceModel>> fetchProvinces() async {
    final snap = await _db.collection('provinces').orderBy('name').get();
    return snap.docs
        .map((doc) => _mapDocToProvince(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProvinceModel>> fetchSpecialZones() async {
    final snap = await _db.collection('special_zones').orderBy('name').get();
    return snap.docs
        .map((doc) => _mapDocToProvince(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProvinceModel>> fetchCommunesForProvince(
    String provinceName,
  ) async {
    // Build a list of candidate names to try: exact name first, then stripped prefix
    final candidates = <String>{provinceName};
    for (final prefix in [
      'Tỉnh ',
      'Thành phố ',
      'Thành Phố ',
      'Đặc khu ',
      'Quận ',
      'Huyện ',
    ]) {
      if (provinceName.startsWith(prefix)) {
        candidates.add(provinceName.substring(prefix.length));
        break;
      }
    }

    // Try each candidate until we find results
    QuerySnapshot snap = await _db
        .collection('communes')
        .where('parent_name', isEqualTo: provinceName)
        .limit(1)
        .get();
    String matchedName = provinceName;
    for (final candidate in candidates) {
      snap = await _db
          .collection('communes')
          .where('parent_name', isEqualTo: candidate)
          .get();
      if (snap.docs.isNotEmpty) {
        matchedName = candidate;
        debugPrint(
          'DEBUG: Matched parent_name == "$candidate" for "$provinceName"',
        );
        break;
      }
    }

    // If all candidates failed, use the original name (snap will be empty)
    if (snap.docs.isEmpty) {
      debugPrint(
        'DEBUG: No communes found for any candidate for "$provinceName" (tried: ${candidates.join(", ")})',
      );
    }

    final results = snap.docs
        .map((doc) => _mapDocToProvince(doc.data() as Map<String, dynamic>))
        .toList();
    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }

  Future<List<Map<String, dynamic>>> fetchCalculatedDensities() async {
    // 🚀 Tối ưu: lấy từ provinces (34 docs) thay vì communes (10.000+ docs)
    // Mỗi province đã có sẵn population, area_km2, density trong Firestore
    final provinces = await fetchProvinces();
    final results = provinces
        .where((p) => p.population != null || p.areaKm2 != null)
        .map((p) {
          final pop = (p.population ?? 0).toDouble();
          final area = (p.areaKm2 ?? 0).toDouble();
          return {
            'name': p.name,
            'population': pop,
            'area': area,
            'density': area > 0 ? pop / area : 0,
            'key': getProvinceKey(p.name),
          };
        })
        .toList();
    results.sort(
      (a, b) => (b['density'] as double).compareTo(a['density'] as double),
    );
    return results;
  }

  /// Strip tất cả prefix tỉnh/thành phổ biến để so sánh
  String _stripProvincePrefix(String name) {
    String s = name.trim();
    for (final prefix in [
      'Tỉnh ',
      'Thành phố ',
      'Thành Phố ',
      'Đặc khu ',
      'TP. ',
      'Tp. ',
      'tp. ',
    ]) {
      if (s.startsWith(prefix)) {
        s = s.substring(prefix.length).trim();
        break;
      }
    }
    return s;
  }

  Future<List<HighSchool>> fetchHighSchoolsByCommuneName(
    String communeName, {
    String? provinceName,
  }) async {
    debugPrint(
      '🏫 [HS] communeName="$communeName", provinceName="$provinceName"',
    );

    // Chuẩn hóa tên tỉnh (strip prefix)
    final shortProvince = provinceName != null && provinceName.isNotEmpty
        ? _stripProvincePrefix(provinceName)
        : '';

    // Query 1: khớp chính xác tên phường/xã
    var snap = await _db
        .collection('high_schools')
        .where('ten_xa_phuong', isEqualTo: communeName)
        .get();
    debugPrint('🏫 [Q1 exact] "$communeName" → ${snap.docs.length} docs');
    for (final doc in snap.docs) {
      final d = doc.data();
      debugPrint(
        '  Q1: ten_tinh_tp="${d['ten_tinh_tp']}", ten_truong="${d['ten_truong']}"',
      );
    }

    // Query 2 (fallback): strip prefix Phường/Xã/Thị trấn nếu Q1 rỗng
    if (snap.docs.isEmpty) {
      String shortName = communeName;
      for (final prefix in ['Phường ', 'Xã ', 'Thị trấn ', 'Thị Trấn ']) {
        if (shortName.startsWith(prefix)) {
          shortName = shortName.substring(prefix.length);
          break;
        }
      }
      if (shortName != communeName) {
        snap = await _db
            .collection('high_schools')
            .where('ten_xa_phuong', isEqualTo: shortName)
            .get();
        debugPrint('🏫 [Q2 stripped] "$shortName" → ${snap.docs.length} docs');
      }
    }

    var results = snap.docs
        .map((doc) => HighSchool.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    // Lọc theo tỉnh: normalize CẢ HAI phía để tránh mismatch "TP. Đồng Nai" vs "Đồng Nai"
    if (shortProvince.isNotEmpty) {
      final before = results.length;
      results = results.where((s) {
        if (s.tenTinhTp == null) return true;
        final dbProvince = _stripProvincePrefix(s.tenTinhTp!);
        return dbProvince.toLowerCase() == shortProvince.toLowerCase();
      }).toList();
      debugPrint(
        '🏫 [province filter] "$shortProvince": $before → ${results.length}',
      );
    }

    debugPrint(
      '🏫 [FINAL] ${results.length} schools for "$communeName" in "$provinceName"',
    );
    results.sort((a, b) => (a.tenTruong ?? '').compareTo(b.tenTruong ?? ''));

    return results;
  }

  /// Chuẩn hóa chuỗi: bỏ dấu tiếng Việt, chuyển lowercase để so sánh không phân biệt dấu
  String _normalizeVietnamese(String s) {
    var str = s.toLowerCase();
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
    accentMap.forEach((k, v) => str = str.replaceAll(k, v));
    return str;
  }

  Future<List<SearchResult>> searchLocations(String query) async {
    if (query.trim().isEmpty) return [];
    final q = _normalizeVietnamese(query.trim());
    final results = <SearchResult>[];

    // Provinces: chỉ 63 doc — fetch hết và filter client-side
    final provSnap = await _db.collection('provinces').get();
    for (final doc in provSnap.docs) {
      final model = _mapDocToProvince(doc.data() as Map<String, dynamic>);
      if (_normalizeVietnamese(model.name).contains(q)) {
        results.add(
          SearchResult(name: model.name, type: 'province', model: model),
        );
        if (results.where((r) => r.type == 'province').length >= 5) break;
      }
    }

    // Special zones
    final zoneSnap = await _db.collection('special_zones').get();
    for (final doc in zoneSnap.docs) {
      final model = _mapDocToProvince(doc.data() as Map<String, dynamic>);
      if (_normalizeVietnamese(model.name).contains(q)) {
        results.add(
          SearchResult(name: model.name, type: 'special_zone', model: model),
        );
        if (results.where((r) => r.type == 'special_zone').length >= 3) break;
      }
    }

    // Communes: giới hạn 300 doc để tránh đọc toàn bộ collection
    final comSnap = await _db.collection('communes').limit(300).get();
    int comCount = 0;
    for (final doc in comSnap.docs) {
      final model = _mapDocToProvince(doc.data() as Map<String, dynamic>);
      if (_normalizeVietnamese(model.name).contains(q)) {
        results.add(
          SearchResult(
            name: '${model.name} (${model.parentTen ?? ''})',
            type: 'commune',
            model: model,
          ),
        );
        comCount++;
        if (comCount >= 8) break;
      }
    }

    return results;
  }

  // ===================================================================
  // ADDRESS DROPDOWN DATA
  // ===================================================================

  Future<List<String>> fetchDistinctNeighborhoods() async {
    final snap = await _db.collection('households').get();
    final set = <String>{};
    for (final doc in snap.docs) {
      final n = doc.data()['neighborhood']?.toString() ?? '';
      if (n.isNotEmpty) set.add(n);
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<List<String>> fetchDistinctWards() async {
    final snap = await _db
        .collection('communes')
        .where('name', isNotEqualTo: 'nan')
        .orderBy('name')
        .get();
    return snap.docs
        .map((doc) => doc.data()['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<List<String>> fetchCommunesForProvinceName(String provinceName) async {
    // Build candidates list: exact name first, then stripped prefix
    final candidates = <String>{provinceName};
    for (final prefix in [
      'Tỉnh ',
      'Thành phố ',
      'Thành Phố ',
      'Đặc khu ',
      'Quận ',
      'Huyện ',
    ]) {
      if (provinceName.startsWith(prefix)) {
        candidates.add(provinceName.substring(prefix.length));
        break;
      }
    }

    // Try querying exact name first
    QuerySnapshot snap = await _db
        .collection('communes')
        .where('parent_name', isEqualTo: provinceName)
        .get();

    // If exact name returns no results, try other candidates (like stripped name)
    if (snap.docs.isEmpty) {
      for (final candidate in candidates) {
        if (candidate == provinceName) continue;
        snap = await _db
            .collection('communes')
            .where('parent_name', isEqualTo: candidate)
            .get();
        if (snap.docs.isNotEmpty) {
          debugPrint(
            'DEBUG (dropdown): Matched parent_name == "$candidate" for "$provinceName"',
          );
          break;
        }
      }
    }

    final results = snap.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['name']?.toString() ?? '';
        })
        .where((s) => s.isNotEmpty && s != 'nan')
        .toList();
    results.sort();
    return results;
  }

  Future<List<String>> fetchDistinctDistricts() async {
    final snap = await _db.collection('households').get();
    final set = <String>{};
    for (final doc in snap.docs) {
      final d = doc.data()['district']?.toString() ?? '';
      if (d.isNotEmpty) set.add(d);
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<List<Map<String, String>>> fetchDistinctCities() async {
    final snap = await _db.collection('provinces').orderBy('name').get();
    return snap.docs
        .map(
          (doc) => {
            'code': doc.data()['code']?.toString() ?? '',
            'name': doc.data()['name']?.toString() ?? '',
          },
        )
        .toList();
  }

  Future<List<String>> fetchCommunesForParentCode(String parentCode) async {
    final snap = await _db
        .collection('communes')
        .where('parent_code', isEqualTo: parentCode)
        .get();
    final results = snap.docs
        .map((doc) => doc.data()['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty && s != 'nan')
        .toList();
    results.sort();
    return results;
  }

  Future<List<String>> fetchNeighborhoodList() async {
    return fetchDistinctNeighborhoods();
  }

  // ===================================================================
  // HOUSEHOLD CRUD
  // ===================================================================

  /// Tìm household theo số điện thoại (dùng indexed query, nhanh hơn fetchHouseholdList)
  Future<Household?> fetchHouseholdByPhone(String phone) async {
    if (phone.trim().isEmpty) return null;
    final snap = await _db
        .collection('households')
        .where('phone', isEqualTo: phone.trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Household.fromJson(snap.docs.first.data() as Map<String, dynamic>);
  }

  Future<String> generateIncidentCode() async {
    final snap = await _db
        .collection('incidents')
        .orderBy('incident_code', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return 'SV-0001';
    final lastCode =
        snap.docs.first.data()['incident_code']?.toString() ?? 'SV-0000';
    final match = RegExp(r'^SV-(\d+)$').firstMatch(lastCode);
    if (match == null) return 'SV-0001';
    final lastNumber = int.parse(match.group(1)!);
    return 'SV-${(lastNumber + 1).toString().padLeft(4, '0')}';
  }

  Future<String> generateHouseholdCode() async {
    final snap = await _db
        .collection('households')
        .where('household_code', isGreaterThanOrEqualTo: 'HGD-')
        .where('household_code', isLessThanOrEqualTo: 'HGD-\uf8ff')
        .orderBy('household_code', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return 'HGD-0001';
    final lastCode =
        snap.docs.first.data()['household_code']?.toString() ?? 'HGD-0000';
    final match = RegExp(r'^HGD-(\d+)$').firstMatch(lastCode);
    if (match == null) return 'HGD-0001';
    final lastNumber = int.parse(match.group(1)!);
    return 'HGD-${(lastNumber + 1).toString().padLeft(4, '0')}';
  }

  Future<List<Household>> fetchHouseholdList({
    String? searchQuery,
    String? neighborhood,
    String? ward,
    int? createdBy,
    int limit = 50,
    int offset = 0,
  }) async {
    // Tải toàn bộ households để thực hiện lọc và sắp xếp in-memory nhằm tránh lỗi yêu cầu Composite Index của Firestore
    final snap = await _db.collection('households').get();
    var households = snap.docs
        .map((doc) => Household.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    // Lọc theo neighborhood
    if (neighborhood != null && neighborhood.isNotEmpty) {
      households = households
          .where((h) => h.neighborhood == neighborhood)
          .toList();
    }
    // Lọc theo ward
    if (ward != null && ward.isNotEmpty) {
      households = households.where((h) => h.ward == ward).toList();
    }
    // Lọc theo created_by
    if (createdBy != null) {
      households = households.where((h) => h.createdBy == createdBy).toList();
    }

    // Lọc theo searchQuery
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      households = households.where((h) {
        return (h.headOfHousehold.toLowerCase().contains(q)) ||
            (h.householdCode.toLowerCase().contains(q)) ||
            (h.phone?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Sắp xếp theo created_at giảm dần
    households.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    final total = households.length;
    if (offset >= total) return [];
    final end = (offset + limit > total) ? total : offset + limit;
    return households.sublist(offset, end);
  }

  Future<Household?> fetchHouseholdById(int id) async {
    final doc = await _db.collection('households').doc(id.toString()).get();
    if (!doc.exists) return null;
    return Household.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<Household> createHousehold(Household household) async {
    final id = await _nextId('households');
    final code = await generateHouseholdCode();
    final map = household.toDbMap();
    map['id'] = id;
    map['household_code'] = code;
    map['created_at'] = DateTime.now().toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();
    await _setWithId('households', id, map);
    return Household.fromJson(map);
  }

  Future<Household> updateHousehold(Household household) async {
    final map = household.toDbMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    await _db.collection('households').doc(household.id.toString()).update(map);
    return household;
  }

  Future<void> deleteHousehold(int id) async {
    await _db.collection('households').doc(id.toString()).delete();
  }

  Future<List<Household>> fetchHouseholdsByCommuneName(
    String communeName,
  ) async {
    final snap = await _db
        .collection('households')
        .where('ward', isEqualTo: communeName)
        .get();
    final results = snap.docs
        .map((doc) => Household.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
    results.sort(
      (a, b) => (a.householdCode ?? '').compareTo(b.householdCode ?? ''),
    );
    return results;
  }

  Future<List<Household>> fetchHouseholdsByWard(String ward) async {
    return fetchHouseholdsByCommuneName(ward);
  }

  Future<int> countHouseholds({
    String? searchQuery,
    String? neighborhood,
    String? ward,
    int? createdBy,
  }) async {
    final snap = await _db.collection('households').count().get();
    return snap.count ?? 0;
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
    // Tải toàn bộ incidents để thực hiện lọc và sắp xếp in-memory nhằm tránh lỗi yêu cầu Composite Index của Firestore
    final snap = await _db.collection('incidents').get();
    var incidents = snap.docs
        .map((doc) => Incident.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    // Lọc theo status
    if (status != null && status.isNotEmpty) {
      incidents = incidents.where((i) => i.status.dbValue == status).toList();
    }
    // Lọc theo neighborhood
    if (neighborhood != null && neighborhood.isNotEmpty) {
      incidents = incidents
          .where((i) => i.neighborhood == neighborhood)
          .toList();
    }
    // Lọc theo ward
    if (ward != null && ward.isNotEmpty) {
      incidents = incidents.where((i) => i.ward == ward).toList();
    }
    // Lọc theo household_id
    if (householdId != null) {
      incidents = incidents.where((i) => i.householdId == householdId).toList();
    }
    // Lọc theo created_by (người tạo)
    if (createdBy != null) {
      incidents = incidents.where((i) => i.createdBy == createdBy).toList();
    }

    // Lọc theo searchQuery
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      incidents = incidents.where((inc) {
        return (inc.title.toLowerCase().contains(q)) ||
            (inc.incidentCode.toLowerCase().contains(q)) ||
            (inc.headOfHousehold?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Sắp xếp theo created_at giảm dần
    incidents.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    final total = incidents.length;
    if (offset >= total) return [];
    final end = (offset + limit > total) ? total : offset + limit;
    return incidents.sublist(offset, end);
  }

  Future<Incident?> fetchIncidentById(int id) async {
    final doc = await _db.collection('incidents').doc(id.toString()).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
    final hhId = data['household_id'] as int?;
    if (hhId != null) {
      final hhDoc = await _db
          .collection('households')
          .doc(hhId.toString())
          .get();
      if (hhDoc.exists) {
        final hhData = hhDoc.data() as Map<String, dynamic>;
        data['household_name'] = hhData['head_of_household'];
        data['household_phone'] = hhData['phone'];
      }
    }
    return Incident.fromJson(data);
  }

  Future<Incident> createIncident(Incident incident) async {
    final id = await _nextId('incidents');
    final map = incident.toDbMap();
    map['id'] = id;
    final code = incident.incidentCode ?? await generateIncidentCode();
    map['incident_code'] = code;
    map['created_at'] = DateTime.now().toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();
    await _setWithId('incidents', id, map);
    final result = Incident.fromJson(map);

    // 🔔 Notify all admins: incident_created
    final adminIds = await _getAdminUserIds();
    final createdBy = result.createdBy;
    for (final adminId in adminIds) {
      // Don't notify the creator if they are an admin themselves
      if (adminId == createdBy) continue;
      await _addNotification(
        type: 'incident_created',
        title: 'Sự vụ mới: $code',
        body: 'Sự vụ "${result.title}" vừa được tạo bởi user #$createdBy',
        targetUserId: adminId,
        actorUserId: createdBy,
        relatedId: id,
        relatedCode: code,
      );
    }

    return result;
  }

  Future<Incident> updateIncident(Incident incident, {int? updatedBy}) async {
    // Fetch old incident data to compare changes
    final oldDoc = await _db
        .collection('incidents')
        .doc(incident.id.toString())
        .get();

    final oldData = oldDoc.data();
    final oldStatus = oldData?['status']?.toString() ?? '';
    final oldCreatedByRaw = oldData?['created_by'];
    final int? oldCreatedBy;
    if (oldCreatedByRaw is int) {
      oldCreatedBy = oldCreatedByRaw;
    } else {
      oldCreatedBy = int.tryParse('${oldCreatedByRaw}');
    }
    final oldCode = oldData?['incident_code']?.toString() ?? '';

    final map = Map<String, dynamic>.from(incident.toDbMap());
    map.remove('id');
    map.remove('incident_code');
    map.remove('created_by');
    map.remove('created_at');
    map['updated_at'] = DateTime.now().toIso8601String();
    await _db.collection('incidents').doc(incident.id.toString()).update(map);

    final newStatus = incident.status.dbValue;

    // 🔔 Luồng thông báo cập nhật sự vụ:
    // - Trạng thái thay đổi (admin cập nhật status) → thông báo tới người tạo sự vụ
    // - Thông tin khác thay đổi (user tự cập nhật) → thông báo tới chính người cập nhật
    if (oldStatus != newStatus) {
      // Admin thay đổi status → người tạo sự vụ nhận thông báo
      if (oldCreatedBy != null) {
        await _addNotification(
          type: 'incident_status_changed',
          title: 'Sự vụ #$oldCode: $newStatus',
          body:
              'Sự vụ "${incident.title}" đã chuyển sang trạng thái "$newStatus"',
          targetUserId: oldCreatedBy,
          actorUserId: updatedBy,
          relatedId: incident.id,
          relatedCode: oldCode,
        );
      }
    } else {
      // User cập nhật thông tin khác → chính người cập nhật nhận thông báo
      if (updatedBy != null) {
        await _addNotification(
          type: 'incident_updated',
          title: 'Sự vụ #$oldCode đã được cập nhật',
          body: 'Sự vụ "${incident.title}" vừa được chỉnh sửa',
          targetUserId: updatedBy,
          actorUserId: updatedBy,
          relatedId: incident.id,
          relatedCode: oldCode,
        );
      }
    }

    return incident;
  }

  Future<void> deleteIncident(int id, {int? deletedBy}) async {
    // Fetch old incident data before deleting
    final oldDoc = await _db.collection('incidents').doc(id.toString()).get();
    final oldData = oldDoc.data();
    final oldCode = oldData?['incident_code']?.toString() ?? '';
    final oldTitle = oldData?['title']?.toString() ?? '';

    await _db.collection('incidents').doc(id.toString()).delete();

    // 🔔 Luồng xóa sự vụ: chỉ thông báo tới chính người thực hiện xóa
    if (deletedBy != null) {
      await _addNotification(
        type: 'incident_deleted',
        title: 'Sự vụ #$oldCode đã bị xoá',
        body: 'Sự vụ "$oldTitle" (mã $oldCode) đã bị xoá khỏi hệ thống',
        targetUserId: deletedBy,
        actorUserId: deletedBy,
        relatedId: id,
        relatedCode: oldCode,
      );
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
    final snap = await _db.collection('incidents').count().get();
    return snap.count ?? 0;
  }

  // ===================================================================
  // DIA DIEM LICH SU CRUD
  // ===================================================================

  Future<List<DiaDiemLichSu>> fetchDiaDiemLichSuList({
    String? searchQuery,
  }) async {
    Query query = _db
        .collection('dia_diem_lich_su')
        .orderBy('created_at', descending: true);
    final snap = await query.get();
    var items = snap.docs
        .map(
          (doc) => DiaDiemLichSu.fromJson(doc.data() as Map<String, dynamic>),
        )
        .toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      items = items.where((item) {
        return (item.ten?.toLowerCase().contains(q) ?? false) ||
            (item.loaiDiTich?.toLowerCase().contains(q) ?? false) ||
            (item.diaChi?.toLowerCase().contains(q) ?? false) ||
            (item.thoiKy?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return items;
  }

  Future<DiaDiemLichSu?> fetchDiaDiemLichSuById(int id) async {
    final doc = await _db
        .collection('dia_diem_lich_su')
        .doc(id.toString())
        .get();
    if (!doc.exists) return null;
    return DiaDiemLichSu.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<DiaDiemLichSu> createDiaDiemLichSu(DiaDiemLichSu item) async {
    final map = item.toJson();
    map['created_at'] = DateTime.now().toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();

    // 🐛 Fix bug "lưu được 2 cái, cái thứ 3 mất cái đầu":
    // Gộp counter increment + tạo document trong 1 transaction atomic
    // để tránh race condition: counter cho ID=1 nhưng doc/1 đã tồn tại
    // (do double-tap, retry, hoặc đồng bộ nhiều thiết bị)
    final id = await _db.runTransaction((transaction) async {
      final counterRef = _db.collection('counters').doc('dia_diem_lich_su');
      final counterDoc = await transaction.get(counterRef);
      final currentId = (!counterDoc.exists
          ? 0
          : (counterDoc.data()?['current_id'] as num?)?.toInt() ?? 0);
      final nextId = currentId + 1;
      transaction.set(counterRef, {'current_id': nextId});

      final docRef = _db.collection('dia_diem_lich_su').doc(nextId.toString());
      map['id'] = nextId;
      transaction.set(docRef, map);
      return nextId;
    });

    return DiaDiemLichSu.fromJson(map);
  }

  Future<DiaDiemLichSu> updateDiaDiemLichSu(DiaDiemLichSu item) async {
    final map = Map<String, dynamic>.from(item.toJson());
    map.remove('id');
    map.remove('created_at');
    map['updated_at'] = DateTime.now().toIso8601String();
    await _db
        .collection('dia_diem_lich_su')
        .doc(item.id.toString())
        .update(map);
    return item;
  }

  Future<void> deleteDiaDiemLichSu(int id) async {
    await _db.collection('dia_diem_lich_su').doc(id.toString()).delete();
  }

  // ===================================================================
  // STATISTICS
  // ===================================================================

  Future<Map<String, int>> statisticsIncidentsByMonth(int year) async {
    final snap = await _db.collection('incidents').get();
    final Map<String, int> result = {};
    for (int i = 1; i <= 12; i++) {
      result['Month $i'] = 0;
    }
    for (final doc in snap.docs) {
      final data = doc.data();
      final createdAtStr = data['created_at']?.toString();
      if (createdAtStr == null) continue;
      final dt = DateTime.tryParse(createdAtStr);
      if (dt == null || dt.year != year) continue;
      result['Month ${dt.month}'] = (result['Month ${dt.month}'] ?? 0) + 1;
    }
    return result;
  }

  Future<Map<String, int>> statisticsIncidentsByNeighborhood() async {
    final snap = await _db.collection('incidents').get();
    final Map<String, int> result = {};
    for (final doc in snap.docs) {
      final neighborhood = doc.data()['neighborhood']?.toString() ?? 'Unknown';
      result[neighborhood] = (result[neighborhood] ?? 0) + 1;
    }
    return result;
  }

  Future<Map<String, int>> statisticsIncidentsByStatus() async {
    final snap = await _db.collection('incidents').get();
    final Map<String, int> result = {};
    for (final doc in snap.docs) {
      final status = doc.data()['status']?.toString() ?? 'received';
      final statusName = IncidentStatus.fromString(status).displayName;
      result[statusName] = (result[statusName] ?? 0) + 1;
    }
    return result;
  }

  // ===================================================================
  // KHU PHO CRUD
  // ===================================================================

  Future<List<KhuPhoModel>> fetchKhuPhos() async {
    final snap = await _db.collection('khu_pho').orderBy('ten_khu_pho').get();
    return snap.docs
        .map((doc) => KhuPhoModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<KhuPhoModel?> fetchKhuPhoById(int id) async {
    final doc = await _db.collection('khu_pho').doc(id.toString()).get();
    if (!doc.exists) return null;
    return KhuPhoModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<KhuPhoModel> createKhuPho(KhuPhoModel model) async {
    final id = await _nextId('khu_pho');
    final map = model.toJson();
    map['id'] = id;
    map['created_at'] = DateTime.now().toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();
    await _setWithId('khu_pho', id, map);
    return KhuPhoModel.fromJson(map);
  }

  Future<KhuPhoModel> updateKhuPho(KhuPhoModel model) async {
    final map = model.toJson();
    map['updated_at'] = DateTime.now().toIso8601String();
    await _db.collection('khu_pho').doc(model.id.toString()).update(map);
    return model;
  }

  Future<void> deleteKhuPho(int id) async {
    final daiDiens = await _db
        .collection('dai_dien_khu_pho')
        .where('khu_pho_id', isEqualTo: id)
        .get();
    for (final doc in daiDiens.docs) {
      await doc.reference.delete();
    }
    await _db.collection('khu_pho').doc(id.toString()).delete();
  }

  // ===================================================================
  // DAI DIEN KHU PHO CRUD
  // ===================================================================

  Future<List<DaiDienModel>> fetchDaiDiens() async {
    final snap = await _db
        .collection('dai_dien_khu_pho')
        .orderBy('ho_ten')
        .get();
    final list = <DaiDienModel>[];
    for (final doc in snap.docs) {
      final data = Map<String, dynamic>.from(
        doc.data() as Map<String, dynamic>,
      );
      final khuPhoId = data['khu_pho_id'] as int?;
      if (khuPhoId != null) {
        final kpDoc = await _db
            .collection('khu_pho')
            .doc(khuPhoId.toString())
            .get();
        if (kpDoc.exists) {
          data['ten_khu_pho'] =
              (kpDoc.data() as Map<String, dynamic>)['ten_khu_pho'];
        }
      }
      list.add(DaiDienModel.fromJson(data));
    }
    return list;
  }

  Future<List<DaiDienModel>> fetchDaiDiensByKhuPho(int khuPhoId) async {
    final snap = await _db
        .collection('dai_dien_khu_pho')
        .where('khu_pho_id', isEqualTo: khuPhoId)
        .orderBy('ho_ten')
        .get();
    final list = <DaiDienModel>[];
    for (final doc in snap.docs) {
      final data = Map<String, dynamic>.from(
        doc.data() as Map<String, dynamic>,
      );
      final kpDoc = await _db
          .collection('khu_pho')
          .doc(khuPhoId.toString())
          .get();
      if (kpDoc.exists) {
        data['ten_khu_pho'] =
            (kpDoc.data() as Map<String, dynamic>)['ten_khu_pho'];
      }
      list.add(DaiDienModel.fromJson(data));
    }
    return list;
  }

  Future<DaiDienModel?> fetchDaiDienById(int id) async {
    final doc = await _db
        .collection('dai_dien_khu_pho')
        .doc(id.toString())
        .get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
    final khuPhoId = data['khu_pho_id'] as int?;
    if (khuPhoId != null) {
      final kpDoc = await _db
          .collection('khu_pho')
          .doc(khuPhoId.toString())
          .get();
      if (kpDoc.exists) {
        data['ten_khu_pho'] =
            (kpDoc.data() as Map<String, dynamic>)['ten_khu_pho'];
      }
    }
    return DaiDienModel.fromJson(data);
  }

  Future<DaiDienModel> createDaiDien(DaiDienModel model) async {
    final id = await _nextId('dai_dien_khu_pho');
    final map = model.toJson();
    map['id'] = id;
    map['created_at'] = DateTime.now().toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();
    await _setWithId('dai_dien_khu_pho', id, map);
    return (await fetchDaiDienById(id))!;
  }

  Future<DaiDienModel> updateDaiDien(DaiDienModel model) async {
    final map = model.toJson();
    map['updated_at'] = DateTime.now().toIso8601String();
    await _db
        .collection('dai_dien_khu_pho')
        .doc(model.id.toString())
        .update(map);
    return (await fetchDaiDienById(model.id!))!;
  }

  Future<void> deleteDaiDien(int id) async {
    await _db.collection('dai_dien_khu_pho').doc(id.toString()).delete();
  }

  Future<List<DaiDienModel>> searchDaiDiens(String query) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    final snap = await _db.collection('dai_dien_khu_pho').get();
    final filtered = <DaiDienModel>[];
    for (final doc in snap.docs) {
      final data = Map<String, dynamic>.from(
        doc.data() as Map<String, dynamic>,
      );
      final hoTen = (data['ho_ten']?.toString() ?? '').toLowerCase();
      final soDienThoai = (data['so_dien_thoai']?.toString() ?? '')
          .toLowerCase();
      final email = (data['email']?.toString() ?? '').toLowerCase();
      if (hoTen.contains(q) || soDienThoai.contains(q) || email.contains(q)) {
        final khuPhoId = data['khu_pho_id'] as int?;
        if (khuPhoId != null) {
          final kpDoc = await _db
              .collection('khu_pho')
              .doc(khuPhoId.toString())
              .get();
          if (kpDoc.exists) {
            data['ten_khu_pho'] =
                (kpDoc.data() as Map<String, dynamic>)['ten_khu_pho'];
          }
        }
        filtered.add(DaiDienModel.fromJson(data));
      }
    }
    filtered.sort((a, b) => a.hoTen.compareTo(b.hoTen));
    return filtered;
  }

  // ===================================================================
  // HOUSEHOLD REQUESTS CRUD
  // ===================================================================

  Future<HouseholdRequest> createHouseholdRequest(
    HouseholdRequest request,
  ) async {
    final id = await _nextId('household_requests');
    final map = request.toJson();
    map['id'] = id;
    map['created_at'] = DateTime.now().toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();
    await _setWithId('household_requests', id, map);
    final result = HouseholdRequest.fromJson(map);

    // 🔔 Notify all admins: request_created
    final adminIds = await _getAdminUserIds();
    for (final adminId in adminIds) {
      if (adminId == result.userId) continue;
      await _addNotification(
        type: 'request_created',
        title: 'Yêu cầu xác nhận hộ khẩu mới',
        body: 'Yêu cầu hộ khẩu mới từ user #${result.userId}',
        targetUserId: adminId,
        actorUserId: result.userId,
        relatedId: id,
        relatedCode: 'HR-$id',
      );
    }

    return result;
  }

  Future<List<HouseholdRequest>> fetchHouseholdRequests({
    String? status,
    int? userId,
  }) async {
    // Tải toàn bộ household_requests để thực hiện lọc và sắp xếp in-memory nhằm tránh lỗi yêu cầu Composite Index của Firestore
    final snap = await _db.collection('household_requests').get();
    var requests = snap.docs
        .map(
          (doc) =>
              HouseholdRequest.fromJson(doc.data() as Map<String, dynamic>),
        )
        .toList();

    // Lọc theo status
    if (status != null && status.isNotEmpty) {
      requests = requests.where((r) => r.status == status).toList();
    }
    // Lọc theo user_id
    if (userId != null) {
      requests = requests.where((r) => r.userId == userId).toList();
    }

    // Sắp xếp theo created_at giảm dần
    requests.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return requests;
  }

  Future<HouseholdRequest?> fetchHouseholdRequestById(int id) async {
    final doc = await _db
        .collection('household_requests')
        .doc(id.toString())
        .get();
    if (!doc.exists) return null;
    return HouseholdRequest.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<HouseholdRequest> updateHouseholdRequestStatus(
    int id,
    String status, {
    int? approvedBy,
    String? adminNote,
  }) async {
    // Fetch old request data before updating
    final oldDoc = await _db
        .collection('household_requests')
        .doc(id.toString())
        .get();
    final oldData = oldDoc.data();
    final userIdRaw = oldData?['user_id'];
    final int? userId;
    if (userIdRaw is int) {
      userId = userIdRaw;
    } else {
      userId = int.tryParse('${userIdRaw}');
    }

    final data = <String, dynamic>{
      'status': status,
      'admin_note': adminNote,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (approvedBy != null) data['approved_by'] = approvedBy;
    await _db.collection('household_requests').doc(id.toString()).update(data);
    final updated = (await fetchHouseholdRequestById(id))!;

    // 🔔 Notify the requester about the status change
    if (userId != null) {
      final title = status == 'approved'
          ? 'Yêu cầu xác nhận hộ khẩu đã được duyệt'
          : 'Yêu cầu xác nhận hộ khẩu đã bị từ chối';
      final body = status == 'approved'
          ? 'Yêu cầu hộ khẩu của bạn đã được phê duyệt thành công'
          : 'Yêu cầu hộ khẩu của bạn đã bị từ chối${adminNote != null ? '. Lý do: $adminNote' : ''}';
      await _addNotification(
        type: 'household_request_$status',
        title: title,
        body: body,
        targetUserId: userId,
        actorUserId: approvedBy,
        relatedId: id,
        relatedCode: 'HR-$id',
      );
    }

    return updated;
  }

  // ===================================================================
  // UTILITY
  // ===================================================================

  ProvinceModel _mapDocToProvince(Map<String, dynamic> data) {
    final properties = <String, dynamic>{
      'ten': data['name']?.toString(),
      'ma': data['code']?.toString(),
      'type': data['type']?.toString(),
      'area_km2': (data['area_km2'] as num?)?.toDouble(),
      'population': (data['population'] as num?)?.toInt(),
      'density': (data['density'] as num?)?.toDouble(),
      'capital': data['capital']?.toString(),
      'decree': data['decree']?.toString(),
      'macro_region': data['macro_region']?.toString(),
      'predecessors': data['predecessors']?.toString(),
      'parent_ma': data['parent_code']?.toString(),
      'parent_ten': data['parent_name']?.toString(),
    };
    // Pass raw data directly so ProvinceModel.fromJson can handle
    // both 'geometry' and 'geometry_json' keys as originally designed.
    return ProvinceModel.fromJson({...data, 'properties': properties});
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
    str = str.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    return str;
  }

  // ===================================================================
  // NOTIFICATION METHODS
  // ===================================================================

  /// Internal helper: create a notification document in Firestore
  Future<void> _addNotification({
    required String type,
    required String title,
    required String body,
    int? targetUserId,
    int? actorUserId,
    int? relatedId,
    String? relatedCode,
  }) async {
    try {
      final id = await _nextId('notifications');
      await _setWithId('notifications', id, {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'is_read': false,
        'target_user_id': targetUserId,
        'actor_user_id': actorUserId,
        'related_id': relatedId,
        'related_code': relatedCode,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('FirestoreService._addNotification error: $e');
    }
  }

  /// Public method: add a notification (can be called from anywhere)
  Future<void> addNotification({
    required String type,
    required String title,
    required String body,
    int? targetUserId,
    int? actorUserId,
    int? relatedId,
    String? relatedCode,
  }) {
    return _addNotification(
      type: type,
      title: title,
      body: body,
      targetUserId: targetUserId,
      actorUserId: actorUserId,
      relatedId: relatedId,
      relatedCode: relatedCode,
    );
  }

  /// Public getter for admin user IDs
  Future<List<int>> fetchAdminUserIds() => _getAdminUserIds();

  /// Get all admin user IDs for broadcasting notifications
  Future<List<int>> _getAdminUserIds() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();
    return snap.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['id'] is int
              ? data['id'] as int
              : int.tryParse('${data['id']}');
        })
        .where((id) => id != null)
        .cast<int>()
        .toList();
  }
}

/// Lớp SearchResult (giữ nguyên tương thích với code cũ)
class SearchResult {
  final String name;
  final String type;
  final ProvinceModel model;

  SearchResult({required this.name, required this.type, required this.model});
}
