import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/family_model.dart';
import '../models/child_device_model.dart';
import '../models/sos_alert_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Save user profile
  Future<void> saveUserProfile(UserModel user) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  /// Get user profile by UID
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print('getUserProfile error: $e');
    }
    return null;
  }

  /// Generate 6-digit invitation code for Parent device pairing
  Future<String> generatePairingCode(String parentId) async {
    final String randomCode = (100000 + Random().nextInt(900000)).toString();
    final String familyId = 'fam_${parentId.substring(0, min(6, parentId.length))}';

    final family = FamilyModel(
      familyId: familyId,
      parentId: parentId,
      inviteCode: randomCode,
      codeExpiresAt: DateTime.now().add(const Duration(hours: 24)),
      childDeviceIds: [],
    );

    await _db
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .set(family.toMap(), SetOptions(merge: true));

    // Update parent user with familyId
    await _db
        .collection(AppConstants.usersCollection)
        .doc(parentId)
        .set({'familyId': familyId}, SetOptions(merge: true));

    return randomCode;
  }

  /// Verify 6-digit pairing code on Child Device
  Future<FamilyModel?> pairChildWithCode({
    required String code,
    required String childDeviceName,
    required String deviceId,
  }) async {
    try {
      final query = await _db
          .collection(AppConstants.familiesCollection)
          .where('inviteCode', isEqualTo: code.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final familyDoc = query.docs.first;
      final family = FamilyModel.fromMap(familyDoc.data(), familyDoc.id);

      // Register child device document
      final newChildDevice = ChildDeviceModel(
        deviceId: deviceId,
        childName: childDeviceName,
        deviceModel: 'Android Phone',
        batteryLevel: 95,
        isLocked: false,
        isOnline: true,
        dailyTimeLimitMinutes: AppConstants.defaultDailyQuotaMinutes,
        usedMinutesToday: 35,
        blockedAppPackages: [],
        latitude: 30.0444,
        longitude: 31.2357,
        lastSeen: DateTime.now(),
      );

      await _db
          .collection(AppConstants.childDevicesCollection)
          .doc(deviceId)
          .set(newChildDevice.toMap(), SetOptions(merge: true));

      // Add child deviceId to family doc
      await _db
          .collection(AppConstants.familiesCollection)
          .doc(family.familyId)
          .set({
        'childDeviceIds': FieldValue.arrayUnion([deviceId])
      }, SetOptions(merge: true));

      return family;
    } catch (e) {
      print('pairChildWithCode error: $e');
      rethrow;
    }
  }

  /// Stream single child device state
  Stream<ChildDeviceModel?> streamChildDevice(String deviceId) {
    return _db
        .collection(AppConstants.childDevicesCollection)
        .doc(deviceId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return ChildDeviceModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  /// Stream strictly REAL linked child devices for Parent (NO Dummy Devices!)
  Stream<List<ChildDeviceModel>> streamFamilyChildDevices(String familyId) {
    return _db
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .snapshots()
        .asyncMap((familySnap) async {
      if (!familySnap.exists || familySnap.data() == null) return [];

      final family = FamilyModel.fromMap(familySnap.data()!, familySnap.id);
      if (family.childDeviceIds.isEmpty) return [];

      final List<ChildDeviceModel> devices = [];
      for (String devId in family.childDeviceIds) {
        final devDoc = await _db
            .collection(AppConstants.childDevicesCollection)
            .doc(devId)
            .get();
        if (devDoc.exists && devDoc.data() != null) {
          devices.add(ChildDeviceModel.fromMap(devDoc.data()!, devDoc.id));
        }
      }
      return devices;
    });
  }

  /// Manage Children - Rename Child Device
  Future<void> renameChildDevice(String deviceId, String newName) async {
    await _db
        .collection(AppConstants.childDevicesCollection)
        .doc(deviceId)
        .update({'childName': newName});
  }

  /// Manage Children - Unpair & Remove Child Device
  Future<void> unpairChildDevice(String familyId, String deviceId) async {
    await _db.collection(AppConstants.familiesCollection).doc(familyId).update({
      'childDeviceIds': FieldValue.arrayRemove([deviceId])
    });

    await _db
        .collection(AppConstants.childDevicesCollection)
        .doc(deviceId)
        .delete();
  }

  // --- 6 NEW CONTROL TOOL FIRESTORE UPDATES ---

  /// 1. Wi-Fi Kill Switch
  Future<void> toggleWifiKill(String deviceId, bool disableWifi) async {
    await _db
        .collection(AppConstants.childDevicesCollection)
        .doc(deviceId)
        .update({'isWifiDisabled': disableWifi});
  }

  /// 2. Remote Mute / Ringer Control
  Future<void> toggleRingerMute(String deviceId, bool isMuted) async {
    await _db
        .collection(AppConstants.childDevicesCollection)
        .doc(deviceId)
        .update({'isMuted': isMuted});
  }

  /// 3. Remote Camera Lock
  Future<void> toggleCameraLock(String deviceId, bool disableCamera) async {
    await _db
        .collection(AppConstants.childDevicesCollection)
        .doc(deviceId)
        .update({'isCameraDisabled': disableCamera});
  }

  /// 4. Instant Siren Phone Alarm
  Future<void> toggleSirenAlarm(String deviceId, bool active) async {
    await _db
        .collection(AppConstants.childDevicesCollection)
        .doc(deviceId)
        .update({'isSirenActive': active});
  }

  /// 5. Bedtime Schedule Lock
  Future<void> setBedtimeSchedule(String deviceId, String start, String end) async {
    await _db
        .collection(AppConstants.childDevicesCollection)
        .doc(deviceId)
        .update({
      'bedtimeStart': start,
      'bedtimeEnd': end,
    });
  }

  /// 6. App Installation Blocker
  Future<void> toggleAppInstallBlock(String deviceId, bool block) async {
    await _db
        .collection(AppConstants.childDevicesCollection)
        .doc(deviceId)
        .update({'isInstallBlocked': block});
  }

  /// Trigger Child SOS Emergency Alert to Firestore
  Future<void> sendSOSAlert({
    required String deviceId,
    required String childName,
    double latitude = 30.0444,
    double longitude = 31.2357,
  }) async {
    final alertId = 'sos_${DateTime.now().millisecondsSinceEpoch}';
    final alert = SOSAlertModel(
      alertId: alertId,
      deviceId: deviceId,
      childName: childName,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      isResolved: false,
    );

    await _db
        .collection('sos_alerts')
        .doc(alertId)
        .set(alert.toMap(), SetOptions(merge: true));
  }

  /// Stream active unresolved SOS Alerts for Parent App
  Stream<List<SOSAlertModel>> streamSOSAlerts() {
    return _db
        .collection('sos_alerts')
        .where('isResolved', isEqualTo: false)
        .snapshots()
        .map((query) => query.docs
            .map((doc) => SOSAlertModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Dismiss/Resolve SOS Alert
  Future<void> resolveSOSAlert(String alertId) async {
    await _db.collection('sos_alerts').doc(alertId).update({'isResolved': true});
  }

  /// Update screen lock state on child device
  Future<void> setDeviceLockState(String deviceId, bool isLocked) async {
    await _db
        .collection(AppConstants.childDevicesCollection)
        .doc(deviceId)
        .update({'isLocked': isLocked});
  }

  /// Update daily time limit for child device
  Future<void> setDailyTimeLimit(String deviceId, int limitMinutes) async {
    await _db
        .collection(AppConstants.childDevicesCollection)
        .doc(deviceId)
        .update({'dailyTimeLimitMinutes': limitMinutes});
  }

  /// Toggle app block status
  Future<void> toggleAppBlock(String deviceId, String packageName, bool block) async {
    final docRef = _db.collection(AppConstants.childDevicesCollection).doc(deviceId);
    if (block) {
      await docRef.update({
        'blockedAppPackages': FieldValue.arrayUnion([packageName])
      });
    } else {
      await docRef.update({
        'blockedAppPackages': FieldValue.arrayRemove([packageName])
      });
    }
  }

  /// Update Child Device Location GPS
  Future<void> updateChildLocation({
    required String deviceId,
    required double latitude,
    required double longitude,
  }) async {
    await _db
        .collection(AppConstants.childDevicesCollection)
        .doc(deviceId)
        .update({
      'latitude': latitude,
      'longitude': longitude,
      'lastSeen': DateTime.now().toIso8601String(),
    });
  }
}
