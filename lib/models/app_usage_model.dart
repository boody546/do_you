class AppUsageItem {
  final String packageName;
  final String appName;
  final int durationMinutes;
  final bool isBlocked;

  AppUsageItem({
    required this.packageName,
    required this.appName,
    required this.durationMinutes,
    this.isBlocked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'durationMinutes': durationMinutes,
      'isBlocked': isBlocked,
    };
  }

  factory AppUsageItem.fromMap(Map<String, dynamic> map) {
    return AppUsageItem(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      durationMinutes: (map['durationMinutes'] ?? 0) as int,
      isBlocked: map['isBlocked'] ?? false,
    );
  }
}
