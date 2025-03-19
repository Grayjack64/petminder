import 'package:flutter/foundation.dart';
import '../models/feeding.dart';
import '../models/pet.dart';
import '../services/database_service.dart';

class FeedingProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Feeding> _feedings = [];
  bool _isLoading = false;
  String? _error;
  String? _currentPetId;

  // Getters
  List<Feeding> get feedings => _feedings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get the latest feeding for display on pet details
  Future<Feeding?> getLatestFeeding(String petId) async {
    return await _db.getLatestFeedingForPet(petId);
  }

  // Load feedings for a specific pet
  Future<void> loadFeedingsForPet(String petId) async {
    _isLoading = true;
    _error = null;
    _currentPetId = petId;
    notifyListeners();

    try {
      _feedings = await _db.getFeedingsForPet(petId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load feedings: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new feeding record
  Future<void> addFeeding(Feeding feeding) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _db.insertFeeding(feeding);
      
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
      _feedings.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by newest first
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add feeding: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing feeding record
  Future<void> updateFeeding(Feeding feeding) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _db.updateFeeding(feeding);
      
      if (success) {
        final index = _feedings.indexWhere((f) => f.id == feeding.id);
        if (index != -1) {
          _feedings[index] = feeding;
          _feedings.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by newest first
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update feeding: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a feeding record
  Future<void> deleteFeeding(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _db.deleteFeeding(id);
      
      if (success) {
        _feedings.removeWhere((feeding) => feeding.id == id);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete feeding: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Quick add methods for common feeding operations
  
  // Add a food feeding with default values
  Future<void> quickAddFood(Pet pet, double amount, String unit) async {
    final feeding = Feeding(
      petId: pet.id,
      type: 'food',
      amount: amount,
      unit: unit,
      timestamp: DateTime.now(),
    );
    
    await addFeeding(feeding);
  }
  
  // Add a water feeding with default values
  Future<void> quickAddWater(Pet pet, double amount, String unit) async {
    final feeding = Feeding(
      petId: pet.id,
      type: 'water',
      amount: amount,
      unit: unit,
      timestamp: DateTime.now(),
    );
    
    await addFeeding(feeding);
  }
} 