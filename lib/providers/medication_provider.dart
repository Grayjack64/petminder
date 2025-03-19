import 'package:flutter/foundation.dart';
import '../models/medication.dart';
import '../models/pet.dart';
import '../services/database_service.dart';

class MedicationProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Medication> _medications = [];
  bool _isLoading = false;
  String? _error;
  String? _currentPetId;

  // Getters
  List<Medication> get medications => _medications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get upcoming medications for all pets
  Future<List<Medication>> getUpcomingMedications() async {
    return await _db.getUpcomingMedications();
  }

  // Get upcoming medications for a specific pet
  List<Medication> getUpcomingMedicationsForPet(String petId) {
    final now = DateTime.now();
    return _medications
        .where((med) => 
            med.petId == petId && 
            med.nextDose.isAfter(now) && 
            (med.endDate == null || med.endDate!.isAfter(now)))
        .toList()
        ..sort((a, b) => a.nextDose.compareTo(b.nextDose));
  }

  // Load medications for a specific pet
  Future<void> loadMedicationsForPet(String petId) async {
    _isLoading = true;
    _error = null;
    _currentPetId = petId;
    notifyListeners();

    try {
      _medications = await _db.getMedicationsForPet(petId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load medications: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new medication
  Future<void> addMedication(Medication medication) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _db.insertMedication(medication);
      
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
      _medications.sort((a, b) => a.nextDose.compareTo(b.nextDose)); // Sort by soonest first
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add medication: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing medication
  Future<void> updateMedication(Medication medication) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _db.updateMedication(medication);
      
      if (success) {
        final index = _medications.indexWhere((m) => m.id == medication.id);
        if (index != -1) {
          _medications[index] = medication;
          _medications.sort((a, b) => a.nextDose.compareTo(b.nextDose)); // Sort by soonest first
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update medication: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a medication
  Future<void> deleteMedication(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _db.deleteMedication(id);
      
      if (success) {
        _medications.removeWhere((medication) => medication.id == id);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete medication: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark a medication as administered
  Future<void> markMedicationAdministered(Medication medication, Pet pet) async {
    if (!medication.isRecurring || medication.frequencyDays == null) {
      // If not recurring, delete it after administration
      if (medication.id != null) {
        await deleteMedication(medication.id!);
      }
      return;
    }
    
    // For recurring medications, update the next dose date
    final updatedMedication = medication.updateNextDose();
    
    if (updatedMedication.nextDose == medication.nextDose) {
      // No update needed (might be at the end date)
      return;
    }
    
    await updateMedication(updatedMedication);
  }
} 