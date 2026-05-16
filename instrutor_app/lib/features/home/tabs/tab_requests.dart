import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';



import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/profile.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/mock/_seed.dart';
import '../../../data/repositories/mock/mock_booking_repository.dart';
import '../../../shared/widgets/widgets.dart';
import '../home_providers.dart';

/// Aba SOLICITAÇÕES — bookings com status `pending` para o instrutor
/// confirmar ou recusar.
class TabRequests extends ConsumerWidget {
  const TabRequests({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // L6: usa o provider compartilhado de home_providers para que a aba
    // Home, a aba Solicitações e o badge do bottom nav fiquem em sync.
    // (Existia um provider local duplicado aqui — removido.)
    final AsyncValue<List<Booking>> async =
        ref.watch(pendingBookingsProvider);

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

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.booking});
  final Booking booking;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  // Guarda contra double-tap. Sem isso, o usuário pode tocar duas vezes
  // antes do refresh do provider e disparar duas mutações + duas notifs.
  bool _busy = false;

  Booking get booking => widget.booking;

  Future<void> _respond(BookingStatus status) async {
    if (_busy) return;
    String? reason;
    if (status == BookingStatus.cancelled) {
      // L5: pede motivo opcional antes de recusar. Mesmo vazio, o aluno
      // recebe notificação genérica — o motivo é incluído quando dado.
      reason = await _askRejectionReason(context);
      if (reason == null) return; // user cancelou o sheet
    }
    setState(() => _busy = true);
    try {
      await ref.read(bookingRepositoryProvider).updateStatus(
            booking.id,
            status: status,
            cancellationReason: reason?.isEmpty == true ? null : reason,
            cancelledBy: status == BookingStatus.cancelled
                ? booking.instructorId
                : null,
          );
    } on BookingConflictException catch (e) {
      // L4: já existe outra confirmada no mesmo horário. Bloqueia e
      // informa qual é o conflito.
      if (!mounted) return;
      final DateFormat conflictDf =
          DateFormat('dd/MM \'às\' HH:mm', 'pt_BR');
      CnhhjSnack.error(
        context,
        'Conflito: já há aula confirmada em '
        '${conflictDf.format(e.conflictingWith.scheduledStart)}.',
      );
      setState(() => _busy = false);
      return;
    } catch (_) {
      if (!mounted) return;
      CnhhjSnack.error(context, 'Erro ao processar. Tente novamente.');
      setState(() => _busy = false);
      return;
    }
    // Os providers compartilhados se atualizam sozinhos via stream, mas
    // forçamos refresh dos contadores que são FutureProviders (não Stream).
    ref.invalidate(pendingBookingsProvider);
    ref.invalidate(pendingBookingsCountProvider);
    ref.invalidate(confirmedBookingsCountProvider);
    if (!mounted) return;
    if (status == BookingStatus.confirmed) {
      CnhhjSnack.success(context, 'Aula confirmada!');
    } else {
      CnhhjSnack.info(context, 'Solicitação recusada.');
    }
    // Após o invalidate, este card vai sair da lista — não precisa
    // resetar _busy.
  }

  @override
  Widget build(BuildContext context) {
    final Profile? student = MockState.instance.profiles[booking.studentId];
    final DateFormat df = DateFormat('EEE, dd/MM \'às\' HH:mm', 'pt_BR');

    return CnhhjCard(
      // Toque no card abre o perfil do aluno com o bookingId em context
      // — assim a tela do perfil mostra Aceitar/Recusar no rodapé.
      // Os botões dentro do card consomem o próprio tap antes de propagar.
      onTap: _busy
          ? null
          : () => context.push(
                '/students/${booking.studentId}?bookingId=${booking.id}',
              ),
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
                  onPressed: _busy
                      ? null
                      : () => _respond(BookingStatus.cancelled),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CnhhjPrimaryButton(
                  label: 'Aceitar',
                  icon: PhosphorIconsRegular.check,
                  onPressed: _busy
                      ? null
                      : () => _respond(BookingStatus.confirmed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet que coleta o motivo opcional de recusa. Retorna:
///   • `null` se o usuário cancelar (não recusa);
///   • `''` se confirmar sem motivo;
///   • texto preenchido caso justifique.
Future<String?> _askRejectionReason(BuildContext context) {
  final TextEditingController controller = TextEditingController();
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Recusar solicitação',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Conte (opcional) o motivo para que o aluno entenda.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Ex: horário indisponível, fora da minha região...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.primary.withOpacity(0.08),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: CnhhjSecondaryButton(
                    label: 'Voltar',
                    onPressed: () => Navigator.of(ctx).pop(null),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CnhhjPrimaryButton(
                    label: 'Recusar',
                    icon: PhosphorIconsRegular.x,
                    onPressed: () =>
                        Navigator.of(ctx).pop(controller.text.trim()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
