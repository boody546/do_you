import 'dart:async';
import 'package:flutter/material.dart';
import '../models/child_device_model.dart';
import '../models/app_usage_model.dart';
import '../services/firestore_service.dart';
import '../core/native/native_bridge.dart';

class ChildDeviceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  ChildDeviceModel? _childDevice;
  List<AppUsageItem> _appUsageList = [];
  bool _isLoading = false;
  StreamSubscription<ChildDeviceModel?>? _deviceSubscription;

  ChildDeviceModel? get childDevice => _childDevice;
  List<AppUsageItem> get appUsageList => _appUsageList;
  bool get isLoading => _isLoading;
  bool get isLocked => _childDevice?.isLocked ?? false;

  /// Start listening to child device state in Firestore
  void listenToChildDevice(String deviceId) {
    _deviceSubscription?.cancel();
    _deviceSubscription = _firestoreService.streamChildDevice(deviceId).listen((device) {
      _childDevice = device;
      notifyListeners();
    });
  }

  /// Toggle instant screen lock from Parent App
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

    // Sort by duration descending
    _appUsageList.sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    super.dispose();
  }
}
