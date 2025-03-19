import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';
import 'package:rxdart/subjects.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final BehaviorSubject<String?> onNotificationClick = BehaviorSubject();
  bool _isInitialized = false;

  // Static method to handle received actions
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Get the singleton instance
    final NotificationService service = NotificationService();
    
    // Forward the notification to our stream
    if (receivedAction.payload != null && receivedAction.payload!.containsKey('id')) {
      service.onNotificationClick.add(receivedAction.payload!['id']);
    }
  }

  // This must be called after the app is fully loaded
  Future<bool> initialize() async {
    // Prevent multiple initializations
    if (_isInitialized) {
      return true;
    }

    try {
      // First register the action handling method
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationService.onActionReceivedMethod
      );
      
      // Then initialize the channels
      bool success = await AwesomeNotifications().initialize(
        null, // No custom icon, will use the default app icon
        [
          NotificationChannel(
            channelKey: 'basic_channel',
            channelName: 'Basic Notifications',
            channelDescription: 'Basic notification channel for PetMinder',
            defaultColor: const Color(0xFF7EB5A6),
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
          NotificationChannel(
            channelKey: 'feeding_channel',
            channelName: 'Feeding Reminders',
            channelDescription: 'Notifications for pet feeding reminders',
            defaultColor: const Color(0xFFE8C07D), // Gold
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
          NotificationChannel(
            channelKey: 'medication_channel',
            channelName: 'Medication Reminders',
            channelDescription: 'Notifications for pet medication reminders',
            defaultColor: const Color(0xFFF6AE99), // Coral
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
          NotificationChannel(
            channelKey: 'grooming_channel',
            channelName: 'Grooming Reminders',
            channelDescription: 'Notifications for pet grooming reminders',
            defaultColor: const Color(0xFF7EB5A6), // Teal
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
          NotificationChannel(
            channelKey: 'other_channel',
            channelName: 'Other Reminders',
            channelDescription: 'Notifications for other pet reminders',
            defaultColor: Colors.grey,
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
        ],
      );
      
      if (!success) {
        print('Failed to initialize Awesome Notifications');
        return false;
      }

      // Request notification permissions (don't throw if this fails)
      try {
        await requestPermissions();
      } catch (e) {
        print('Failed to request notification permissions: $e');
        // Continue even if permissions fail
      }
      
      _isInitialized = true;
      print('Notification service initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing notification service: $e');
      return false;
    }
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  // Get the channel key based on reminder type
  String _getChannelKeyForType(ReminderType type) {
    switch (type) {
      case ReminderType.feeding:
        return 'feeding_channel';
      case ReminderType.medication:
        return 'medication_channel';
      case ReminderType.grooming:
        return 'grooming_channel';
      case ReminderType.other:
        return 'other_channel';
    }
  }

  // Get reminder icon based on type
  String _getIconForType(ReminderType type) {
    switch (type) {
      case ReminderType.feeding:
        return 'resource://drawable/res_restaurant';
      case ReminderType.medication:
        return 'resource://drawable/res_medication';
      case ReminderType.grooming:
        return 'resource://drawable/res_brush';
      case ReminderType.other:
        return 'resource://drawable/res_notification';
    }
  }

  // Schedule a notification for a reminder - safe wrapper method
  Future<bool> safeScheduleReminderNotification(Reminder reminder) async {
    try {
      // Make sure notifications are initialized
      if (!_isInitialized) {
        final success = await initialize();
        if (!success) return false;
      }
      
      return await scheduleReminderNotification(reminder);
    } catch (e) {
      print('Error scheduling reminder notification: $e');
      return false;
    }
  }

  // Schedule a notification for a reminder
  Future<bool> scheduleReminderNotification(Reminder reminder) async {
    // Check which day of week today is
    final now = DateTime.now();
    final weekday = now.weekday - 1; // 0 = Monday, 6 = Sunday
    
    // Find all the days we need to schedule for
    List<int> daysToSchedule = [];
    for (int i = 0; i < reminder.daysOfWeek.length; i++) {
      if (reminder.daysOfWeek[i]) {
        daysToSchedule.add(i);
      }
    }
    
    if (daysToSchedule.isEmpty) {
      return false; // No days selected
    }

    // Delete any existing notifications for this reminder
    if (reminder.id != null) {
      await safeCancelReminderNotification(reminder.id!);
    }

    // For each day of the week, schedule a notification
    bool allSuccessful = true;
    for (int dayIndex in daysToSchedule) {
      // Calculate days until the next occurrence of this weekday
      int daysUntil = (dayIndex - weekday) % 7;
      if (daysUntil == 0) {
        // If today, check if the time has already passed
        final nowTime = TimeOfDay.fromDateTime(now);
        if (reminder.time.hour < nowTime.hour ||
            (reminder.time.hour == nowTime.hour && reminder.time.minute <= nowTime.minute)) {
          // Time has passed today, schedule for next week
          daysUntil = 7;
        }
      }
      
      // Create the schedule date
      DateTime scheduleDate = DateTime(
        now.year,
        now.month,
        now.day + daysUntil,
        reminder.time.hour,
        reminder.time.minute,
      );
      
      // Create a unique ID for each day of the week
      int notificationId = (reminder.id ?? 0) * 10 + dayIndex;
      
      // Schedule the notification
      try {
        bool success = await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: notificationId,
            channelKey: _getChannelKeyForType(reminder.type),
            title: 'Time to ${_getReminderActionText(reminder.type)}',
            body: '${reminder.title} ${reminder.details.isNotEmpty ? '(${reminder.details})' : ''}',
            icon: _getIconForType(reminder.type),
            notificationLayout: NotificationLayout.Default,
            payload: {'id': '${reminder.id}', 'type': reminder.type.toString()},
            color: _getColorForType(reminder.type),
          ),
          schedule: NotificationCalendar(
            weekday: dayIndex + 1, // Awesome Notifications uses 1-7 for Monday-Sunday
            hour: reminder.time.hour,
            minute: reminder.time.minute,
            second: 0,
            millisecond: 0,
            repeats: true,
            allowWhileIdle: true,
          ),
        );
        
        if (!success) {
          print('Failed to schedule notification for day $dayIndex');
          allSuccessful = false;
        }
      } catch (e) {
        print('Error scheduling notification for day $dayIndex: $e');
        allSuccessful = false;
      }
    }

    return allSuccessful;
  }

  // Safe wrapper for cancelling notifications
  Future<void> safeCancelReminderNotification(int id) async {
    try {
      // Make sure notifications are initialized
      if (!_isInitialized) {
        final success = await initialize();
        if (!success) return;
      }
      
      await cancelReminderNotification(id);
    } catch (e) {
      print('Error cancelling reminder notification: $e');
    }
  }

  // Cancel a reminder notification
  Future<void> cancelReminderNotification(int id) async {
    try {
      // Using a group key would be better, but for now cancel each possible day individually
      for (int i = 0; i < 7; i++) {
        await AwesomeNotifications().cancel(id * 10 + i);
      }
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  // Safe wrapper for showing today's reminders
  Future<bool> safeShowTodayRemindersNotification(List<Reminder> reminders, {ReminderType? filterType}) async {
    try {
      // Make sure notifications are initialized
      if (!_isInitialized) {
        final success = await initialize();
        if (!success) return false;
      }
      
      return await showTodayRemindersNotification(reminders, filterType: filterType);
    } catch (e) {
      print('Error showing today\'s reminders notification: $e');
      return false;
    }
  }

  // Schedule immediate notification for today's reminders
  Future<bool> showTodayRemindersNotification(List<Reminder> reminders, {ReminderType? filterType}) async {
    if (reminders.isEmpty) return false;
    
    // Filter by type if specified
    final filteredReminders = filterType != null 
        ? reminders.where((r) => r.type == filterType).toList()
        : reminders;
    
    if (filteredReminders.isEmpty) return false;
    
    String title;
    String body;
    String channelKey;
    Color color;
    
    if (filterType != null) {
      // Notification for a specific type
      title = '${_capitalizeString(filterType.name)} Reminders';
      channelKey = _getChannelKeyForType(filterType);
      color = _getColorForType(filterType);
      
      if (filteredReminders.length == 1) {
        body = 'Time for ${filteredReminders[0].title}';
      } else {
        body = 'You have ${filteredReminders.length} ${filterType.name} reminders today';
      }
    } else {
      // Summary notification
      title = 'Today\'s Reminders';
      channelKey = 'basic_channel';
      color = const Color(0xFF7EB5A6); // App primary color
      
      if (filteredReminders.length == 1) {
        body = 'Time for ${filteredReminders[0].title}';
      } else {
        body = 'You have ${filteredReminders.length} reminders scheduled for today';
      }
    }
    
    try {
      return await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: filterType != null ? filterType.index + 100 : 99,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          color: color,
        ),
      );
    } catch (e) {
      print('Error creating notification: $e');
      return false;
    }
  }
  
  // Get action text based on reminder type
  String _getReminderActionText(ReminderType type) {
    switch (type) {
      case ReminderType.feeding:
        return 'feed your pet';
      case ReminderType.medication:
        return 'give medication';
      case ReminderType.grooming:
        return 'groom your pet';
      case ReminderType.other:
        return 'check on your pet';
    }
  }
  
  // Get color for reminder type
  Color _getColorForType(ReminderType type) {
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
  
  // Helper function to capitalize a string
  String _capitalizeString(String s) {
    if (s.isEmpty) return s;
    return "${s[0].toUpperCase()}${s.substring(1)}";
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 