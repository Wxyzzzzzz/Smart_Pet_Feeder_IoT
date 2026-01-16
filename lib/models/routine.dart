import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Routine {
  final String? id;
  final String time; // Format: "HH:MM" (24-hour)
  final int portionSize; // in grams
  final List<int> days; // 0=Monday, 6=Sunday
  final bool enabled;

  Routine({
    this.id,
    required this.time,
    required this.portionSize,
    required this.days,
    this.enabled = true,
  });

  // Convert Firestore map to Routine object
  factory Routine.fromFirestore(Map<String, dynamic> data, String id) {
    return Routine(
      id: id,
      time: data['time'] ?? '00:00',
      portionSize: data['portion_size'] ?? 20,
      days: List<int>.from(data['days'] ?? []),
      enabled: data['enabled'] ?? true,
    );
  }

  // Convert Routine object to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'time': time,
      'portion_size': portionSize,
      'days': days,
      'enabled': enabled,
    };
  }

  // Helper: Convert TimeOfDay to HH:MM string
  static String timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Helper: Convert HH:MM string to TimeOfDay
  static TimeOfDay stringToTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  // Helper: Get day name from day index
  static String getDayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day];
  }

  // Helper: Get formatted days string (e.g., "Mon, Wed, Fri")
  String getFormattedDays() {
    if (days.length == 7) return 'Every day';
    if (days.isEmpty) return 'No days';

    // Check for weekdays (0-4)
    if (days.length == 5 &&
        days.contains(0) &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4)) {
      return 'Weekdays';
    }

    // Check for weekends (5-6)
    if (days.length == 2 && days.contains(5) && days.contains(6)) {
      return 'Weekends';
    }

    return days.map((d) => getDayName(d)).join(', ');
  }

  // Get TimeOfDay from time string
  TimeOfDay getTimeOfDay() {
    return stringToTimeOfDay(time);
  }

  // Copy with method for updates
  Routine copyWith({
    String? id,
    String? time,
    int? portionSize,
    List<int>? days,
    bool? enabled,
  }) {
    return Routine(
      id: id ?? this.id,
      time: time ?? this.time,
      portionSize: portionSize ?? this.portionSize,
      days: days ?? this.days,
      enabled: enabled ?? this.enabled,
    );
  }
}
