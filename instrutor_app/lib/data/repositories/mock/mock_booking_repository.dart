import 'dart:async';

import '../../models/app_notification.dart';
import '../../models/booking.dart';
import '../../models/enums.dart';
import '../booking_repository.dart';
import '../notification_repository.dart';
import '_seed.dart';

class MockBookingRepository implements BookingRepository {
  MockBookingRepository({this.notifications});

  /// Opcional para mantermos os testes simples. Quando provido, gera
  /// `AppNotification` em runtime nos eventos relevantes (accept, reject)
  /// para que o app não fique com badge estático.
  final NotificationRepository? notifications;

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

    final Booking current = MockState.instance.bookings[idx];

    // L4: previne overbooking. Ao confirmar, checa se já existe outra
    // booking confirmada do mesmo instrutor sobrepondo o intervalo
    // [scheduledStart, scheduledEnd). Lança erro para a UI tratar.
    if (status == BookingStatus.confirmed) {
      final List<Booking> conflicting = MockState.instance.bookings.where(
        (Booking b) =>
            b.id != bookingId &&
            b.instructorId == current.instructorId &&
            b.status == BookingStatus.confirmed &&
            b.scheduledStart.isBefore(current.scheduledEnd) &&
            b.scheduledEnd.isAfter(current.scheduledStart),
      ).toList(growable: false);
      if (conflicting.isNotEmpty) {
        throw BookingConflictException(conflicting.first);
      }
    }

    final Booking updated = current.copyWith(
      status: status,
      cancellationReason: cancellationReason,
      cancelledBy: cancelledBy,
      updatedAt: DateTime.now(),
    );
    MockState.instance.bookings[idx] = updated;
    _changes.add(<Booking>[]); // dispara watchers

    // C4 + L5: emite notificações em runtime. São side-effects — se
    // qualquer create falhar, a booking já foi salva e a UI não pode
    // ter o save desfeito por isso. Captura genericamente.
    if (notifications != null) {
      try {
        await _emitStatusNotifications(updated, status, cancellationReason);
      } catch (_) {
        // Não-fatal: log para diagnostics em produção, swallow aqui.
      }
    }

    return updated;
  }

  Future<void> _emitStatusNotifications(
    Booking updated,
    BookingStatus status,
    String? cancellationReason,
  ) async {
    final DateTime now = DateTime.now();
    switch (status) {
      case BookingStatus.confirmed:
        await notifications!.create(
          AppNotification(
            id: 'notif-${now.millisecondsSinceEpoch.toRadixString(36)}-s',
            userId: updated.studentId,
            type: NotificationType.bookingConfirmed,
            title: 'Aula confirmada',
            body: 'Sua aula foi confirmada pelo instrutor.',
            createdAt: now,
            actionRoute: '/home/agenda',
          ),
        );
        // Recibo para o instrutor (não-essencial, mas mantém o feed vivo).
        await notifications!.create(
          AppNotification(
            id: 'notif-${now.millisecondsSinceEpoch.toRadixString(36)}-i',
            userId: updated.instructorId,
            type: NotificationType.bookingConfirmed,
            title: 'Você confirmou uma aula',
            body: 'A aula foi adicionada à sua agenda.',
            createdAt: now,
            actionRoute: '/home/agenda',
          ),
        );
      case BookingStatus.cancelled:
        final String reason = cancellationReason?.trim().isNotEmpty == true
            ? '\nMotivo: $cancellationReason'
            : '';
        await notifications!.create(
          AppNotification(
            id: 'notif-${now.millisecondsSinceEpoch.toRadixString(36)}-s',
            userId: updated.studentId,
            type: NotificationType.bookingCancelled,
            title: 'Solicitação recusada',
            body: 'O instrutor não pôde aceitar a solicitação.$reason',
            createdAt: now,
          ),
        );
      case BookingStatus.completed:
        await notifications!.create(
          AppNotification(
            id: 'notif-${now.millisecondsSinceEpoch.toRadixString(36)}-s',
            userId: updated.studentId,
            type: NotificationType.review,
            title: 'Como foi sua aula?',
            body: 'Deixe sua avaliação para o instrutor.',
            createdAt: now,
            actionRoute: '/reviews',
          ),
        );
      case BookingStatus.pending:
      case BookingStatus.noShow:
        break;
    }
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

/// Lançada por [MockBookingRepository.updateStatus] quando tentamos
/// confirmar uma booking que conflitaria com outra já confirmada.
class BookingConflictException implements Exception {
  BookingConflictException(this.conflictingWith);
  final Booking conflictingWith;
  @override
  String toString() =>
      'BookingConflictException(conflicting: ${conflictingWith.id})';
}
