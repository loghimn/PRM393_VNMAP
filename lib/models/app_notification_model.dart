/// Model cho In-App Notification (🔔)
///
/// Hỗ trợ 6 loại thông báo:
/// 1. Incident: Tạo mới → Admin nhận
/// 2. Incident: Cập nhật → Người tạo nhận
/// 3. Incident: Xóa → Người tạo nhận
/// 4. Incident: Thay đổi status → Admin + người tạo nhận
/// 5. Household Request: Tạo request → Admin nhận
/// 6. Household Request: Duyệt/từ chối → Người request nhận
class AppNotification {
  final int? id;
  final String
  type; // incident_created, incident_updated, incident_deleted, incident_status_changed, request_created, request_approved
  final String title;
  final String body;
  final bool isRead;
  final int? targetUserId; // ID của user nhận thông báo
  final int? actorUserId; // ID của user thực hiện hành động
  final int? relatedId; // ID của incident hoặc household_request
  final String? relatedCode; // Mã code: SV-0042, HGD-0038
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppNotification({
    this.id,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.targetUserId,
    this.actorUserId,
    this.relatedId,
    this.relatedCode,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}'),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      isRead: json['is_read'] == true || json['is_read']?.toString() == 'true',
      targetUserId: json['target_user_id'] is int
          ? json['target_user_id']
          : int.tryParse('${json['target_user_id']}'),
      actorUserId: json['actor_user_id'] is int
          ? json['actor_user_id']
          : int.tryParse('${json['actor_user_id']}'),
      relatedId: json['related_id'] is int
          ? json['related_id']
          : int.tryParse('${json['related_id']}'),
      relatedCode: json['related_code']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'title': title,
      'body': body,
      'is_read': isRead,
      'target_user_id': targetUserId,
      'actor_user_id': actorUserId,
      'related_id': relatedId,
      'related_code': relatedCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Icon emoji tương ứng với type
  String get iconEmoji {
    switch (type) {
      case 'incident_created':
        return '🆕';
      case 'incident_updated':
        return '✏️';
      case 'incident_deleted':
        return '🗑️';
      case 'incident_status_changed':
        return '🔄';
      case 'request_created':
        return '📋';
      case 'request_approved':
        return '✅';
      case 'request_rejected':
        return '❌';
      default:
        return '🔔';
    }
  }
}
