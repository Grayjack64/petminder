import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../models/task.dart';
import '../models/medication.dart';
import '../providers/pet_provider.dart';
import '../providers/task_provider.dart';
import '../providers/medication_provider.dart';
import 'pet_detail_screen.dart';
import 'add_pet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInit = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      setState(() {
        _isLoading = true;
      });
      
      Provider.of<PetProvider>(context).loadPets().then((_) {
        setState(() {
          _isLoading = false;
        });
      });
      
      _isInit = true;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Care'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddPet(context),
        tooltip: 'Add Pet',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final petProvider = Provider.of<PetProvider>(context);
    
    if (petProvider.error != null) {
      return Center(
        child: Text(
          'Error: ${petProvider.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    
    final pets = petProvider.pets;
    
    if (pets.isEmpty) {
      return const Center(
        child: Text('No pets added yet. Add your first pet!'),
      );
    }
    
    return Column(
      children: [
        // Upcoming events section
        _buildUpcomingEventsSection(context),
        
        // Pets list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return _buildPetCard(context, pet);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingEventsSection(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        Provider.of<TaskProvider>(context, listen: false).getAllIncompleteTasks(),
        Provider.of<MedicationProvider>(context, listen: false).getUpcomingMedications(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final tasks = snapshot.data![0] as List<Task>;
        final medications = snapshot.data![1] as List<Medication>;
        
        if (tasks.isEmpty && medications.isEmpty) {
          return const SizedBox();  // No upcoming events
        }
        
        // Combine and sort tasks and medications by date
        final allEvents = <Map<String, dynamic>>[];
        
        for (final task in tasks) {
          allEvents.add({
            'type': 'task',
            'date': task.dueDate,
            'data': task,
          });
        }
        
        for (final med in medications) {
          allEvents.add({
            'type': 'medication',
            'date': med.nextDose,
            'data': med,
          });
        }
        
        // Sort by date
        allEvents.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        
        // Take only the next 5 events
        final nextEvents = allEvents.take(5).toList();
        
        return Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: nextEvents.length,
                itemBuilder: (context, index) {
                  final event = nextEvents[index];
                  final isTask = event['type'] == 'task';
                  final date = event['date'] as DateTime;
                  
                  if (isTask) {
                    final task = event['data'] as Task;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: const Icon(Icons.task_alt, color: Colors.orange),
                      ),
                      title: Text(task.description),
                      subtitle: Text(_formatDate(date)),
                      dense: true,
                    );
                  } else {
                    final medication = event['data'] as Medication;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        child: const Icon(Icons.medication, color: Colors.red),
                      ),
                      title: Text(medication.name),
                      subtitle: Text(_formatDate(date)),
                      dense: true,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPetCard(BuildContext context, Pet pet) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: () => _navigateToPetDetail(context, pet),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade100,
                child: Icon(
                  pet.species == 'Dog' 
                      ? Icons.pets 
                      : pet.species == 'Cat'
                          ? Icons.emoji_nature
                          : Icons.cruelty_free,
                  size: 30,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet.breed ?? "Unknown breed"}, ${pet.getAge() ?? "Unknown"} years old',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (pet.notes.isNotEmpty)
                      Text(
                        pet.notes,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPetDetail(BuildContext context, Pet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(pet: pet),
      ),
    );
  }

  void _navigateToAddPet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPetScreen(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateDay == tomorrow) {
      return 'Tomorrow, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
} 