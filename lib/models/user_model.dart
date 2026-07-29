class UserModel {
  final String uid;
  final String email;
  final String role; // 'parent' or 'child'
  final String? familyId;
  final String? deviceId;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.familyId,
    this.deviceId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'familyId': familyId,
      'deviceId': deviceId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      role: map['role'] ?? 'parent',
      familyId: map['familyId'],
      deviceId: map['deviceId'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
