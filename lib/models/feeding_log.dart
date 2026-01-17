import 'package:cloud_firestore/cloud_firestore.dart';

class FeedingLog {
  final String id;
  final String deviceId;
  final int foodRemaining;
  final DateTime lastSeen;
  final String source;
  final DateTime timestamp;
  final double portionSize; 

  FeedingLog({
    required this.id,
    required this.deviceId,
    required this.foodRemaining,
    required this.lastSeen,
    required this.source,
    required this.timestamp,
    this.portionSize = 0.0,
  });

  factory FeedingLog.fromFirestore(Map<String, dynamic> data, String docId) {
    return FeedingLog(
      id: docId,
      deviceId: data['device_id'] ?? '',
      foodRemaining: data['food_remaining'] ?? 0,
      lastSeen: _parseTimestamp(data['last_seen']),
      source: data['source'] ?? '',
      timestamp: _parseTimestamp(data['timestamp']),
      portionSize: (data['portion_size'] ?? 0).toDouble(),
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
      'device_id': deviceId,
      'food_remaining': foodRemaining,
      'last_seen': Timestamp.fromDate(lastSeen),
      'source': source,
      'timestamp': Timestamp.fromDate(timestamp),
      'portion_size': portionSize,
    };
  }
}
