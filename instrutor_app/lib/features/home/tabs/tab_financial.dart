import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/enums.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/mock/_seed.dart';
import '../../../shared/widgets/widgets.dart';

/// Aba FINANCEIRO — histórico simples no MVP (sem integração de pagamento).
/// Lista aulas concluídas, com o valor combinado.
class TabFinancial extends ConsumerWidget {
  const TabFinancial({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String userId =
        ref.read(authRepositoryProvider).currentSession?.userId ??
            MockState.currentInstructorId;
    final AsyncValue<List<Booking>> async = ref.watch(_completedProvider(userId));

    return CnhhjScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.textPrimary),
        ),
        error: (Object err, _) => Center(child: Text('Erro: $err')),
        data: (List<Booking> items) {
          final double total = items.fold<double>(
            0,
            (double sum, Booking b) => sum + (b.agreedPrice ?? 0),
          );
          return Column(
            children: <Widget>[
              CnhhjCard(
                child: Column(
                  children: <Widget>[
                    Text(
                      'Total recebido',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${total.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Pagamentos via PIX direto com aluno',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Expanded(
                  child: CnhhjEmptyState(
                    icon: Icons.payments_outlined,
                    message: 'Nenhuma aula concluída ainda.\nDepois de cada aula, ela aparece aqui.',
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext c, int i) =>
                        _Row(booking: items[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

final FutureProviderFamily<List<Booking>, String> _completedProvider =
    FutureProvider.family<List<Booking>, String>((Ref ref, String userId) {
  return ref
      .watch(bookingRepositoryProvider)
      .listByStatus(userId, BookingStatus.completed);
});

class _Row extends StatelessWidget {
  const _Row({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final String name =
        MockState.instance.profiles[booking.studentId]?.fullName ?? 'Aluno';
    final DateFormat df = DateFormat('dd/MM/yyyy', 'pt_BR');
    return CnhhjCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
          Text(
            booking.agreedPrice == null
                ? '—'
                : 'R\$ ${booking.agreedPrice!.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
