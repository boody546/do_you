class FamilyModel {
  final String familyId;
  final String parentId;
  final String inviteCode;
  final DateTime codeExpiresAt;
  final List<String> childDeviceIds;

  FamilyModel({
    required this.familyId,
    required this.parentId,
    required this.inviteCode,
    required this.codeExpiresAt,
    required this.childDeviceIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'parentId': parentId,
      'inviteCode': inviteCode,
      'codeExpiresAt': codeExpiresAt.toIso8601String(),
      'childDeviceIds': childDeviceIds,
    };
  }

  factory FamilyModel.fromMap(Map<String, dynamic> map, String id) {
    return FamilyModel(
      familyId: id,
      parentId: map['parentId'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      codeExpiresAt: map['codeExpiresAt'] != null
          ? DateTime.parse(map['codeExpiresAt'])
          : DateTime.now().add(const Duration(hours: 24)),
      childDeviceIds: List<String>.from(map['childDeviceIds'] ?? []),
    );
  }
}
