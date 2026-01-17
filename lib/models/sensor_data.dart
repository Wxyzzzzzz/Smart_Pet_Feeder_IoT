import 'package:cloud_firestore/cloud_firestore.dart';

class SensorData {
  final String id;
  final bool detected;
  final String deviceId;
  final int foodLevel;
  final int humidity;
  final DateTime lastSeen;
  final double temp; 
  final DateTime timestamp;
  final String? type; 

  SensorData({
    required this.id,
    required this.detected,
    required this.deviceId,
    required this.foodLevel,
    required this.humidity,
    required this.lastSeen,
    required this.temp,
    required this.timestamp,
    this.type,
  });

  factory SensorData.fromFirestore(Map<String, dynamic> data, String docId) {
    print('Parsing sensor data from doc $docId: ${data.keys.toList()}');
    
    return SensorData(
      id: docId,
      detected: data['detected'] ?? false,
      deviceId: data['device_id'] ?? '',
      foodLevel: (data['food_level'] ?? 0).toInt(),
      humidity: (data['humidity'] ?? 0).toInt(),
      lastSeen: _parseTimestamp(data['last_seen']),
      temp: (data['temp'] ?? 0).toDouble(),
      timestamp: _parseTimestamp(data['timestamp']),
      type: data['type'] as String?,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return DateTime.now();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'detected': detected,
      'device_id': deviceId,
      'food_level': foodLevel,
      'humidity': humidity,
      'last_seen': Timestamp.fromDate(lastSeen),
      'temp': temp,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
