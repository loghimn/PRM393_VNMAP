import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/models/household_model.dart';
import 'package:vietnam_geo_dashboard/models/household_request_model.dart';
import 'package:vietnam_geo_dashboard/providers/household_request_provider.dart';
import 'package:vietnam_geo_dashboard/services/database_service.dart';

// ============================================================
// MOCKS
// ============================================================

class MockDatabaseService extends Mock implements DatabaseService {}

// ============================================================
// HELPERS
// ============================================================

HouseholdRequest createMockRequest({
  int? id,
  int userId = 1,
  String headOfHousehold = 'Nguyễn Văn A',
  String status = 'pending',
  String? adminNote,
}) {
  return HouseholdRequest(
    id: id,
    userId: userId,
    headOfHousehold: headOfHousehold,
    phone: '0909123456',
    houseNumber: '123',
    street: 'Đường Lê Lợi',
    neighborhood: 'Khu phố 1',
    ward: 'Phường Bến Nghé',
    district: 'Quận 1',
    city: 'Hồ Chí Minh',
    status: status,
    adminNote: adminNote,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(createMockRequest());
    registerFallbackValue(
      Household(householdCode: '', headOfHousehold: '', phone: ''),
    );
  });

  late HouseholdRequestProvider provider;
  late MockDatabaseService mockDb;

  final pendingReq1 = createMockRequest(id: 1, status: 'pending');
  final pendingReq2 = createMockRequest(id: 2, userId: 2, status: 'pending');
  final approvedReq = createMockRequest(id: 3, status: 'approved');
  final rejectedReq = createMockRequest(id: 4, status: 'rejected');
  final allRequests = [pendingReq1, pendingReq2, approvedReq, rejectedReq];

  setUp(() {
    mockDb = MockDatabaseService();
    provider = HouseholdRequestProvider(db: mockDb);
  });

  group('HouseholdRequestProvider — construction & initial state', () {
    test('should have correct initial state', () {
      expect(provider.requests, isEmpty);
      expect(provider.pendingRequests, isEmpty);
      expect(provider.approvedRequests, isEmpty);
      expect(provider.rejectedRequests, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });
  });

  group('HouseholdRequestProvider — getters (filtered requests)', () {
    test('pendingRequests should return only pending requests', () {
      provider.setRequestsForTesting(allRequests);
      expect(provider.pendingRequests, equals([pendingReq1, pendingReq2]));
    });

    test('approvedRequests should return only approved requests', () {
      provider.setRequestsForTesting(allRequests);
      expect(provider.approvedRequests, equals([approvedReq]));
    });

    test('rejectedRequests should return only rejected requests', () {
      provider.setRequestsForTesting(allRequests);
      expect(provider.rejectedRequests, equals([rejectedReq]));
    });

    test(
      'filtered getters should return empty list when no matching requests',
      () {
        provider.setRequestsForTesting([approvedReq, rejectedReq]);
        expect(provider.pendingRequests, isEmpty);
      },
    );
  });

  group('HouseholdRequestProvider — fetchAllRequests()', () {
    test('should fetch all requests successfully', () async {
      when(
        () => mockDb.fetchHouseholdRequests(),
      ).thenAnswer((_) async => allRequests);

      await provider.fetchAllRequests();

      expect(provider.requests, equals(allRequests));
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('should handle exception during fetchAllRequests', () async {
      when(
        () => mockDb.fetchHouseholdRequests(),
      ).thenThrow(Exception('Fetch failed'));

      await provider.fetchAllRequests();

      expect(provider.requests, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNotNull);
    });

    test('should set loading state correctly', () async {
      final completer = Completer<List<HouseholdRequest>>();
      when(
        () => mockDb.fetchHouseholdRequests(),
      ).thenAnswer((_) => completer.future);

      final future = provider.fetchAllRequests();
      expect(provider.isLoading, isTrue);

      completer.complete(allRequests);
      await future;

      expect(provider.isLoading, isFalse);
    });
  });

  group('HouseholdRequestProvider — fetchUserRequests()', () {
    test('should fetch user requests successfully', () async {
      when(
        () => mockDb.fetchHouseholdRequests(userId: 1),
      ).thenAnswer((_) async => [pendingReq1]);

      final result = await provider.fetchUserRequests(1);

      expect(result, equals([pendingReq1]));
      verify(() => mockDb.fetchHouseholdRequests(userId: 1)).called(1);
    });

    test('should return empty list on exception', () async {
      when(
        () => mockDb.fetchHouseholdRequests(userId: any(named: 'userId')),
      ).thenThrow(Exception('Error'));

      final result = await provider.fetchUserRequests(1);

      expect(result, isEmpty);
      expect(provider.error, isNotNull);
    });
  });

  group('HouseholdRequestProvider — getUserPendingRequest()', () {
    test('should return pending request if exists', () async {
      when(
        () => mockDb.fetchHouseholdRequests(
          userId: any(named: 'userId'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => [pendingReq1]);

      final result = await provider.getUserPendingRequest(1);

      expect(result, equals(pendingReq1));
    });

    test('should return null if no pending request found', () async {
      when(
        () => mockDb.fetchHouseholdRequests(
          userId: any(named: 'userId'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => []);

      final result = await provider.getUserPendingRequest(1);

      expect(result, isNull);
    });

    test('should return null on exception', () async {
      when(
        () => mockDb.fetchHouseholdRequests(
          userId: any(named: 'userId'),
          status: any(named: 'status'),
        ),
      ).thenThrow(Exception('Error'));

      final result = await provider.getUserPendingRequest(1);

      expect(result, isNull);
    });
  });

  group('HouseholdRequestProvider — createRequest()', () {
    test('should create request successfully', () async {
      when(
        () => mockDb.createHouseholdRequest(any()),
      ).thenAnswer((_) async => pendingReq1);

      final result = await provider.createRequest(pendingReq1);

      expect(result, isTrue);
      expect(provider.isLoading, isFalse);
      verify(() => mockDb.createHouseholdRequest(pendingReq1)).called(1);
    });

    test('should handle exception on createRequest', () async {
      when(
        () => mockDb.createHouseholdRequest(any()),
      ).thenThrow(Exception('Create failed'));

      final result = await provider.createRequest(pendingReq1);

      expect(result, isFalse);
      expect(provider.error, contains('Create failed'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('HouseholdRequestProvider — loadRequests()', () {
    test('should load requests successfully', () async {
      when(
        () => mockDb.fetchHouseholdRequests(status: any(named: 'status')),
      ).thenAnswer((_) async => [pendingReq1]);

      await provider.loadRequests(status: 'pending');

      expect(provider.requests, equals([pendingReq1]));
      expect(provider.isLoading, isFalse);
    });

    test('should load requests with userId filter', () async {
      when(
        () => mockDb.fetchHouseholdRequests(userId: 1),
      ).thenAnswer((_) async => [pendingReq1]);

      await provider.loadRequests(userId: 1);

      expect(provider.requests, equals([pendingReq1]));
    });

    test('should handle exception during loadRequests', () async {
      when(
        () => mockDb.fetchHouseholdRequests(
          status: any(named: 'status'),
          userId: any(named: 'userId'),
        ),
      ).thenThrow(Exception('Load failed'));

      await provider.loadRequests(status: 'pending');

      expect(provider.requests, isEmpty);
      expect(provider.error, isNotNull);
    });
  });

  group('HouseholdRequestProvider — approveRequest()', () {
    test('should approve request successfully', () async {
      when(
        () => mockDb.fetchHouseholdRequestById(1),
      ).thenAnswer((_) async => pendingReq1);
      when(
        () => mockDb.updateHouseholdRequestStatus(
          any(),
          any(),
          approvedBy: any(named: 'approvedBy'),
          adminNote: any(named: 'adminNote'),
        ),
      ).thenAnswer((_) async => approvedReq);
      when(() => mockDb.createHousehold(any())).thenAnswer(
        (_) async =>
            Household(householdCode: 'ABC123', headOfHousehold: '', phone: ''),
      );
      when(
        () => mockDb.fetchHouseholdRequests(
          status: any(named: 'status'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => allRequests);

      final result = await provider.approveRequest(
        1,
        approvedBy: 1,
        adminNote: 'Approved',
      );

      expect(result, isTrue);
      verify(() => mockDb.fetchHouseholdRequestById(1)).called(1);
      verify(
        () => mockDb.updateHouseholdRequestStatus(
          1,
          'approved',
          approvedBy: 1,
          adminNote: 'Approved',
        ),
      ).called(1);
      verify(() => mockDb.createHousehold(any())).called(1);
    });

    test('should return false if request not found', () async {
      when(
        () => mockDb.fetchHouseholdRequestById(999),
      ).thenAnswer((_) async => null);

      final result = await provider.approveRequest(999, approvedBy: 1);

      expect(result, isFalse);
      expect(provider.error, equals('Không tìm thấy yêu cầu'));
    });

    test('should handle exception during approveRequest', () async {
      when(
        () => mockDb.fetchHouseholdRequestById(1),
      ).thenThrow(Exception('Approve failed'));

      final result = await provider.approveRequest(1, approvedBy: 1);

      expect(result, isFalse);
      expect(provider.error, contains('Approve failed'));
    });
  });

  group('HouseholdRequestProvider — rejectRequest()', () {
    test('should reject request successfully', () async {
      when(
        () => mockDb.updateHouseholdRequestStatus(
          any(),
          any(),
          approvedBy: any(named: 'approvedBy'),
          adminNote: any(named: 'adminNote'),
        ),
      ).thenAnswer((_) async => rejectedReq);
      when(
        () => mockDb.fetchHouseholdRequests(
          status: any(named: 'status'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => allRequests);

      final result = await provider.rejectRequest(
        1,
        approvedBy: 1,
        adminNote: 'Rejected because...',
      );

      expect(result, isTrue);
      verify(
        () => mockDb.updateHouseholdRequestStatus(
          1,
          'rejected',
          approvedBy: 1,
          adminNote: 'Rejected because...',
        ),
      ).called(1);
    });

    test('should handle exception during rejectRequest', () async {
      when(
        () => mockDb.updateHouseholdRequestStatus(
          any(),
          any(),
          approvedBy: any(named: 'approvedBy'),
          adminNote: any(named: 'adminNote'),
        ),
      ).thenThrow(Exception('Reject failed'));

      final result = await provider.rejectRequest(1, approvedBy: 1);

      expect(result, isFalse);
      expect(provider.error, contains('Reject failed'));
    });
  });
}
