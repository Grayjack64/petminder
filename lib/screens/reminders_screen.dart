import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder.dart';
import '../models/pet.dart';
import '../providers/reminder_provider.dart';
import '../providers/pet_provider.dart';
import '../services/notification_service.dart';
import '../widgets/reminder_card.dart';
import 'add_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  final String? petId; // If provided, only show reminders for this pet

  const RemindersScreen({super.key, this.petId});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInit = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: ReminderType.values.length + 1, vsync: this);
  }

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      _loadData();
      _isInit = true;
    }
    super.didChangeDependencies();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    
    try {
      if (widget.petId != null) {
        await reminderProvider.loadRemindersForPet(widget.petId!);
      } else {
        await reminderProvider.loadReminders();
      }
      
      // Also make sure pet data is loaded
      await Provider.of<PetProvider>(context, listen: false).loadPets();
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading reminders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.petId != null ? 'Pet Reminders' : 'All Reminders'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'All'),
            const Tab(text: 'Feeding'),
            const Tab(text: 'Medication'),
            const Tab(text: 'Grooming'),
            const Tab(text: 'Other'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRemindersTab(null), // All reminders
                _buildRemindersTab(ReminderType.feeding),
                _buildRemindersTab(ReminderType.medication),
                _buildRemindersTab(ReminderType.grooming),
                _buildRemindersTab(ReminderType.other),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddReminder(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRemindersTab(ReminderType? type) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Consumer<ReminderProvider>(
        builder: (context, reminderProvider, child) {
          List<Reminder> reminders;
          
          if (type == null) {
            // Show all reminders
            reminders = reminderProvider.reminders;
          } else {
            // Show only reminders of this type
            reminders = reminderProvider.getRemindersByType(type, widget.petId);
          }

          if (reminders.isEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Container(
                      height: constraints.maxHeight,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No reminders yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            type == null
                                ? 'Add your first reminder by tapping the + button'
                                : 'Add your first ${type.name} reminder by tapping the + button',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _navigateToAddReminder(context, type: type),
                            icon: const Icon(Icons.add),
                            label: Text('Add ${type?.name.toLowerCase() ?? ''} Reminder'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          }

          // Add pet names to reminders for display
          final petProvider = Provider.of<PetProvider>(context, listen: false);
          final petsMap = {for (var pet in petProvider.pets) pet.id: pet};

          final remindersWithPetNames = reminders.map((reminder) {
            final pet = petsMap[reminder.petId];
            return reminder.copyWith(
              petName: pet?.name,
            );
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: remindersWithPetNames.length,
            itemBuilder: (context, index) {
              final reminder = remindersWithPetNames[index];
              
              return ReminderCard(
                reminder: reminder,
                showPetName: widget.petId == null, // Only show pet name in the All Reminders screen
                onEdit: () => _navigateToEditReminder(context, reminder),
                onDelete: () => _deleteReminder(context, reminder),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToAddReminder(BuildContext context, {ReminderType? type}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReminderScreen(
          petId: widget.petId,
          initialReminderType: type,
        ),
      ),
    );
    
    // Refresh the list when returning
    if (mounted) {
      _loadData();
    }
  }

  void _navigateToEditReminder(BuildContext context, Reminder reminder) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReminderScreen(
          reminder: reminder,
        ),
      ),
    );
    
    // Refresh the list when returning
    if (mounted) {
      _loadData();
    }
  }

  void _deleteReminder(BuildContext context, Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete the ${reminder.title} reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              if (reminder.id != null) {
                await Provider.of<ReminderProvider>(context, listen: false)
                    .deleteReminder(reminder.id!);
              }
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reminder deleted'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 