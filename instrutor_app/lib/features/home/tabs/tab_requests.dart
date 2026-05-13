import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/profile.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/mock/_seed.dart';
import '../../../shared/widgets/widgets.dart';

/// Aba SOLICITAÇÕES — bookings com status `pending` para o instrutor
/// confirmar ou recusar.
class TabRequests extends ConsumerWidget {
  const TabRequests({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String userId = ref.read(authRepositoryProvider).currentSession?.userId ??
        MockState.currentInstructorId;
    final AsyncValue<List<Booking>> async = ref.watch(_pendingBookingsProvider(userId));

    return CnhhjScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.textPrimary),
        ),
        error: (Object err, _) => Center(
          child: Text('Erro: $err'),
        ),
        data: (List<Booking> items) {
          if (items.isEmpty) {
            return const CnhhjEmptyState(
              icon: Icons.notifications_none,
              message: 'Nenhuma solicitação pendente.\nQuando alunos pedirem aulas, elas aparecem aqui.',
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (BuildContext ctx, int i) =>
                _RequestCard(booking: items[i]),
          );
        },
      ),
    );
  }
}

final FutureProviderFamily<List<Booking>, String> _pendingBookingsProvider =
    FutureProvider.family<List<Booking>, String>((Ref ref, String userId) {
  return ref
      .watch(bookingRepositoryProvider)
      .listByStatus(userId, BookingStatus.pending);
});

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Profile? student = MockState.instance.profiles[booking.studentId];
    final DateFormat df = DateFormat('EEE, dd/MM HH:mm', 'pt_BR');

    Future<void> respond(BookingStatus status) async {
      await ref.read(bookingRepositoryProvider).updateStatus(
            booking.id,
            status: status,
            cancelledBy: status == BookingStatus.cancelled
                ? booking.instructorId
                : null,
          );
      // Invalida o provider para refrescar a lista.
      ref.invalidate(_pendingBookingsProvider);
      if (!context.mounted) return;
      CnhhjSnack.success(
        context,
        status == BookingStatus.confirmed
            ? 'Aula confirmada!'
            : 'Solicitação recusada.',
      );
    }

    return CnhhjCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              CnhhjAvatar(size: 44, fullName: student?.fullName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      student?.fullName ?? 'Aluno',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      df.format(booking.scheduledStart),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (booking.agreedPrice != null)
                Text(
                  'R\$ ${booking.agreedPrice!.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (booking.meetingPoint != null) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const Icon(Icons.place_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.meetingPoint!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: CnhhjSecondaryButton(
                  label: 'Recusar',
                  onPressed: () => respond(BookingStatus.cancelled),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CnhhjPrimaryButton(
                  label: 'Aceitar',
                  onPressed: () => respond(BookingStatus.confirmed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
