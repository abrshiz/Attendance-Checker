class UserModel {
  final String id;
  final String username;
  final String password;
  final UserRole role;
  final String? studentId; // For student role, link to student
  final String? teacherId; // For teacher role
  final String name;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    this.studentId,
    this.teacherId,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role.index,
      'studentId': studentId,
      'teacherId': teacherId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      role: UserRole.values[map['role']],
      studentId: map['studentId'],
      teacherId: map['teacherId'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

enum UserRole { teacher, student }
