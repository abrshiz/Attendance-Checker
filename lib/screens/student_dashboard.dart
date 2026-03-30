import 'package:flutter/material.dart';
import 'package:qr_app/models/student.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../database/simple_storage.dart';
import '../models/attendance_model.dart';
import '../models/student_model.dart';

class StudentDashboard extends StatefulWidget {
  final String studentId;
  final String studentName;
  final StudentModel studentObject;

  const StudentDashboard({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentObject,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final SimpleStorage _storage = SimpleStorage();
  List<AttendanceModel> _attendanceHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Get attendance history for this student
    _attendanceHistory =
        await _storage.getAttendanceByStudent(widget.studentObject.id);

    setState(() => _isLoading = false);
  }

  String _getQRData() {
    // This QR data matches what the teacher generates
    return jsonEncode({
      'studentId': widget.studentId,
      'name': widget.studentName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My QR Code"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceHistoryScreen(
                    attendanceHistory: _attendanceHistory,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Student Info Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.green.shade100,
                            child: Text(
                              widget.studentName[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 36,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.studentName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "ID: ${widget.studentId}",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          if (widget.studentObject.email != null)
                            Text(
                              widget.studentObject.email!,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // QR Code Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            "My Personal QR Code",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Show this to your teacher to mark attendance",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: _getQRData(),
                              size: 250,
                              eyeStyle: QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Colors.green.shade700,
                              ),
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                "Teacher will scan this QR code",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick Stats Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            "This Month Summary",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildQuickStats(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Recent Attendance Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            "Recent Activity",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _attendanceHistory.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text("No attendance records yet"),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _attendanceHistory.length > 5
                                      ? 5
                                      : _attendanceHistory.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(),
                                  itemBuilder: (context, index) {
                                    final record = _attendanceHistory[index];
                                    return ListTile(
                                      leading: Icon(
                                        record.status ==
                                                AttendanceStatus.present
                                            ? Icons.check_circle
                                            : record.status ==
                                                    AttendanceStatus.late
                                                ? Icons.access_time
                                                : Icons.cancel,
                                        color: record.statusColor,
                                      ),
                                      title: Text(
                                        DateFormat('EEEE, MMM d, yyyy')
                                            .format(record.date),
                                      ),
                                      subtitle: Text(
                                        record.checkInTime != null
                                            ? "Check-in: ${DateFormat('hh:mm a').format(record.checkInTime!)}"
                                            : "Not checked in",
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: record.statusColor
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          record.statusText,
                                          style: TextStyle(
                                            color: record.statusColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          if (_attendanceHistory.length > 5)
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AttendanceHistoryScreen(
                                      attendanceHistory: _attendanceHistory,
                                    ),
                                  ),
                                );
                              },
                              child: const Text("View All"),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickStats() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    final thisMonthAttendance = _attendanceHistory
        .where((a) =>
            a.date.isAfter(firstDayOfMonth) && a.date.isBefore(lastDayOfMonth))
        .toList();

    final total = thisMonthAttendance.length;
    final present = thisMonthAttendance
        .where((a) => a.status == AttendanceStatus.present)
        .length;
    final late = thisMonthAttendance
        .where((a) => a.status == AttendanceStatus.late)
        .length;
    final absent = thisMonthAttendance
        .where((a) => a.status == AttendanceStatus.absent)
        .length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem("Present", present, Colors.green),
        _buildStatItem("Late", late, Colors.orange),
        _buildStatItem("Absent", absent, Colors.red),
        _buildStatItem("Total", total, Colors.blue),
      ],
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

// Attendance History Screen
class AttendanceHistoryScreen extends StatelessWidget {
  final List<AttendanceModel> attendanceHistory;

  const AttendanceHistoryScreen({super.key, required this.attendanceHistory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance History"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: attendanceHistory.isEmpty
          ? const Center(child: Text("No attendance records found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: attendanceHistory.length,
              itemBuilder: (context, index) {
                final record = attendanceHistory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: record.statusColor.withOpacity(0.2),
                      child: Icon(
                        record.status == AttendanceStatus.present
                            ? Icons.check
                            : record.status == AttendanceStatus.late
                                ? Icons.access_time
                                : Icons.close,
                        color: record.statusColor,
                      ),
                    ),
                    title: Text(
                      DateFormat('EEEE, MMM d, yyyy').format(record.date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Status: ${record.statusText}"),
                        if (record.checkInTime != null)
                          Text(
                              "Time: ${DateFormat('hh:mm a').format(record.checkInTime!)}"),
                        if (record.remarks != null)
                          Text("Note: ${record.remarks!}",
                              style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: record.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        record.statusText,
                        style: TextStyle(
                          color: record.statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
