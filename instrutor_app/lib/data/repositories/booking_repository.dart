import '../models/booking.dart';
import '../models/enums.dart';

abstract class BookingRepository {
  /// Lista todas as bookings do instrutor (qualquer status), ordenadas por
  /// data agendada desc.
  Future<List<Booking>> listForInstructor(String instructorId);

  /// Emite a lista atualizada sempre que houver mudança (para realtime).
  Stream<List<Booking>> watchForInstructor(String instructorId);

  /// Lista filtrada por status (ex: solicitações pendentes).
  Future<List<Booking>> listByStatus(
    String instructorId,
    BookingStatus status,
  );

  Future<Booking> updateStatus(
    String bookingId, {
    required BookingStatus status,
    String? cancellationReason,
    String? cancelledBy,
  });
}
