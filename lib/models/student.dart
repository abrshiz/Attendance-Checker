import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum AttendanceStatus { present, absent, late, excused }

extension AttendanceStatusExtension on AttendanceStatus {
  String get statusText {
    switch (this) {
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

  Color get statusColor {
    switch (this) {
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
}

class Student {
  final String id;
  final String name;
  final DateTime timestamp;
  final AttendanceStatus status;

  Student({
    required this.id,
    required this.name,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'timestamp': timestamp.toIso8601String(),
        'status': status.index,
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'],
        name: json['name'],
        timestamp: DateTime.parse(json['timestamp']),
        status: AttendanceStatus.values[json['status']],
      );

  String get formattedTime => DateFormat('hh:mm a').format(timestamp);
  String get formattedDate => DateFormat('yyyy-MM-dd').format(timestamp);

  bool get isPresent => status == AttendanceStatus.present;
  bool get isAbsent => status == AttendanceStatus.absent;
}
