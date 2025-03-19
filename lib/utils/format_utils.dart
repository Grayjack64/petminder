import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Format a date to a readable string like 'January 1, 2023'
String formatDate(DateTime date) {
  return DateFormat.yMMMMd().format(date);
}

/// Format a date to a shorter string like 'Jan 1, 2023'
String formatShortDate(DateTime date) {
  return DateFormat.yMMMd().format(date);
}

/// Format a date to show only the day and month like 'Jan 1'
String formatDayMonth(DateTime date) {
  return DateFormat.MMMd().format(date);
}

/// Format a TimeOfDay to a string like '2:30 PM'
String formatTimeOfDay(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

/// Format a date with time like 'Jan 1, 2:30 PM'
String formatDateWithTime(DateTime date, {TimeOfDay? time}) {
  final dateStr = formatDayMonth(date);
  if (time != null) {
    final timeStr = formatTimeOfDay(time);
    return '$dateStr, $timeStr';
  } else {
    final timeStr = DateFormat.jm().format(date);
    return '$dateStr, $timeStr';
  }
}

/// Get a relative date string like 'Today', 'Yesterday', or 'Jan 1'
String getRelativeDateString(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final tomorrow = today.add(const Duration(days: 1));
  
  final inputDate = DateTime(date.year, date.month, date.day);
  
  if (inputDate == today) {
    return 'Today';
  } else if (inputDate == yesterday) {
    return 'Yesterday';
  } else if (inputDate == tomorrow) {
    return 'Tomorrow';
  } else {
    return formatDayMonth(date);
  }
}

/// Get weekday name from index (0 = Monday, 6 = Sunday)
String getWeekdayName(int index) {
  final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return weekdays[index];
}

/// Get short weekday name from index (0 = Mon, 6 = Sun)
String getShortWeekdayName(int index) {
  final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return weekdays[index];
}

/// Format a duration in a human readable way, e.g. "2h 30m"
String formatDuration(Duration duration) {
  final days = duration.inDays;
  final hours = duration.inHours % 24;
  final minutes = duration.inMinutes % 60;
  
  if (days > 0) {
    return '${days}d ${hours}h';
  } else if (hours > 0) {
    return '${hours}h ${minutes}m';
  } else {
    return '${minutes}m';
  }
}

/// Format a number as a weight with the given unit (default: kg)
String formatWeight(double weight, {String unit = 'kg'}) {
  return '${weight.toStringAsFixed(1)} $unit';
}

/// Format age in years and months
String formatAge(int ageInMonths) {
  if (ageInMonths < 1) {
    return 'Newborn';
  } else if (ageInMonths < 12) {
    return '$ageInMonths ${ageInMonths == 1 ? 'month' : 'months'}';
  } else {
    final years = ageInMonths ~/ 12;
    final months = ageInMonths % 12;
    if (months == 0) {
      return '$years ${years == 1 ? 'year' : 'years'}';
    } else {
      return '$years ${years == 1 ? 'year' : 'years'}, $months ${months == 1 ? 'month' : 'months'}';
    }
  }
} 