import 'package:flutter/material.dart';

class Pet {
  final String id;
  final String name;
  final String species;
  final DateTime? birthDate;
  final String? breed;
  final double? weight;
  final String? imageUrl;
  final String notes;

  Pet({
    String? id,
    required this.name,
    required this.species,
    this.birthDate,
    this.breed,
    this.weight,
    this.imageUrl,
    this.notes = '',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Copy method for easy updates
  Pet copyWith({
    String? id,
    String? name,
    String? species,
    DateTime? birthDate,
    String? breed,
    double? weight,
    String? imageUrl,
    String? notes,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      birthDate: birthDate ?? this.birthDate,
      breed: breed ?? this.breed,
      weight: weight ?? this.weight,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'birthDate': birthDate?.toIso8601String(),
      'breed': breed,
      'weight': weight,
      'imageUrl': imageUrl,
      'notes': notes,
    };
  }

  // Create a Pet from a Map
  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      birthDate: map['birthDate'] != null ? DateTime.parse(map['birthDate']) : null,
      breed: map['breed'],
      weight: map['weight'] != null ? map['weight'].toDouble() : null,
      imageUrl: map['imageUrl'],
      notes: map['notes'] ?? '',
    );
  }

  // Calculate pet's age in years
  int? getAge() {
    if (birthDate == null) return null;
    
    final now = DateTime.now();
    final age = now.difference(birthDate!).inDays ~/ 365;
    return age;
  }

  // For debugging
  @override
  String toString() {
    return 'Pet{id: $id, name: $name, species: $species, breed: $breed, age: ${getAge()}}';
  }
}

// Sample pets for initial data
List<Pet> getSamplePets() {
  return [
    Pet(
      id: '1',
      name: 'Buddy',
      species: 'Dog',
      birthDate: DateTime(2020, 5, 15),
      breed: 'Golden Retriever',
      weight: 30.5,
      imageUrl: 'https://images.unsplash.com/photo-1552053831-71594a27632d',
    ),
    Pet(
      id: '2',
      name: 'Whiskers',
      species: 'Cat',
      birthDate: DateTime(2019, 8, 10),
      breed: 'Siamese',
      weight: 5.2,
      imageUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba',
    ),
    Pet(
      id: '3',
      name: 'Bubbles',
      species: 'Fish',
      breed: 'Goldfish',
      weight: 0.1,
      imageUrl: null,
    ),
  ];
} 