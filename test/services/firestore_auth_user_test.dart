import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vietnam_geo_dashboard/services/firestore_service.dart';

import 'mock_helper.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    service = createTestFirestoreService(
      firestore: fakeFirestore,
      firebaseAuth: mockAuth,
    );
  });

  group('FirestoreService — Auth / Users', () {
    group('signInWithEmail', () {
      test('returns UserModel when sign-in succeeds', () async {
        // Seed a user document
        await fakeFirestore.collection('users').doc('uid-1').set({
          'id': 1,
          'uid': 'uid-1',
          'username': 'testuser',
          'email': 'test@example.com',
          'full_name': 'Test User',
          'phone': '0909123456',
          'role': 'user',
          'avatar_url': null,
          'is_active': true,
          'created_at': '2025-01-01T00:00:00.000',
          'updated_at': '2025-01-01T00:00:00.000',
        });

        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();
        when(() => mockUser.uid).thenReturn('uid-1');
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(
          () => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => mockUserCredential);

        final result = await service.signInWithEmail(
          'test@example.com',
          'pass',
        );

        expect(result, isNotNull);
        expect(result!.id, 1);
        expect(result.email, 'test@example.com');
        verify(
          () => mockAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'pass',
          ),
        ).called(1);
      });

      test('returns null when auth fails', () async {
        when(
          () => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(auth.FirebaseAuthException(code: 'user-not-found'));

        final result = await service.signInWithEmail('x@y.z', 'wrong');

        expect(result, isNull);
      });

      test('returns null when uid is null', () async {
        final mockUserCredential = MockUserCredential();
        when(() => mockUserCredential.user).thenReturn(null);
        when(
          () => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => mockUserCredential);

        final result = await service.signInWithEmail('test@test.com', 'pass');

        expect(result, isNull);
      });
    });

    group('createUserWithAuth', () {
      test('creates user with Firebase Auth and Firestore profile', () async {
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();

        when(() => mockUser.uid).thenReturn('new-uid-1');
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.sendEmailVerification()).thenAnswer((_) async {});
        when(
          () => mockAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => mockUserCredential);

        final user = createTestUser(id: 0, uid: null);
        final result = await service.createUserWithAuth(
          'new@example.com',
          'password123',
          user,
        );

        expect(result.id, 1);
        expect(result.uid, 'new-uid-1');
        expect(result.email, 'new@example.com');

        // Verify document was created in Firestore
        final doc = await fakeFirestore
            .collection('users')
            .doc('new-uid-1')
            .get();
        expect(doc.exists, isTrue);
        expect(doc.data()!['id'], 1);
        expect(doc.data()!['email'], 'new@example.com');
      });
    });

    group('changePasswordFirebase', () {
      test('returns true on success', () async {
        final mockUser = MockUser();
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.updatePassword(any())).thenAnswer((_) async {});

        final result = await service.changePasswordFirebase('newPass');

        expect(result, isTrue);
        verify(() => mockUser.updatePassword('newPass')).called(1);
      });

      test('returns false when no current user', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final result = await service.changePasswordFirebase('newPass');

        expect(result, isFalse);
      });

      test('returns false on FirebaseAuthException', () async {
        final mockUser = MockUser();
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(
          () => mockUser.updatePassword(any()),
        ).thenThrow(auth.FirebaseAuthException(code: 'weak-password'));

        final result = await service.changePasswordFirebase('newPass');

        expect(result, isFalse);
      });
    });

    group('sendPasswordResetEmail', () {
      test('returns true on success', () async {
        when(
          () => mockAuth.sendPasswordResetEmail(email: any(named: 'email')),
        ).thenAnswer((_) async {});

        final result = await service.sendPasswordResetEmail('test@example.com');

        expect(result, isTrue);
        verify(
          () => mockAuth.sendPasswordResetEmail(email: 'test@example.com'),
        ).called(1);
      });

      test('returns false on failure', () async {
        when(
          () => mockAuth.sendPasswordResetEmail(email: any(named: 'email')),
        ).thenThrow(Exception('Network error'));

        final result = await service.sendPasswordResetEmail('test@example.com');

        expect(result, isFalse);
      });
    });

    group('getUserByUid', () {
      test('returns UserModel when found', () async {
        await fakeFirestore.collection('users').doc('uid-1').set({
          'id': 1,
          'uid': 'uid-1',
          'username': 'testuser',
          'email': 'test@example.com',
          'full_name': 'Test User',
          'phone': '0909123456',
          'role': 'user',
          'avatar_url': null,
          'is_active': true,
          'created_at': '2025-01-01T00:00:00.000',
          'updated_at': '2025-01-01T00:00:00.000',
        });

        final result = await service.getUserByUid('uid-1');

        expect(result, isNotNull);
        expect(result!.id, 1);
        expect(result.username, 'testuser');
      });

      test('returns null when not found', () async {
        final result = await service.getUserByUid('nonexistent');

        expect(result, isNull);
      });

      test('auto-assigns id if missing', () async {
        await fakeFirestore.collection('users').doc('no-id').set({
          'uid': 'no-id',
          'username': 'noid',
          'email': 'noid@test.com',
          'full_name': 'No ID User',
          'phone': '0909000000',
          'role': 'user',
          'avatar_url': null,
          'is_active': true,
          'created_at': '2025-01-01T00:00:00.000',
          'updated_at': '2025-01-01T00:00:00.000',
        });

        final result = await service.getUserByUid('no-id');

        expect(result, isNotNull);
        expect(result!.id, 1);
      });
    });

    group('getUserById', () {
      test('returns UserModel when found', () async {
        await fakeFirestore.collection('users').doc('uid-1').set({
          'id': 42,
          'uid': 'uid-1',
          'username': 'user42',
          'email': 'user42@test.com',
          'full_name': 'User 42',
          'phone': '0909123456',
          'role': 'user',
          'avatar_url': null,
          'is_active': true,
          'created_at': '2025-01-01T00:00:00.000',
          'updated_at': '2025-01-01T00:00:00.000',
        });

        final result = await service.getUserById(42);

        expect(result, isNotNull);
        expect(result!.username, 'user42');
      });

      test('returns null when not found', () async {
        final result = await service.getUserById(999);

        expect(result, isNull);
      });
    });

    group('getUserByUsername', () {
      test('returns UserModel when found', () async {
        await fakeFirestore.collection('users').doc('uid-admin').set({
          'id': 1,
          'uid': 'uid-admin',
          'username': 'admin',
          'email': 'admin@test.com',
          'full_name': 'Admin',
          'phone': '0909123456',
          'role': 'admin',
          'avatar_url': null,
          'is_active': true,
          'created_at': '2025-01-01T00:00:00.000',
          'updated_at': '2025-01-01T00:00:00.000',
        });

        final result = await service.getUserByUsername('admin');

        expect(result, isNotNull);
        expect(result!.role, 'admin');
      });

      test('returns null when not found', () async {
        final result = await service.getUserByUsername('ghost');

        expect(result, isNull);
      });
    });

    group('updateUser', () {
      test('updates user with uid and returns it', () async {
        const testUid = 'firebase-uid-1';
        await fakeFirestore.collection('users').doc(testUid).set({
          'id': 1,
          'uid': testUid,
          'username': 'oldname',
          'email': 'test@example.com',
          'full_name': 'Old Name',
          'phone': '0909123456',
          'role': 'user',
          'avatar_url': null,
          'is_active': true,
          'created_at': '2025-01-01T00:00:00.000',
          'updated_at': '2025-01-01T00:00:00.000',
        });

        final updatedUser = createTestUser(uid: testUid, fullName: 'New Name');

        final result = await service.updateUser(updatedUser);

        expect(result.fullName, 'New Name');

        final doc = await fakeFirestore.collection('users').doc(testUid).get();
        expect(doc.data()!['full_name'], 'New Name');
      });

      test('falls back to id query when uid is empty', () async {
        await fakeFirestore.collection('users').doc('some-uid').set({
          'id': 1,
          'uid': 'some-uid',
          'username': 'testuser',
          'email': 'test@test.com',
          'full_name': 'Original',
          'phone': '0909123456',
          'role': 'user',
          'avatar_url': null,
          'is_active': true,
          'created_at': '2025-01-01T00:00:00.000',
          'updated_at': '2025-01-01T00:00:00.000',
        });

        final user = createTestUser(id: 1, uid: '', fullName: 'Updated');

        final result = await service.updateUser(user);

        expect(result.fullName, 'Updated');
        final doc = await fakeFirestore
            .collection('users')
            .doc('some-uid')
            .get();
        expect(doc.data()!['full_name'], 'Updated');
      });
    });

    group('getAllUsers', () {
      test('returns all users without search', () async {
        await fakeFirestore.collection('users').doc('uid-1').set({
          'id': 1,
          'uid': 'uid-1',
          'username': 'user1',
          'email': 'u1@test.com',
          'full_name': 'User 1',
          'phone': '0909000001',
          'role': 'user',
          'avatar_url': null,
          'is_active': true,
          'created_at': '2025-01-01T00:00:00.000',
          'updated_at': '2025-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('users').doc('uid-2').set({
          'id': 2,
          'uid': 'uid-2',
          'username': 'user2',
          'email': 'u2@test.com',
          'full_name': 'User 2',
          'phone': '0909000002',
          'role': 'admin',
          'avatar_url': null,
          'is_active': true,
          'created_at': '2025-01-02T00:00:00.000',
          'updated_at': '2025-01-02T00:00:00.000',
        });

        final result = await service.getAllUsers();

        expect(result.length, 2);
      });

      test('filters by searchQuery', () async {
        await fakeFirestore.collection('users').doc('uid-1').set({
          'id': 1,
          'uid': 'uid-1',
          'username': 'admin',
          'email': 'admin@test.com',
          'full_name': 'Admin',
          'phone': '0909000001',
          'role': 'admin',
          'avatar_url': null,
          'is_active': true,
          'created_at': '2025-01-01T00:00:00.000',
          'updated_at': '2025-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('users').doc('uid-2').set({
          'id': 2,
          'uid': 'uid-2',
          'username': 'user1',
          'email': 'u1@test.com',
          'full_name': 'User 1',
          'phone': '0909000002',
          'role': 'user',
          'avatar_url': null,
          'is_active': true,
          'created_at': '2025-01-02T00:00:00.000',
          'updated_at': '2025-01-02T00:00:00.000',
        });

        final result = await service.getAllUsers(searchQuery: 'admin');

        expect(result.length, 1);
        expect(result.first.username, 'admin');
      });
    });

    group('fetchAdminUserIds', () {
      test('returns list of admin user ids', () async {
        await fakeFirestore.collection('users').doc('uid-1').set({
          'id': 1,
          'uid': 'uid-1',
          'username': 'admin1',
          'email': 'a1@test.com',
          'full_name': 'Admin 1',
          'phone': '0909000001',
          'role': 'admin',
          'avatar_url': null,
          'is_active': true,
          'created_at': '2025-01-01T00:00:00.000',
          'updated_at': '2025-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('users').doc('uid-2').set({
          'id': 2,
          'uid': 'uid-2',
          'username': 'admin2',
          'email': 'a2@test.com',
          'full_name': 'Admin 2',
          'phone': '0909000002',
          'role': 'admin',
          'avatar_url': null,
          'is_active': true,
          'created_at': '2025-01-01T00:00:00.000',
          'updated_at': '2025-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('users').doc('uid-3').set({
          'id': 3,
          'uid': 'uid-3',
          'username': 'user1',
          'email': 'u1@test.com',
          'full_name': 'User 1',
          'phone': '0909000003',
          'role': 'user',
          'avatar_url': null,
          'is_active': true,
          'created_at': '2025-01-01T00:00:00.000',
          'updated_at': '2025-01-01T00:00:00.000',
        });

        final result = await service.fetchAdminUserIds();

        expect(result, [1, 2]);
      });

      test('returns empty list if no admins', () async {
        final result = await service.fetchAdminUserIds();

        expect(result, isEmpty);
      });
    });
  });
}
