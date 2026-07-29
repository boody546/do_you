import 'dart:async';
import 'package:flutter/material.dart';
import '../models/child_device_model.dart';
import '../models/app_usage_model.dart';
import '../services/firestore_service.dart';
import '../core/native/native_bridge.dart';

class ChildDeviceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  ChildDeviceModel? _childDevice;
  List<ChildDeviceModel> _familyDevices = [];
  List<AppUsageItem> _appUsageList = [];
  bool _isLoading = false;
  
  StreamSubscription<ChildDeviceModel?>? _deviceSubscription;
  StreamSubscription<List<ChildDeviceModel>>? _familyDevicesSubscription;

  ChildDeviceModel? get childDevice => _childDevice;
  List<ChildDeviceModel> get familyDevices => _familyDevices;
  List<AppUsageItem> get appUsageList => _appUsageList;
  bool get isLoading => _isLoading;
  bool get isLocked => _childDevice?.isLocked ?? false;

  /// Start listening to single child device state in Firestore (Memory Safe)
  void listenToChildDevice(String deviceId) {
    _deviceSubscription?.cancel();
    _deviceSubscription = _firestoreService.streamChildDevice(deviceId).listen((device) {
      _childDevice = device;
      notifyListeners();
    });
  }

  /// Start listening to strictly REAL paired children devices for Parent (Memory Safe)
  void listenToFamilyDevices(String familyId) {
    _familyDevicesSubscription?.cancel();
    _familyDevicesSubscription = _firestoreService.streamFamilyChildDevices(familyId).listen((devices) {
      _familyDevices = devices;
      notifyListeners();
    });
  }

  /// Toggle instant screen lock
  Future<void> toggleRemoteLock(String deviceId, bool lockState) async {
    await _firestoreService.setDeviceLockState(deviceId, lockState);
  }

  /// Update daily screen time quota limit (minutes)
  Future<void> setDailyLimit(String deviceId, int limitMinutes) async {
    await _firestoreService.setDailyTimeLimit(deviceId, limitMinutes);
  }

  /// Toggle specific app block status
  Future<void> toggleAppBlock(String deviceId, String packageName, bool currentBlocked) async {
    await _firestoreService.toggleAppBlock(deviceId, packageName, !currentBlocked);
  }

  // --- 6 NEW REMOTE CONTROL TOOLS ---

  /// 1. Wi-Fi Kill Switch
  Future<void> toggleWifiKill(String deviceId, bool currentDisabled) async {
    await _firestoreService.toggleWifiKill(deviceId, !currentDisabled);
  }

  /// 2. Remote Mute / Ringer Control
  Future<void> toggleRingerMute(String deviceId, bool currentMuted) async {
    await _firestoreService.toggleRingerMute(deviceId, !currentMuted);
  }

  /// 3. Remote Camera Lock
  Future<void> toggleCameraLock(String deviceId, bool currentDisabled) async {
    await _firestoreService.toggleCameraLock(deviceId, !currentDisabled);
  }

  /// 4. Instant Siren Alarm
  Future<void> toggleSirenAlarm(String deviceId, bool active) async {
    await _firestoreService.toggleSirenAlarm(deviceId, active);
  }

  /// 5. Bedtime Schedule Lock
  Future<void> setBedtimeSchedule(String deviceId, String start, String end) async {
    await _firestoreService.setBedtimeSchedule(deviceId, start, end);
  }

  /// 6. App Installation Blocker
  Future<void> toggleAppInstallBlock(String deviceId, bool currentBlocked) async {
    await _firestoreService.toggleAppInstallBlock(deviceId, !currentBlocked);
  }

  // --- MANAGE CHILDREN ---

  /// Rename Child Device
  Future<void> renameChildDevice(String deviceId, String newName) async {
    await _firestoreService.renameChildDevice(deviceId, newName);
  }

  /// Unpair Child Device
  Future<void> unpairChildDevice(String familyId, String deviceId) async {
    await _firestoreService.unpairChildDevice(familyId, deviceId);
  }

  /// Load daily app usage metrics via Native Kotlin Channel
  Future<void> loadNativeUsageStats() async {
    _isLoading = true;
    notifyListeners();

    final rawStats = await NativeBridge.getDailyAppUsage();
    _appUsageList = rawStats.map((item) {
      final int totalMs = (item['totalTimeMs'] ?? 0) as int;
      final int minutes = (totalMs / (1000 * 60)).round();
      return AppUsageItem(
        packageName: item['packageName'] ?? 'com.app',
        appName: item['appName'] ?? 'App',
        durationMinutes: minutes,
      );
    }).toList();

    _appUsageList.sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // Explicit Stream Cancellation to Prevent Memory Leaks & Freezes
    _deviceSubscription?.cancel();
    _familyDevicesSubscription?.cancel();
    super.dispose();
  }
}
