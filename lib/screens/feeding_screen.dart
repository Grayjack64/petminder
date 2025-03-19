import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../models/feeding.dart';
import '../providers/feeding_provider.dart';

class FeedingScreen extends StatefulWidget {
  final Pet pet;
  final Feeding? feeding; // If provided, we're editing an existing feeding

  const FeedingScreen({
    super.key, 
    required this.pet, 
    this.feeding,
  });

  @override
  State<FeedingScreen> createState() => _FeedingScreenState();
}

class _FeedingScreenState extends State<FeedingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _selectedType = 'food';
  final _amountController = TextEditingController();
  String _selectedUnit = 'cups';
  DateTime _selectedDateTime = DateTime.now();
  final _notesController = TextEditingController();
  
  bool _isEditing = false;

  final List<String> _feedingTypes = ['food', 'water', 'treats'];
  final Map<String, List<String>> _unitsByType = {
    'food': ['cups', 'grams', 'oz'],
    'water': ['ml', 'oz', 'cups'],
    'treats': ['pieces', 'grams', 'oz'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.feeding != null) {
      _isEditing = true;
      _selectedType = widget.feeding!.type;
      _amountController.text = widget.feeding!.amount.toString();
      _selectedUnit = widget.feeding!.unit;
      _selectedDateTime = widget.feeding!.timestamp;
      _notesController.text = widget.feeding!.notes;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    
    if (pickedDate == null) return;

    if (!mounted) return;
    
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    
    if (pickedTime != null) {
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  void _saveFeeding() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Create a feeding object from form data
    final feeding = Feeding(
      id: _isEditing ? widget.feeding!.id : null,
      petId: widget.pet.id,
      type: _selectedType,
      amount: double.parse(_amountController.text),
      unit: _selectedUnit,
      timestamp: _selectedDateTime,
      notes: _notesController.text,
    );

    // Save the feeding
    if (_isEditing) {
      Provider.of<FeedingProvider>(context, listen: false)
          .updateFeeding(feeding)
          .then((_) {
        Navigator.pop(context);
      });
    } else {
      Provider.of<FeedingProvider>(context, listen: false)
          .addFeeding(feeding)
          .then((_) {
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = _unitsByType[_selectedType] ?? ['cups'];
    
    if (!units.contains(_selectedUnit)) {
      _selectedUnit = units.first;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Feeding' : 'Add Feeding'),
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
              
              // Feeding type
              const Text(
                'Type of Feeding',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: _feedingTypes.map((type) {
                  return ButtonSegment<String>(
                    value: type,
                    label: Text(type.capitalize()),
                    icon: Icon(_getIconForType(type)),
                  );
                }).toList(),
                selected: {_selectedType},
                onSelectionChanged: (Set<String> selection) {
                  setState(() {
                    _selectedType = selection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Amount and unit
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedUnit,
                      items: units.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedUnit = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Date and time
              InkWell(
                onTap: () => _selectDateTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date & Time',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('MMM d, yyyy - HH:mm').format(_selectedDateTime),
                  ),
                ),
              ),
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
                  onPressed: _saveFeeding,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: Text(_isEditing ? 'Update Feeding' : 'Add Feeding'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'water':
        return Icons.water_drop;
      case 'treats':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 