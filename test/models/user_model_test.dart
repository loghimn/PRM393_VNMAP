import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/user_model.dart';

void main() {
  group('UserModel.fromJson', () {
    test('should parse full JSON data', () {
      final json = {
        'id': 1,
        'uid': 'firebase_uid_123',
        'username': 'nguyenvana',
        'password_hash': 'hashed_password',
        'email': 'a@gmail.com',
        'full_name': 'Nguyễn Văn A',
        'phone': '0909123456',
        'role': 'admin',
        'avatar_url': 'https://example.com/avatar.jpg',
        'is_active': true,
        'last_login': '2024-01-15T10:00:00.000',
        'created_at': '2024-01-01T08:00:00.000',
        'updated_at': '2024-01-16T10:00:00.000',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 1);
      expect(user.uid, 'firebase_uid_123');
      expect(user.username, 'nguyenvana');
      expect(user.passwordHash, 'hashed_password');
      expect(user.email, 'a@gmail.com');
      expect(user.fullName, 'Nguyễn Văn A');
      expect(user.phone, '0909123456');
      expect(user.role, 'admin');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.isActive, true);
      expect(user.lastLogin, DateTime(2024, 1, 15, 10, 0, 0));
      expect(user.createdAt, DateTime(2024, 1, 1, 8, 0, 0));
      expect(user.updatedAt, DateTime(2024, 1, 16, 10, 0, 0));
    });

    test('should handle id as string', () {
      final json = {'id': '99', 'username': 'testuser'};

      final user = UserModel.fromJson(json);

      expect(user.id, 99);
    });

    test('should handle null id', () {
      final json = {'username': 'testuser'};

      final user = UserModel.fromJson(json);

      expect(user.id, isNull);
    });

    test('should handle is_active as string "true"', () {
      final json = {'username': 'testuser', 'is_active': 'true'};

      final user = UserModel.fromJson(json);

      expect(user.isActive, true);
    });

    test('should handle is_active as string "false"', () {
      final json = {'username': 'testuser', 'is_active': 'false'};

      final user = UserModel.fromJson(json);

      expect(user.isActive, false);
    });

    test('should default isActive to false when not provided', () {
      final json = {'username': 'testuser'};

      final user = UserModel.fromJson(json);

      expect(user.isActive, false);
    });

    test('should default role to "user" when not provided', () {
      final json = {'username': 'testuser'};

      final user = UserModel.fromJson(json);

      expect(user.role, 'user');
    });

    test('should handle missing optional fields', () {
      final json = {'username': 'testuser'};

      final user = UserModel.fromJson(json);

      expect(user.uid, isNull);
      expect(user.email, isNull);
      expect(user.fullName, isNull);
      expect(user.phone, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.lastLogin, isNull);
      expect(user.createdAt, isNull);
      expect(user.updatedAt, isNull);
      expect(user.passwordHash, isNull);
    });

    test('should default username to empty string when not provided', () {
      final json = <String, dynamic>{};

      final user = UserModel.fromJson(json);

      expect(user.username, '');
    });
  });

  group('UserModel.toJson', () {
    test('should convert to JSON correctly', () {
      final user = UserModel(
        id: 1,
        uid: 'firebase_uid_123',
        username: 'nguyenvana',
        passwordHash: 'hashed',
        email: 'a@gmail.com',
        fullName: 'Nguyễn Văn A',
        phone: '0909123456',
        role: 'admin',
        avatarUrl: 'https://example.com/avatar.jpg',
        isActive: true,
      );

      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['uid'], 'firebase_uid_123');
      expect(json['username'], 'nguyenvana');
      expect(json['password_hash'], 'hashed');
      expect(json['email'], 'a@gmail.com');
      expect(json['full_name'], 'Nguyễn Văn A');
      expect(json['phone'], '0909123456');
      expect(json['role'], 'admin');
      expect(json['avatar_url'], 'https://example.com/avatar.jpg');
      expect(json['is_active'], true);
    });

    test('should not include null id', () {
      final user = UserModel(username: 'testuser');

      final json = user.toJson();

      expect(json.containsKey('id'), isFalse);
    });

    test('should not include null uid', () {
      final user = UserModel(username: 'testuser');

      final json = user.toJson();

      expect(json.containsKey('uid'), isFalse);
    });

    test('should include null fields as null', () {
      final user = UserModel(username: 'testuser');

      final json = user.toJson();

      expect(json['email'], isNull);
      expect(json['full_name'], isNull);
      expect(json['phone'], isNull);
      expect(json['avatar_url'], isNull);
    });
  });
}
