import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/weekly_availability.dart';

abstract class AvailabilityRepository {
  /// Lista todos os slots recorrentes do instrutor.
  Future<List<WeeklyAvailability>> listForInstructor(String instructorId);

  /// Cria um novo slot recorrente (dia da semana + intervalo).
  Future<WeeklyAvailability> create(
    String instructorId, {
    required DayOfWeek dayOfWeek,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  });

  Future<void> delete(String slotId);

  /// Substitui toda a grade recorrente do instrutor por uma nova.
  /// Útil para a tela "Configurar aula" onde o usuário define tudo de uma vez.
  Future<void> replaceAll(
    String instructorId,
    List<WeeklyAvailability> slots,
  );
}
