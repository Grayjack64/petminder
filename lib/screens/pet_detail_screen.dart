import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../models/feeding.dart';
import '../models/medication.dart';
import '../models/task.dart';
import '../providers/feeding_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/task_provider.dart';
import 'feeding_screen.dart';
import 'medication_screen.dart';
import 'task_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final Pet pet;

  const PetDetailScreen({
    super.key, 
    required this.pet,
  });

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInit = false;
  bool _isLoadingFeedings = false;
  bool _isLoadingMedications = false;
  bool _isLoadingTasks = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      _loadData();
      _isInit = true;
    }
    super.didChangeDependencies();
  }

  void _loadData() {
    setState(() {
      _isLoadingFeedings = true;
      _isLoadingMedications = true;
      _isLoadingTasks = true;
    });

    // Load feedings
    Provider.of<FeedingProvider>(context, listen: false)
        .loadFeedingsForPet(widget.pet.id)
        .then((_) {
      setState(() {
        _isLoadingFeedings = false;
      });
    });

    // Load medications
    Provider.of<MedicationProvider>(context, listen: false)
        .loadMedicationsForPet(widget.pet.id)
        .then((_) {
      setState(() {
        _isLoadingMedications = false;
      });
    });

    // Load tasks
    Provider.of<TaskProvider>(context, listen: false)
        .loadTasksForPet(widget.pet.id)
        .then((_) {
      setState(() {
        _isLoadingTasks = false;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pet.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Medications'),
            Tab(text: 'Tasks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _isLoadingMedications 
              ? const Center(child: CircularProgressIndicator())
              : _buildMedicationsTab(),
          _isLoadingTasks 
              ? const Center(child: CircularProgressIndicator())
              : _buildTasksTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleAddAction(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pet header
          Center(
            child: Column(
              children: [
                Hero(
                  tag: 'pet-avatar-${widget.pet.id}',
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      widget.pet.species == 'Dog' 
                          ? Icons.pets 
                          : widget.pet.species == 'Cat'
                              ? Icons.emoji_nature
                              : Icons.cruelty_free,
                      size: 60,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.pet.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '${widget.pet.species} • ${widget.pet.breed}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '${widget.pet.getAge() ?? "Unknown"} years old${widget.pet.weight != null ? ' • ${widget.pet.weight} kg' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (widget.pet.birthDate != null)
                  Text(
                    'Born: ${DateFormat('MMM d, yyyy').format(widget.pet.birthDate!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          
          if (widget.pet.notes.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(widget.pet.notes),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Recent feedings
          const Text(
            'Recent Feedings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _isLoadingFeedings
              ? const Center(child: CircularProgressIndicator())
              : _buildRecentFeedings(),
          
          const SizedBox(height: 24),
          
          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickActionButton(
                context,
                'Add Feeding',
                Icons.restaurant,
                Colors.green,
                () => _navigateToFeedingScreen(context),
              ),
              _buildQuickActionButton(
                context,
                'Add Medication',
                Icons.medication,
                Colors.red,
                () => _navigateToMedicationScreen(context),
              ),
              _buildQuickActionButton(
                context,
                'Add Task',
                Icons.assignment,
                Colors.orange,
                () => _navigateToTaskScreen(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFeedings() {
    final feedingProvider = Provider.of<FeedingProvider>(context);
    final feedings = feedingProvider.feedings;
    
    if (feedings.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No feeding records yet. Add your first feeding!'),
        ),
      );
    }
    
    // Only show the last 3 feedings
    final recentFeedings = feedings.take(3).toList();
    
    return Column(
      children: recentFeedings.map((feeding) {
        final isFood = feeding.type.toLowerCase() == 'food';
        final isWater = feeding.type.toLowerCase() == 'water';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isFood 
                  ? Colors.amber.shade100
                  : isWater 
                      ? Colors.blue.shade100 
                      : Colors.purple.shade100,
              child: Icon(
                isFood 
                    ? Icons.restaurant 
                    : isWater 
                        ? Icons.water_drop 
                        : Icons.cake,
                color: isFood 
                    ? Colors.amber 
                    : isWater 
                        ? Colors.blue 
                        : Colors.purple,
              ),
            ),
            title: Text('${feeding.amount} ${feeding.unit} of ${feeding.type}'),
            subtitle: Text(DateFormat('MMM d, yyyy - HH:mm').format(feeding.timestamp)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteFeeding(context, feeding),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMedicationsTab() {
    final medicationProvider = Provider.of<MedicationProvider>(context);
    final medications = medicationProvider.medications;
    
    if (medications.isEmpty) {
      return const Center(
        child: Text('No medications added yet.'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final medication = medications[index];
        final isOverdue = medication.nextDose.isBefore(DateTime.now());
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isOverdue 
                  ? Colors.red.shade100 
                  : Colors.green.shade100,
              child: Icon(
                isOverdue ? Icons.warning : Icons.medication,
                color: isOverdue ? Colors.red : Colors.green,
              ),
            ),
            title: Text(medication.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dosage: ${medication.dosage}'),
                Text('Next dose: ${DateFormat('MMM d, yyyy - HH:mm').format(medication.nextDose)}'),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () => _markMedicationAdministered(context, medication),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteMedication(context, medication),
                ),
              ],
            ),
            onTap: () => _navigateToMedicationScreen(context, medication: medication),
          ),
        );
      },
    );
  }

  Widget _buildTasksTab() {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;
    
    if (tasks.isEmpty) {
      return const Center(
        child: Text('No tasks added yet.'),
      );
    }
    
    // Separate completed and incomplete tasks
    final incompleteTasks = tasks.where((task) => !task.completed).toList();
    final completedTasks = tasks.where((task) => task.completed).toList();
    
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        if (incompleteTasks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Pending Tasks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...incompleteTasks.map((task) => _buildTaskItem(context, task)).toList(),
        ],
        
        if (completedTasks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Completed Tasks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...completedTasks.map((task) => _buildTaskItem(context, task)).toList(),
        ],
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task) {
    final isOverdue = task.isOverdue;
    final isHighPriority = task.priority == 3;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: task.completed,
          onChanged: (value) {
            if (value != null) {
              _toggleTaskCompletion(context, task);
            }
          },
        ),
        title: Text(
          task.description,
          style: TextStyle(
            decoration: task.completed ? TextDecoration.lineThrough : null,
            color: task.completed ? Colors.grey : null,
            fontWeight: isHighPriority ? FontWeight.bold : null,
          ),
        ),
        subtitle: Text(
          'Due: ${DateFormat('MMM d, yyyy').format(task.dueDate)}${task.recurring ? ' (Recurring)' : ''}',
          style: TextStyle(
            color: isOverdue && !task.completed ? Colors.red : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteTask(context, task),
        ),
        onTap: () => _navigateToTaskScreen(context, task: task),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddAction(BuildContext context) {
    final tabIndex = _tabController.index;
    
    switch (tabIndex) {
      case 0:
        // Overview tab - show dialog to choose what to add
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Add'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.restaurant, color: Colors.green),
                  title: const Text('Feeding'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToFeedingScreen(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.medication, color: Colors.red),
                  title: const Text('Medication'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToMedicationScreen(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.orange),
                  title: const Text('Task'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTaskScreen(context);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
        break;
      case 1:
        // Medications tab
        _navigateToMedicationScreen(context);
        break;
      case 2:
        // Tasks tab
        _navigateToTaskScreen(context);
        break;
    }
  }

  void _navigateToFeedingScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedingScreen(pet: widget.pet),
      ),
    );
  }

  void _navigateToMedicationScreen(BuildContext context, {Medication? medication}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationScreen(
          pet: widget.pet,
          medication: medication,
        ),
      ),
    );
  }

  void _navigateToTaskScreen(BuildContext context, {Task? task}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskScreen(
          pet: widget.pet,
          task: task,
        ),
      ),
    );
  }

  void _deleteFeeding(BuildContext context, Feeding feeding) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this feeding record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<FeedingProvider>(context, listen: false)
                  .deleteFeeding(feeding.id!);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteMedication(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this medication?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<MedicationProvider>(context, listen: false)
                  .deleteMedication(medication.id!);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _markMedicationAdministered(BuildContext context, Medication medication) {
    Provider.of<MedicationProvider>(context, listen: false)
        .markMedicationAdministered(medication, widget.pet);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${medication.name} marked as administered'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<TaskProvider>(context, listen: false)
                  .deleteTask(task.id!);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleTaskCompletion(BuildContext context, Task task) {
    Provider.of<TaskProvider>(context, listen: false)
        .toggleTaskCompletion(task);
  }
} 