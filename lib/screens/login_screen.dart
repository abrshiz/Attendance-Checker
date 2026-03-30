import 'package:flutter/material.dart';
import 'package:qr_app/screens/teacher_dashboard.dart';
import 'package:qr_app/screens/student_dashboard.dart';
import 'package:qr_app/database/simple_storage.dart';
import 'package:qr_app/models/student_model.dart'; // Add this import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SimpleStorage _storage = SimpleStorage();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'teacher';

  @override
  void initState() {
    super.initState();
    _createDemoData();
  }

  Future<void> _createDemoData() async {
    final students = await _storage.getStudentsByClass('all');
    if (students.isEmpty) {
      // Create demo student with login credentials
      final demoStudent = StudentModel(
        id: 'student_001',
        studentId: 'STU2024001',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '+1234567890',
        classId: 'class_001', // Add classId
        enrolledDate: DateTime.now(),
        isActive: true,
        username: 'john_doe',
        password: 'student123',
      );
      await _storage.insertStudent(demoStudent);
      print('Demo student created - Username: john_doe, Password: student123');
    }
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage("Please enter username and password", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedRole == 'teacher') {
        // Teacher login
        if (_storage.authenticateTeacher(
            _usernameController.text, _passwordController.text)) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherDashboard(
                teacherId: 'teacher_001', // Add teacherId
                teacherName: 'Teacher', // Add teacherName
              ),
            ),
          );
        } else {
          _showMessage("Invalid teacher credentials", Colors.red);
        }
      } else {
        // Student login
        final student = await _storage.authenticateStudent(
          _usernameController.text,
          _passwordController.text,
        );

        if (student != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDashboard(
                studentId: student.studentId,
                studentName: student.name,
                studentObject: student,
              ),
            ),
          );
        } else {
          _showMessage("Invalid student credentials", Colors.red);
        }
      }
    } catch (e) {
      _showMessage("Error: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.blue.shade300],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.qr_code_scanner,
                        size: 64,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Attendance Checker",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in to continue",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 32),

                    // Role Selection
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'teacher',
                          label: Text("Teacher"),
                          icon: Icon(Icons.school),
                        ),
                        ButtonSegment(
                          value: 'student',
                          label: Text("Student"),
                          icon: Icon(Icons.person),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedRole = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Username Field
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: _selectedRole == 'teacher'
                            ? "Username"
                            : "Username",
                        hintText:
                            _selectedRole == 'teacher' ? "teacher" : "john_doe",
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        hintText: _selectedRole == 'teacher'
                            ? "teacher123"
                            : "student123",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue.shade900,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                "Login",
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Demo credentials hint
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Demo Credentials:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          if (_selectedRole == 'teacher')
                            Text(
                              "Teacher: teacher / teacher123",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700),
                            ),
                          if (_selectedRole == 'student')
                            Text(
                              "Student: john_doe / student123",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
