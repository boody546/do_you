class ChildDeviceModel {
  final String deviceId;
  final String childName;
  final String deviceModel;
  final int batteryLevel;
  final bool isLocked;
  final bool isOnline;
  final int dailyTimeLimitMinutes;
  final int usedMinutesToday;
  final List<String> blockedAppPackages;
  final double latitude;
  final double longitude;
  final DateTime lastSeen;

  ChildDeviceModel({
    required this.deviceId,
    required this.childName,
    required this.deviceModel,
    required this.batteryLevel,
    required this.isLocked,
    required this.isOnline,
    required this.dailyTimeLimitMinutes,
    required this.usedMinutesToday,
    required this.blockedAppPackages,
    required this.latitude,
    required this.longitude,
    required this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'childName': childName,
      'deviceModel': deviceModel,
      'batteryLevel': batteryLevel,
      'isLocked': isLocked,
      'isOnline': isOnline,
      'dailyTimeLimitMinutes': dailyTimeLimitMinutes,
      'usedMinutesToday': usedMinutesToday,
      'blockedAppPackages': blockedAppPackages,
      'latitude': latitude,
      'longitude': longitude,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  factory ChildDeviceModel.fromMap(Map<String, dynamic> map, String id) {
    return ChildDeviceModel(
      deviceId: id,
      childName: map['childName'] ?? 'Child Device',
      deviceModel: map['deviceModel'] ?? 'Android Phone',
      batteryLevel: (map['batteryLevel'] ?? 85) as int,
      isLocked: map['isLocked'] ?? false,
      isOnline: map['isOnline'] ?? true,
      dailyTimeLimitMinutes: (map['dailyTimeLimitMinutes'] ?? 120) as int,
      usedMinutesToday: (map['usedMinutesToday'] ?? 45) as int,
      blockedAppPackages: List<String>.from(map['blockedAppPackages'] ?? []),
      latitude: (map['latitude'] ?? 30.0444) as double,
      longitude: (map['longitude'] ?? 31.2357) as double,
      lastSeen: map['lastSeen'] != null
          ? DateTime.parse(map['lastSeen'])
          : DateTime.now(),
    );
  }
}
