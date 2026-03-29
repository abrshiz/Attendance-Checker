import 'package:flutter/material.dart';
import 'student.dart';

class AttendanceModel {
  final String id;
  final String studentId;
  final String classId;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? remarks;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'classId': classId,
      'date': date.toIso8601String(),
      'status': status.index,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'remarks': remarks,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'],
      studentId: map['studentId'],
      classId: map['classId'],
      date: DateTime.parse(map['date']),
      status: AttendanceStatus.values[map['status']],
      checkInTime: map['checkInTime'] != null
          ? DateTime.parse(map['checkInTime'])
          : null,
      checkOutTime: map['checkOutTime'] != null
          ? DateTime.parse(map['checkOutTime'])
          : null,
      remarks: map['remarks'],
    );
  }

  String get statusText => status.statusText;
  Color get statusColor => status.statusColor;
}
