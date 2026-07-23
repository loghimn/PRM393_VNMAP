import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/app_notification_model.dart';

void main() {
  group('AppNotification.fromJson', () {
    test('should parse full JSON data', () {
      final json = {
        'id': 1,
        'type': 'incident_created',
        'title': 'Sự cố mới',
        'body': 'Sự cố SV-0042 vừa được tạo',
        'is_read': true,
        'target_user_id': 5,
        'actor_user_id': 1,
        'related_id': 42,
        'related_code': 'SV-0042',
        'created_at': '2024-01-15T10:00:00.000',
        'updated_at': '2024-01-16T10:00:00.000',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.id, 1);
      expect(notification.type, 'incident_created');
      expect(notification.title, 'Sự cố mới');
      expect(notification.body, 'Sự cố SV-0042 vừa được tạo');
      expect(notification.isRead, true);
      expect(notification.targetUserId, 5);
      expect(notification.actorUserId, 1);
      expect(notification.relatedId, 42);
      expect(notification.relatedCode, 'SV-0042');
      expect(notification.createdAt, DateTime(2024, 1, 15, 10, 0, 0));
      expect(notification.updatedAt, DateTime(2024, 1, 16, 10, 0, 0));
    });

    test('should handle id as string', () {
      final json = {
        'id': '99',
        'type': 'incident_created',
        'title': 'Test',
        'body': 'Test body',
        'created_at': '2024-01-15T10:00:00.000',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.id, 99);
    });

    test('should default isRead to false', () {
      final json = {
        'type': 'incident_created',
        'title': 'Test',
        'body': 'Test body',
        'created_at': '2024-01-15T10:00:00.000',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.isRead, false);
    });

    test('should handle is_read as string "true"', () {
      final json = {
        'type': 'incident_updated',
        'title': 'Test',
        'body': 'Test',
        'is_read': 'true',
        'created_at': '2024-01-15T10:00:00.000',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.isRead, true);
    });

    test('should handle null optional int fields', () {
      final json = {
        'type': 'incident_deleted',
        'title': 'Test',
        'body': 'Test',
        'created_at': '2024-01-15T10:00:00.000',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.id, isNull);
      expect(notification.targetUserId, isNull);
      expect(notification.actorUserId, isNull);
      expect(notification.relatedId, isNull);
      expect(notification.relatedCode, isNull);
      expect(notification.updatedAt, isNull);
    });

    test('should default createdAt to now when not provided', () {
      final json = {'type': 'test', 'title': 'Test', 'body': 'Test'};

      final notification = AppNotification.fromJson(json);

      // createdAt should be close to now
      final now = DateTime.now();
      expect(
        notification.createdAt.difference(now).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('should handle target_user_id as string', () {
      final json = {
        'id': 1,
        'type': 'request_created',
        'title': 'Test',
        'body': 'Test',
        'target_user_id': '10',
        'created_at': '2024-01-15T10:00:00.000',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.targetUserId, 10);
    });

    test('should handle related_id as string', () {
      final json = {
        'id': 1,
        'type': 'request_created',
        'title': 'Test',
        'body': 'Test',
        'related_id': '99',
        'created_at': '2024-01-15T10:00:00.000',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.relatedId, 99);
    });
  });

  group('AppNotification.toJson', () {
    test('should convert to JSON correctly', () {
      final notification = AppNotification(
        id: 1,
        type: 'incident_created',
        title: 'Sự cố mới',
        body: 'Nội dung',
        isRead: true,
        targetUserId: 5,
        actorUserId: 1,
        relatedId: 42,
        relatedCode: 'SV-0042',
        createdAt: DateTime(2024, 1, 15, 10, 0, 0),
        updatedAt: DateTime(2024, 1, 16, 10, 0, 0),
      );

      final json = notification.toJson();

      expect(json['id'], 1);
      expect(json['type'], 'incident_created');
      expect(json['title'], 'Sự cố mới');
      expect(json['body'], 'Nội dung');
      expect(json['is_read'], true);
      expect(json['target_user_id'], 5);
      expect(json['actor_user_id'], 1);
      expect(json['related_id'], 42);
      expect(json['related_code'], 'SV-0042');
      expect(json['created_at'], '2024-01-15T10:00:00.000');
      expect(json['updated_at'], '2024-01-16T10:00:00.000');
    });

    test('should not include null id', () {
      final notification = AppNotification(
        type: 'incident_created',
        title: 'Test',
        body: 'Test',
      );

      final json = notification.toJson();

      expect(json.containsKey('id'), isFalse);
    });

    test('should set updated_at to null when not provided', () {
      final notification = AppNotification(
        type: 'incident_created',
        title: 'Test',
        body: 'Test',
      );

      final json = notification.toJson();

      expect(json['updated_at'], isNull);
    });

    test('should include null optional fields as null', () {
      final notification = AppNotification(
        type: 'test',
        title: 'Test',
        body: 'Test',
      );

      final json = notification.toJson();

      expect(json['target_user_id'], isNull);
      expect(json['actor_user_id'], isNull);
      expect(json['related_id'], isNull);
      expect(json['related_code'], isNull);
    });
  });

  group('AppNotification.iconEmoji', () {
    test('should return 🆕 for incident_created', () {
      final notification = AppNotification(
        type: 'incident_created',
        title: 'Test',
        body: 'Test',
      );

      expect(notification.iconEmoji, '🆕');
    });

    test('should return ✏️ for incident_updated', () {
      final notification = AppNotification(
        type: 'incident_updated',
        title: 'Test',
        body: 'Test',
      );

      expect(notification.iconEmoji, '✏️');
    });

    test('should return 🗑️ for incident_deleted', () {
      final notification = AppNotification(
        type: 'incident_deleted',
        title: 'Test',
        body: 'Test',
      );

      expect(notification.iconEmoji, '🗑️');
    });

    test('should return 🔄 for incident_status_changed', () {
      final notification = AppNotification(
        type: 'incident_status_changed',
        title: 'Test',
        body: 'Test',
      );

      expect(notification.iconEmoji, '🔄');
    });

    test('should return 📋 for request_created', () {
      final notification = AppNotification(
        type: 'request_created',
        title: 'Test',
        body: 'Test',
      );

      expect(notification.iconEmoji, '📋');
    });

    test('should return ✅ for request_approved', () {
      final notification = AppNotification(
        type: 'request_approved',
        title: 'Test',
        body: 'Test',
      );

      expect(notification.iconEmoji, '✅');
    });

    test('should return ❌ for request_rejected', () {
      final notification = AppNotification(
        type: 'request_rejected',
        title: 'Test',
        body: 'Test',
      );

      expect(notification.iconEmoji, '❌');
    });

    test('should return 🔔 for unknown type', () {
      final notification = AppNotification(
        type: 'unknown_type',
        title: 'Test',
        body: 'Test',
      );

      expect(notification.iconEmoji, '🔔');
    });
  });
}
