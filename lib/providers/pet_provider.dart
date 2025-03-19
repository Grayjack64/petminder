import 'package:flutter/foundation.dart';
import '../models/pet.dart';
import '../services/database_service.dart';

class PetProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Pet> _pets = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Pet> get pets => _pets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all pets
  Future<void> loadPets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pets = await _db.getAllPets();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load pets: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a specific pet by ID
  Future<Pet?> getPet(String id) async {
    return await _db.getPetById(id);
  }

  // Add a new pet
  Future<void> addPet(Pet pet) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _db.insertPet(pet);
      final newPet = Pet(
        id: id,
        name: pet.name,
        species: pet.species,
        breed: pet.breed,
        birthDate: pet.birthDate,
        weight: pet.weight,
        imageUrl: pet.imageUrl,
        notes: pet.notes,
      );
      
      _pets.add(newPet);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add pet: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing pet
  Future<void> updatePet(Pet pet) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _db.updatePet(pet);
      
      if (success) {
        final index = _pets.indexWhere((p) => p.id == pet.id);
        if (index != -1) {
          _pets[index] = pet;
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update pet: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a pet
  Future<void> deletePet(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _db.deletePet(id);
      
      if (success) {
        _pets.removeWhere((pet) => pet.id == id);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete pet: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
} 