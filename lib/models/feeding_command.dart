import 'package:cloud_firestore/cloud_firestore.dart';

class FeedingCommand {
  final String id;
  final String deviceId;
  final int portionSize; 
  final String status; 
  final DateTime createdAt;
  final DateTime? executedAt;
  final String? errorMessage;

  FeedingCommand({
    required this.id,
    required this.deviceId,
    required this.portionSize,
    required this.status,
    required this.createdAt,
    this.executedAt,
    this.errorMessage,
  });

  // Create from Firestore document
  factory FeedingCommand.fromFirestore(Map<String, dynamic> data, String docId) {
    return FeedingCommand(
      id: docId,
      deviceId: data['device_id'] ?? '',
      portionSize: data['portion_size'] ?? 0,
      status: data['status'] ?? 'pending',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      executedAt: data['executed_at'] != null 
          ? (data['executed_at'] as Timestamp).toDate() 
          : null,
      errorMessage: data['error_message'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'device_id': deviceId,
      'portion_size': portionSize,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'executed_at': executedAt != null ? Timestamp.fromDate(executedAt!) : null,
      'error_message': errorMessage,
    };
  }
}
