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

  // 6 New Remote Control Tool Settings
  final bool isWifiDisabled;
  final bool isMuted;
  final bool isCameraDisabled;
  final bool isSirenActive;
  final bool isInstallBlocked;
  final String bedtimeStart;
  final String bedtimeEnd;

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
    this.isWifiDisabled = false,
    this.isMuted = false,
    this.isCameraDisabled = false,
    this.isSirenActive = false,
    this.isInstallBlocked = false,
    this.bedtimeStart = '21:00',
    this.bedtimeEnd = '07:00',
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
      'isWifiDisabled': isWifiDisabled,
      'isMuted': isMuted,
      'isCameraDisabled': isCameraDisabled,
      'isSirenActive': isSirenActive,
      'isInstallBlocked': isInstallBlocked,
      'bedtimeStart': bedtimeStart,
      'bedtimeEnd': bedtimeEnd,
    };
  }

  factory ChildDeviceModel.fromMap(Map<String, dynamic> map, String id) {
    return ChildDeviceModel(
      deviceId: id,
      childName: map['childName'] ?? 'Child Device',
      deviceModel: map['deviceModel'] ?? 'Android Phone',
      batteryLevel: (map['batteryLevel'] ?? 88) as int,
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
      isWifiDisabled: map['isWifiDisabled'] ?? false,
      isMuted: map['isMuted'] ?? false,
      isCameraDisabled: map['isCameraDisabled'] ?? false,
      isSirenActive: map['isSirenActive'] ?? false,
      isInstallBlocked: map['isInstallBlocked'] ?? false,
      bedtimeStart: map['bedtimeStart'] ?? '21:00',
      bedtimeEnd: map['bedtimeEnd'] ?? '07:00',
    );
  }
}
