import 'user_role.dart';

/// User profile model corresponding to public.profiles table
class UserProfile {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String? avatarPath;
  final String accountStatus;
  final List<UserRole> roles;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.avatarPath,
    this.accountStatus = 'active',
    this.roles = const [UserRole.customer],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => accountStatus == 'active';
  bool get isProvider => roles.contains(UserRole.provider);
  bool get isAdmin =>
      roles.contains(UserRole.admin) || roles.contains(UserRole.superAdmin);

  factory UserProfile.fromJson(
    Map<String, dynamic> json, [
    List<UserRole>? userRoles,
  ]) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'User',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatarPath: json['avatar_path'] as String?,
      accountStatus: json['account_status'] as String? ?? 'active',
      roles: userRoles ?? [UserRole.customer],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'avatar_path': avatarPath,
      'account_status': accountStatus,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? avatarPath,
    String? accountStatus,
    List<UserRole>? roles,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
      accountStatus: accountStatus ?? this.accountStatus,
      roles: roles ?? this.roles,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
