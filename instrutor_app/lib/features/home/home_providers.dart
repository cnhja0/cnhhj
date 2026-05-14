import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/booking.dart';
import '../../data/models/conversation.dart';
import '../../data/models/enums.dart';
import '../../data/models/instructor.dart';
import '../../data/models/profile.dart';
import '../../data/providers.dart';
import '../../data/repositories/mock/_seed.dart';

/// Providers **compartilhados** entre as abas da Home.
///
/// O objetivo é que ao mudar algo em uma aba (ex: ligar/desligar
/// "recebendo aulas" em [TabLesson]) outras abas (ex: [TabHome] mostrando
/// status ON/OFF) reflitam a mudança sem dependerem de hot-reload.
///
/// Para forçar refresh após uma mutação, chame:
/// ```dart
/// ref.invalidate(currentInstructorProvider);
/// ```

final Provider<String> currentUserIdProvider = Provider<String>((Ref ref) {
  return ref.watch(authRepositoryProvider).currentSession?.userId ??
      MockState.currentInstructorId;
});

/// Profile do usuário logado. Invalida com `ref.invalidate(currentProfileProvider)`
/// quando os dados pessoais mudam (ex: após salvar Edição de Perfil).
final FutureProvider<Profile?> currentProfileProvider =
    FutureProvider<Profile?>((Ref ref) async {
  try {
    return await ref.watch(authRepositoryProvider).currentProfile();
  } catch (_) {
    return null;
  }
});

final FutureProvider<Instructor?> currentInstructorProvider =
    FutureProvider<Instructor?>((Ref ref) {
  final String userId = ref.watch(currentUserIdProvider);
  return ref.watch(instructorRepositoryProvider).getById(userId);
});

final FutureProvider<int> pendingBookingsCountProvider =
    FutureProvider<int>((Ref ref) async {
  final String userId = ref.watch(currentUserIdProvider);
  final List<Booking> b = await ref
      .watch(bookingRepositoryProvider)
      .listByStatus(userId, BookingStatus.pending);
  return b.length;
});

final FutureProvider<int> confirmedBookingsCountProvider =
    FutureProvider<int>((Ref ref) async {
  final String userId = ref.watch(currentUserIdProvider);
  final List<Booking> b = await ref
      .watch(bookingRepositoryProvider)
      .listByStatus(userId, BookingStatus.confirmed);
  return b.length;
});

final FutureProvider<int> conversationsCountProvider =
    FutureProvider<int>((Ref ref) async {
  final String userId = ref.watch(currentUserIdProvider);
  final List<Conversation> c =
      await ref.watch(chatRepositoryProvider).listConversations(userId);
  return c.length;
});

final FutureProvider<List<Booking>> pendingBookingsProvider =
    FutureProvider<List<Booking>>((Ref ref) {
  final String userId = ref.watch(currentUserIdProvider);
  return ref
      .watch(bookingRepositoryProvider)
      .listByStatus(userId, BookingStatus.pending);
});
