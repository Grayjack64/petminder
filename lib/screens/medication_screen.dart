import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../models/medication.dart';
import '../providers/medication_provider.dart';

class MedicationScreen extends StatefulWidget {
  final Pet pet;
  final Medication? medication; // If provided, we're editing an existing medication

  const MedicationScreen({
    super.key, 
    required this.pet, 
    this.medication,
  });

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  DateTime _nextDose = DateTime.now().add(const Duration(days: 1));
  bool _isRecurring = false;
  int? _frequencyDays;
  DateTime? _endDate;
  final _notesController = TextEditingController();
  
  bool _isEditing = false;

  final List<int> _frequencyOptions = [1, 7, 14, 30, 60, 90, 180, 365];

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _isEditing = true;
      _nameController.text = widget.medication!.name;
      _dosageController.text = widget.medication!.dosage;
      _instructionsController.text = widget.medication!.instructions;
      _nextDose = widget.medication!.nextDose;
      _isRecurring = widget.medication!.isRecurring;
      _frequencyDays = widget.medication!.frequencyDays;
      _endDate = widget.medication!.endDate;
      _notesController.text = widget.medication!.notes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectNextDoseDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _nextDose,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (pickedDate == null) return;

    if (!mounted) return;
    
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_nextDose),
    );
    
    if (pickedTime != null) {
      setState(() {
        _nextDose = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _nextDose.add(const Duration(days: 30)),
      firstDate: _nextDose,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (pickedDate != null) {
      setState(() {
        _endDate = pickedDate;
      });
    }
  }

  void _clearEndDate() {
    setState(() {
      _endDate = null;
    });
  }

  void _saveMedication() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Create a medication object from form data
    final medication = Medication(
      id: _isEditing ? widget.medication!.id : null,
      petId: widget.pet.id,
      name: _nameController.text,
      dosage: _dosageController.text,
      instructions: _instructionsController.text,
      nextDose: _nextDose,
      isRecurring: _isRecurring,
      frequencyDays: _isRecurring ? _frequencyDays : null,
      endDate: _isRecurring ? _endDate : null,
      notes: _notesController.text,
    );

    // Save the medication
    if (_isEditing) {
      Provider.of<MedicationProvider>(context, listen: false)
          .updateMedication(medication)
          .then((_) {
        Navigator.pop(context);
      });
    } else {
      Provider.of<MedicationProvider>(context, listen: false)
          .addMedication(medication)
          .then((_) {
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medication' : 'Add Medication'),
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
              
              // Medication name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a medication name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Dosage
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage (e.g., "1 tablet" or "10ml")',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the dosage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Instructions
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions (e.g., "With food")',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Next dose date and time
              InkWell(
                onTap: () => _selectNextDoseDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Next Dose Date & Time',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('MMM d, yyyy - HH:mm').format(_nextDose),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Recurring medication options
              SwitchListTile(
                title: const Text('Recurring Medication'),
                subtitle: const Text('Set up a schedule for this medication'),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                    if (value && _frequencyDays == null) {
                      _frequencyDays = 30; // Default to monthly
                    }
                  });
                },
              ),
              
              if (_isRecurring) ...[
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
                  value: _frequencyDays ?? 30,
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
                    if (_isRecurring && value == null) {
                      return 'Please select a frequency';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // End date (optional)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _endDate != null ? () => _selectEndDate(context) : null,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _endDate == null 
                                ? 'No end date'
                                : DateFormat('MMM d, yyyy').format(_endDate!),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectEndDate(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _endDate != null ? _clearEndDate : null,
                    ),
                  ],
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
                  onPressed: _saveMedication,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: Text(_isEditing ? 'Update Medication' : 'Add Medication'),
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