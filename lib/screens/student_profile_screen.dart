import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/student_model.dart';

class StudentProfileScreen extends StatefulWidget {
  final String studentId;
  final String classId;

  const StudentProfileScreen({
    super.key,
    required this.studentId,
    required this.classId,
  });

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  StudentModel? _student;
  bool _isLoading = true;
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    setState(() => _isLoading = true);
    _student = await _db.getStudentById(widget.studentId);

    if (_student != null) {
      _nameController.text = _student!.name;
      _emailController.text = _student!.email ?? '';
      _phoneController.text = _student!.phone ?? '';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name cannot be empty")),
      );
      return;
    }

    final updatedStudent = StudentModel(
      id: _student!.id,
      studentId: _student!.studentId,
      name: _nameController.text,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      classId: widget.classId,
      enrolledDate: _student!.enrolledDate,
      isActive: _student!.isActive,
    );

    await _db.updateStudent(updatedStudent);
    setState(() {
      _isEditing = false;
      _student = updatedStudent;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully")),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Profile" : "Student Profile"),
        actions: [
          if (!_isEditing && _student != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _saveChanges,
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _student == null
              ? const Center(child: Text("Student not found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Profile Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            _student!.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 48,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Student ID Card
                      Card(
                        elevation: 2,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Student Information",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              _buildInfoRow(
                                icon: Icons.badge,
                                label: "Student ID",
                                value: _student!.studentId,
                              ),
                              const SizedBox(height: 12),
                              _buildEditableRow(
                                icon: Icons.person,
                                label: "Full Name",
                                value: _student!.name,
                                controller: _nameController,
                                isEditing: _isEditing,
                              ),
                              const SizedBox(height: 12),
                              _buildEditableRow(
                                icon: Icons.email,
                                label: "Email",
                                value: _student!.email ?? "Not set",
                                controller: _emailController,
                                isEditing: _isEditing,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),
                              _buildEditableRow(
                                icon: Icons.phone,
                                label: "Phone",
                                value: _student!.phone ?? "Not set",
                                controller: _phoneController,
                                isEditing: _isEditing,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                icon: Icons.calendar_today,
                                label: "Enrolled Date",
                                value: _student!.formattedEnrolledDate,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Delete Button
                      if (!_isEditing)
                        Card(
                          color: Colors.red.shade50,
                          child: ListTile(
                            leading:
                                Icon(Icons.delete, color: Colors.red.shade700),
                            title: Text(
                              "Delete Student",
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                            subtitle: Text(
                              "Remove this student from the class",
                              style: TextStyle(color: Colors.red.shade400),
                            ),
                            onTap: () => _showDeleteConfirmation(),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableRow({
    required IconData icon,
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              isEditing
                  ? TextFormField(
                      controller: controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      keyboardType: keyboardType,
                    )
                  : Text(
                      value,
                      style: const TextStyle(fontSize: 16),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Student"),
        content: Text("Are you sure you want to delete ${_student!.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.deleteStudent(_student!.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Student deleted successfully")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
