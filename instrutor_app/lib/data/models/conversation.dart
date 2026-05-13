/// Thread de chat entre um instrutor e um aluno (uma por par).
/// Espelha a tabela `conversations`.
class Conversation {
  const Conversation({
    required this.id,
    required this.instructorId,
    required this.studentId,
    this.lastMessageAt,
    required this.createdAt,
  });

  final String id;
  final String instructorId;
  final String studentId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      instructorId: json['instructor_id'] as String,
      studentId: json['student_id'] as String,
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.parse(json['last_message_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'instructor_id': instructorId,
        'student_id': studentId,
        'last_message_at': lastMessageAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
