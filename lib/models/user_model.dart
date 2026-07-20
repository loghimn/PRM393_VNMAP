class UserModel {
  final int? id;
  final String? uid; // Firebase Auth UID
  final String username;
  final String? passwordHash;
  final String? email;
  final String? fullName;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.id,
    this.uid,
    required this.username,
    this.passwordHash,
    this.email,
    this.fullName,
    this.phone,
    this.role = 'user',
    this.avatarUrl,
    this.isActive = true,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}'),
      uid: json['uid']?.toString(),
      username: json['username']?.toString() ?? '',
      passwordHash: json['password_hash']?.toString(),
      email: json['email']?.toString(),
      fullName: json['full_name']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'user',
      avatarUrl: json['avatar_url']?.toString(),
      isActive:
          json['is_active'] == true || json['is_active']?.toString() == 'true',
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      'username': username,
      'password_hash': passwordHash,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'avatar_url': avatarUrl,
      'is_active': isActive,
    };
  }
}
