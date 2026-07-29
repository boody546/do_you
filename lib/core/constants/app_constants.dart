class AppConstants {
  static const String appName = 'DO you';
  static const String appTagline = 'Smart Family Shield & Child Protection';

  // Method Channel
  static const String nativeChannelName = 'com.doyou.parentalcontrol/native_admin';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String familiesCollection = 'families';
  static const String childDevicesCollection = 'child_devices';
  static const String appUsageStatsCollection = 'app_usage_stats';
  static const String deviceCommandsCollection = 'device_commands';

  // Roles
  static const String roleParent = 'parent';
  static const String roleChild = 'child';

  // Default Policy Settings
  static const int defaultDailyQuotaMinutes = 120; // 2 hours
  static const String defaultBedtimeStart = '21:00';
  static const String defaultBedtimeEnd = '07:00';
}
