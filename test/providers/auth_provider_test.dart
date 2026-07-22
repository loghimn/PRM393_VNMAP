import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, User;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vietnam_geo_dashboard/models/user_model.dart';
import 'package:vietnam_geo_dashboard/providers/auth_provider.dart';
import 'package:vietnam_geo_dashboard/services/database_service.dart';
import 'package:vietnam_geo_dashboard/services/storage_service.dart';

// ============================================================
// MOCKS
// ============================================================

class MockDatabaseService extends Mock implements DatabaseService {}

class MockStorageService extends Mock implements StorageService {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseUser extends Mock implements User {}

// ============================================================
// HELPERS
// ============================================================

UserModel createMockUser({
  int? id = 1,
  String? uid = 'firebase-uid-123',
  String username = 'testuser',
  String email = 'test@example.com',
  String role = 'user',
  bool isActive = true,
}) {
  return UserModel(
    id: id,
    uid: uid,
    username: username,
    email: email,
    fullName: 'Test User',
    phone: '0909123456',
    role: role,
    avatarUrl: 'https://example.com/avatar.png',
    isActive: isActive,
  );
}

void main() {
  late AuthProvider provider;
  late MockDatabaseService mockDb;
  late MockStorageService mockStorage;
  late MockFirebaseAuth mockFirebaseAuth;
  late StreamController<User?> authStateController;

  final testUser = createMockUser();
  final adminUser = createMockUser(role: 'admin', username: 'admin');
  final mockFirebaseUser = MockFirebaseUser();

  setUpAll(() {
    registerFallbackValue(createMockUser());
    registerFallbackValue(File('test.png'));
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockStorage = MockStorageService();
    mockFirebaseAuth = MockFirebaseAuth();
    authStateController = StreamController<User?>.broadcast();

    // Mock authStateChanges to return a broadcast stream
    when(
      () => mockFirebaseAuth.authStateChanges(),
    ).thenAnswer((_) => authStateController.stream);

    // Default: no current Firebase user
    when(() => mockFirebaseAuth.currentUser).thenReturn(null);

    provider = AuthProvider(
      databaseService: mockDb,
      storageService: mockStorage,
      firebaseAuth: mockFirebaseAuth,
    );
  });

  tearDown(() async {
    await authStateController.close();
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthProvider — construction & initial state', () {
    test('should have correct initial state', () {
      expect(provider.currentUser, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.isLoggedIn, isFalse);
      expect(provider.isInitialized, isFalse);
      expect(provider.isAdmin, isFalse);
    });
  });

  group('AuthProvider — initialize()', () {
    test('should set initialized to true after initialization', () async {
      SharedPreferences.setMockInitialValues({});

      await provider.initialize();

      expect(provider.isInitialized, isTrue);
    });

    test('should load user from Firebase currentUser if available', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
      when(() => mockFirebaseUser.uid).thenReturn('firebase-uid-123');
      when(
        () => mockDb.getUserByUid('firebase-uid-123'),
      ).thenAnswer((_) async => testUser);

      await provider.initialize();

      expect(provider.currentUser, equals(testUser));
      expect(provider.isInitialized, isTrue);
      expect(provider.isLoggedIn, isTrue);
    });

    test(
      'should handle when Firebase user exists but DB returns null',
      () async {
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn('firebase-uid-456');
        when(
          () => mockDb.getUserByUid('firebase-uid-456'),
        ).thenAnswer((_) async => null);

        await provider.initialize();

        expect(provider.currentUser, isNull);
        expect(provider.isInitialized, isTrue);
      },
    );

    test('should skip re-initialization if already initialized', () async {
      // First call
      await provider.initialize();
      expect(provider.isInitialized, isTrue);

      // Reset mock to verify it's NOT called again
      // Second call should return immediately
      await provider.initialize();

      // Still initialized
      expect(provider.isInitialized, isTrue);
    });
  });

  group('AuthProvider — login()', () {
    test('should login successfully', () async {
      when(
        () => mockDb.signInWithEmail('test@example.com', 'password123'),
      ).thenAnswer((_) async => testUser);
      SharedPreferences.setMockInitialValues({});

      final result = await provider.login('test@example.com', 'password123');

      expect(result, isTrue);
      expect(provider.currentUser, equals(testUser));
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('should return false when signIn returns null', () async {
      when(
        () => mockDb.signInWithEmail(any(), any()),
      ).thenAnswer((_) async => null);
      SharedPreferences.setMockInitialValues({});

      final result = await provider.login('wrong@email.com', 'wrongpass');

      expect(result, isFalse);
      expect(provider.currentUser, isNull);
      expect(provider.error, isNotNull);
    });

    test('should handle exception during login', () async {
      when(
        () => mockDb.signInWithEmail(any(), any()),
      ).thenThrow(Exception('Network error'));
      SharedPreferences.setMockInitialValues({});

      final result = await provider.login('test@example.com', 'password123');

      expect(result, isFalse);
      expect(provider.error, contains('Network error'));
      expect(provider.isLoading, isFalse);
    });

    test('should set loading state correctly during login', () async {
      final completer = Completer<UserModel?>();
      when(
        () => mockDb.signInWithEmail(any(), any()),
      ).thenAnswer((_) => completer.future);
      SharedPreferences.setMockInitialValues({});

      final future = provider.login('test@example.com', 'password123');
      expect(provider.isLoading, isTrue);

      completer.complete(testUser);
      await future;

      expect(provider.isLoading, isFalse);
    });
  });

  group('AuthProvider — logout()', () {
    test('should clear user and uid on logout', () async {
      // First login to set user
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);
      when(
        () => mockDb.signInWithEmail(any(), any()),
      ).thenAnswer((_) async => testUser);
      when(
        () => mockFirebaseAuth.signOut(),
      ).thenAnswer((_) async => Future.value());
      SharedPreferences.setMockInitialValues({});

      await provider.login('test@example.com', 'password123');
      expect(provider.currentUser, isNotNull);

      await provider.logout();

      expect(provider.currentUser, isNull);
      expect(provider.isLoggedIn, isFalse);
      verify(() => mockFirebaseAuth.signOut()).called(1);
    });
  });

  group('AuthProvider — isAdmin getter', () {
    test('should return true when user has admin role', () {
      provider.setCurrentUserForTesting(adminUser);
      expect(provider.isAdmin, isTrue);
    });

    test('should return false when user has user role', () {
      provider.setCurrentUserForTesting(testUser);
      expect(provider.isAdmin, isFalse);
    });

    test('should return false when no user is logged in', () {
      provider.setCurrentUserForTesting(null);
      expect(provider.isAdmin, isFalse);
    });
  });

  group('AuthProvider — changePassword()', () {
    test('should return true when password change succeeds', () async {
      when(
        () => mockDb.changePasswordFirebase('newPass123'),
      ).thenAnswer((_) async => true);

      final result = await provider.changePassword('newPass123');

      expect(result, isTrue);
    });

    test('should return false when password change fails', () async {
      when(
        () => mockDb.changePasswordFirebase(any()),
      ).thenAnswer((_) async => false);

      final result = await provider.changePassword('bad');

      expect(result, isFalse);
    });

    test('should return false on exception', () async {
      when(
        () => mockDb.changePasswordFirebase(any()),
      ).thenThrow(Exception('Error'));

      final result = await provider.changePassword('newPass123');

      expect(result, isFalse);
    });
  });

  group('AuthProvider — updateProfile()', () {
    test('should update profile successfully', () async {
      provider.setCurrentUserForTesting(testUser);
      when(() => mockDb.updateUser(any())).thenAnswer((_) async => testUser);

      final result = await provider.updateProfile(
        fullName: 'Updated Name',
        email: 'updated@example.com',
        phone: '0987654321',
      );

      expect(result, isTrue);
      expect(provider.isLoading, isFalse);
      verify(() => mockDb.updateUser(any())).called(1);
    });

    test('should return false if no user is logged in', () async {
      provider.setCurrentUserForTesting(null);

      final result = await provider.updateProfile(fullName: 'New Name');

      expect(result, isFalse);
    });

    test('should upload avatar when avatarFile is provided', () async {
      final mockFile = File('test.png');
      provider.setCurrentUserForTesting(testUser);
      when(
        () => mockStorage.uploadAvatar(
          uid: any(named: 'uid'),
          image: any(named: 'image'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async => 'https://example.com/new-avatar.png');
      when(() => mockDb.updateUser(any())).thenAnswer((_) async => testUser);

      final result = await provider.updateProfile(
        fullName: 'New Name',
        avatarFile: mockFile,
      );

      expect(result, isTrue);
      verify(
        () => mockStorage.uploadAvatar(
          uid: any(named: 'uid'),
          image: mockFile,
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);
    });

    test('should handle exception during updateProfile', () async {
      provider.setCurrentUserForTesting(testUser);
      when(
        () => mockDb.updateUser(any()),
      ).thenThrow(Exception('Update failed'));

      final result = await provider.updateProfile(fullName: 'New Name');

      expect(result, isFalse);
      expect(provider.error, contains('Update failed'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('AuthProvider — register()', () {
    test('should register successfully', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
      when(() => mockFirebaseUser.uid).thenReturn('firebase-uid-123');
      when(
        () => mockDb.createUserWithAuth(any(), any(), any()),
      ).thenAnswer((_) async => testUser);
      when(
        () => mockDb.getUserByUid('firebase-uid-123'),
      ).thenAnswer((_) async => testUser);
      SharedPreferences.setMockInitialValues({});

      final result = await provider.register(
        'newuser',
        'password123',
        email: 'new@example.com',
        fullName: 'New User',
        phone: '0909123456',
      );

      expect(result, isTrue);
      expect(provider.currentUser, equals(testUser));
      expect(provider.isLoading, isFalse);
    });

    test('should return false if username is too short', () async {
      final result = await provider.register(
        'ab',
        'password123',
        email: 'test@example.com',
      );

      expect(result, isFalse);
      expect(provider.error, contains('3 ký tự'));
      expect(provider.isLoading, isFalse);
    });

    test('should return false if password is too short', () async {
      final result = await provider.register(
        'validuser',
        '12345',
        email: 'test@example.com',
      );

      expect(result, isFalse);
      expect(provider.error, contains('6 ký tự'));
      expect(provider.isLoading, isFalse);
    });

    test('should return false if email is empty', () async {
      final result = await provider.register(
        'validuser',
        'password123',
        email: '',
      );

      expect(result, isFalse);
      expect(provider.error, contains('email'));
      expect(provider.isLoading, isFalse);
    });

    test('should handle exception during register', () async {
      when(
        () => mockDb.createUserWithAuth(any(), any(), any()),
      ).thenThrow(Exception('Registration error'));

      final result = await provider.register(
        'validuser',
        'password123',
        email: 'test@example.com',
      );

      expect(result, isFalse);
      expect(provider.error, contains('Registration error'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('AuthProvider — clearError()', () {
    test('should clear error', () async {
      // Trigger an error first
      when(
        () => mockDb.signInWithEmail(any(), any()),
      ).thenAnswer((_) async => null);
      await provider.login('x', 'y');
      expect(provider.error, isNotNull);

      provider.clearError();

      expect(provider.error, isNull);
    });
  });
}
