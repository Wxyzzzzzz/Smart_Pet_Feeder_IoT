import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Routine {
  final String? id;
  final String time; 
  final int portionSize; 
  final List<int> days; 
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

  // Convert Time
  static String timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Convert Time String
  static TimeOfDay stringToTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  // Get day name 
  static String getDayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day];
  }

  String getFormattedDays() {
    if (days.length == 7) return 'Every day';
    if (days.isEmpty) return 'No days';

    if (days.length == 5 &&
        days.contains(0) &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4)) {
      return 'Weekdays';
    }

    if (days.length == 2 && days.contains(5) && days.contains(6)) {
      return 'Weekends';
    }

    return days.map((d) => getDayName(d)).join(', ');
  }

  TimeOfDay getTimeOfDay() {
    return stringToTimeOfDay(time);
  }

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
