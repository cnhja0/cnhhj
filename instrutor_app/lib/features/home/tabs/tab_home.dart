import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/instructor.dart';
import '../../../data/models/profile.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/widgets.dart';
import '../home_providers.dart';
import '../home_state.dart';
import '../widgets/home_banner.dart';

/// Aba HOME — dashboard com saudação, indicadores principais e grid
/// de acesso rápido para as outras funcionalidades.
///
/// Lê todos os indicadores dos providers compartilhados em
/// [home_providers.dart] — quando outra aba invalida um deles
/// (ex: TabLesson após salvar), esta tela se atualiza automaticamente.
class TabHome extends ConsumerWidget {
  const TabHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Profile?> profileAsync =
        ref.watch(_currentProfileProvider);
    final AsyncValue<Instructor?> instructorAsync =
        ref.watch(currentInstructorProvider);
    final AsyncValue<int> pendingCount =
        ref.watch(pendingBookingsCountProvider);
    final AsyncValue<int> confirmedCount =
        ref.watch(confirmedBookingsCountProvider);
    final AsyncValue<int> conversationsCount =
        ref.watch(conversationsCountProvider);

    final DateTime now = DateTime.now();
    final String greeting = switch (now.hour) {
      < 12 => 'Bom dia',
      < 18 => 'Boa tarde',
      _ => 'Boa noite',
    };
    final String first = (profileAsync.value?.fullName ?? '').split(' ').first;
    final String dateLabel =
        DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(now);

    final List<_QuickAction> actions = <_QuickAction>[
      _QuickAction(
        icon: PhosphorIconsDuotone.steeringWheel,
        label: 'Configurar aula',
        onTap: () => ref.read(tabIndexProvider.notifier).state = 1,
      ),
      _QuickAction(
        icon: PhosphorIconsDuotone.tray,
        label: 'Solicitações',
        badge: pendingCount.value ?? 0,
        onTap: () => ref.read(tabIndexProvider.notifier).state = 2,
      ),
      _QuickAction(
        icon: PhosphorIconsDuotone.calendarDots,
        label: 'Agenda',
        subtitle: (confirmedCount.value ?? 0) > 0
            ? '${confirmedCount.value} aula${confirmedCount.value == 1 ? '' : 's'}'
            : null,
        onTap: () => ref.read(tabIndexProvider.notifier).state = 3,
      ),
      _QuickAction(
        icon: PhosphorIconsDuotone.chatCircleDots,
        label: 'Conversas',
        badge: conversationsCount.value ?? 0,
        onTap: () => context.push(AppRoutes.chatList),
      ),
      _QuickAction(
        icon: PhosphorIconsDuotone.star,
        label: 'Avaliações',
        subtitle: instructorAsync.value != null
            ? '★ ${instructorAsync.value!.averageRating.toStringAsFixed(1)}'
            : null,
        onTap: () => context.push(AppRoutes.reviewsList),
      ),
      _QuickAction(
        icon: PhosphorIconsDuotone.headset,
        label: 'Suporte',
        onTap: () => CnhhjSnack.info(context, 'Em breve.'),
      ),
    ];

    return CnhhjScaffold(
      // Padding bottom pequeno — gap mínimo entre conteúdo e navbar.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TabHeader(
              title: '$greeting${first.isEmpty ? '' : ', $first'}!',
              subtitle:
                  dateLabel[0].toUpperCase() + dateLabel.substring(1),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 14),
            const HomeBanner()
                .animate()
                .fadeIn(delay: 80.ms, duration: 350.ms)
                .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 14),
            _StatsCard(
              instructor: instructorAsync.value,
              confirmed: confirmedCount.value ?? 0,
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 350.ms)
                .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              // 1.3 deixa cards mais 'achatados' — 3 fileiras cabem
              // confortavelmente acima do bottom nav em telas pequenas.
              childAspectRatio: 1.3,
              children: <Widget>[
                for (int i = 0; i < actions.length; i++)
                  _HomeCard(action: actions[i])
                      .animate()
                      .fadeIn(
                        delay: (200 + i * 70).ms,
                        duration: 350.ms,
                      )
                      .slideY(
                        begin: 0.12,
                        end: 0,
                        curve: Curves.easeOutCubic,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    this.subtitle,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final int? badge;
  final VoidCallback? onTap;
}

// Profile provider local (não compartilhado, já está em home_providers o
// resto). Mantido aqui pois só TabHome consome.
final FutureProvider<Profile?> _currentProfileProvider =
    FutureProvider<Profile?>((Ref ref) async {
  try {
    return await ref.watch(authRepositoryProvider).currentProfile();
  } catch (_) {
    return null;
  }
});

// ─── Card único de stats (3 chips horizontais com divisores) ─────────
class _StatsCard extends StatelessWidget {
  const _StatsCard({this.instructor, this.confirmed = 0});
  final Instructor? instructor;
  final int confirmed;

  @override
  Widget build(BuildContext context) {
    final bool isActive = instructor?.isActive ?? false;
    return CnhhjCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      border: Border.all(color: AppColors.textPrimary, width: 1.5),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _StatChip(
              icon: PhosphorIconsDuotone.star,
              label: 'Nota',
              value: (instructor?.averageRating ?? 0).toStringAsFixed(1),
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _StatChip(
              icon: PhosphorIconsDuotone.calendarCheck,
              label: 'Aulas',
              value: '$confirmed',
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _StatChip(
              icon: isActive
                  ? PhosphorIconsFill.circle
                  : PhosphorIconsRegular.circle,
              label: 'Status',
              value: isActive ? 'On' : 'Off',
              valueColor:
                  isActive ? AppColors.success : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: AppColors.divider);
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Icon(icon, size: 18, color: valueColor ?? AppColors.textPrimary),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: valueColor ?? AppColors.textPrimary,
            height: 1.1,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Card do grid (com BORDA PRETA pra quebrar o amarelo) ────────────
class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return CnhhjCard(
      padding: const EdgeInsets.all(14),
      onTap: action.onTap,
      border: Border.all(color: AppColors.textPrimary, width: 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action.icon,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      height: 1.1,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (action.subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (action.badge != null && action.badge! > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${action.badge}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.surface,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
