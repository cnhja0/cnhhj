import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/weekly_availability.dart';
import '../availability_repository.dart';
import '_seed.dart';

class MockAvailabilityRepository implements AvailabilityRepository {
  @override
  Future<List<WeeklyAvailability>> listForInstructor(
    String instructorId,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return MockState.instance.availability
        .where((WeeklyAvailability a) => a.instructorId == instructorId)
        .toList(growable: false);
  }

  @override
  Future<WeeklyAvailability> create(
    String instructorId, {
    required DayOfWeek dayOfWeek,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final WeeklyAvailability slot = WeeklyAvailability(
      id: 'avail-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
      instructorId: instructorId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      createdAt: DateTime.now(),
    );
    MockState.instance.availability.add(slot);
    return slot;
  }

  @override
  Future<void> delete(String slotId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    MockState.instance.availability
        .removeWhere((WeeklyAvailability a) => a.id == slotId);
  }

  @override
  Future<void> replaceAll(
    String instructorId,
    List<WeeklyAvailability> slots,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    MockState.instance.availability
        .removeWhere((WeeklyAvailability a) => a.instructorId == instructorId);
    MockState.instance.availability.addAll(slots);
  }
}
