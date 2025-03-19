import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/pet.dart';
import '../services/database_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  String? _currentPetId;

  // Getters
  List<Task> get tasks => _tasks;
  List<Task> get incompleteTasks => _tasks.where((task) => !task.completed).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all incomplete tasks
  Future<List<Task>> getAllIncompleteTasks() async {
    return await _db.getIncompleteTasks();
  }

  // Get all tasks for today
  List<Task> getTodaysTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _tasks
        .where((task) => 
            !task.completed && 
            DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day).isAtSameMomentAs(today))
        .toList();
  }

  // Get overdue tasks
  List<Task> getOverdueTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _tasks
        .where((task) => 
            !task.completed && 
            DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day).isBefore(today))
        .toList();
  }

  // Load tasks for a specific pet
  Future<void> loadTasksForPet(String petId) async {
    _isLoading = true;
    _error = null;
    _currentPetId = petId;
    notifyListeners();

    try {
      _tasks = await _db.getTasksForPet(petId);
      _tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate)); // Sort by date
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load tasks: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new task
  Future<void> addTask(Task task) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _db.insertTask(task);
      
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
      _tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate)); // Sort by date
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add task: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing task
  Future<void> updateTask(Task task) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _db.updateTask(task);
      
      if (success) {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task;
          _tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate)); // Sort by date
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update task: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a task
  Future<void> deleteTask(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _db.deleteTask(id);
      
      if (success) {
        _tasks.removeWhere((task) => task.id == id);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete task: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle task completion status
  Future<void> toggleTaskCompletion(Task task) async {
    // Create a new copy with toggled completion status
    final updatedTask = task.copyWith(completed: !task.completed);
    
    await updateTask(updatedTask);
    
    // If completed and recurring, create next task
    if (updatedTask.completed && updatedTask.recurring && updatedTask.frequencyDays != null) {
      final nextTask = task.createNextRecurringTask();
      await addTask(nextTask);
    }
  }
} 