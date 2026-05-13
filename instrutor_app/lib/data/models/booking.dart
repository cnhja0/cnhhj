import 'enums.dart';

/// Agendamento de aula entre instrutor e aluno. Espelha a tabela `bookings`.
class Booking {
  const Booking({
    required this.id,
    required this.instructorId,
    required this.studentId,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.status = BookingStatus.pending,
    this.meetingPoint,
    this.notes,
    this.agreedPrice,
    this.cancelledBy,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String instructorId;
  final String studentId;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final BookingStatus status;
  final String? meetingPoint;
  final String? notes;
  final double? agreedPrice;
  final String? cancelledBy;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking copyWith({
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    BookingStatus? status,
    String? meetingPoint,
    String? notes,
    double? agreedPrice,
    String? cancelledBy,
    String? cancellationReason,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id,
      instructorId: instructorId,
      studentId: studentId,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      status: status ?? this.status,
      meetingPoint: meetingPoint ?? this.meetingPoint,
      notes: notes ?? this.notes,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      instructorId: json['instructor_id'] as String,
      studentId: json['student_id'] as String,
      scheduledStart: DateTime.parse(json['scheduled_start'] as String),
      scheduledEnd: DateTime.parse(json['scheduled_end'] as String),
      status: BookingStatus.fromJson(json['status'] as String),
      meetingPoint: json['meeting_point'] as String?,
      notes: json['notes'] as String?,
      agreedPrice: (json['agreed_price'] as num?)?.toDouble(),
      cancelledBy: json['cancelled_by'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'instructor_id': instructorId,
        'student_id': studentId,
        'scheduled_start': scheduledStart.toIso8601String(),
        'scheduled_end': scheduledEnd.toIso8601String(),
        'status': status.toJson(),
        'meeting_point': meetingPoint,
        'notes': notes,
        'agreed_price': agreedPrice,
        'cancelled_by': cancelledBy,
        'cancellation_reason': cancellationReason,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
