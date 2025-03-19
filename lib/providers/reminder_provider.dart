import 'package:flutter/foundation.dart';
import '../models/reminder.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class ReminderProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  List<Reminder> _reminders = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all reminders
  Future<void> loadReminders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reminders = await _db.getAllReminders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load reminders: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load reminders for a specific pet
  Future<void> loadRemindersForPet(String petId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reminders = await _db.getRemindersForPet(petId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load reminders: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get all reminders due today across all pets
  Future<List<Reminder>> getAllRemindersForToday() async {
    try {
      // If reminders aren't loaded yet, load them
      if (_reminders.isEmpty) {
        await loadReminders();
      }
      
      return getRemindersForToday();
    } catch (e) {
      print('Error getting reminders for today: $e');
      // Return an empty list rather than crashing
      return [];
    }
  }

  // Get reminders for today (filtered by pet if petId is provided)
  List<Reminder> getRemindersForToday([String? petId]) {
    try {
      final now = DateTime.now();
      final weekdayIndex = now.weekday - 1; // Weekday is 1-7, we need 0-6
      
      return _reminders.where((reminder) {
        // Filter by active status
        if (!reminder.isActive) return false;
        
        // Filter by pet if specified
        if (petId != null && reminder.petId != petId) return false;
        
        // Filter by scheduled for today
        return reminder.daysOfWeek[weekdayIndex];
      }).toList();
    } catch (e) {
      print('Error filtering reminders for today: $e');
      // Return an empty list rather than crashing
      return [];
    }
  }

  // Get reminders by type
  List<Reminder> getRemindersByType(ReminderType type, [String? petId]) {
    try {
      return _reminders.where((reminder) {
        // Filter by active status and type
        if (!reminder.isActive || reminder.type != type) return false;
        
        // Filter by pet if specified
        if (petId != null && reminder.petId != petId) return false;
        
        return true;
      }).toList();
    } catch (e) {
      print('Error filtering reminders by type: $e');
      // Return an empty list rather than crashing
      return [];
    }
  }

  // Add a new reminder
  Future<void> addReminder(Reminder reminder) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _db.insertReminder(reminder);
      final newReminder = Reminder(
        id: id,
        petId: reminder.petId,
        type: reminder.type,
        title: reminder.title,
        time: reminder.time,
        daysOfWeek: reminder.daysOfWeek,
        isActive: reminder.isActive,
        details: reminder.details,
        notes: reminder.notes,
      );
      
      _reminders.add(newReminder);
      
      // Safely schedule notification
      try {
        await _notificationService.safeScheduleReminderNotification(newReminder);
      } catch (e) {
        print('Failed to schedule notification: $e');
        // Continue even if notification scheduling fails
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add reminder: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing reminder
  Future<void> updateReminder(Reminder reminder) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _db.updateReminder(reminder);
      
      if (success) {
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index != -1) {
          _reminders[index] = reminder;
        }
        
        // Safely update notification
        try {
          await _notificationService.safeScheduleReminderNotification(reminder);
        } catch (e) {
          print('Failed to update notification: $e');
          // Continue even if notification update fails
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update reminder: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle reminder active state
  Future<void> toggleReminderActive(Reminder reminder) async {
    final updatedReminder = Reminder(
      id: reminder.id,
      petId: reminder.petId,
      type: reminder.type,
      title: reminder.title,
      time: reminder.time,
      daysOfWeek: reminder.daysOfWeek,
      isActive: !reminder.isActive,
      details: reminder.details,
      notes: reminder.notes,
    );
    
    await updateReminder(updatedReminder);
    
    // Safely cancel notification if deactivated
    if (!updatedReminder.isActive && updatedReminder.id != null) {
      try {
        await _notificationService.safeCancelReminderNotification(updatedReminder.id!);
      } catch (e) {
        print('Failed to cancel notification: $e');
        // Continue even if notification cancellation fails
      }
    }
  }

  // Delete a reminder
  Future<void> deleteReminder(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _db.deleteReminder(id);
      
      if (success) {
        _reminders.removeWhere((reminder) => reminder.id == id);
        
        // Safely cancel notification
        try {
          await _notificationService.safeCancelReminderNotification(id);
        } catch (e) {
          print('Failed to cancel notification: $e');
          // Continue even if notification cancellation fails
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete reminder: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark a feeding reminder as completed (adds a feeding record)
  Future<void> markFeedingComplete(Reminder reminder) async {
    // Extract amount and unit from details if available
    String unit = 'portion';
    double amount = 1.0;
    
    // Try to parse details like "2 cups" or "150 grams"
    if (reminder.details.isNotEmpty) {
      final parts = reminder.details.trim().split(' ');
      if (parts.length >= 2) {
        try {
          amount = double.parse(parts[0]);
          unit = parts.sublist(1).join(' ');
        } catch (e) {
          print('Failed to parse feeding details: $e');
        }
      }
    }
    
    // Call the database service to add a feeding record
    try {
      await _db.insertFeedingFromReminder(
        reminder.petId, 
        reminder.title, 
        amount, 
        unit,
        reminder.notes
      );
      
      // Safely show confirmation notification
      try {
        await _notificationService.safeShowTodayRemindersNotification(
          [reminder],
          filterType: ReminderType.feeding
        );
      } catch (e) {
        print('Failed to show confirmation notification: $e');
        // Continue even if notification fails
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to record feeding: ${e.toString()}';
      notifyListeners();
    }
  }

  // Mark a medication reminder as completed (adds a medication record)
  Future<void> markMedicationComplete(Reminder reminder) async {
    // Call the database service to record medication administration
    try {
      await _db.recordMedicationFromReminder(
        reminder.petId,
        reminder.title,
        reminder.details, // Contains dosage
        reminder.notes
      );
      
      // Safely show confirmation notification
      try {
        await _notificationService.safeShowTodayRemindersNotification(
          [reminder],
          filterType: ReminderType.medication
        );
      } catch (e) {
        print('Failed to show confirmation notification: $e');
        // Continue even if notification fails
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to record medication: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Mark a grooming reminder as completed (creates a completed task)
  Future<void> markGroomingComplete(Reminder reminder) async {
    try {
      await _db.insertGroomingTask(
        reminder.petId,
        reminder.title,
        reminder.notes
      );
      
      // Safely show confirmation notification
      try {
        await _notificationService.safeShowTodayRemindersNotification(
          [reminder],
          filterType: ReminderType.grooming
        );
      } catch (e) {
        print('Failed to show confirmation notification: $e');
        // Continue even if notification fails
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to record grooming: ${e.toString()}';
      notifyListeners();
    }
  }
} 