import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskScreen extends StatefulWidget {
  final Pet pet;
  final Task? task; // If provided, we're editing an existing task

  const TaskScreen({
    super.key, 
    required this.pet, 
    this.task,
  });

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _completed = false;
  int _priority = 2; // Medium priority by default
  bool _recurring = false;
  int? _frequencyDays;
  final _notesController = TextEditingController();
  
  bool _isEditing = false;

  final List<int> _frequencyOptions = [1, 7, 14, 30, 60, 90, 180, 365];
  final List<Map<String, dynamic>> _priorityOptions = [
    {'value': 1, 'label': 'Low', 'color': Colors.green},
    {'value': 2, 'label': 'Medium', 'color': Colors.orange},
    {'value': 3, 'label': 'High', 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _isEditing = true;
      _descriptionController.text = widget.task!.description;
      _dueDate = widget.task!.dueDate;
      _completed = widget.task!.completed;
      _priority = widget.task!.priority;
      _recurring = widget.task!.recurring;
      _frequencyDays = widget.task!.frequencyDays;
      _notesController.text = widget.task!.notes;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Allow backdating tasks
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (pickedDate == null) return;

    if (!mounted) return;
    
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );
    
    if (pickedTime != null) {
      setState(() {
        _dueDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    } else {
      setState(() {
        _dueDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _dueDate.hour,
          _dueDate.minute,
        );
      });
    }
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Create a task object from form data
    final task = Task(
      id: _isEditing ? widget.task!.id : null,
      petId: widget.pet.id,
      description: _descriptionController.text,
      dueDate: _dueDate,
      completed: _completed,
      priority: _priority,
      recurring: _recurring,
      frequencyDays: _recurring ? _frequencyDays : null,
      notes: _notesController.text,
    );

    // Save the task
    if (_isEditing) {
      Provider.of<TaskProvider>(context, listen: false)
          .updateTask(task)
          .then((_) {
        Navigator.pop(context);
      });
    } else {
      Provider.of<TaskProvider>(context, listen: false)
          .addTask(task)
          .then((_) {
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Add Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pet info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(
                          widget.pet.species == 'Dog' 
                              ? Icons.pets 
                              : widget.pet.species == 'Cat'
                                  ? Icons.emoji_nature
                                  : Icons.cruelty_free,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pet.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.pet.species}, ${widget.pet.getAge() ?? "Unknown"} years old',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Task description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Task Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a task description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Due date
              InkWell(
                onTap: () => _selectDueDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date & Time',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('MMM d, yyyy - HH:mm').format(_dueDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Priority selection
              const Text(
                'Priority',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: _priorityOptions.map((option) {
                  return ButtonSegment<int>(
                    value: option['value'],
                    label: Text(option['label']),
                    icon: Icon(Icons.flag, color: option['color']),
                  );
                }).toList(),
                selected: {_priority},
                onSelectionChanged: (Set<int> selection) {
                  setState(() {
                    _priority = selection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Completed status
              if (_isEditing)
                CheckboxListTile(
                  title: const Text('Mark as Completed'),
                  value: _completed,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _completed = value;
                      });
                    }
                  },
                ),
              
              // Recurring task options
              SwitchListTile(
                title: const Text('Recurring Task'),
                subtitle: const Text('Set up a schedule for this task'),
                value: _recurring,
                onChanged: (value) {
                  setState(() {
                    _recurring = value;
                    if (value && _frequencyDays == null) {
                      _frequencyDays = 7; // Default to weekly
                    }
                  });
                },
              ),
              
              if (_recurring) ...[
                const SizedBox(height: 8),
                
                // Frequency selection
                const Text(
                  'Frequency',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Repeat Every',
                    border: OutlineInputBorder(),
                  ),
                  value: _frequencyDays ?? 7,
                  items: _frequencyOptions.map((days) {
                    return DropdownMenuItem<int>(
                      value: days,
                      child: Text(_getFrequencyText(days)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _frequencyDays = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (_recurring && value == null) {
                      return 'Please select a frequency';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Save button
              Center(
                child: ElevatedButton(
                  onPressed: _saveTask,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: Text(_isEditing ? 'Update Task' : 'Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFrequencyText(int days) {
    switch (days) {
      case 1:
        return 'Daily';
      case 7:
        return 'Weekly';
      case 14:
        return 'Every 2 weeks';
      case 30:
        return 'Monthly';
      case 60:
        return 'Every 2 months';
      case 90:
        return 'Every 3 months';
      case 180:
        return 'Every 6 months';
      case 365:
        return 'Yearly';
      default:
        return 'Every $days days';
    }
  }
} 