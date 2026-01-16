import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feeding_log.dart';
import '../models/sensor_data.dart';
import '../models/feeding_command.dart';
import '../models/routine.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String deviceId = 'feeder_001';

  // Get reference to feeder document
  DocumentReference get _feederRef =>
      _firestore.collection('feeders').doc(deviceId);

  // ===== FEEDING LOGS =====

  // Get all feeding logs (for history screen)
  Stream<List<FeedingLog>> getFeedingLogs({int limit = 50}) {
    return _feederRef
        .collection('feeding_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedingLog.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Add new feeding log
  Future<void> addFeedingLog({
    required int foodRemaining,
    required String source, // "manually" or "scheduled"
    double portionSize = 0.0, // in grams
  }) async {
    try {
      await _feederRef.collection('feeding_logs').add({
        'device_id': deviceId,
        'food_remaining': foodRemaining,
        'last_seen': FieldValue.serverTimestamp(),
        'source': source,
        'timestamp': FieldValue.serverTimestamp(),
        'portion_size': portionSize,
      });
    } catch (e) {
      print('Error adding feeding log: $e');
      rethrow;
    }
  }

  // Get feeding logs for specific date range (for analytics)
  Stream<List<FeedingLog>> getFeedingLogsByDateRange(
      DateTime start, DateTime end) {
    return _feederRef
        .collection('feeding_logs')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThanOrEqualTo: end)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedingLog.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Get today's feeding logs
  Stream<List<FeedingLog>> getTodaysFeedingLogs() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getFeedingLogsByDateRange(startOfDay, endOfDay);
  }

  // Calculate total portions fed today
  Future<double> getTodaysTotalPortions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      final snapshot = await _feederRef
          .collection('feeding_logs')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final portionSize = (data['portion_size'] ?? 0).toDouble();
        total += portionSize;
      }

      print('DEBUG: Total portions fed today: ${total}g');
      return total;
    } catch (e) {
      print('Error calculating today\'s total: $e');
      return 0.0;
    }
  }

  // ===== SENSOR HISTORY =====

  // Get latest sensor data (for dashboard)
  // Reading from main document: feeders/feeder_001
  Stream<SensorData?> getLatestSensorData() {
    return _feederRef.snapshots().map((snapshot) {
      print('DEBUG: Reading from main document feeder_001');

      if (!snapshot.exists) {
        print('DEBUG: Main document does not exist');
        return null;
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) {
        print('DEBUG: Main document has no data');
        return null;
      }

      print('DEBUG: Main document data: $data');
      print('DEBUG: Available fields: ${data.keys.toList()}');

      // Check if it has required sensor data fields
      if (!data.containsKey('temp') || !data.containsKey('humidity')) {
        print('DEBUG: Missing required sensor fields (temp, humidity)');
        return null;
      }

      // Parse last_seen for debugging
      if (data['last_seen'] != null) {
        try {
          final lastSeenTime = (data['last_seen'] as dynamic).toDate();
          final now = DateTime.now();
          final diff = now.difference(lastSeenTime);
          print(
              'DEBUG: last_seen was ${diff.inMinutes} minutes ago (${diff.inHours} hours)');
        } catch (e) {
          print('DEBUG: Error parsing last_seen: $e');
        }
      }

      try {
        return SensorData.fromFirestore(data, snapshot.id);
      } catch (e) {
        print('DEBUG: Error parsing sensor data: $e');
        rethrow;
      }
    });
  }

  // Alternative: Get sensor data from main document (if your IoT writes there)
  Stream<SensorData?> getSensorDataFromMainDoc() {
    return _feederRef.snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return null;

      // Check if it has sensor data fields
      if (data.containsKey('temp') && data.containsKey('humidity')) {
        try {
          return SensorData.fromFirestore(data, snapshot.id);
        } catch (e) {
          print('Error parsing sensor data from main doc: $e');
          return null;
        }
      }
      return null;
    });
  }

  // Get sensor history (for analytics)
  Stream<List<SensorData>> getSensorHistory({int limit = 100}) {
    return _feederRef
        .collection('sensor_history')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SensorData.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Get sensor data for specific date range
  Stream<List<SensorData>> getSensorDataByDateRange(
      DateTime start, DateTime end) {
    return _feederRef
        .collection('sensor_history')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThanOrEqualTo: end)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SensorData.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Add new sensor data
  Future<void> addSensorData({
    required bool detected,
    required int foodLevel,
    required int humidity,
    required int temp,
  }) async {
    try {
      await _feederRef.collection('sensor_history').add({
        'detected': detected,
        'device_id': deviceId,
        'food_level': foodLevel,
        'humidity': humidity,
        'last_seen': FieldValue.serverTimestamp(),
        'temp': temp,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding sensor data: $e');
      rethrow;
    }
  }

  // ===== ANALYTICS HELPERS =====

  // Get sensor data for last N days
  Stream<List<SensorData>> getSensorDataLastNDays(int days) {
    final start = DateTime.now().subtract(Duration(days: days));
    return getSensorDataByDateRange(start, DateTime.now());
  }

  // Get feeding logs for last N days
  Stream<List<FeedingLog>> getFeedingLogsLastNDays(int days) {
    final start = DateTime.now().subtract(Duration(days: days));
    return getFeedingLogsByDateRange(start, DateTime.now());
  }

  // Calculate food level percentage
  double calculateFoodLevelPercentage(int foodLevel, {int maxLevel = 100}) {
    return (foodLevel / maxLevel).clamp(0.0, 1.0);
  }

  // ===== FEEDING COMMANDS (IoT Control) =====

  // Send feeding command to IoT device
  Future<String> sendFeedingCommand(int portionSize) async {
    try {
      print('DEBUG: Starting sendFeedingCommand with portion: $portionSize');

      // 1. Create the command tracking document first
      final commandRef = await _feederRef.collection('feeding_commands').add({
        'device_id': deviceId,
        'portion_size': portionSize,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'executed_at': null,
        'error_message': null,
      });
      print('DEBUG: Command document created: ${commandRef.id}');

      // 2. Then set manual_feed to true to trigger the backend listener
      // Using set() with merge:true to create field if it doesn't exist
      await _feederRef.set({
        'manual_feed': true,
      }, SetOptions(merge: true));

      print('DEBUG: manual_feed set to true successfully!');

      return commandRef.id;
    } catch (e) {
      print('ERROR sending feeding command: $e');
      print('ERROR details: ${e.toString()}');
      rethrow;
    }
  }

  // Listen to command status updates
  Stream<FeedingCommand?> watchCommandStatus(String commandId) {
    return _feederRef
        .collection('feeding_commands')
        .doc(commandId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return FeedingCommand.fromFirestore(snapshot.data()!, snapshot.id);
    });
  }

  // Get all pending commands (for IoT device to process)
  Stream<List<FeedingCommand>> getPendingCommands() {
    return _feederRef
        .collection('feeding_commands')
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedingCommand.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Update command status (called by IoT device)
  Future<void> updateCommandStatus({
    required String commandId,
    required String status,
    String? errorMessage,
  }) async {
    try {
      await _feederRef.collection('feeding_commands').doc(commandId).update({
        'status': status,
        'executed_at':
            status != 'pending' ? FieldValue.serverTimestamp() : null,
        'error_message': errorMessage,
      });
    } catch (e) {
      print('Error updating command status: $e');
      rethrow;
    }
  }

  // Get recent commands (for history/debugging)
  Stream<List<FeedingCommand>> getRecentCommands({int limit = 20}) {
    return _feederRef
        .collection('feeding_commands')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedingCommand.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // ===== ROUTINE/SCHEDULE MANAGEMENT =====

  // Get all routines for this feeder
  Stream<List<Routine>> getRoutines() {
    return _feederRef.snapshots().map((snapshot) {
      if (!snapshot.exists) return [];

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('routines')) return [];

      final routinesList = data['routines'] as List<dynamic>;
      return routinesList.asMap().entries.map((entry) {
        final index = entry.key;
        final routineData = entry.value as Map<String, dynamic>;
        return Routine.fromFirestore(routineData, index.toString());
      }).toList();
    });
  }

  // Add new routine
  Future<void> addRoutine(Routine routine) async {
    try {
      print('DEBUG: Adding routine...');
      print('DEBUG: Routine data: ${routine.toFirestore()}');

      final doc = await _feederRef.get();
      print('DEBUG: Document exists: ${doc.exists}');

      if (!doc.exists) {
        print(
            'DEBUG: Document does not exist, creating it with routines field...');
        await _feederRef.set({
          'device_id': deviceId,
          'routines': [routine.toFirestore()],
        });
        print('DEBUG: ✅ Document and routine created!');
        return;
      }

      final data = doc.data() as Map<String, dynamic>? ?? {};
      print('DEBUG: Current document data keys: ${data.keys.toList()}');

      // Get existing routines or create new empty list
      List<Map<String, dynamic>> routines;

      if (!data.containsKey('routines')) {
        print('DEBUG: routines field does not exist, creating it...');
        routines = [];
      } else if (data['routines'] is! List) {
        print(
            'DEBUG: routines field exists but is not a list, replacing it...');
        routines = [];
      } else {
        try {
          routines = List<Map<String, dynamic>>.from(data['routines']);
          print('DEBUG: Existing routines count: ${routines.length}');
        } catch (e) {
          print(
              'DEBUG: Error parsing existing routines, creating fresh list: $e');
          routines = [];
        }
      }

      routines.add(routine.toFirestore());
      print('DEBUG: New routines count: ${routines.length}');
      print('DEBUG: Full routines array: $routines');

      await _feederRef.set({
        'routines': routines,
      }, SetOptions(merge: true));

      print('DEBUG: ✅ Routine saved to Firebase!');

      // Verify it was saved
      await Future.delayed(Duration(milliseconds: 500));
      final verifyDoc = await _feederRef.get();
      final verifyData = verifyDoc.data() as Map<String, dynamic>?;
      print(
          'DEBUG: Verification - routines in Firebase: ${verifyData?['routines']}');
    } catch (e) {
      print('ERROR adding routine: $e');
      print('ERROR stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Update existing routine by index
  Future<void> updateRoutine(int index, Routine routine) async {
    try {
      final doc = await _feederRef.get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final routines = List<Map<String, dynamic>>.from(data['routines'] ?? []);

      if (index >= 0 && index < routines.length) {
        routines[index] = routine.toFirestore();

        await _feederRef.update({
          'routines': routines,
        });

        print('Routine updated successfully');
      } else {
        throw Exception('Invalid routine index: $index');
      }
    } catch (e) {
      print('Error updating routine: $e');
      rethrow;
    }
  }

  // Delete routine by index
  Future<void> deleteRoutine(int index) async {
    try {
      final doc = await _feederRef.get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final routines = List<Map<String, dynamic>>.from(data['routines'] ?? []);

      if (index >= 0 && index < routines.length) {
        routines.removeAt(index);

        await _feederRef.update({
          'routines': routines,
        });

        print('Routine deleted successfully');
      } else {
        throw Exception('Invalid routine index: $index');
      }
    } catch (e) {
      print('Error deleting routine: $e');
      rethrow;
    }
  }

  // Toggle routine enabled/disabled
  Future<void> toggleRoutineEnabled(int index) async {
    try {
      final doc = await _feederRef.get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final routines = List<Map<String, dynamic>>.from(data['routines'] ?? []);

      if (index >= 0 && index < routines.length) {
        routines[index]['enabled'] = !(routines[index]['enabled'] ?? true);

        await _feederRef.update({
          'routines': routines,
        });

        print('Routine toggle successful');
      }
    } catch (e) {
      print('Error toggling routine: $e');
      rethrow;
    }
  }
}
