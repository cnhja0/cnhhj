import 'package:flutter/material.dart';

import 'enums.dart';

/// Disponibilidade semanal recorrente do instrutor.
/// Espelha a tabela `instructor_weekly_availability`.
class WeeklyAvailability {
  const WeeklyAvailability({
    required this.id,
    required this.instructorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
  });

  final String id;
  final String instructorId;
  final DayOfWeek dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final DateTime createdAt;

  factory WeeklyAvailability.fromJson(Map<String, dynamic> json) {
    return WeeklyAvailability(
      id: json['id'] as String,
      instructorId: json['instructor_id'] as String,
      dayOfWeek: DayOfWeek.fromValue(json['day_of_week'] as int),
      startTime: _parseTime(json['start_time'] as String),
      endTime: _parseTime(json['end_time'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'instructor_id': instructorId,
        'day_of_week': dayOfWeek.value,
        'start_time': _formatTime(startTime),
        'end_time': _formatTime(endTime),
        'created_at': createdAt.toIso8601String(),
      };

  static TimeOfDay _parseTime(String hms) {
    final List<String> parts = hms.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
}
