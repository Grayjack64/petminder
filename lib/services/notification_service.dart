import 'package:flutter/material.dart';
import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';
import 'package:rxdart/subjects.dart';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import '../services/database_service.dart';

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
      try {
        await AwesomeNotifications().setListeners(
          onActionReceivedMethod: NotificationService.onActionReceivedMethod
        );
      } catch (e) {
        print('Error setting notification listeners: $e');
        // Continue with initialization even if this part fails
      }
      
      // Then initialize the channels with timeout
      bool success = false;
      try {
        success = await Future.any([
          AwesomeNotifications().initialize(
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
          ),
          // Add timeout to prevent hanging if permissions are denied
          Future.delayed(const Duration(seconds: 3), () => false),
        ]);
      } catch (e) {
        print('Error initializing notification channels: $e');
        // Failed to initialize channels, but we'll continue
        success = false;
      }
      
      if (!success) {
        print('Failed to initialize Awesome Notifications - proceeding without notifications');
        // We'll still mark as initialized but with limited functionality
        _isInitialized = true;
        return false;
      }

      // Request notification permissions (don't throw if this fails)
      try {
        // Add timeout to permissions request
        bool permissionSuccess = await Future.any([
          requestPermissions(),
          Future.delayed(const Duration(seconds: 2), () => false),
        ]);
        
        if (!permissionSuccess) {
          print('Failed to get notification permissions');
        }
      } catch (e) {
        print('Error requesting notification permissions: $e');
        // Continue even if permissions fail
      }
      
      _isInitialized = true;
      print('Notification service initialized successfully');
      return true;
    } catch (e) {
      print('Error in notification service initialization: $e');
      // Mark as initialized anyway to prevent repeated attempts
      _isInitialized = true;
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

  // Schedule a periodic check for upcoming reminders - replaces background service functionality
  Future<void> scheduleReminderCheck() async {
    print('Setting up reminder check scheduler');
    
    // Perform an initial check right away
    await _checkAndScheduleReminders();
    
    // Set up periodic checks using a Timer
    Timer.periodic(const Duration(hours: 1), (_) async {
      print('Performing periodic reminder check');
      await _checkAndScheduleReminders();
    });
  }
  
  // Check for upcoming reminders and schedule notifications for them
  Future<void> _checkAndScheduleReminders() async {
    print('Checking for upcoming reminders...');
    try {
      // Get the database service - using direct reference instead of dynamic import
      final db = DatabaseService();
      
      // Get upcoming medications and tasks
      final upcomingMedications = await db.getUpcomingDueMedications();
      final upcomingTasks = await db.getUpcomingDueTasks();
      
      print('Found ${upcomingMedications.length} upcoming medications and ${upcomingTasks.length} upcoming tasks');
      
      // Create reminders from upcoming medications and tasks
      List<Reminder> reminders = [];
      
      // Process medications
      for (final medication in upcomingMedications) {
        // Create a reminder for the medication
        final nextDose = medication.nextDose;
        
        // Create a reminder with all required fields
        final reminder = Reminder(
          id: medication.id ?? 0, // Default to 0 if null
          petId: medication.petId.toString(),
          type: ReminderType.medication,
          title: medication.name,
          time: TimeOfDay(hour: nextDose.hour, minute: nextDose.minute),
          daysOfWeek: List.generate(7, (_) => true), // Every day
          details: medication.dosage,
          notes: medication.notes ?? '',
          frequency: ReminderFrequency.daily,
          startDate: nextDose,
        );
        
        reminders.add(reminder);
      }
      
      // Process tasks
      for (final task in upcomingTasks) {
        if (!task.completed) {
          final dueDate = task.dueDate;
          
          // Create a reminder for the task
          final reminder = Reminder(
            id: task.id ?? 0, // Default to 0 if null
            petId: task.petId.toString(),
            type: ReminderType.other,
            title: task.description,
            time: TimeOfDay(hour: dueDate.hour, minute: dueDate.minute),
            daysOfWeek: List.generate(7, (_) => true), // Every day
            details: '',
            notes: task.notes ?? '',
            frequency: ReminderFrequency.daily,
            startDate: dueDate,
          );
          
          reminders.add(reminder);
        }
      }
      
      // Schedule each reminder
      int successCount = 0;
      for (final reminder in reminders) {
        bool success = await safeScheduleReminderNotification(reminder);
        if (success) {
          successCount++;
        }
      }
      
      print('Successfully scheduled $successCount out of ${reminders.length} reminders');
    } catch (e) {
      print('Error checking for reminders: $e');
    }
  }

  // Safe wrapper for scheduling a reminder notification
  Future<bool> safeScheduleReminderNotification(Reminder reminder) async {
    try {
      // Skip if the reminder's time has already passed for today
      final now = DateTime.now();
      final reminderDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        reminder.time.hour,
        reminder.time.minute,
      );
      
      if (reminderDateTime.isBefore(now) && 
          reminder.startDate?.day == now.day && 
          reminder.startDate?.month == now.month && 
          reminder.startDate?.year == now.year) {
        print('Skipping past reminder: ${reminder.title}');
        return false;
      }
      
      // Create notification content
      final content = NotificationContent(
        id: reminder.id ?? 0, // Default to 0 if null
        channelKey: _getChannelKeyForType(reminder.type),
        title: '${reminder.title} reminder',
        body: reminder.details.isNotEmpty ? reminder.details : 'Time for ${reminder.title}',
        notificationLayout: NotificationLayout.Default,
        criticalAlert: true,
        wakeUpScreen: true,
        fullScreenIntent: true,
        category: NotificationCategory.Reminder,
        displayOnForeground: true,
        displayOnBackground: true,
      );
      
      // Create scheduled trigger
      final scheduledDate = DateTime(
        reminderDateTime.year,
        reminderDateTime.month,
        reminderDateTime.day,
        reminder.time.hour,
        reminder.time.minute,
      );
      
      final trigger = NotificationCalendar(
        hour: scheduledDate.hour,
        minute: scheduledDate.minute,
        second: 0,
        repeats: true,
        preciseAlarm: true,
      );
      
      // Schedule the notification
      await AwesomeNotifications().createNotification(
        content: content,
        schedule: trigger,
      );
      
      print('Successfully scheduled notification for: ${reminder.title}');
      return true;
    } catch (e) {
      print('Error scheduling notification for ${reminder.title}: $e');
      return false;
    }
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
      // For day-of-week reminders, cancel each possible day
      for (int i = 0; i < 7; i++) {
        await AwesomeNotifications().cancel(id * 10 + i);
      }
      
      // For frequency-based reminders, cancel the base notification
      await AwesomeNotifications().cancel(id * 10);
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
  
  // Send a test notification immediately
  Future<bool> sendTestNotification() async {
    try {
      // Make sure notifications are initialized
      if (!_isInitialized) {
        final success = await initialize();
        if (!success) return false;
      }
      
      // Check notification permission
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        final permissionGranted = await requestPermissions();
        if (!permissionGranted) {
          print('Notification permission denied');
          return false;
        }
      }
      
      print('Sending test notification...');
      return await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 999,
          channelKey: 'basic_channel',
          title: 'Test Notification',
          body: 'This is a test notification from PetMinder. If you can see this, notifications are working!',
          notificationLayout: NotificationLayout.Default,
          criticalAlert: true,
          wakeUpScreen: true,
          category: NotificationCategory.Reminder,
        ),
      );
    } catch (e) {
      print('Error sending test notification: $e');
      return false;
    }
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
} 