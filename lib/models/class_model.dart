class ClassModel {
  final String id;
  final String name;
  final String section;
  final String subject;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.name,
    required this.section,
    required this.subject,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'section': section,
      'subject': subject,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'],
      name: map['name'],
      section: map['section'] ?? '',
      subject: map['subject'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
