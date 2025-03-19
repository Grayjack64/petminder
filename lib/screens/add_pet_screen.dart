import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../providers/pet_provider.dart';

class AddPetScreen extends StatefulWidget {
  final Pet? pet; // If provided, we're editing an existing pet

  const AddPetScreen({super.key, this.pet});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _birthDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _isEditing = true;
      _nameController.text = widget.pet!.name;
      _speciesController.text = widget.pet!.species;
      _breedController.text = widget.pet!.breed ?? '';
      if (widget.pet!.getAge() != null) {
        _ageController.text = widget.pet!.getAge().toString();
      }
      if (widget.pet!.weight != null) {
        _weightController.text = widget.pet!.weight.toString();
      }
      _notesController.text = widget.pet!.notes;
      _birthDate = widget.pet!.birthDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
        // Update age based on birth date
        final now = DateTime.now();
        final age = now.year - picked.year - 
            (now.month > picked.month || 
            (now.month == picked.month && now.day >= picked.day) ? 0 : 1);
        _ageController.text = age.toString();
      });
    }
  }

  void _savePet() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Create a pet object from form data
    final pet = Pet(
      id: _isEditing ? widget.pet!.id : null,
      name: _nameController.text,
      species: _speciesController.text,
      breed: _breedController.text.isNotEmpty ? _breedController.text : null,
      birthDate: _birthDate,
      weight: _weightController.text.isNotEmpty 
          ? double.parse(_weightController.text) 
          : null,
      notes: _notesController.text,
    );

    // Save the pet
    if (_isEditing) {
      Provider.of<PetProvider>(context, listen: false)
          .updatePet(pet)
          .then((_) {
        Navigator.pop(context);
      });
    } else {
      Provider.of<PetProvider>(context, listen: false)
          .addPet(pet)
          .then((_) {
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit ${widget.pet!.name}' : 'Add New Pet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Pet Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _speciesController,
                decoration: const InputDecoration(
                  labelText: 'Species (Dog, Cat, etc.)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a species';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(
                  labelText: 'Breed',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a breed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age (years)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an age';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Birth date picker
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Birth Date (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _birthDate == null 
                              ? 'Select a date'
                              : DateFormat('MMM d, yyyy').format(_birthDate!),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
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
              
              Center(
                child: ElevatedButton(
                  onPressed: _savePet,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: Text(_isEditing ? 'Save Changes' : 'Add Pet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 