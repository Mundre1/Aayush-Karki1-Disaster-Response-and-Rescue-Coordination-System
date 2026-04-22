class UserModel {
  final int userId;
  final String name;
  final String email;
  final String? phone;
  final int roleId;
  final String? roleName;
  final DateTime? createdAt;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.roleId,
    this.roleName,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int
    int parseInt(String camelKey, String snakeKey, {int defaultValue = 0}) {
      final value = json[camelKey] ?? json[snakeKey];
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return UserModel(
      userId: parseInt('userId', 'user_id'),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      roleId: parseInt('roleId', 'role_id', defaultValue: 0),
      roleName: json['roleName'] ?? json['role']?['roleName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'roleId': roleId,
      'roleName': roleName,
    };
  }
}
