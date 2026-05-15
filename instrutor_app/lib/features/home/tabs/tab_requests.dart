import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/profile.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/mock/_seed.dart';
import '../../../shared/widgets/widgets.dart';
import '../home_providers.dart';

/// Aba SOLICITAÇÕES — bookings com status `pending` para o instrutor
/// confirmar ou recusar.
class TabRequests extends ConsumerWidget {
  const TabRequests({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String userId =
        ref.read(authRepositoryProvider).currentSession?.userId ??
            MockState.currentInstructorId;
    final AsyncValue<List<Booking>> async =
        ref.watch(_pendingBookingsProvider(userId));

    return CnhhjScaffold(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TabHeader(
            title: 'Solicitações',
            subtitle: async.value == null
                ? null
                : '${async.value!.length} ${async.value!.length == 1 ? 'pendente' : 'pendentes'}',
          ),
          const SizedBox(height: 14),
          Expanded(
            child: async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.textPrimary),
              ),
              error: (Object err, _) => Center(child: Text('Erro: $err')),
              data: (List<Booking> items) {
                if (items.isEmpty) {
                  return const CnhhjEmptyState(
                    icon: PhosphorIconsDuotone.tray,
                    message:
                        'Nenhuma solicitação pendente.\nQuando alunos pedirem aulas, elas aparecem aqui.',
                  );
                }
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext ctx, int i) {
                    return _RequestCard(booking: items[i])
                        .animate()
                        .fadeIn(delay: (i * 80).ms, duration: 350.ms)
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        );
                  },
                );
              },
            ),
          ),
        ],
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
    final DateFormat df = DateFormat('EEE, dd/MM \'às\' HH:mm', 'pt_BR');

    Future<void> respond(BookingStatus status) async {
      await ref.read(bookingRepositoryProvider).updateStatus(
            booking.id,
            status: status,
            cancelledBy: status == BookingStatus.cancelled
                ? booking.instructorId
                : null,
          );
      // Invalida providers locais + da Home para que badges/contadores
      // atualizem em todas as telas.
      ref.invalidate(_pendingBookingsProvider);
      ref.invalidate(pendingBookingsCountProvider);
      ref.invalidate(confirmedBookingsCountProvider);
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
              CnhhjAvatar(size: 48, fullName: student?.fullName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      student?.fullName ?? 'Aluno',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        const Icon(
                          PhosphorIconsRegular.clock,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          df.format(booking.scheduledStart),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (booking.agreedPrice != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'R\$ ${booking.agreedPrice!.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
          if (booking.meetingPoint != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceOverlay,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    PhosphorIconsDuotone.mapPin,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.meetingPoint!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: CnhhjSecondaryButton(
                  label: 'Recusar',
                  icon: PhosphorIconsRegular.x,
                  onPressed: () => respond(BookingStatus.cancelled),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CnhhjPrimaryButton(
                  label: 'Aceitar',
                  icon: PhosphorIconsRegular.check,
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
