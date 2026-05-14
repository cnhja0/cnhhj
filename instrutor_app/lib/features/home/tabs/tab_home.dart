import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/instructor.dart';
import '../../../data/models/profile.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/mock/_seed.dart';
import '../../../shared/widgets/widgets.dart';
import '../home_state.dart';

/// Aba HOME — dashboard com saudação, indicadores principais e grid
/// de acesso rápido para as outras funcionalidades.
class TabHome extends ConsumerWidget {
  const TabHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String userId =
        ref.watch(authRepositoryProvider).currentSession?.userId ??
            MockState.currentInstructorId;

    final AsyncValue<Profile?> profileAsync =
        ref.watch(_currentProfileProvider);
    final AsyncValue<Instructor?> instructorAsync =
        ref.watch(_instructorProvider(userId));
    final AsyncValue<int> pendingCount =
        ref.watch(_pendingCountProvider(userId));
    final AsyncValue<int> confirmedCount =
        ref.watch(_confirmedCountProvider(userId));
    final AsyncValue<int> conversationsCount =
        ref.watch(_conversationsCountProvider(userId));

    return CnhhjScaffold(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Header(name: profileAsync.value?.fullName),
            const SizedBox(height: 18),
            _StatsRow(
              instructor: instructorAsync.value,
              confirmed: confirmedCount.value ?? 0,
            ),
            const SizedBox(height: 28),
            Text(
              'Acesso rápido',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: <Widget>[
                _HomeCard(
                  icon: Icons.school_rounded,
                  label: 'Configurar\nAula',
                  onTap: () =>
                      ref.read(tabIndexProvider.notifier).state = 1,
                ),
                _HomeCard(
                  icon: Icons.notifications_rounded,
                  label: 'Solicitações',
                  badge: pendingCount.value ?? 0,
                  onTap: () =>
                      ref.read(tabIndexProvider.notifier).state = 2,
                ),
                _HomeCard(
                  icon: Icons.calendar_today_rounded,
                  label: 'Agenda',
                  subtitle: (confirmedCount.value ?? 0) > 0
                      ? '${confirmedCount.value} aula${confirmedCount.value == 1 ? '' : 's'}'
                      : null,
                  onTap: () =>
                      ref.read(tabIndexProvider.notifier).state = 3,
                ),
                _HomeCard(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Conversas',
                  badge: conversationsCount.value ?? 0,
                  onTap: () => context.push(AppRoutes.chatList),
                ),
                _HomeCard(
                  icon: Icons.star_rounded,
                  label: 'Avaliações',
                  subtitle: instructorAsync.value != null
                      ? '★ ${instructorAsync.value!.averageRating.toStringAsFixed(1)}'
                      : null,
                  onTap: () => context.push(AppRoutes.reviewsList),
                ),
                _HomeCard(
                  icon: Icons.support_agent_rounded,
                  label: 'Suporte',
                  onTap: () => CnhhjSnack.info(context, 'Em breve.'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Providers locais ────────────────────────────────────────────────
final FutureProvider<Profile?> _currentProfileProvider =
    FutureProvider<Profile?>((Ref ref) async {
  try {
    return await ref.watch(authRepositoryProvider).currentProfile();
  } catch (_) {
    return null;
  }
});

final FutureProviderFamily<Instructor?, String> _instructorProvider =
    FutureProvider.family<Instructor?, String>((Ref ref, String userId) {
  return ref.watch(instructorRepositoryProvider).getById(userId);
});

final FutureProviderFamily<int, String> _pendingCountProvider =
    FutureProvider.family<int, String>((Ref ref, String userId) async {
  final List<Booking> b = await ref
      .watch(bookingRepositoryProvider)
      .listByStatus(userId, BookingStatus.pending);
  return b.length;
});

final FutureProviderFamily<int, String> _confirmedCountProvider =
    FutureProvider.family<int, String>((Ref ref, String userId) async {
  final List<Booking> b = await ref
      .watch(bookingRepositoryProvider)
      .listByStatus(userId, BookingStatus.confirmed);
  return b.length;
});

final FutureProviderFamily<int, String> _conversationsCountProvider =
    FutureProvider.family<int, String>((Ref ref, String userId) async {
  final List<dynamic> c =
      await ref.watch(chatRepositoryProvider).listConversations(userId);
  return c.length;
});

// ─── Header (saudação) ───────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String greeting = switch (now.hour) {
      < 12 => 'Bom dia',
      < 18 => 'Boa tarde',
      _ => 'Boa noite',
    };
    final String first = (name ?? '').split(' ').first;
    final String dateLabel = DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(now);

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$greeting${first.isEmpty ? '' : ', $first'}!',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateLabel[0].toUpperCase() + dateLabel.substring(1),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const CnhhjLogo(size: 36, iconOnly: true),
      ],
    );
  }
}

// ─── Stats Row (3 chips) ─────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({this.instructor, this.confirmed = 0});
  final Instructor? instructor;
  final int confirmed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _Stat(
            icon: Icons.star_rounded,
            label: 'Sua nota',
            value: (instructor?.averageRating ?? 0).toStringAsFixed(1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Stat(
            icon: Icons.event_available_rounded,
            label: 'Aulas',
            value: '$confirmed',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Stat(
            icon: Icons.power_rounded,
            label: 'Status',
            value: (instructor?.isActive ?? false) ? 'On' : 'Off',
            valueColor: (instructor?.isActive ?? false)
                ? AppColors.success
                : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
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
    return CnhhjCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.textPrimary),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 17,
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
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card do grid ────────────────────────────────────────────────────
class _HomeCard extends StatelessWidget {
  const _HomeCard({
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

  @override
  Widget build(BuildContext context) {
    return CnhhjCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
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
                child: Icon(icon, color: AppColors.textPrimary, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          if (badge != null && badge! > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badge',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.surface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
