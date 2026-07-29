import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserRole = 'user_role';
  static const String keyFamilyId = 'family_id';
  static const String keyDeviceId = 'device_id';
  static const String keyChildName = 'child_name';
  static const String keyUserEmail = 'user_email';

  /// Save session state locally
  static Future<void> saveSession({
    required String role,
    String? email,
    String? familyId,
    String? deviceId,
    String? childName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, true);
    await prefs.setString(keyUserRole, role);
    if (email != null) await prefs.setString(keyUserEmail, email);
    if (familyId != null) await prefs.setString(keyFamilyId, familyId);
    if (deviceId != null) await prefs.setString(keyDeviceId, deviceId);
    if (childName != null) await prefs.setString(keyChildName, childName);
  }

  /// Get stored session details
  static Future<Map<String, dynamic>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isLoggedIn': prefs.getBool(keyIsLoggedIn) ?? false,
      'role': prefs.getString(keyUserRole) ?? 'parent',
      'email': prefs.getString(keyUserEmail),
      'familyId': prefs.getString(keyFamilyId),
      'deviceId': prefs.getString(keyDeviceId),
      'childName': prefs.getString(keyChildName),
    };
  }

  /// Clear session on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
