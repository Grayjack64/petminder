import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder.dart';
import '../providers/reminder_provider.dart';
import '../utils/format_utils.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showPetName;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onEdit,
    this.onDelete,
    this.showPetName = false,
  });

  @override
  Widget build(BuildContext context) {
    final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    final bool isDue = reminder.isScheduledForToday();
    final Color typeColor = _getColorByType(reminder.type);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDue ? typeColor : Colors.transparent,
          width: isDue ? 1.5 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Icon
                CircleAvatar(
                  radius: 20,
                  backgroundColor: typeColor.withOpacity(0.2),
                  child: Icon(
                    _getIconByType(reminder.type),
                    color: typeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Title and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (showPetName && reminder.petName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'For ${reminder.petName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      if (reminder.details.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            reminder.details,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Switch for active/inactive
                Switch(
                  value: reminder.isActive,
                  activeColor: typeColor,
                  onChanged: (value) {
                    reminderProvider.toggleReminderActive(reminder);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Time and repeat info
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  formatTimeOfDay(reminder.time),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.repeat,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _getRepeatText(reminder.daysOfWeek),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            
            // Action buttons
            if (isDue) 
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Action buttons area (edit, delete)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEdit != null)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: onEdit,
                            color: Colors.grey[600],
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (onEdit != null && onDelete != null)
                          const SizedBox(width: 16),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: onDelete,
                            color: Colors.grey[600],
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    
                    // "Done" button for today's reminders
                    ElevatedButton(
                      onPressed: () => _markAsDone(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: typeColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(60, 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Color _getColorByType(ReminderType type) {
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
  
  IconData _getIconByType(ReminderType type) {
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
  
  String _getRepeatText(List<bool> daysOfWeek) {
    if (daysOfWeek.every((day) => day)) {
      return 'Every day';
    }
    
    if (daysOfWeek.sublist(0, 5).every((day) => day) && 
        daysOfWeek.sublist(5, 7).every((day) => !day)) {
      return 'Weekdays';
    }
    
    if (daysOfWeek.sublist(0, 5).every((day) => !day) && 
        daysOfWeek.sublist(5, 7).every((day) => day)) {
      return 'Weekends';
    }
    
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedDays = <String>[];
    
    for (int i = 0; i < daysOfWeek.length; i++) {
      if (daysOfWeek[i]) {
        selectedDays.add(dayLabels[i]);
      }
    }
    
    if (selectedDays.length <= 3) {
      return selectedDays.join(', ');
    } else {
      return '${selectedDays.length} days';
    }
  }
  
  void _markAsDone(BuildContext context) async {
    final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    
    try {
      switch (reminder.type) {
        case ReminderType.feeding:
          await reminderProvider.markFeedingComplete(reminder);
          break;
        case ReminderType.medication:
          await reminderProvider.markMedicationComplete(reminder);
          break;
        case ReminderType.grooming:
          await reminderProvider.markGroomingComplete(reminder);
          break;
        case ReminderType.other:
          // Just mark as completed for the day
          break;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked ${reminder.type.name} reminder as done!'),
          backgroundColor: _getColorByType(reminder.type),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking reminder as done: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
} 