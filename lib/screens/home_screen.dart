import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../models/task.dart';
import '../models/medication.dart';
import '../models/reminder.dart';
import '../providers/pet_provider.dart';
import '../providers/task_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/ad_service.dart';
import '../utils/format_utils.dart';
import 'pet_detail_screen.dart';
import 'add_pet_screen.dart';
import 'reminders_screen.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _error;
  bool _upcomingEventsLoading = true;
  String? _upcomingEventsError;
  List<Reminder> _todayReminders = [];
  
  // Ad-related variables
  final AdService _adService = AdService();
  BannerAd? _topBannerAd;
  bool _isTopBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    print("HomeScreen: initState called");
    
    // Load pets when the screen initializes, but don't block the UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("HomeScreen: postFrameCallback executed");
      
      // Set a timeout to ensure we always exit loading state
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isLoading) {
          print("HomeScreen: Loading timeout reached, showing error state");
          setState(() {
            _isLoading = false;
            _error = "Loading timed out - please check your connection";
          });
        }
        
        if (mounted && _upcomingEventsLoading) {
          print("HomeScreen: Events loading timeout reached");
          setState(() {
            _upcomingEventsLoading = false;
            _upcomingEventsError = "Loading events timed out";
          });
        }
      });
      
      // Load data non-blockingly
      _loadPets();
      _loadTodayReminders();
      _loadAds();
    });
  }
  
  @override
  void dispose() {
    _topBannerAd?.dispose();
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("HomeScreen: didChangeDependencies called");
    
    // Reload reminders data every time the screen becomes active
    if (!_upcomingEventsLoading) {
      _loadTodayReminders();
    }
  }
  
  // Load ads
  Future<void> _loadAds() async {
    try {
      _topBannerAd = await _adService.loadTopBannerAd();
      
      if (mounted && _topBannerAd != null) {
        setState(() {
          _isTopBannerAdLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading ads: $e');
    }
  }
  
  // Show an interstitial ad
  Future<void> _showInterstitialAd() async {
    await _adService.showInterstitialAd();
  }

  Future<void> _loadPets() async {
    print("HomeScreen: Loading pets...");
    if (!mounted) {
      print("HomeScreen: Widget not mounted, skipping pet loading");
      return;
    }
    
    try {
      final petProvider = Provider.of<PetProvider>(context, listen: false);
      await petProvider.loadPets().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("HomeScreen: Pet loading timed out");
          throw TimeoutException("Pet loading timed out");
        },
      );
      
      if (mounted) {
        print("HomeScreen: Pets loaded successfully");
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      print("HomeScreen: Error loading pets: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Error loading pets: $e";
        });
      }
    }
  }
  
  // Load today's reminders
  Future<void> _loadTodayReminders() async {
    print("HomeScreen: Loading today's reminders...");
    if (!mounted) {
      print("HomeScreen: Widget not mounted, skipping reminder loading");
      return;
    }
    
    try {
      final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
      final reminders = await reminderProvider.getAllRemindersForToday().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("HomeScreen: Reminder loading timed out");
          throw TimeoutException("Reminder loading timed out");
        },
      );
      
      if (mounted) {
        print("HomeScreen: Reminders loaded successfully: ${reminders.length} items");
        setState(() {
          _todayReminders = reminders;
          _upcomingEventsLoading = false;
          _upcomingEventsError = null;
        });
      }
    } catch (e) {
      print("HomeScreen: Error loading reminders: $e");
      if (mounted) {
        setState(() {
          _upcomingEventsLoading = false;
          _upcomingEventsError = "Error loading reminders: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("HomeScreen: build method called");
    return Scaffold(
      appBar: AppBar(
        title: const Text('PetMinder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'All Reminders',
            onPressed: () => _navigateToAllReminders(context),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Test Notification',
            onPressed: () => _testNotification(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top banner ad
            if (_isTopBannerAdLoaded && _topBannerAd != null)
              Container(
                alignment: Alignment.center,
                width: _topBannerAd!.size.width.toDouble(),
                height: _topBannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _topBannerAd!),
              ),
              
            // Main content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Loading pets..."),
                        ],
                      ),
                    )
                  : _error != null 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Error: $_error',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                    _error = null;
                                  });
                                  _loadPets();
                                },
                                child: const Text('Retry'),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _error = null;
                                  });
                                },
                                child: const Text('Continue Without Loading'),
                              ),
                            ],
                          ),
                        )
                      : _buildBody(context),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show an interstitial ad when adding a new pet
          _showInterstitialAd();
          _navigateToAddPet(context);
        },
        tooltip: 'Add Pet',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final petProvider = Provider.of<PetProvider>(context);
    
    if (petProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${petProvider.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadPets();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    final pets = petProvider.pets;
    
    if (pets.isEmpty) {
      return const Center(
        child: Text('No pets added yet. Add your first pet!'),
      );
    }
    
    return Column(
      children: [
        // Upcoming events section with proper error handling
        _upcomingEventsLoading 
            ? Container(
                height: 100,
                padding: const EdgeInsets.all(12),
                child: const Center(child: CircularProgressIndicator()),
              )
            : _upcomingEventsError != null
                ? Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEE),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Error: $_upcomingEventsError',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        TextButton(
                          onPressed: _loadTodayReminders,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _buildUpcomingEventsSection(),
        
        // Pets list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return _buildPetCard(context, pet);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPetCard(BuildContext context, Pet pet) {
    // Restore reminders count with error handling
    List<Reminder> todayReminders = [];
    
    try {
      final reminderProvider = Provider.of<ReminderProvider>(context);
      todayReminders = reminderProvider.getRemindersForToday(pet.id);
    } catch (e) {
      print("Error getting reminders for pet ${pet.name}: $e");
      // Continue without reminders
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: () => _navigateToPetDetail(context, pet),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Hero(
                tag: 'pet-avatar-${pet.id}',
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFE6F2EF), // Light teal background
                  backgroundImage: _getPetImage(pet),
                  child: (pet.imageUrl == null || pet.imageUrl!.isEmpty)
                    ? Icon(
                        pet.species == 'Dog' 
                            ? Icons.pets 
                            : pet.species == 'Cat'
                                ? Icons.emoji_nature
                                : Icons.cruelty_free,
                        size: 30,
                        color: const Color(0xFF7EB5A6), // Teal icon
                      )
                    : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row with pet name and reminder count
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pet.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (todayReminders.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${todayReminders.length} today',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet.breed ?? "Unknown breed"}, ${pet.getAge() ?? "Unknown"} years old',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (pet.notes.isNotEmpty)
                      Text(
                        pet.notes,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildUpcomingEventsSection() {
    if (_todayReminders.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F2EF),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Center(
          child: Text(
            'No reminders for today',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      );
    }
    
    // Group reminders by type
    final feedingReminders = _todayReminders.where((r) => r.type == ReminderType.feeding).toList();
    final medicationReminders = _todayReminders.where((r) => r.type == ReminderType.medication).toList();
    final groomingReminders = _todayReminders.where((r) => r.type == ReminderType.grooming).toList();
    final otherReminders = _todayReminders.where((r) => r.type == ReminderType.other).toList();
    
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F2EF),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s Reminders',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                GestureDetector(
                  onTap: _loadTodayReminders,
                  child: const Icon(Icons.refresh, size: 18),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 105,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              children: [
                if (feedingReminders.isNotEmpty) 
                  _buildReminderCard(feedingReminders, ReminderType.feeding),
                if (medicationReminders.isNotEmpty) 
                  _buildReminderCard(medicationReminders, ReminderType.medication),
                if (groomingReminders.isNotEmpty) 
                  _buildReminderCard(groomingReminders, ReminderType.grooming),
                if (otherReminders.isNotEmpty) 
                  _buildReminderCard(otherReminders, ReminderType.other),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReminderCard(List<Reminder> reminders, ReminderType type) {
    return GestureDetector(
      onTap: () => _navigateToAllReminders(context),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        color: _getBackgroundColorByType(type),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getIconByType(type),
                    color: _getColorByType(type),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getReminderTypeText(type),
                    style: TextStyle(
                      color: _getColorByType(type),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${reminders.length} reminder${reminders.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatNextReminder(reminders),
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatNextReminder(List<Reminder> reminders) {
    // Sort reminders by time
    final sortedReminders = [...reminders]..sort((a, b) {
      final aTimeValue = a.time.hour * 60 + a.time.minute;
      final bTimeValue = b.time.hour * 60 + b.time.minute;
      return aTimeValue.compareTo(bTimeValue);
    });
    
    if (sortedReminders.isEmpty) return "No reminders";
    
    // Get the next reminder
    final now = TimeOfDay.now();
    final nowValue = now.hour * 60 + now.minute;
    
    Reminder? nextReminder;
    
    // First look for a reminder later today
    for (final reminder in sortedReminders) {
      final reminderValue = reminder.time.hour * 60 + reminder.time.minute;
      if (reminderValue > nowValue) {
        nextReminder = reminder;
        break;
      }
    }
    
    // If no reminders later today, get the first one
    nextReminder ??= sortedReminders.first;
    
    // Format the time
    final hour = nextReminder.time.hour;
    final minute = nextReminder.time.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    final formattedMinute = minute.toString().padLeft(2, '0');
    
    return "Next: ${formattedHour}:${formattedMinute} ${period}";
  }
  
  String _getReminderTypeText(ReminderType type) {
    switch (type) {
      case ReminderType.feeding:
        return 'Feeding';
      case ReminderType.medication:
        return 'Medication';
      case ReminderType.grooming:
        return 'Grooming';
      case ReminderType.other:
        return 'Other';
    }
  }

  // Helper method to get pet image
  ImageProvider? _getPetImage(Pet pet) {
    if (pet.imageUrl == null || pet.imageUrl!.isEmpty) {
      return null;
    }

    if (pet.imageUrl!.startsWith('http')) {
      return NetworkImage(pet.imageUrl!);
    } else {
      return FileImage(File(pet.imageUrl!));
    }
  }

  void _navigateToPetDetail(BuildContext context, Pet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(pet: pet),
      ),
    ).then((_) {
      // Refresh reminders when returning from PetDetailScreen
      _loadTodayReminders();
    });
  }

  void _navigateToAddPet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPetScreen(),
      ),
    ).then((_) {
      // Refresh data when returning from AddPetScreen
      _loadPets();
      _loadTodayReminders();
    });
  }
  
  void _navigateToAllReminders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RemindersScreen(),
      ),
    ).then((_) {
      // Refresh reminders when returning from RemindersScreen
      _loadTodayReminders();
    });
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
  
  Color _getBackgroundColorByType(ReminderType type) {
    switch (type) {
      case ReminderType.feeding:
        return const Color(0xFFF3E6C8); // Light gold
      case ReminderType.medication:
        return const Color(0xFFFAE2D9); // Light coral
      case ReminderType.grooming:
        return const Color(0xFFE6F2EF); // Light teal
      case ReminderType.other:
        return Colors.grey.shade100;
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

  void _testNotification() {
    // Create a notification service instance
    final notificationService = NotificationService();
    
    // Send a test notification
    notificationService.sendTestNotification().then((success) {
      // Show snackbar with result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Test notification sent successfully. Check your notifications!' 
              : 'Failed to send test notification'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }
} 