class Task {
  final int? id;
  final String petId;
  final String description;
  final DateTime dueDate;
  final bool completed;
  final int priority; // 1 = low, 2 = medium, 3 = high
  final String notes;
  final bool recurring;
  final int? frequencyDays; // For recurring tasks

  Task({
    this.id,
    required this.petId,
    required this.description,
    required this.dueDate,
    this.completed = false,
    this.priority = 2, // Medium priority by default
    this.notes = '',
    this.recurring = false,
    this.frequencyDays,
  });

  // Check if task is overdue
  bool get isOverdue {
    return !completed && dueDate.isBefore(DateTime.now());
  }

  // Create a new task with the next due date for recurring tasks
  Task createNextRecurringTask() {
    if (!recurring || frequencyDays == null) {
      return this;
    }
    
    final newDueDate = dueDate.add(Duration(days: frequencyDays!));
    
    return Task(
      petId: petId,
      description: description,
      dueDate: newDueDate,
      priority: priority,
      notes: notes,
      recurring: recurring,
      frequencyDays: frequencyDays,
    );
  }

  // Copy with new values
  Task copyWith({
    int? id,
    String? petId,
    String? description,
    DateTime? dueDate,
    bool? completed,
    int? priority,
    String? notes,
    bool? recurring,
    int? frequencyDays,
  }) {
    return Task(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      recurring: recurring ?? this.recurring,
      frequencyDays: frequencyDays ?? this.frequencyDays,
    );
  }

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'completed': completed ? 1 : 0,
      'priority': priority,
      'notes': notes,
      'recurring': recurring ? 1 : 0,
      'frequencyDays': frequencyDays,
    };
  }

  // Create from Map for database retrieval
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      petId: map['petId'],
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      completed: map['completed'] == 1,
      priority: map['priority'] ?? 2,
      notes: map['notes'] ?? '',
      recurring: map['recurring'] == 1,
      frequencyDays: map['frequencyDays'],
    );
  }
}

// Sample task data
final List<Task> sampleTasks = [
  Task(
    id: 1,
    petId: '1', // Buddy
    description: 'Grooming appointment',
    dueDate: DateTime.now().add(const Duration(days: 2)),
    priority: 2, // Medium
    notes: 'At PetSmart, 2:00 PM',
  ),
  Task(
    id: 2,
    petId: '1', // Buddy
    description: 'Vet checkup',
    dueDate: DateTime.now().add(const Duration(days: 14)),
    priority: 3, // High
    notes: 'Annual wellness exam',
  ),
  Task(
    id: 3,
    petId: '2', // Whiskers
    description: 'Clean litter box',
    dueDate: DateTime.now(),
    recurring: true,
    frequencyDays: 1,
    priority: 2, // Medium
  ),
  Task(
    id: 4,
    petId: '3', // Hopper
    description: 'Clean cage',
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
    recurring: true,
    frequencyDays: 7,
    priority: 2, // Medium
  ),
]; 