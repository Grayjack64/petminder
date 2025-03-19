import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'providers/pet_provider.dart';
import 'providers/feeding_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/task_provider.dart';
import 'providers/reminder_provider.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data
  tz.initializeTimeZones();
  
  // Initialize notification service safely
  try {
    final notificationService = NotificationService();
    // We don't await this - let it complete in the background
    // The service will handle initialization when needed
    notificationService.initialize().then((success) {
      if (success) {
        print("Notification service initialized successfully");
      } else {
        print("Failed to initialize notification service");
      }
    });
  } catch (e) {
    print("Error during notification setup: $e");
    // Continue even if notification setup fails
  }
  
  runApp(const PetMinder());
}

class PetMinder extends StatelessWidget {
  const PetMinder({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => FeedingProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
      ],
      child: MaterialApp(
        title: 'PetMinder',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7EB5A6), // Soft teal/mint
            primary: const Color(0xFF7EB5A6),
            secondary: const Color(0xFFE8C07D), // Soft gold/wheat
            tertiary: const Color(0xFFF6AE99), // Soft coral
            background: const Color(0xFFF5F5F5), // Light grey background
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF7EB5A6),
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF7EB5A6),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF7EB5A6),
            foregroundColor: Colors.white,
          ),
          cardTheme: CardTheme(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          tabBarTheme: const TabBarTheme(
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xDDFFFFFF),
            indicatorColor: Colors.white,
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
