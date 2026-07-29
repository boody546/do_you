import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel(AppConstants.nativeChannelName);

  /// Trigger instant hardware device lock on Android via DevicePolicyManager
  static Future<bool> lockScreen() async {
    try {
      final bool result = await _channel.invokeMethod('lockScreen');
      return result;
    } catch (e) {
      print('NativeBridge lockScreen error: $e');
      return false;
    }
  }

  /// 1. Remote Camera Lock (DevicePolicyManager.setCameraDisabled)
  static Future<bool> setCameraDisabled(bool disabled) async {
    try {
      final bool result = await _channel.invokeMethod('setCameraDisabled', {'disabled': disabled});
      return result;
    } catch (e) {
      print('NativeBridge setCameraDisabled error: $e');
      return false;
    }
  }

  /// 2. Remote Mute / Ringer Mode Control
  static Future<bool> setRingerMute(bool mute) async {
    try {
      final bool result = await _channel.invokeMethod('setRingerMute', {'mute': mute});
      return result;
    } catch (e) {
      print('NativeBridge setRingerMute error: $e');
      return false;
    }
  }

  /// 3. Wi-Fi Kill Switch
  static Future<bool> toggleWifi(bool enable) async {
    try {
      final bool result = await _channel.invokeMethod('toggleWifi', {'enable': enable});
      return result;
    } catch (e) {
      print('NativeBridge toggleWifi error: $e');
      return false;
    }
  }

  /// 4. Instant Siren Alarm Play
  static Future<bool> playSirenAlarm() async {
    try {
      final bool result = await _channel.invokeMethod('playSirenAlarm');
      return result;
    } catch (e) {
      print('NativeBridge playSirenAlarm error: $e');
      return false;
    }
  }

  /// Stop Siren Alarm
  static Future<bool> stopSirenAlarm() async {
    try {
      final bool result = await _channel.invokeMethod('stopSirenAlarm');
      return result;
    } catch (e) {
      print('NativeBridge stopSirenAlarm error: $e');
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
