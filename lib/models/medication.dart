class Medication {
  final int? id;
  final String petId;
  final String name;
  final String dosage;
  final String instructions;
  final DateTime nextDose;
  final bool isRecurring;
  final int? frequencyDays; // How often to administer (every X days)
  final DateTime? endDate; // Optional end date for the medication
  final String notes;

  Medication({
    this.id,
    required this.petId,
    required this.name,
    required this.dosage,
    this.instructions = '',
    required this.nextDose,
    this.isRecurring = false,
    this.frequencyDays,
    this.endDate,
    this.notes = '',
  });

  // Check if medication is active
  bool get isActive {
    if (endDate != null && DateTime.now().isAfter(endDate!)) {
      return false;
    }
    return true;
  }

  // Method to update the next dose date for recurring medications
  Medication updateNextDose() {
    if (!isRecurring || frequencyDays == null) {
      return this;
    }
    
    final newNextDose = nextDose.add(Duration(days: frequencyDays!));
    
    // If there's an end date and the new next dose is after it, don't update
    if (endDate != null && newNextDose.isAfter(endDate!)) {
      return this;
    }
    
    return copyWith(nextDose: newNextDose);
  }

  // Copy with new values
  Medication copyWith({
    int? id,
    String? petId,
    String? name,
    String? dosage,
    String? instructions,
    DateTime? nextDose,
    bool? isRecurring,
    int? frequencyDays,
    DateTime? endDate,
    String? notes,
  }) {
    return Medication(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      nextDose: nextDose ?? this.nextDose,
      isRecurring: isRecurring ?? this.isRecurring,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
    );
  }

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'name': name,
      'dosage': dosage,
      'instructions': instructions,
      'nextDose': nextDose.toIso8601String(),
      'isRecurring': isRecurring ? 1 : 0,
      'frequencyDays': frequencyDays,
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
    };
  }

  // Create from Map for database retrieval
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      petId: map['petId'],
      name: map['name'],
      dosage: map['dosage'],
      instructions: map['instructions'] ?? '',
      nextDose: DateTime.parse(map['nextDose']),
      isRecurring: map['isRecurring'] == 1,
      frequencyDays: map['frequencyDays'],
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      notes: map['notes'] ?? '',
    );
  }
}

// Sample medication data
final List<Medication> sampleMedications = [
  Medication(
    id: 1,
    petId: 'Buddy',
    name: 'Heartgard',
    dosage: '1 tablet',
    instructions: 'Give with food',
    nextDose: DateTime.now().add(const Duration(days: 1)),
    isRecurring: true,
    frequencyDays: 30,
    notes: 'Monthly heartworm prevention',
  ),
  Medication(
    id: 2,
    petId: 'Buddy',
    name: 'Antibiotics',
    dosage: '10mg',
    instructions: 'Give twice daily',
    nextDose: DateTime.now().add(const Duration(hours: 6)),
    isRecurring: true,
    frequencyDays: 1,
    endDate: DateTime.now().add(const Duration(days: 10)),
    notes: 'For ear infection',
  ),
  Medication(
    id: 3,
    petId: 'Whiskers',
    name: 'Frontline',
    dosage: '1 application',
    instructions: 'Apply to back of neck',
    nextDose: DateTime.now().add(const Duration(days: 15)),
    isRecurring: true,
    frequencyDays: 30,
    notes: 'Flea and tick prevention',
  ),
]; 