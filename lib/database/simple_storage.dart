import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';

class SimpleStorage {
  static final SimpleStorage _instance = SimpleStorage._internal();
  factory SimpleStorage() => _instance;
  SimpleStorage._internal();

  List<ClassModel> _classes = [];
  List<StudentModel> _students = [];
  List<AttendanceModel> _attendance = [];

  // Class methods
  Future<void> insertClass(ClassModel classModel) async {
    _classes.add(classModel);
    print('Class added: ${classModel.name}');
  }

  Future<List<ClassModel>> getAllClasses() async {
    return _classes;
  }

  Future<void> deleteClass(String id) async {
    _classes.removeWhere((c) => c.id == id);
    _students.removeWhere((s) => s.classId == id);
    _attendance.removeWhere((a) => a.classId == id);
  }

  // Student methods
  Future<void> insertStudent(StudentModel student) async {
    _students.add(student);
    print('Student added: ${student.name} with username: ${student.username}');
  }

  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    if (classId == 'all') {
      return _students.where((s) => s.isActive).toList();
    }
    return _students.where((s) => s.classId == classId && s.isActive).toList();
  }

  Future<StudentModel?> getStudentById(String id) async {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<StudentModel?> getStudentByUsername(String username) async {
    try {
      return _students.firstWhere((s) => s.username == username);
    } catch (e) {
      return null;
    }
  }

  Future<StudentModel?> authenticateStudent(
      String username, String password) async {
    try {
      return _students.firstWhere(
        (s) => s.username == username && s.password == password && s.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> updateStudent(StudentModel student) async {
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      _students[index] = student;
    }
  }

  Future<void> deleteStudent(String id) async {
    _students.removeWhere((s) => s.id == id);
    _attendance.removeWhere((a) => a.studentId == id);
  }

  // Attendance methods
  Future<void> insertAttendance(AttendanceModel attendance) async {
    final index = _attendance.indexWhere((a) =>
        a.studentId == attendance.studentId &&
        a.date.year == attendance.date.year &&
        a.date.month == attendance.date.month &&
        a.date.day == attendance.date.day);
    if (index != -1) {
      _attendance[index] = attendance;
    } else {
      _attendance.add(attendance);
    }
  }

  Future<List<AttendanceModel>> getAttendanceByClassAndDate(
      String classId, DateTime date) async {
    return _attendance
        .where((a) =>
            a.classId == classId &&
            a.date.year == date.year &&
            a.date.month == date.month &&
            a.date.day == date.day)
        .toList();
  }

  Future<List<AttendanceModel>> getAttendanceByStudent(String studentId) async {
    return _attendance
        .where((a) => a.studentId == studentId)
        .toList()
        .reversed
        .toList();
  }

  Future<AttendanceModel?> getAttendanceByStudentAndDate(
      String studentId, DateTime date) async {
    try {
      return _attendance.firstWhere((a) =>
          a.studentId == studentId &&
          a.date.year == date.year &&
          a.date.month == date.month &&
          a.date.day == date.day);
    } catch (e) {
      return null;
    }
  }

  // Teacher authentication (simple for demo)
  bool authenticateTeacher(String username, String password) {
    return username == 'teacher' && password == 'teacher123';
  }
}
