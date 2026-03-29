import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';

// Models
import '../models/student.dart';
import '../models/attendance_model.dart';
import '../models/student_model.dart';

// Database
import '../database/database_helper.dart';

// Screens
import 'qr_generator_screen.dart';
import 'qr_scanner_screen.dart';
import 'attendance_list_screen.dart';
import 'student_profile_screen.dart';

class TeacherDashboard extends StatefulWidget {
  final String classId;
  final String className;

  const TeacherDashboard({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Student> _students = [];
  List<AttendanceModel> _attendanceList = [];
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load students for this class
      final students = await _db.getStudentsByClass(widget.classId);
      _students = students
          .map((s) => Student(
                id: s.id,
                name: s.name,
                timestamp: DateTime.now(),
                status: AttendanceStatus.absent,
              ))
          .toList();

      // Load attendance for today
      _attendanceList =
          await _db.getAttendanceByClassAndDate(widget.classId, _selectedDate);
    } catch (e) {
      _showMessage("Error loading data: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAttendance(Student student, AttendanceStatus status) async {
    try {
      final existing =
          await _db.getAttendanceByStudentAndDate(student.id, _selectedDate);

      final attendance = AttendanceModel(
        id: existing?.id ?? const Uuid().v4(),
        studentId: student.id,
        classId: widget.classId,
        date: _selectedDate,
        status: status,
        checkInTime: status == AttendanceStatus.present ? DateTime.now() : null,
        remarks: status == AttendanceStatus.late ? "Marked late" : null,
      );

      await _db.insertAttendance(attendance);
      await _loadData();

      _showMessage("${student.name} marked as ${_getStatusText(status)}",
          _getStatusColor(status));
    } catch (e) {
      _showMessage("Error marking attendance: $e", Colors.red);
    }
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.excused:
        return Colors.blue;
    }
  }

  void _showMessage(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _changeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _loadData();
    }
  }

  Future<void> _exportAttendance() async {
    if (_attendanceList.isEmpty) {
      _showMessage("No attendance data to export", Colors.orange);
      return;
    }

    final csvData = StringBuffer();
    csvData.writeln("Student ID,Student Name,Status,Time");

    for (var attendance in _attendanceList) {
      final student = _students.firstWhere(
        (s) => s.id == attendance.studentId,
        orElse: () => Student(
            id: '',
            name: 'Unknown',
            timestamp: DateTime.now(),
            status: AttendanceStatus.absent),
      );

      csvData.writeln(
        "${student.id},${student.name},${attendance.statusText},${attendance.checkInTime != null ? DateFormat('hh:mm a').format(attendance.checkInTime!) : '-'}",
      );
    }

    final bytes = Uint8List.fromList(utf8.encode(csvData.toString()));
    final fileName =
        "attendance_${DateFormat('yyyy-MM-dd').format(_selectedDate)}.csv";

    await Share.shareXFiles(
      [XFile.fromData(bytes, name: fileName, mimeType: 'text/csv')],
      text:
          "Attendance Report for ${widget.className}\nDate: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
    );

    _showMessage("Attendance exported successfully", Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.className),
            Text(
              DateFormat('dd MMM yyyy').format(_selectedDate),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _changeDate,
            tooltip: "Change Date",
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportAttendance,
            tooltip: "Export Attendance",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code), text: "Generate"),
            Tab(icon: Icon(Icons.qr_code_scanner), text: "Scan"),
            Tab(icon: Icon(Icons.list), text: "List"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                QRGeneratorScreen(
                  classId: widget.classId,
                  onStudentGenerated: (student) async {
                    await _markAttendance(student, AttendanceStatus.present);
                    _tabController.animateTo(2);
                    _showMessage(
                        "${student.name} marked present!", Colors.green);
                  },
                ),
                QRScannerScreen(
                  classId: widget.classId,
                  onStudentScanned: (student) async {
                    await _markAttendance(student, AttendanceStatus.present);
                    _tabController.animateTo(2);
                    _showMessage(
                        "${student.name} marked present!", Colors.green);
                  },
                ),
                AttendanceListScreen(
                  students: _students,
                  attendanceList: _attendanceList,
                  selectedDate: _selectedDate,
                  onMarkPresent: (student) =>
                      _markAttendance(student, AttendanceStatus.present),
                  onMarkLate: (student) =>
                      _markAttendance(student, AttendanceStatus.late),
                  onMarkAbsent: (student) =>
                      _markAttendance(student, AttendanceStatus.absent),
                  onMarkExcused: (student) =>
                      _markAttendance(student, AttendanceStatus.excused),
                  onViewProfile: (student) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentProfileScreen(
                          studentId: student.id,
                          classId: widget.classId,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStudentDialog(),
        child: const Icon(Icons.add),
        tooltip: "Add Student",
      ),
    );
  }

  void _showAddStudentDialog() {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Student"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: "Student ID *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email (Optional)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone (Optional)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (idController.text.isNotEmpty &&
                  nameController.text.isNotEmpty) {
                final newStudent = StudentModel(
                  id: const Uuid().v4(),
                  studentId: idController.text,
                  name: nameController.text,
                  email: emailController.text.isNotEmpty
                      ? emailController.text
                      : null,
                  phone: phoneController.text.isNotEmpty
                      ? phoneController.text
                      : null,
                  classId: widget.classId,
                  enrolledDate: DateTime.now(),
                  isActive: true,
                );

                await _db.insertStudent(newStudent);
                await _loadData();
                Navigator.pop(context);
                _showMessage("Student added successfully", Colors.green);
              } else {
                _showMessage("Please fill all required fields", Colors.orange);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
