import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/attendance_model.dart';

class AttendanceListScreen extends StatelessWidget {
  final List<Student> students;
  final List<AttendanceModel> attendanceList;
  final DateTime selectedDate;
  final Function(Student) onMarkPresent;
  final Function(Student) onMarkLate;
  final Function(Student) onMarkAbsent;
  final Function(Student) onMarkExcused;
  final Function(Student) onViewProfile;

  const AttendanceListScreen({
    super.key,
    required this.students,
    required this.attendanceList,
    required this.selectedDate,
    required this.onMarkPresent,
    required this.onMarkLate,
    required this.onMarkAbsent,
    required this.onMarkExcused,
    required this.onViewProfile,
  });

  AttendanceStatus? _getStudentStatus(String studentId) {
    final attendance = attendanceList.firstWhere(
      (a) => a.studentId == studentId,
      orElse: () => AttendanceModel(
        id: '',
        studentId: '',
        classId: '',
        date: selectedDate,
        status: AttendanceStatus.absent,
      ),
    );
    return attendance.status;
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = attendanceList
        .where((a) => a.status == AttendanceStatus.present)
        .length;
    final absentCount =
        attendanceList.where((a) => a.status == AttendanceStatus.absent).length;
    final lateCount =
        attendanceList.where((a) => a.status == AttendanceStatus.late).length;
    final excusedCount = attendanceList
        .where((a) => a.status == AttendanceStatus.excused)
        .length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blue.shade50,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard("Present", presentCount, Colors.green),
                const SizedBox(width: 12),
                _buildStatCard("Absent", absentCount, Colors.red),
                const SizedBox(width: 12),
                _buildStatCard("Late", lateCount, Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard("Excused", excusedCount, Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard("Total", students.length, Colors.grey),
              ],
            ),
          ),
        ),
        Expanded(
          child: students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "No students in this class",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tap + to add students",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final status = _getStudentStatus(student.id);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: status?.statusColor ?? Colors.grey,
                          child: Text(
                            student.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          student.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("ID: ${student.id}"),
                        trailing: PopupMenuButton<AttendanceStatus>(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: status?.statusColor.withOpacity(0.1) ??
                                  Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(status),
                                  size: 16,
                                  color: status?.statusColor ?? Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status?.statusText ?? "Not Marked",
                                  style: TextStyle(
                                    color: status?.statusColor ?? Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 20),
                              ],
                            ),
                          ),
                          onSelected: (newStatus) {
                            switch (newStatus) {
                              case AttendanceStatus.present:
                                onMarkPresent(student);
                                break;
                              case AttendanceStatus.late:
                                onMarkLate(student);
                                break;
                              case AttendanceStatus.absent:
                                onMarkAbsent(student);
                                break;
                              case AttendanceStatus.excused:
                                onMarkExcused(student);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: AttendanceStatus.present,
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text("Present"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: AttendanceStatus.late,
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text("Late"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: AttendanceStatus.absent,
                              child: Row(
                                children: [
                                  Icon(Icons.cancel, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text("Absent"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: AttendanceStatus.excused,
                              child: Row(
                                children: [
                                  Icon(Icons.medical_services,
                                      color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text("Excused"),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => onViewProfile(student),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            count.toString(),
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.excused:
        return Icons.medical_services;
      default:
        return Icons.help_outline;
    }
  }
}
