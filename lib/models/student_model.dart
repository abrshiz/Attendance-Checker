import 'package:intl/intl.dart';

class StudentModel {
  final String id;
  final String studentId;
  final String name;
  final String? email;
  final String? phone;
  final String? photoPath;
  final String classId;
  final DateTime enrolledDate;
  final bool isActive;

  StudentModel({
    required this.id,
    required this.studentId,
    required this.name,
    this.email,
    this.phone,
    this.photoPath,
    required this.classId,
    required this.enrolledDate,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'name': name,
      'email': email,
      'phone': phone,
      'photoPath': photoPath,
      'classId': classId,
      'enrolledDate': enrolledDate.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'],
      studentId: map['studentId'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      photoPath: map['photoPath'],
      classId: map['classId'],
      enrolledDate: DateTime.parse(map['enrolledDate']),
      isActive: map['isActive'] == 1,
    );
  }

  String get formattedEnrolledDate =>
      DateFormat('dd MMM yyyy').format(enrolledDate);
}
