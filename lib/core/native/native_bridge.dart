import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class NativeBridge {
  static const MethodChannel _channel =
      MethodChannel(AppConstants.nativeChannelName);

  // ── Screen Lock ────────────────────────────────────────────────────────────
  static Future<bool> lockScreen() async {
    try {
      return await _channel.invokeMethod('lockScreen');
    } catch (e) {
      print('lockScreen error: $e');
      return false;
    }
  }

  // ── Factory Reset (wipeData) ────────────────────────────────────────────────
  static Future<bool> factoryReset() async {
    try {
      return await _channel.invokeMethod('factoryReset');
    } catch (e) {
      print('factoryReset error: $e');
      return false;
    }
  }

  // ── Anti-Theft Siren (DND Override) ────────────────────────────────────────
  static Future<bool> playSirenAlarm() async {
    try {
      return await _channel.invokeMethod('playSirenAlarm');
    } catch (e) {
      print('playSirenAlarm error: $e');
      return false;
    }
  }

  static Future<bool> stopSirenAlarm() async {
    try {
      return await _channel.invokeMethod('stopSirenAlarm');
    } catch (e) {
      print('stopSirenAlarm error: $e');
      return false;
    }
  }

  // ── Camera Lock ─────────────────────────────────────────────────────────────
  static Future<bool> setCameraDisabled(bool disabled) async {
    try {
      return await _channel
          .invokeMethod('setCameraDisabled', {'disabled': disabled});
    } catch (e) {
      print('setCameraDisabled error: $e');
      return false;
    }
  }

  // ── Remote Mute ─────────────────────────────────────────────────────────────
  static Future<bool> setRingerMute(bool mute) async {
    try {
      return await _channel.invokeMethod('setRingerMute', {'mute': mute});
    } catch (e) {
      print('setRingerMute error: $e');
      return false;
    }
  }

  // ── Wi-Fi Kill Switch ────────────────────────────────────────────────────────
  static Future<bool> toggleWifi(bool enable) async {
    try {
      return await _channel.invokeMethod('toggleWifi', {'enable': enable});
    } catch (e) {
      print('toggleWifi error: $e');
      return false;
    }
  }

  // ── Accessibility Service ────────────────────────────────────────────────────
  static Future<bool> isAccessibilityEnabled() async {
    try {
      return await _channel.invokeMethod('isAccessibilityEnabled');
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestAccessibilityPermission() async {
    try {
      return await _channel.invokeMethod('requestAccessibilityPermission');
    } catch (e) {
      return false;
    }
  }

  static Future<String> getLastBrowserUrl() async {
    try {
      final String url =
          await _channel.invokeMethod('getLastBrowserUrl');
      return url;
    } catch (e) {
      return '';
    }
  }

  // ── DND Permission ───────────────────────────────────────────────────────────
  static Future<bool> hasDNDPermission() async {
    try {
      return await _channel.invokeMethod('hasDNDPermission');
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestDNDPermission() async {
    try {
      return await _channel.invokeMethod('requestDNDPermission');
    } catch (e) {
      return false;
    }
  }

  // ── Device Admin ─────────────────────────────────────────────────────────────
  static Future<bool> isAdminActive() async {
    try {
      return await _channel.invokeMethod('isAdminActive');
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestAdminPermission() async {
    try {
      return await _channel.invokeMethod('requestAdminPermission');
    } catch (e) {
      return false;
    }
  }

  // ── Usage Stats ──────────────────────────────────────────────────────────────
  static Future<bool> hasUsagePermission() async {
    try {
      return await _channel.invokeMethod('hasUsagePermission');
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestUsagePermission() async {
    try {
      return await _channel.invokeMethod('requestUsagePermission');
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getDailyAppUsage() async {
    try {
      final List<dynamic>? raw =
          await _channel.invokeMethod('getDailyAppUsage');
      if (raw == null) return [];
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      print('getDailyAppUsage error: $e');
      return [];
    }
  }

  // ── Firebase Command Listener Service ────────────────────────────────────────
  /// Starts the native Kotlin foreground service that listens to Firebase RTDB
  /// for remote commands (trigger_alarm, lock_screen, wipe_data).
  static Future<bool> startCommandListener(String deviceId) async {
    try {
      return await _channel.invokeMethod(
          'startCommandListener', {'deviceId': deviceId});
    } catch (e) {
      print('startCommandListener error: $e');
      return false;
    }
  }

  static Future<bool> stopCommandListener() async {
    try {
      return await _channel.invokeMethod('stopCommandListener');
    } catch (e) {
      print('stopCommandListener error: $e');
      return false;
    }
  }
}
