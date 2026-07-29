class SOSAlertModel {
  final String alertId;
  final String deviceId;
  final String childName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool isResolved;

  SOSAlertModel({
    required this.alertId,
    required this.deviceId,
    required this.childName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.isResolved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'alertId': alertId,
      'deviceId': deviceId,
      'childName': childName,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'isResolved': isResolved,
    };
  }

  factory SOSAlertModel.fromMap(Map<String, dynamic> map, String id) {
    return SOSAlertModel(
      alertId: id,
      deviceId: map['deviceId'] ?? '',
      childName: map['childName'] ?? 'Child Device',
      latitude: (map['latitude'] ?? 30.0444) as double,
      longitude: (map['longitude'] ?? 31.2357) as double,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      isResolved: map['isResolved'] ?? false,
    );
  }
}
