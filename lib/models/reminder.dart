import 'package:flutter/material.dart';

enum ReminderType {
  feeding,
  medication,
  grooming,
  other
}

class Reminder {
  final int? id;
  final String petId;
  final ReminderType type;
  final String title;
  final TimeOfDay time;
  final List<bool> daysOfWeek; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  final bool isActive;
  final String details; // For storing predefined amounts, medicine dosage, etc.
  final String notes;
  
  // Optional pet name for display purposes
  final String? petName;

  Reminder({
    this.id,
    required this.petId,
    required this.type,
    required this.title,
    required this.time,
    required this.daysOfWeek,
    this.isActive = true,
    this.details = '',
    this.notes = '',
    this.petName,
  });

  // Returns if a reminder is scheduled for today
  bool isScheduledForToday() {
    final now = DateTime.now();
    // DateTime weekday is 1-7, where 1 is Monday, 7 is Sunday
    // Our daysOfWeek array is 0-6, where 0 is Monday, 6 is Sunday
    final weekdayIndex = now.weekday - 1;
    return daysOfWeek[weekdayIndex];
  }

  // Returns the next scheduled date and time for this reminder
  DateTime getNextOccurrence() {
    final now = DateTime.now();
    final nowTimeOfDay = TimeOfDay.fromDateTime(now);
    
    // Check if scheduled for today and time hasn't passed yet
    if (isScheduledForToday()) {
      // If reminder time is later today, return today's date with the reminder time
      if (time.hour > nowTimeOfDay.hour || 
          (time.hour == nowTimeOfDay.hour && time.minute >= nowTimeOfDay.minute)) {
        return DateTime(
          now.year, 
          now.month, 
          now.day, 
          time.hour, 
          time.minute
        );
      }
    }
    
    // Otherwise find next occurrence in the week
    int daysToAdd = 1;
    int checkIndex = (now.weekday) % 7; // Tomorrow's index
    
    // Find the next day that has a reminder scheduled
    while (daysToAdd < 8) {
      if (daysOfWeek[checkIndex]) {
        return DateTime(
          now.year, 
          now.month, 
          now.day + daysToAdd, 
          time.hour, 
          time.minute
        );
      }
      checkIndex = (checkIndex + 1) % 7;
      daysToAdd++;
    }
    
    // If no valid day found (shouldn't happen if at least one day is selected)
    // Return tomorrow's date with reminder time
    return DateTime(
      now.year, 
      now.month, 
      now.day + 1, 
      time.hour, 
      time.minute
    );
  }

  // Get icon based on type
  IconData get typeIcon {
    switch (type) {
      case ReminderType.feeding:
        return Icons.restaurant;
      case ReminderType.medication:
        return Icons.medication;
      case ReminderType.grooming:
        return Icons.brush;
      case ReminderType.other:
        return Icons.event_note;
    }
  }

  // Get color based on type
  Color get typeColor {
    switch (type) {
      case ReminderType.feeding:
        return const Color(0xFFE8C07D); // Gold
      case ReminderType.medication:
        return const Color(0xFFF6AE99); // Coral
      case ReminderType.grooming:
        return const Color(0xFF7EB5A6); // Teal
      case ReminderType.other:
        return Colors.grey;
    }
  }

  // Create a copy with updated fields
  Reminder copyWith({
    int? id,
    String? petId,
    ReminderType? type,
    String? title,
    TimeOfDay? time,
    List<bool>? daysOfWeek,
    bool? isActive,
    String? details,
    String? notes,
    String? petName,
  }) {
    return Reminder(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      type: type ?? this.type,
      title: title ?? this.title,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? List.from(this.daysOfWeek),
      isActive: isActive ?? this.isActive,
      details: details ?? this.details,
      notes: notes ?? this.notes,
      petName: petName ?? this.petName,
    );
  }

  // Convert TimeOfDay to string for storage
  String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour}:${time.minute}';
  }

  // Convert string to TimeOfDay for retrieval
  static TimeOfDay _stringToTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'type': type.index,
      'title': title,
      'time': _timeOfDayToString(time),
      'daysOfWeek': daysOfWeek.map((day) => day ? 1 : 0).join(','),
      'isActive': isActive ? 1 : 0,
      'details': details,
      'notes': notes,
    };
  }

  // Create from Map for database retrieval
  factory Reminder.fromMap(Map<String, dynamic> map) {
    final daysString = map['daysOfWeek'] as String;
    final daysValues = daysString.split(',');
    final days = daysValues.map((value) => value == '1').toList();
    
    return Reminder(
      id: map['id'],
      petId: map['petId'],
      type: ReminderType.values[map['type']],
      title: map['title'],
      time: _stringToTimeOfDay(map['time']),
      daysOfWeek: days,
      isActive: map['isActive'] == 1,
      details: map['details'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
} 