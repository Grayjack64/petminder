import '../models/pet.dart';
import '../models/feeding.dart';
import '../models/medication.dart';
import '../models/task.dart';
import '../models/reminder.dart';

// Simple in-memory database service
// In a real app, you would use sqflite or Hive for local storage
class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // In-memory storage
  List<Pet> _pets = getSamplePets(); // Use the sample pets from the updated Pet model
  List<Feeding> _feedings = [];
  List<Medication> _medications = [];
  List<Task> _tasks = [];
  List<Reminder> _reminders = []; // New reminders list

  // PETS
  Future<List<Pet>> getAllPets() async {
    return [..._pets];
  }

  Future<Pet?> getPetById(String id) async {
    try {
      return _pets.firstWhere((pet) => pet.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<String> insertPet(Pet pet) async {
    // Pet already has an ID generated in its constructor
    _pets.add(pet);
    return pet.id;
  }

  Future<bool> updatePet(Pet pet) async {
    final index = _pets.indexWhere((p) => p.id == pet.id);
    if (index == -1) return false;
    
    _pets[index] = pet;
    return true;
  }

  Future<bool> deletePet(String id) async {
    final initialLength = _pets.length;
    _pets.removeWhere((pet) => pet.id == id);
    
    // Also remove associated data
    _feedings.removeWhere((feeding) => feeding.petId == id);
    _medications.removeWhere((medication) => medication.petId == id);
    _tasks.removeWhere((task) => task.petId == id);
    
    return initialLength != _pets.length;
  }

  // FEEDINGS
  Future<List<Feeding>> getFeedingsForPet(String petId) async {
    return _feedings.where((feeding) => feeding.petId == petId).toList();
  }

  Future<Feeding?> getFeedingById(int? id) async {
    try {
      return _feedings.firstWhere((feeding) => feeding.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> insertFeeding(Feeding feeding) async {
    final id = _feedings.isEmpty 
        ? 1 
        : _feedings.map((f) => f.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    
    final newFeeding = Feeding(
      id: id,
      petId: feeding.petId,
      type: feeding.type,
      amount: feeding.amount,
      unit: feeding.unit,
      timestamp: feeding.timestamp,
      notes: feeding.notes,
    );
    
    _feedings.add(newFeeding);
    return id;
  }

  Future<bool> updateFeeding(Feeding feeding) async {
    final index = _feedings.indexWhere((f) => f.id == feeding.id);
    if (index == -1) return false;
    
    _feedings[index] = feeding;
    return true;
  }

  Future<bool> deleteFeeding(int? id) async {
    final initialLength = _feedings.length;
    _feedings.removeWhere((feeding) => feeding.id == id);
    return initialLength != _feedings.length;
  }

  // Get the most recent feeding for a pet
  Future<Feeding?> getLatestFeedingForPet(String petId) async {
    final petFeedings = await getFeedingsForPet(petId);
    if (petFeedings.isEmpty) return null;
    
    return petFeedings.reduce((a, b) => 
        a.timestamp.isAfter(b.timestamp) ? a : b);
  }

  // MEDICATIONS
  Future<List<Medication>> getMedicationsForPet(String petId) async {
    return _medications.where((medication) => medication.petId == petId).toList();
  }

  Future<List<Medication>> getUpcomingMedications() async {
    final now = DateTime.now();
    return _medications
        .where((medication) => 
            medication.nextDose.isAfter(now) && 
            (medication.endDate == null || medication.endDate!.isAfter(now)))
        .toList()
        ..sort((a, b) => a.nextDose.compareTo(b.nextDose));
  }

  Future<Medication?> getMedicationById(int? id) async {
    try {
      return _medications.firstWhere((medication) => medication.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> insertMedication(Medication medication) async {
    final id = _medications.isEmpty 
        ? 1 
        : _medications.map((m) => m.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    
    final newMedication = Medication(
      id: id,
      petId: medication.petId,
      name: medication.name,
      dosage: medication.dosage,
      instructions: medication.instructions,
      nextDose: medication.nextDose,
      isRecurring: medication.isRecurring,
      frequencyDays: medication.frequencyDays,
      endDate: medication.endDate,
      notes: medication.notes,
    );
    
    _medications.add(newMedication);
    return id;
  }

  Future<bool> updateMedication(Medication medication) async {
    final index = _medications.indexWhere((m) => m.id == medication.id);
    if (index == -1) return false;
    
    _medications[index] = medication;
    return true;
  }

  Future<bool> deleteMedication(int? id) async {
    final initialLength = _medications.length;
    _medications.removeWhere((medication) => medication.id == id);
    return initialLength != _medications.length;
  }

  // TASKS
  Future<List<Task>> getTasksForPet(String petId) async {
    return _tasks.where((task) => task.petId == petId).toList();
  }

  Future<List<Task>> getIncompleteTasks() async {
    return _tasks
        .where((task) => !task.completed)
        .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Future<Task?> getTaskById(int? id) async {
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> insertTask(Task task) async {
    final id = _tasks.isEmpty 
        ? 1 
        : _tasks.map((t) => t.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    
    final newTask = Task(
      id: id,
      petId: task.petId,
      description: task.description,
      dueDate: task.dueDate,
      completed: task.completed,
      priority: task.priority,
      notes: task.notes,
      recurring: task.recurring,
      frequencyDays: task.frequencyDays,
    );
    
    _tasks.add(newTask);
    return id;
  }

  Future<bool> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return false;
    
    _tasks[index] = task;
    return true;
  }

  Future<bool> deleteTask(int? id) async {
    final initialLength = _tasks.length;
    _tasks.removeWhere((task) => task.id == id);
    return initialLength != _tasks.length;
  }

  // REMINDERS 
  Future<List<Reminder>> getAllReminders() async {
    return [..._reminders];
  }

  Future<List<Reminder>> getRemindersForPet(String petId) async {
    return _reminders.where((reminder) => reminder.petId == petId).toList();
  }

  Future<Reminder?> getReminderById(int? id) async {
    try {
      return _reminders.firstWhere((reminder) => reminder.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> insertReminder(Reminder reminder) async {
    final id = _reminders.isEmpty 
        ? 1 
        : _reminders.map((r) => r.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    
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
    return id;
  }

  Future<bool> updateReminder(Reminder reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index == -1) return false;
    
    _reminders[index] = reminder;
    return true;
  }

  Future<bool> deleteReminder(int? id) async {
    final initialLength = _reminders.length;
    _reminders.removeWhere((reminder) => reminder.id == id);
    return initialLength != _reminders.length;
  }

  // Helper methods for handling reminder actions

  // Create a feeding record from a reminder
  Future<int> insertFeedingFromReminder(
    String petId, 
    String type, 
    double amount, 
    String unit,
    String notes
  ) async {
    final feeding = Feeding(
      petId: petId,
      type: type,
      amount: amount,
      unit: unit,
      timestamp: DateTime.now(),
      notes: notes,
    );
    
    return await insertFeeding(feeding);
  }

  // Record medication administration from a reminder
  Future<void> recordMedicationFromReminder(
    String petId,
    String medicationName,
    String dosage,
    String notes
  ) async {
    // Find the existing medication
    try {
      final medications = await getMedicationsForPet(petId);
      final medication = medications.firstWhere(
        (med) => med.name == medicationName,
        orElse: () => Medication(
          petId: petId,
          name: medicationName,
          dosage: dosage,
          nextDose: DateTime.now().add(const Duration(days: 1)),
          notes: notes,
        ),
      );
      
      // If it's a recurring medication, update next dose
      if (medication.isRecurring && medication.frequencyDays != null) {
        final updatedMedication = medication.updateNextDose();
        
        if (medication.id != null) {
          await updateMedication(updatedMedication);
        } else {
          await insertMedication(updatedMedication);
        }
      }
    } catch (e) {
      // Create a one-time medication record if needed
      final medication = Medication(
        petId: petId,
        name: medicationName,
        dosage: dosage,
        nextDose: DateTime.now().add(const Duration(days: 1)),
        notes: 'Administered on ${DateTime.now()}. $notes',
      );
      
      await insertMedication(medication);
    }
  }
  
  // Create a grooming task record from a reminder
  Future<int> insertGroomingTask(
    String petId,
    String description,
    String notes
  ) async {
    final task = Task(
      petId: petId,
      description: description,
      dueDate: DateTime.now(),
      completed: true,
      notes: 'Completed on ${DateTime.now()}. $notes',
    );
    
    return await insertTask(task);
  }
} 