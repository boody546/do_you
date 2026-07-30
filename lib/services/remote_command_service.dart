import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

/// Parent-side service that writes remote commands to Firebase Realtime Database.
/// The child device's [CommandListenerService] (Kotlin) picks them up instantly.
class RemoteCommandService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Internal helper: write a command entry to RTDB for a given device
  Future<void> _sendCommand(String deviceId, String command) async {
    try {
      final ref = _db.ref('device_commands/$deviceId');
      await ref.set({
        'command': command,
        'status': 'pending',
        'sentAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('RemoteCommandService._sendCommand error: $e');
      rethrow;
    }
  }

  // ── 1. Trigger Anti-Theft Siren Alarm ────────────────────────────────────────
  Future<void> triggerAlarm(String deviceId) =>
      _sendCommand(deviceId, 'trigger_alarm');

  // ── 2. Stop Siren Alarm ──────────────────────────────────────────────────────
  Future<void> stopAlarm(String deviceId) =>
      _sendCommand(deviceId, 'stop_alarm');

  // ── 3. Remote Hardware Screen Lock ───────────────────────────────────────────
  Future<void> lockScreen(String deviceId) =>
      _sendCommand(deviceId, 'lock_screen');

  // ── 4. Factory Reset (wipeData) ──────────────────────────────────────────────
  Future<void> wipeDevice(String deviceId) =>
      _sendCommand(deviceId, 'wipe_data');

  // ── 5. Request Real-time Location Update ─────────────────────────────────────
  Future<void> requestLocation(String deviceId) =>
      _sendCommand(deviceId, 'locate_device');

  // ── Listen for last known location of child device ───────────────────────────
  Stream<Map<String, dynamic>?> streamChildLocation(String deviceId) {
    return _db
        .ref('device_locations/$deviceId')
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return null;
      return Map<String, dynamic>.from(data as Map);
    });
  }
}

/// Child-side service that streams GPS location to Firebase Realtime Database.
/// Called from [ChildDashboard] after [CommandListenerService] starts.
class LocationStreamService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  StreamSubscription<Position>? _positionSubscription;

  /// Start streaming GPS position updates to Firebase RTDB
  Future<void> startStreaming(String deviceId) async {
    // Request permission first
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      print('LocationStreamService: Location permission permanently denied');
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // update every 10 metres
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) async {
      try {
        await _db.ref('device_locations/$deviceId').set({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'speed': position.speed,
          'timestamp': ServerValue.timestamp,
        });
      } catch (e) {
        print('LocationStreamService: write error $e');
      }
    });
  }

  /// Stop streaming GPS updates
  void stopStreaming() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
