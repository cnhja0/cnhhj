import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import 'repositories/auth_repository.dart';
import 'repositories/availability_repository.dart';
import 'repositories/booking_repository.dart';
import 'repositories/chat_repository.dart';
import 'repositories/instructor_repository.dart';
import 'repositories/mock/mock_auth_repository.dart';
import 'repositories/mock/mock_availability_repository.dart';
import 'repositories/mock/mock_booking_repository.dart';
import 'repositories/mock/mock_chat_repository.dart';
import 'repositories/mock/mock_instructor_repository.dart';
import 'repositories/mock/mock_notification_repository.dart';
import 'repositories/mock/mock_review_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/review_repository.dart';

/// Providers de repositórios. Cada um decide entre mock e supabase com base
/// em `Env.mode`. A implementação Supabase entra aqui no futuro.

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((Ref ref) {
  return switch (Env.mode) {
    AppMode.mock => MockAuthRepository(),
    AppMode.supabase => MockAuthRepository(), // TODO: SupabaseAuthRepository
  };
});

final Provider<InstructorRepository> instructorRepositoryProvider =
    Provider<InstructorRepository>((Ref ref) {
  return switch (Env.mode) {
    AppMode.mock => MockInstructorRepository(),
    AppMode.supabase => MockInstructorRepository(), // TODO: Supabase impl
  };
});

final Provider<AvailabilityRepository> availabilityRepositoryProvider =
    Provider<AvailabilityRepository>((Ref ref) {
  return switch (Env.mode) {
    AppMode.mock => MockAvailabilityRepository(),
    AppMode.supabase => MockAvailabilityRepository(),
  };
});

final Provider<BookingRepository> bookingRepositoryProvider =
    Provider<BookingRepository>((Ref ref) {
  return switch (Env.mode) {
    AppMode.mock => MockBookingRepository(),
    AppMode.supabase => MockBookingRepository(),
  };
});

final Provider<ChatRepository> chatRepositoryProvider =
    Provider<ChatRepository>((Ref ref) {
  return switch (Env.mode) {
    AppMode.mock => MockChatRepository(),
    AppMode.supabase => MockChatRepository(),
  };
});

final Provider<ReviewRepository> reviewRepositoryProvider =
    Provider<ReviewRepository>((Ref ref) {
  return switch (Env.mode) {
    AppMode.mock => MockReviewRepository(),
    AppMode.supabase => MockReviewRepository(),
  };
});

final Provider<NotificationRepository> notificationRepositoryProvider =
    Provider<NotificationRepository>((Ref ref) {
  return switch (Env.mode) {
    AppMode.mock => MockNotificationRepository(),
    AppMode.supabase => MockNotificationRepository(),
  };
});

/// Sessão atual (null = não autenticado). Atualiza sozinho via stream.
final StreamProvider<AuthSession?> authSessionProvider =
    StreamProvider<AuthSession?>((Ref ref) {
  final AuthRepository auth = ref.watch(authRepositoryProvider);
  return auth.watchSession();
});
