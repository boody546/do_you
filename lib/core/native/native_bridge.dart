import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel(AppConstants.nativeChannelName);

  /// Trigger instant hardware device lock on Android via DevicePolicyManager
  static Future<bool> lockScreen() async {
    try {
      final bool result = await _channel.invokeMethod('lockScreen');
      return result;
    } on PlatformException catch (e) {
      print('NativeBridge lockScreen error: ${e.message}');
      return false;
    } catch (e) {
      print('NativeBridge generic error: $e');
      return false;
    }
  }

  /// Check if Device Admin permission is enabled for DO you
  static Future<bool> isAdminActive() async {
    try {
      final bool result = await _channel.invokeMethod('isAdminActive');
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Request Device Admin permission setup screen
  static Future<bool> requestAdminPermission() async {
    try {
      final bool result = await _channel.invokeMethod('requestAdminPermission');
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Check if Usage Access permission is granted
  static Future<bool> hasUsagePermission() async {
    try {
      final bool result = await _channel.invokeMethod('hasUsagePermission');
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Request Usage Access permission settings page
  static Future<bool> requestUsagePermission() async {
    try {
      final bool result = await _channel.invokeMethod('requestUsagePermission');
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Fetch list of installed app usage stats for today
  static Future<List<Map<String, dynamic>>> getDailyAppUsage() async {
    try {
      final List<dynamic>? rawList = await _channel.invokeMethod('getDailyAppUsage');
      if (rawList == null) return [];

      return rawList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (e) {
      print('Failed to get daily usage stats: $e');
      return [];
    }
  }
}
