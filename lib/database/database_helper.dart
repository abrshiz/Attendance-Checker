import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;
  static bool _initialized = false;

  // Initialize FFI for desktop platforms
  static void init() {
    if (!_initialized) {
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        // Initialize FFI for desktop
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        print('FFI database factory initialized for desktop');
      }
      _initialized = true;
    }
  }

  Future<Database> get database async {
    init(); // Ensure FFI is initialized
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'attendance_app.db');
      print('Database path: $path');

      // Delete existing database if there are issues (optional - remove if you want to keep data)
      // await deleteDatabase(path);

      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          print('Creating database tables...');

          // Create classes table
          await db.execute('''
            CREATE TABLE classes(
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              section TEXT,
              subject TEXT,
              createdAt TEXT NOT NULL
            )
          ''');

          // Create students table
          await db.execute('''
            CREATE TABLE students(
              id TEXT PRIMARY KEY,
              studentId TEXT NOT NULL,
              name TEXT NOT NULL,
              email TEXT,
              phone TEXT,
              photoPath TEXT,
              classId TEXT NOT NULL,
              enrolledDate TEXT NOT NULL,
              isActive INTEGER DEFAULT 1
            )
          ''');

          // Create attendance table
          await db.execute('''
            CREATE TABLE attendance(
              id TEXT PRIMARY KEY,
              studentId TEXT NOT NULL,
              classId TEXT NOT NULL,
              date TEXT NOT NULL,
              status INTEGER NOT NULL,
              checkInTime TEXT,
              checkOutTime TEXT,
              remarks TEXT
            )
          ''');

          print('Database tables created successfully');

          // Insert a test class to verify
          await db.insert('classes', {
            'id': 'test123',
            'name': 'Test Class',
            'section': 'Test Section',
            'subject': 'Test Subject',
            'createdAt': DateTime.now().toIso8601String(),
          });
          print('Test class inserted');
        },
        onOpen: (db) {
          print('Database opened successfully');
        },
      );

      return db;
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  // Class CRUD
  Future<void> insertClass(ClassModel classModel) async {
    try {
      final db = await database;
      await db.insert(
        'classes',
        classModel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Class inserted: ${classModel.name}');
    } catch (e) {
      print('Error inserting class: $e');
      throw e;
    }
  }

  Future<List<ClassModel>> getAllClasses() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'classes',
        orderBy: 'createdAt DESC',
      );
      print('Found ${maps.length} classes');
      return List.generate(maps.length, (i) => ClassModel.fromMap(maps[i]));
    } catch (e) {
      print('Error getting classes: $e');
      return [];
    }
  }

  Future<void> deleteClass(String id) async {
    try {
      final db = await database;
      await db.delete('classes', where: 'id = ?', whereArgs: [id]);
      await db.delete('students', where: 'classId = ?', whereArgs: [id]);
      await db.delete('attendance', where: 'classId = ?', whereArgs: [id]);
      print('Class deleted: $id');
    } catch (e) {
      print('Error deleting class: $e');
    }
  }

  // Student CRUD
  Future<void> insertStudent(StudentModel student) async {
    try {
      final db = await database;
      await db.insert('students', student.toMap());
      print('Student inserted: ${student.name}');
    } catch (e) {
      print('Error inserting student: $e');
      throw e;
    }
  }

  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'students',
        where: 'classId = ? AND isActive = 1',
        whereArgs: [classId],
        orderBy: 'name ASC',
      );
      print('Found ${maps.length} students in class $classId');
      return List.generate(maps.length, (i) => StudentModel.fromMap(maps[i]));
    } catch (e) {
      print('Error getting students: $e');
      return [];
    }
  }

  Future<StudentModel?> getStudentById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'students',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return StudentModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting student: $e');
      return null;
    }
  }

  Future<void> updateStudent(StudentModel student) async {
    try {
      final db = await database;
      await db.update(
        'students',
        student.toMap(),
        where: 'id = ?',
        whereArgs: [student.id],
      );
      print('Student updated: ${student.name}');
    } catch (e) {
      print('Error updating student: $e');
      throw e;
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      final db = await database;
      await db.delete('students', where: 'id = ?', whereArgs: [id]);
      await db.delete('attendance', where: 'studentId = ?', whereArgs: [id]);
      print('Student deleted: $id');
    } catch (e) {
      print('Error deleting student: $e');
    }
  }

  // Attendance CRUD
  Future<void> insertAttendance(AttendanceModel attendance) async {
    try {
      final db = await database;
      await db.insert('attendance', attendance.toMap());
      print('Attendance inserted for student: ${attendance.studentId}');
    } catch (e) {
      print('Error inserting attendance: $e');
      throw e;
    }
  }

  Future<List<AttendanceModel>> getAttendanceByClassAndDate(
      String classId, DateTime date) async {
    try {
      final db = await database;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final List<Map<String, dynamic>> maps = await db.query(
        'attendance',
        where: 'classId = ? AND date >= ? AND date < ?',
        whereArgs: [
          classId,
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String()
        ],
      );
      return List.generate(
          maps.length, (i) => AttendanceModel.fromMap(maps[i]));
    } catch (e) {
      print('Error getting attendance: $e');
      return [];
    }
  }

  Future<AttendanceModel?> getAttendanceByStudentAndDate(
      String studentId, DateTime date) async {
    try {
      final db = await database;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final List<Map<String, dynamic>> maps = await db.query(
        'attendance',
        where: 'studentId = ? AND date >= ? AND date < ?',
        whereArgs: [
          studentId,
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String()
        ],
      );
      if (maps.isNotEmpty) {
        return AttendanceModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting attendance: $e');
      return null;
    }
  }
}
