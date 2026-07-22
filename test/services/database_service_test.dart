import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/models/high_school_model.dart';
import 'package:vietnam_geo_dashboard/models/household_model.dart';
import 'package:vietnam_geo_dashboard/models/incident_model.dart';
import 'package:vietnam_geo_dashboard/models/dia_diem_lich_su_model.dart';
import 'package:vietnam_geo_dashboard/models/khu_pho_model.dart';
import 'package:vietnam_geo_dashboard/models/dai_dien_model.dart';
import 'package:vietnam_geo_dashboard/models/user_model.dart';
import 'package:vietnam_geo_dashboard/models/household_request_model.dart';
import 'package:vietnam_geo_dashboard/services/database_service.dart';
import 'package:vietnam_geo_dashboard/services/firestore_service.dart';

import 'mock_helper.dart';

// ============================================================
// MOCK FIRESTORE SERVICE
// ============================================================

class MockFirestoreService extends Mock implements FirestoreService {}

// ============================================================
// SETUP
// ============================================================

/// Extension helper to turn a value into a Future (simulates async methods).
Future<T> _asyncValue<T>(T value) async => value;

void main() {
  late MockFirestoreService mockFirestore;
  late DatabaseService db;

  setUp(() {
    mockFirestore = MockFirestoreService();
    db = DatabaseService.withService(mockFirestore);
  });

  tearDown(() {
    reset(mockFirestore);
  });

  group('DatabaseService — delegation to FirestoreService', () {
    group('signInWithEmail', () {
      test('delegates to FirestoreService.signInWithEmail', () async {
        const email = 'test@example.com';
        const password = 'password123';
        final expectedUser = createTestUser();

        when(
          () => mockFirestore.signInWithEmail(email, password),
        ).thenAnswer((_) => _asyncValue(expectedUser));

        final result = await db.signInWithEmail(email, password);

        expect(result, expectedUser);
        verify(() => mockFirestore.signInWithEmail(email, password)).called(1);
      });

      test('returns null when sign-in fails', () async {
        when(
          () => mockFirestore.signInWithEmail(any(), any()),
        ).thenAnswer((_) => _asyncValue(null));

        final result = await db.signInWithEmail('x@y.z', 'wrong');

        expect(result, isNull);
      });
    });

    group('createUserWithAuth', () {
      test('delegates to FirestoreService.createUserWithAuth', () async {
        const email = 'new@example.com';
        const password = 'pass123';
        final user = createTestUser();
        final expectedUser = createTestUser(id: 2);

        when(
          () => mockFirestore.createUserWithAuth(email, password, user),
        ).thenAnswer((_) => _asyncValue(expectedUser));

        final result = await db.createUserWithAuth(email, password, user);

        expect(result, expectedUser);
        verify(
          () => mockFirestore.createUserWithAuth(email, password, user),
        ).called(1);
      });
    });

    group('changePasswordFirebase', () {
      test('delegates and returns true on success', () async {
        when(
          () => mockFirestore.changePasswordFirebase(any()),
        ).thenAnswer((_) => _asyncValue(true));

        final result = await db.changePasswordFirebase('newPass');

        expect(result, isTrue);
        verify(() => mockFirestore.changePasswordFirebase('newPass')).called(1);
      });

      test('returns false on failure', () async {
        when(
          () => mockFirestore.changePasswordFirebase(any()),
        ).thenAnswer((_) => _asyncValue(false));

        final result = await db.changePasswordFirebase('newPass');

        expect(result, isFalse);
      });
    });

    group('sendPasswordResetEmail', () {
      test('delegates and returns true on success', () async {
        when(
          () => mockFirestore.sendPasswordResetEmail(any()),
        ).thenAnswer((_) => _asyncValue(true));

        final result = await db.sendPasswordResetEmail('test@example.com');

        expect(result, isTrue);
        verify(
          () => mockFirestore.sendPasswordResetEmail('test@example.com'),
        ).called(1);
      });
    });

    group('getUserByUid', () {
      test('delegates to FirestoreService.getUserByUid', () async {
        const uid = 'firebase-uid-1';
        final expectedUser = createTestUser();

        when(
          () => mockFirestore.getUserByUid(uid),
        ).thenAnswer((_) => _asyncValue(expectedUser));

        final result = await db.getUserByUid(uid);

        expect(result, expectedUser);
        verify(() => mockFirestore.getUserByUid(uid)).called(1);
      });
    });

    group('getUserById', () {
      test('delegates to FirestoreService.getUserById', () async {
        const id = 42;
        final expectedUser = createTestUser(id: id);

        when(
          () => mockFirestore.getUserById(id),
        ).thenAnswer((_) => _asyncValue(expectedUser));

        final result = await db.getUserById(id);

        expect(result, expectedUser);
        verify(() => mockFirestore.getUserById(id)).called(1);
      });
    });

    group('getUserByUsername', () {
      test('delegates to FirestoreService.getUserByUsername', () async {
        const username = 'admin';
        final expectedUser = createTestUser(username: username);

        when(
          () => mockFirestore.getUserByUsername(username),
        ).thenAnswer((_) => _asyncValue(expectedUser));

        final result = await db.getUserByUsername(username);

        expect(result, expectedUser);
        verify(() => mockFirestore.getUserByUsername(username)).called(1);
      });
    });

    group('updateUser', () {
      test('delegates to FirestoreService.updateUser', () async {
        final user = createTestUser();
        final updatedUser = createTestUser(fullName: 'Updated Name');

        when(
          () => mockFirestore.updateUser(user),
        ).thenAnswer((_) => _asyncValue(updatedUser));

        final result = await db.updateUser(user);

        expect(result, updatedUser);
        verify(() => mockFirestore.updateUser(user)).called(1);
      });
    });

    group('getAllUsers', () {
      test('delegates without searchQuery', () async {
        final users = [
          createTestUser(),
          createTestUser(id: 2, username: 'user2'),
        ];

        when(
          () => mockFirestore.getAllUsers(searchQuery: null),
        ).thenAnswer((_) => _asyncValue(users));

        final result = await db.getAllUsers();

        expect(result, users);
        verify(() => mockFirestore.getAllUsers(searchQuery: null)).called(1);
      });

      test('delegates with searchQuery', () async {
        const query = 'admin';

        when(
          () => mockFirestore.getAllUsers(searchQuery: query),
        ).thenAnswer((_) => _asyncValue(<UserModel>[]));

        await db.getAllUsers(searchQuery: query);

        verify(() => mockFirestore.getAllUsers(searchQuery: query)).called(1);
      });
    });

    group('fetchProvinces', () {
      test('delegates to FirestoreService.fetchProvinces', () async {
        final provinces = [createTestProvince()];

        when(
          () => mockFirestore.fetchProvinces(),
        ).thenAnswer((_) => _asyncValue(provinces));

        final result = await db.fetchProvinces();

        expect(result, provinces);
        verify(() => mockFirestore.fetchProvinces()).called(1);
      });
    });

    group('fetchSpecialZones', () {
      test('delegates to FirestoreService.fetchSpecialZones', () async {
        final zones = [
          createTestProvince(name: 'Đặc khu Hành chính Kinh tế Vũng Tàu'),
        ];

        when(
          () => mockFirestore.fetchSpecialZones(),
        ).thenAnswer((_) => _asyncValue(zones));

        final result = await db.fetchSpecialZones();

        expect(result, zones);
        verify(() => mockFirestore.fetchSpecialZones()).called(1);
      });
    });

    group('fetchCommunesForProvince', () {
      test('delegates with provinceName', () async {
        const provinceName = 'TP. Hồ Chí Minh';
        final communes = [
          createTestProvince(name: 'Quận 1'),
          createTestProvince(name: 'Quận 2'),
        ];

        when(
          () => mockFirestore.fetchCommunesForProvince(provinceName),
        ).thenAnswer((_) => _asyncValue(communes));

        final result = await db.fetchCommunesForProvince(provinceName);

        expect(result, communes);
        verify(
          () => mockFirestore.fetchCommunesForProvince(provinceName),
        ).called(1);
      });
    });

    group('fetchCalculatedDensities', () {
      test('delegates to FirestoreService.fetchCalculatedDensities', () async {
        final densities = [
          {'name': 'TP. Hồ Chí Minh', 'density': 4364.0},
        ];

        when(
          () => mockFirestore.fetchCalculatedDensities(),
        ).thenAnswer((_) => _asyncValue(densities));

        final result = await db.fetchCalculatedDensities();

        expect(result, densities);
        verify(() => mockFirestore.fetchCalculatedDensities()).called(1);
      });
    });

    group('fetchHighSchoolsByCommuneName', () {
      test('delegates without provinceName', () async {
        const communeName = 'Phường 1';
        final schools = [createTestHighSchool()];

        when(
          () => mockFirestore.fetchHighSchoolsByCommuneName(
            communeName,
            provinceName: null,
          ),
        ).thenAnswer((_) => _asyncValue(schools));

        final result = await db.fetchHighSchoolsByCommuneName(communeName);

        expect(result, schools);
        verify(
          () => mockFirestore.fetchHighSchoolsByCommuneName(
            communeName,
            provinceName: null,
          ),
        ).called(1);
      });

      test('delegates with provinceName', () async {
        const communeName = 'Phường 1';
        const provinceName = 'TP. Hồ Chí Minh';
        final schools = [createTestHighSchool()];

        when(
          () => mockFirestore.fetchHighSchoolsByCommuneName(
            communeName,
            provinceName: provinceName,
          ),
        ).thenAnswer((_) => _asyncValue(schools));

        final result = await db.fetchHighSchoolsByCommuneName(
          communeName,
          provinceName: provinceName,
        );

        expect(result, schools);
        verify(
          () => mockFirestore.fetchHighSchoolsByCommuneName(
            communeName,
            provinceName: provinceName,
          ),
        ).called(1);
      });
    });

    group('searchLocations', () {
      test('delegates to FirestoreService.searchLocations', () async {
        const query = 'Hồ Chí Minh';
        final results = [
          SearchResult(
            name: 'TP. Hồ Chí Minh',
            type: 'province',
            model: createTestProvince(),
          ),
        ];

        when(
          () => mockFirestore.searchLocations(query),
        ).thenAnswer((_) => _asyncValue(results));

        final result = await db.searchLocations(query);

        expect(result, results);
        verify(() => mockFirestore.searchLocations(query)).called(1);
      });
    });

    group('fetchDistinctNeighborhoods', () {
      test(
        'delegates to FirestoreService.fetchDistinctNeighborhoods',
        () async {
          final neighborhoods = ['Khu phố 1', 'Khu phố 2'];

          when(
            () => mockFirestore.fetchDistinctNeighborhoods(),
          ).thenAnswer((_) => _asyncValue(neighborhoods));

          final result = await db.fetchDistinctNeighborhoods();

          expect(result, neighborhoods);
          verify(() => mockFirestore.fetchDistinctNeighborhoods()).called(1);
        },
      );
    });

    group('fetchDistinctWards', () {
      test('delegates to FirestoreService.fetchDistinctWards', () async {
        final wards = ['Phường 1', 'Phường 2'];

        when(
          () => mockFirestore.fetchDistinctWards(),
        ).thenAnswer((_) => _asyncValue(wards));

        final result = await db.fetchDistinctWards();

        expect(result, wards);
        verify(() => mockFirestore.fetchDistinctWards()).called(1);
      });
    });

    group('fetchCommunesForProvinceName', () {
      test('delegates with provinceName', () async {
        const provinceName = 'TP. Hồ Chí Minh';
        final communes = ['Quận 1', 'Quận 2'];

        when(
          () => mockFirestore.fetchCommunesForProvinceName(provinceName),
        ).thenAnswer((_) => _asyncValue(communes));

        final result = await db.fetchCommunesForProvinceName(provinceName);

        expect(result, communes);
        verify(
          () => mockFirestore.fetchCommunesForProvinceName(provinceName),
        ).called(1);
      });
    });

    group('fetchDistinctDistricts', () {
      test('delegates to FirestoreService.fetchDistinctDistricts', () async {
        final districts = ['Quận 1', 'Quận 2'];

        when(
          () => mockFirestore.fetchDistinctDistricts(),
        ).thenAnswer((_) => _asyncValue(districts));

        final result = await db.fetchDistinctDistricts();

        expect(result, districts);
        verify(() => mockFirestore.fetchDistinctDistricts()).called(1);
      });
    });

    group('fetchDistinctCities', () {
      test('delegates to FirestoreService.fetchDistinctCities', () async {
        final cities = [
          {'code': '79', 'name': 'TP. Hồ Chí Minh'},
        ];

        when(
          () => mockFirestore.fetchDistinctCities(),
        ).thenAnswer((_) => _asyncValue(cities));

        final result = await db.fetchDistinctCities();

        expect(result, cities);
        verify(() => mockFirestore.fetchDistinctCities()).called(1);
      });
    });

    group('fetchCommunesForParentCode', () {
      test('delegates with parentCode', () async {
        const parentCode = '79';
        final communes = ['Quận 1', 'Quận 2'];

        when(
          () => mockFirestore.fetchCommunesForParentCode(parentCode),
        ).thenAnswer((_) => _asyncValue(communes));

        final result = await db.fetchCommunesForParentCode(parentCode);

        expect(result, communes);
        verify(
          () => mockFirestore.fetchCommunesForParentCode(parentCode),
        ).called(1);
      });
    });

    group('fetchNeighborhoodList', () {
      test('delegates to FirestoreService.fetchNeighborhoodList', () async {
        final neighborhoods = ['Khu phố 1', 'Khu phố 2'];

        when(
          () => mockFirestore.fetchNeighborhoodList(),
        ).thenAnswer((_) => _asyncValue(neighborhoods));

        final result = await db.fetchNeighborhoodList();

        expect(result, neighborhoods);
        verify(() => mockFirestore.fetchNeighborhoodList()).called(1);
      });
    });

    group('generateIncidentCode', () {
      test('delegates to FirestoreService.generateIncidentCode', () async {
        when(
          () => mockFirestore.generateIncidentCode(),
        ).thenAnswer((_) => _asyncValue('SV-0001'));

        final result = await db.generateIncidentCode();

        expect(result, 'SV-0001');
        verify(() => mockFirestore.generateIncidentCode()).called(1);
      });
    });

    group('generateHouseholdCode', () {
      test('delegates to FirestoreService.generateHouseholdCode', () async {
        when(
          () => mockFirestore.generateHouseholdCode(),
        ).thenAnswer((_) => _asyncValue('HGD-0001'));

        final result = await db.generateHouseholdCode();

        expect(result, 'HGD-0001');
        verify(() => mockFirestore.generateHouseholdCode()).called(1);
      });
    });

    group('fetchHouseholdByPhone', () {
      test('delegates with phone', () async {
        const phone = '0909123456';
        final household = createTestHousehold();

        when(
          () => mockFirestore.fetchHouseholdByPhone(phone),
        ).thenAnswer((_) => _asyncValue(household));

        final result = await db.fetchHouseholdByPhone(phone);

        expect(result, household);
        verify(() => mockFirestore.fetchHouseholdByPhone(phone)).called(1);
      });

      test('returns null when not found', () async {
        when(
          () => mockFirestore.fetchHouseholdByPhone(any()),
        ).thenAnswer((_) => _asyncValue(null));

        final result = await db.fetchHouseholdByPhone('0000000000');

        expect(result, isNull);
      });
    });

    group('fetchHouseholdList', () {
      test('delegates with default params', () async {
        final households = [createTestHousehold()];

        when(
          () => mockFirestore.fetchHouseholdList(
            searchQuery: null,
            neighborhood: null,
            ward: null,
            createdBy: null,
            limit: 50,
            offset: 0,
          ),
        ).thenAnswer((_) => _asyncValue(households));

        final result = await db.fetchHouseholdList();

        expect(result, households);
        verify(
          () => mockFirestore.fetchHouseholdList(
            searchQuery: null,
            neighborhood: null,
            ward: null,
            createdBy: null,
            limit: 50,
            offset: 0,
          ),
        ).called(1);
      });

      test('delegates with filters', () async {
        when(
          () => mockFirestore.fetchHouseholdList(
            searchQuery: 'Nguyễn',
            neighborhood: 'Khu phố 1',
            ward: 'Phường 1',
            createdBy: 1,
            limit: 10,
            offset: 20,
          ),
        ).thenAnswer((_) => _asyncValue(<Household>[]));

        await db.fetchHouseholdList(
          searchQuery: 'Nguyễn',
          neighborhood: 'Khu phố 1',
          ward: 'Phường 1',
          createdBy: 1,
          limit: 10,
          offset: 20,
        );

        verify(
          () => mockFirestore.fetchHouseholdList(
            searchQuery: 'Nguyễn',
            neighborhood: 'Khu phố 1',
            ward: 'Phường 1',
            createdBy: 1,
            limit: 10,
            offset: 20,
          ),
        ).called(1);
      });
    });

    group('fetchHouseholdById', () {
      test('delegates with id', () async {
        const id = 1;
        final household = createTestHousehold();

        when(
          () => mockFirestore.fetchHouseholdById(id),
        ).thenAnswer((_) => _asyncValue(household));

        final result = await db.fetchHouseholdById(id);

        expect(result, household);
        verify(() => mockFirestore.fetchHouseholdById(id)).called(1);
      });
    });

    group('createHousehold', () {
      test('delegates to FirestoreService.createHousehold', () async {
        final household = createTestHousehold();
        final createdHousehold = createTestHousehold(id: 2);

        when(
          () => mockFirestore.createHousehold(household),
        ).thenAnswer((_) => _asyncValue(createdHousehold));

        final result = await db.createHousehold(household);

        expect(result, createdHousehold);
        verify(() => mockFirestore.createHousehold(household)).called(1);
      });
    });

    group('updateHousehold', () {
      test('delegates to FirestoreService.updateHousehold', () async {
        final household = createTestHousehold();

        when(
          () => mockFirestore.updateHousehold(household),
        ).thenAnswer((_) => _asyncValue(household));

        final result = await db.updateHousehold(household);

        expect(result, household);
        verify(() => mockFirestore.updateHousehold(household)).called(1);
      });
    });

    group('deleteHousehold', () {
      test('delegates with id', () async {
        const id = 1;

        when(
          () => mockFirestore.deleteHousehold(id),
        ).thenAnswer((_) => Future<void>.value());

        await db.deleteHousehold(id);

        verify(() => mockFirestore.deleteHousehold(id)).called(1);
      });
    });

    group('fetchHouseholdsByCommuneName', () {
      test('delegates with communeName', () async {
        const communeName = 'Phường 1';
        final households = [createTestHousehold()];

        when(
          () => mockFirestore.fetchHouseholdsByCommuneName(communeName),
        ).thenAnswer((_) => _asyncValue(households));

        final result = await db.fetchHouseholdsByCommuneName(communeName);

        expect(result, households);
        verify(
          () => mockFirestore.fetchHouseholdsByCommuneName(communeName),
        ).called(1);
      });
    });

    group('fetchHouseholdsByWard', () {
      test('delegates with ward', () async {
        const ward = 'Phường 1';
        final households = [createTestHousehold()];

        when(
          () => mockFirestore.fetchHouseholdsByWard(ward),
        ).thenAnswer((_) => _asyncValue(households));

        final result = await db.fetchHouseholdsByWard(ward);

        expect(result, households);
        verify(() => mockFirestore.fetchHouseholdsByWard(ward)).called(1);
      });
    });

    group('countHouseholds', () {
      test('delegates with default params', () async {
        when(
          () => mockFirestore.countHouseholds(
            searchQuery: null,
            neighborhood: null,
            ward: null,
            createdBy: null,
          ),
        ).thenAnswer((_) => _asyncValue(5));

        final result = await db.countHouseholds();

        expect(result, 5);
        verify(
          () => mockFirestore.countHouseholds(
            searchQuery: null,
            neighborhood: null,
            ward: null,
            createdBy: null,
          ),
        ).called(1);
      });
    });

    group('fetchIncidentList', () {
      test('delegates with default params', () async {
        final incidents = [createTestIncident()];

        when(
          () => mockFirestore.fetchIncidentList(
            searchQuery: null,
            status: null,
            neighborhood: null,
            ward: null,
            householdId: null,
            createdBy: null,
            limit: 50,
            offset: 0,
          ),
        ).thenAnswer((_) => _asyncValue(incidents));

        final result = await db.fetchIncidentList();

        expect(result, incidents);
        verify(
          () => mockFirestore.fetchIncidentList(
            searchQuery: null,
            status: null,
            neighborhood: null,
            ward: null,
            householdId: null,
            createdBy: null,
            limit: 50,
            offset: 0,
          ),
        ).called(1);
      });
    });

    group('fetchIncidentById', () {
      test('delegates with id', () async {
        const id = 1;
        final incident = createTestIncident(id: id);

        when(
          () => mockFirestore.fetchIncidentById(id),
        ).thenAnswer((_) => _asyncValue(incident));

        final result = await db.fetchIncidentById(id);

        expect(result, incident);
        verify(() => mockFirestore.fetchIncidentById(id)).called(1);
      });
    });

    group('createIncident', () {
      test('delegates to FirestoreService.createIncident', () async {
        final incident = createTestIncident();
        final createdIncident = createTestIncident(
          id: 2,
          incidentCode: 'SV-0002',
        );

        when(
          () => mockFirestore.createIncident(incident),
        ).thenAnswer((_) => _asyncValue(createdIncident));

        final result = await db.createIncident(incident);

        expect(result, createdIncident);
        verify(() => mockFirestore.createIncident(incident)).called(1);
      });
    });

    group('updateIncident', () {
      test('delegates with incident and updatedBy', () async {
        final incident = createTestIncident();
        const updatedBy = 2;

        when(
          () => mockFirestore.updateIncident(incident, updatedBy: updatedBy),
        ).thenAnswer((_) => _asyncValue(incident));

        final result = await db.updateIncident(incident, updatedBy: updatedBy);

        expect(result, incident);
        verify(
          () => mockFirestore.updateIncident(incident, updatedBy: updatedBy),
        ).called(1);
      });
    });

    group('deleteIncident', () {
      test('delegates with id and deletedBy', () async {
        const id = 1;
        const deletedBy = 2;

        when(
          () => mockFirestore.deleteIncident(id, deletedBy: deletedBy),
        ).thenAnswer((_) => Future.value());

        await db.deleteIncident(id, deletedBy: deletedBy);

        verify(
          () => mockFirestore.deleteIncident(id, deletedBy: deletedBy),
        ).called(1);
      });
    });

    group('countIncidents', () {
      test('delegates with default params', () async {
        when(
          () => mockFirestore.countIncidents(
            searchQuery: null,
            status: null,
            neighborhood: null,
            ward: null,
            householdId: null,
            createdBy: null,
          ),
        ).thenAnswer((_) => _asyncValue(10));

        final result = await db.countIncidents();

        expect(result, 10);
        verify(
          () => mockFirestore.countIncidents(
            searchQuery: null,
            status: null,
            neighborhood: null,
            ward: null,
            householdId: null,
            createdBy: null,
          ),
        ).called(1);
      });
    });

    group('fetchDiaDiemLichSuList', () {
      test('delegates without searchQuery', () async {
        final items = [createTestDiaDiemLichSu()];

        when(
          () => mockFirestore.fetchDiaDiemLichSuList(searchQuery: null),
        ).thenAnswer((_) => _asyncValue(items));

        final result = await db.fetchDiaDiemLichSuList();

        expect(result, items);
        verify(
          () => mockFirestore.fetchDiaDiemLichSuList(searchQuery: null),
        ).called(1);
      });

      test('delegates with searchQuery', () async {
        const query = 'Củ Chi';

        when(
          () => mockFirestore.fetchDiaDiemLichSuList(searchQuery: query),
        ).thenAnswer((_) => _asyncValue(<DiaDiemLichSu>[]));

        await db.fetchDiaDiemLichSuList(searchQuery: query);

        verify(
          () => mockFirestore.fetchDiaDiemLichSuList(searchQuery: query),
        ).called(1);
      });
    });

    group('fetchDiaDiemLichSuById', () {
      test('delegates with id', () async {
        const id = 1;
        final item = createTestDiaDiemLichSu(id: id);

        when(
          () => mockFirestore.fetchDiaDiemLichSuById(id),
        ).thenAnswer((_) => _asyncValue(item));

        final result = await db.fetchDiaDiemLichSuById(id);

        expect(result, item);
        verify(() => mockFirestore.fetchDiaDiemLichSuById(id)).called(1);
      });
    });

    group('createDiaDiemLichSu', () {
      test('delegates to FirestoreService.createDiaDiemLichSu', () async {
        final item = createTestDiaDiemLichSu();
        final createdItem = createTestDiaDiemLichSu(id: 2);

        when(
          () => mockFirestore.createDiaDiemLichSu(item),
        ).thenAnswer((_) => _asyncValue(createdItem));

        final result = await db.createDiaDiemLichSu(item);

        expect(result, createdItem);
        verify(() => mockFirestore.createDiaDiemLichSu(item)).called(1);
      });
    });

    group('updateDiaDiemLichSu', () {
      test('delegates to FirestoreService.updateDiaDiemLichSu', () async {
        final item = createTestDiaDiemLichSu();

        when(
          () => mockFirestore.updateDiaDiemLichSu(item),
        ).thenAnswer((_) => _asyncValue(item));

        final result = await db.updateDiaDiemLichSu(item);

        expect(result, item);
        verify(() => mockFirestore.updateDiaDiemLichSu(item)).called(1);
      });
    });

    group('deleteDiaDiemLichSu', () {
      test('delegates with id', () async {
        const id = 1;

        when(
          () => mockFirestore.deleteDiaDiemLichSu(id),
        ).thenAnswer((_) => Future.value());

        await db.deleteDiaDiemLichSu(id);

        verify(() => mockFirestore.deleteDiaDiemLichSu(id)).called(1);
      });
    });

    group('statisticsIncidentsByMonth', () {
      test('delegates with year', () async {
        const year = 2025;
        final stats = {'1': 5, '2': 3};

        when(
          () => mockFirestore.statisticsIncidentsByMonth(year),
        ).thenAnswer((_) => _asyncValue(stats));

        final result = await db.statisticsIncidentsByMonth(year);

        expect(result, stats);
        verify(() => mockFirestore.statisticsIncidentsByMonth(year)).called(1);
      });
    });

    group('statisticsIncidentsByNeighborhood', () {
      test('delegates to FirestoreService', () async {
        final stats = {'Khu phố 1': 5, 'Khu phố 2': 3};

        when(
          () => mockFirestore.statisticsIncidentsByNeighborhood(),
        ).thenAnswer((_) => _asyncValue(stats));

        final result = await db.statisticsIncidentsByNeighborhood();

        expect(result, stats);
        verify(
          () => mockFirestore.statisticsIncidentsByNeighborhood(),
        ).called(1);
      });
    });

    group('statisticsIncidentsByStatus', () {
      test('delegates to FirestoreService', () async {
        final stats = {'received': 10, 'processing': 5, 'resolved': 3};

        when(
          () => mockFirestore.statisticsIncidentsByStatus(),
        ).thenAnswer((_) => _asyncValue(stats));

        final result = await db.statisticsIncidentsByStatus();

        expect(result, stats);
        verify(() => mockFirestore.statisticsIncidentsByStatus()).called(1);
      });
    });

    group('fetchKhuPhos', () {
      test('delegates to FirestoreService.fetchKhuPhos', () async {
        final list = [createTestKhuPho()];

        when(
          () => mockFirestore.fetchKhuPhos(),
        ).thenAnswer((_) => _asyncValue(list));

        final result = await db.fetchKhuPhos();

        expect(result, list);
        verify(() => mockFirestore.fetchKhuPhos()).called(1);
      });
    });

    group('fetchKhuPhoById', () {
      test('delegates with id', () async {
        const id = 1;
        final item = createTestKhuPho(id: id);

        when(
          () => mockFirestore.fetchKhuPhoById(id),
        ).thenAnswer((_) => _asyncValue(item));

        final result = await db.fetchKhuPhoById(id);

        expect(result, item);
        verify(() => mockFirestore.fetchKhuPhoById(id)).called(1);
      });
    });

    group('createKhuPho', () {
      test('delegates to FirestoreService.createKhuPho', () async {
        final item = createTestKhuPho();
        final createdItem = createTestKhuPho(id: 2);

        when(
          () => mockFirestore.createKhuPho(item),
        ).thenAnswer((_) => _asyncValue(createdItem));

        final result = await db.createKhuPho(item);

        expect(result, createdItem);
        verify(() => mockFirestore.createKhuPho(item)).called(1);
      });
    });

    group('updateKhuPho', () {
      test('delegates to FirestoreService.updateKhuPho', () async {
        final item = createTestKhuPho();

        when(
          () => mockFirestore.updateKhuPho(item),
        ).thenAnswer((_) => _asyncValue(item));

        final result = await db.updateKhuPho(item);

        expect(result, item);
        verify(() => mockFirestore.updateKhuPho(item)).called(1);
      });
    });

    group('deleteKhuPho', () {
      test('delegates with id', () async {
        const id = 1;

        when(
          () => mockFirestore.deleteKhuPho(id),
        ).thenAnswer((_) => Future.value());

        await db.deleteKhuPho(id);

        verify(() => mockFirestore.deleteKhuPho(id)).called(1);
      });
    });

    group('fetchDaiDiens', () {
      test('delegates to FirestoreService.fetchDaiDiens', () async {
        final list = [createTestDaiDien()];

        when(
          () => mockFirestore.fetchDaiDiens(),
        ).thenAnswer((_) => _asyncValue(list));

        final result = await db.fetchDaiDiens();

        expect(result, list);
        verify(() => mockFirestore.fetchDaiDiens()).called(1);
      });
    });

    group('fetchDaiDiensByKhuPho', () {
      test('delegates with khuPhoId', () async {
        const khuPhoId = 1;
        final list = [createTestDaiDien(khuPhoId: khuPhoId)];

        when(
          () => mockFirestore.fetchDaiDiensByKhuPho(khuPhoId),
        ).thenAnswer((_) => _asyncValue(list));

        final result = await db.fetchDaiDiensByKhuPho(khuPhoId);

        expect(result, list);
        verify(() => mockFirestore.fetchDaiDiensByKhuPho(khuPhoId)).called(1);
      });
    });

    group('fetchDaiDienById', () {
      test('delegates with id', () async {
        const id = 1;
        final item = createTestDaiDien(id: id);

        when(
          () => mockFirestore.fetchDaiDienById(id),
        ).thenAnswer((_) => _asyncValue(item));

        final result = await db.fetchDaiDienById(id);

        expect(result, item);
        verify(() => mockFirestore.fetchDaiDienById(id)).called(1);
      });
    });

    group('createDaiDien', () {
      test('delegates to FirestoreService.createDaiDien', () async {
        final item = createTestDaiDien();
        final createdItem = createTestDaiDien(id: 2);

        when(
          () => mockFirestore.createDaiDien(item),
        ).thenAnswer((_) => _asyncValue(createdItem));

        final result = await db.createDaiDien(item);

        expect(result, createdItem);
        verify(() => mockFirestore.createDaiDien(item)).called(1);
      });
    });

    group('updateDaiDien', () {
      test('delegates to FirestoreService.updateDaiDien', () async {
        final item = createTestDaiDien();

        when(
          () => mockFirestore.updateDaiDien(item),
        ).thenAnswer((_) => _asyncValue(item));

        final result = await db.updateDaiDien(item);

        expect(result, item);
        verify(() => mockFirestore.updateDaiDien(item)).called(1);
      });
    });

    group('deleteDaiDien', () {
      test('delegates with id', () async {
        const id = 1;

        when(
          () => mockFirestore.deleteDaiDien(id),
        ).thenAnswer((_) => Future.value());

        await db.deleteDaiDien(id);

        verify(() => mockFirestore.deleteDaiDien(id)).called(1);
      });
    });

    group('searchDaiDiens', () {
      test('delegates with query', () async {
        const query = 'Nguyễn';
        final list = [createTestDaiDien()];

        when(
          () => mockFirestore.searchDaiDiens(query),
        ).thenAnswer((_) => _asyncValue(list));

        final result = await db.searchDaiDiens(query);

        expect(result, list);
        verify(() => mockFirestore.searchDaiDiens(query)).called(1);
      });
    });

    group('addNotification', () {
      test('delegates to FirestoreService.addNotification', () async {
        when(
          () => mockFirestore.addNotification(
            type: any(named: 'type'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            targetUserId: any(named: 'targetUserId'),
            actorUserId: any(named: 'actorUserId'),
            relatedId: any(named: 'relatedId'),
            relatedCode: any(named: 'relatedCode'),
          ),
        ).thenAnswer((_) => Future<void>.value());

        await db.addNotification(
          type: 'test',
          title: 'Test',
          body: 'Test body',
          targetUserId: 1,
          actorUserId: 2,
          relatedId: 3,
          relatedCode: 'SV-0001',
        );

        verify(
          () => mockFirestore.addNotification(
            type: 'test',
            title: 'Test',
            body: 'Test body',
            targetUserId: 1,
            actorUserId: 2,
            relatedId: 3,
            relatedCode: 'SV-0001',
          ),
        ).called(1);
      });
    });

    group('fetchAdminUserIds', () {
      test('delegates to FirestoreService.fetchAdminUserIds', () async {
        final adminIds = [1, 2];

        when(
          () => mockFirestore.fetchAdminUserIds(),
        ).thenAnswer((_) => _asyncValue(adminIds));

        final result = await db.fetchAdminUserIds();

        expect(result, adminIds);
        verify(() => mockFirestore.fetchAdminUserIds()).called(1);
      });
    });

    group('createHouseholdRequest', () {
      test('delegates to FirestoreService.createHouseholdRequest', () async {
        final request = createTestHouseholdRequest();
        final createdRequest = createTestHouseholdRequest(id: 2);

        when(
          () => mockFirestore.createHouseholdRequest(request),
        ).thenAnswer((_) => _asyncValue(createdRequest));

        final result = await db.createHouseholdRequest(request);

        expect(result, createdRequest);
        verify(() => mockFirestore.createHouseholdRequest(request)).called(1);
      });
    });

    group('fetchHouseholdRequests', () {
      test('delegates with filters', () async {
        const status = 'pending';
        const userId = 1;
        final requests = [createTestHouseholdRequest()];

        when(
          () => mockFirestore.fetchHouseholdRequests(
            status: status,
            userId: userId,
          ),
        ).thenAnswer((_) => _asyncValue(requests));

        final result = await db.fetchHouseholdRequests(
          status: status,
          userId: userId,
        );

        expect(result, requests);
        verify(
          () => mockFirestore.fetchHouseholdRequests(
            status: status,
            userId: userId,
          ),
        ).called(1);
      });
    });

    group('fetchHouseholdRequestById', () {
      test('delegates with id', () async {
        const id = 1;
        final request = createTestHouseholdRequest(id: id);

        when(
          () => mockFirestore.fetchHouseholdRequestById(id),
        ).thenAnswer((_) => _asyncValue(request));

        final result = await db.fetchHouseholdRequestById(id);

        expect(result, request);
        verify(() => mockFirestore.fetchHouseholdRequestById(id)).called(1);
      });
    });

    group('updateHouseholdRequestStatus', () {
      test('delegates with all params', () async {
        const id = 1;
        const status = 'approved';
        const approvedBy = 2;
        const adminNote = 'OK';

        final request = createTestHouseholdRequest(id: id, status: 'approved');

        when(
          () => mockFirestore.updateHouseholdRequestStatus(
            id,
            status,
            approvedBy: approvedBy,
            adminNote: adminNote,
          ),
        ).thenAnswer((_) => _asyncValue(request));

        final result = await db.updateHouseholdRequestStatus(
          id,
          status,
          approvedBy: approvedBy,
          adminNote: adminNote,
        );

        expect(result, request);
        verify(
          () => mockFirestore.updateHouseholdRequestStatus(
            id,
            status,
            approvedBy: approvedBy,
            adminNote: adminNote,
          ),
        ).called(1);
      });
    });
  });
}
