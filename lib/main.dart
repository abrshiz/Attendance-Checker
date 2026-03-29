import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'screens/class_management_screen.dart';

void main() async {
  // Initialize database for desktop
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.init(); // Initialize FFI for desktop

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const ClassManagementScreen(),
    );
  }
}
