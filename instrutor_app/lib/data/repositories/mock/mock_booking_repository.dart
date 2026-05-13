import 'dart:async';

import '../../models/booking.dart';
import '../../models/enums.dart';
import '../booking_repository.dart';
import '_seed.dart';

class MockBookingRepository implements BookingRepository {
  final StreamController<List<Booking>> _changes =
      StreamController<List<Booking>>.broadcast();

  @override
  Future<List<Booking>> listForInstructor(String instructorId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _forInstructor(instructorId);
  }

  @override
  Stream<List<Booking>> watchForInstructor(String instructorId) async* {
    yield _forInstructor(instructorId);
    yield* _changes.stream
        .map((_) => _forInstructor(instructorId))
        .asBroadcastStream();
  }

  @override
  Future<List<Booking>> listByStatus(
    String instructorId,
    BookingStatus status,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _forInstructor(instructorId)
        .where((Booking b) => b.status == status)
        .toList(growable: false);
  }

  @override
  Future<Booking> updateStatus(
    String bookingId, {
    required BookingStatus status,
    String? cancellationReason,
    String? cancelledBy,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final int idx =
        MockState.instance.bookings.indexWhere((Booking b) => b.id == bookingId);
    if (idx == -1) throw StateError('Booking não encontrada: $bookingId');
    final Booking updated = MockState.instance.bookings[idx].copyWith(
      status: status,
      cancellationReason: cancellationReason,
      cancelledBy: cancelledBy,
      updatedAt: DateTime.now(),
    );
    MockState.instance.bookings[idx] = updated;
    _changes.add(<Booking>[]); // dispara watchers
    return updated;
  }

  List<Booking> _forInstructor(String id) {
    final List<Booking> filtered = MockState.instance.bookings
        .where((Booking b) => b.instructorId == id)
        .toList()
      ..sort((Booking a, Booking b) =>
          b.scheduledStart.compareTo(a.scheduledStart));
    return filtered;
  }
}
