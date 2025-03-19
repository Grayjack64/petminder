import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder.dart';
import '../models/pet.dart';
import '../providers/reminder_provider.dart';
import '../providers/pet_provider.dart';
import '../services/notification_service.dart';

class AddReminderScreen extends StatefulWidget {
  final String? petId; // If provided, pre-select this pet
  final Reminder? reminder; // If provided, we're editing this reminder
  final ReminderType? initialReminderType; // Optional initial reminder type

  const AddReminderScreen({
    super.key, 
    this.petId, 
    this.reminder,
    this.initialReminderType,
  });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers and values
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedPetId;
  ReminderType _selectedType = ReminderType.feeding;
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<bool> _selectedDays = List.filled(7, false); // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  
  bool _isLoading = false;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.petId;
    
    if (widget.reminder != null) {
      _isEditing = true;
      _initFromReminder(widget.reminder!);
    } else {
      // Default values for new reminder - select today
      final now = DateTime.now();
      _selectedDays[now.weekday - 1] = true; // weekday is 1-7 where 1 is Monday
      
      // Set type if provided
      if (widget.initialReminderType != null) {
        _selectedType = widget.initialReminderType!;
      }
    }
    
    // Load pet if not loaded yet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPetsIfNeeded();
    });
  }
  
  void _initFromReminder(Reminder reminder) {
    _titleController.text = reminder.title;
    _detailsController.text = reminder.details;
    _notesController.text = reminder.notes;
    _selectedPetId = reminder.petId;
    _selectedType = reminder.type;
    _selectedTime = reminder.time;
    _selectedDays = List.from(reminder.daysOfWeek);
  }
  
  Future<void> _loadPetsIfNeeded() async {
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    
    if (petProvider.pets.isEmpty) {
      setState(() {
        _isLoading = true;
      });
      
      await petProvider.loadPets();
      
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Reminder' : 'Add Reminder'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPetSelector(),
                    const SizedBox(height: 16),
                    
                    _buildReminderTypeSelector(),
                    const SizedBox(height: 16),
                    
                    _buildTimeSelector(),
                    const SizedBox(height: 16),
                    
                    _buildDaysSelector(),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: _getLabelByType(),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _detailsController,
                      decoration: InputDecoration(
                        labelText: _getDetailsByType(),
                        hintText: _getHintByType(),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      onPressed: _saveReminder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(_isEditing ? 'Update Reminder' : 'Create Reminder'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildPetSelector() {
    final petProvider = Provider.of<PetProvider>(context);
    final pets = petProvider.pets;
    
    if (pets.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No pets added yet. Please add a pet first.'),
        ),
      );
    }
    
    return DropdownButtonFormField<String>(
      value: _selectedPetId,
      decoration: const InputDecoration(
        labelText: 'Pet',
        border: OutlineInputBorder(),
      ),
      items: pets.map((pet) {
        return DropdownMenuItem<String>(
          value: pet.id,
          child: Text(pet.name),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a pet';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {
          _selectedPetId = value;
        });
      },
    );
  }
  
  Widget _buildReminderTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder Type',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeChip(ReminderType.feeding, Icons.restaurant),
            ),
            Expanded(
              child: _buildTypeChip(ReminderType.medication, Icons.medication),
            ),
            Expanded(
              child: _buildTypeChip(ReminderType.grooming, Icons.brush),
            ),
            Expanded(
              child: _buildTypeChip(ReminderType.other, Icons.event_note),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTypeChip(ReminderType type, IconData icon) {
    // Get the appropriate color based on type
    final color = _getColorByType(type);
    final isSelected = _selectedType == type;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isSelected ? color : color.withOpacity(0.2),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _capitalizeString(type.name),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeSelector() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _selectTime,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Time',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _formattedTime(_selectedTime),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.schedule),
          onPressed: _selectTime,
        ),
      ],
    );
  }
  
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  String _formattedTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }
  
  Widget _buildDaysSelector() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Repeat on',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            TextButton(
              onPressed: _toggleAllDays,
              child: Text(
                _allDaysSelected() ? 'Clear All' : 'Select All',
                style: TextStyle(
                  color: _getColorByType(_selectedType),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            return _buildDayChip(days[index], index);
          }),
        ),
      ],
    );
  }
  
  Widget _buildDayChip(String label, int index) {
    final isSelected = _selectedDays[index];
    final color = _getColorByType(_selectedType);
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDays[index] = !_selectedDays[index];
        });
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? color : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label.substring(0, 1),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  void _toggleAllDays() {
    setState(() {
      final newValue = !_allDaysSelected();
      _selectedDays = List.filled(7, newValue);
    });
  }
  
  bool _allDaysSelected() {
    return !_selectedDays.contains(false);
  }
  
  String _getLabelByType() {
    switch (_selectedType) {
      case ReminderType.feeding:
        return 'Food Type';
      case ReminderType.medication:
        return 'Medication Name';
      case ReminderType.grooming:
        return 'Grooming Activity';
      case ReminderType.other:
        return 'Reminder Title';
    }
  }
  
  String _getDetailsByType() {
    switch (_selectedType) {
      case ReminderType.feeding:
        return 'Amount and Unit';
      case ReminderType.medication:
        return 'Dosage';
      case ReminderType.grooming:
        return 'Details';
      case ReminderType.other:
        return 'Details';
    }
  }
  
  String _getHintByType() {
    switch (_selectedType) {
      case ReminderType.feeding:
        return 'e.g., 2 cups, 1 can, 150 grams';
      case ReminderType.medication:
        return 'e.g., 1 tablet, 5ml, 2 drops';
      case ReminderType.grooming:
        return 'e.g., Brush fur, Trim nails, Bathe';
      case ReminderType.other:
        return 'Additional details';
    }
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
  
  void _saveReminder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validate at least one day is selected
    if (!_selectedDays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day of the week'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final reminder = Reminder(
        id: _isEditing ? widget.reminder!.id : null,
        petId: _selectedPetId!,
        type: _selectedType,
        title: _titleController.text,
        time: _selectedTime,
        daysOfWeek: List.from(_selectedDays),
        details: _detailsController.text,
        notes: _notesController.text,
      );
      
      final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
      
      if (_isEditing) {
        await reminderProvider.updateReminder(reminder);
      } else {
        await reminderProvider.addReminder(reminder);
      }
      
      // Schedule notification for this reminder
      final notificationService = NotificationService();
      await notificationService.scheduleReminderNotification(reminder);
      
      // Go back to previous screen
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving reminder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Helper function to capitalize a string
  String _capitalizeString(String s) {
    if (s.isEmpty) return s;
    return "${s[0].toUpperCase()}${s.substring(1)}";
  }
} 