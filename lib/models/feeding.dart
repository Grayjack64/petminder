class Feeding {
  final int? id;
  final String petId;
  final String type; // 'food' or 'water' or 'treats'
  final double amount;
  final String unit; // 'cups', 'ml', 'oz', etc.
  final DateTime timestamp;
  final String notes;

  Feeding({
    this.id,
    required this.petId,
    required this.type,
    required this.amount,
    required this.unit,
    required this.timestamp,
    this.notes = '',
  });

  // Create a copy with updated fields
  Feeding copyWith({
    int? id,
    String? petId,
    String? type,
    double? amount,
    String? unit,
    DateTime? timestamp,
    String? notes,
  }) {
    return Feeding(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'type': type,
      'amount': amount,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  // Create from Map for database retrieval
  factory Feeding.fromMap(Map<String, dynamic> map) {
    return Feeding(
      id: map['id'],
      petId: map['petId'],
      type: map['type'],
      amount: map['amount'],
      unit: map['unit'],
      timestamp: DateTime.parse(map['timestamp']),
      notes: map['notes'] ?? '',
    );
  }
}

// Sample feeding data (normally this would come from a database)
final List<Feeding> sampleFeedings = [
  Feeding(
    id: 1,
    petId: 'Buddy',
    type: 'food',
    amount: 2.0,
    unit: 'cups',
    timestamp: DateTime.now().subtract(const Duration(hours: 6)),
  ),
  Feeding(
    id: 2,
    petId: 'Buddy',
    type: 'water',
    amount: 500,
    unit: 'ml',
    timestamp: DateTime.now().subtract(const Duration(hours: 4)),
  ),
  Feeding(
    id: 3,
    petId: 'Whiskers',
    type: 'food',
    amount: 0.5,
    unit: 'cups',
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
  ),
]; 