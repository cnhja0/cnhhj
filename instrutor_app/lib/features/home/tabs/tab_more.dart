import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/profile.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/widgets.dart';
import '../home_providers.dart';

/// Aba MAIS — menu com Perfil, Conversas, Avaliações, Guia, Suporte, Sair.
class TabMore extends ConsumerWidget {
  const TabMore({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> logout() async {
      await ref.read(authRepositoryProvider).signOut();
      if (!context.mounted) return;
      context.go(AppRoutes.login);
    }

    final List<_MenuEntry> entries = <_MenuEntry>[
      _MenuEntry(
        icon: PhosphorIconsDuotone.userCircle,
        label: 'Perfil',
        onTap: () => context.push(AppRoutes.profileEdit),
      ),
      _MenuEntry(
        icon: PhosphorIconsDuotone.chatCircleDots,
        label: 'Conversas',
        onTap: () => context.push(AppRoutes.chatList),
      ),
      _MenuEntry(
        icon: PhosphorIconsDuotone.star,
        label: 'Avaliações recebidas',
        onTap: () => context.push(AppRoutes.reviewsList),
      ),
      _MenuEntry(
        icon: PhosphorIconsDuotone.steps,
        label: 'Passo a passo',
        onTap: () {},
      ),
      _MenuEntry(
        icon: PhosphorIconsDuotone.bookOpen,
        label: 'Guia',
        onTap: () {},
      ),
      _MenuEntry(
        icon: PhosphorIconsDuotone.headset,
        label: 'Suporte',
        onTap: () {},
      ),
    ];

    return CnhhjScaffold(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          const TabHeader(
            title: 'Mais',
            subtitle: 'Configurações, suporte e ajuda',
          ),
          const SizedBox(height: 14),
          const _UserHeader()
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 16),
          CnhhjCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < entries.length; i++) ...<Widget>[
                  if (i > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  _Item(entry: entries[i])
                      .animate()
                      .fadeIn(delay: (150 + i * 50).ms, duration: 300.ms),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          CnhhjCard(
            padding: EdgeInsets.zero,
            child: _Item(
              entry: _MenuEntry(
                icon: PhosphorIconsDuotone.signOut,
                label: 'Sair',
                onTap: logout,
                destructive: true,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 500.ms, duration: 300.ms),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'CNHhj • versão 0.1.0',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuEntry {
  const _MenuEntry({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

class _UserHeader extends ConsumerWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usa o provider compartilhado — quando profile_edit invalida,
    // este card também se atualiza com nome/foto novos.
    final AsyncValue<Profile?> profileAsync =
        ref.watch(currentProfileProvider);
    final Profile? profile = profileAsync.value;
    final String name = profile?.fullName ?? 'Instrutor';
    return CnhhjCard(
      onTap: () => context.push(AppRoutes.profileEdit),
      child: Row(
        children: <Widget>[
          CnhhjAvatar(
            size: 60,
            fullName: name,
            imageUrl: profile?.avatarUrl,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    const Icon(
                      PhosphorIconsFill.steeringWheel,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Instrutor de aulas práticas',
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
          Icon(
            PhosphorIconsRegular.caretRight,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.entry});
  final _MenuEntry entry;

  @override
  Widget build(BuildContext context) {
    final Color color =
        entry.destructive ? AppColors.error : AppColors.textPrimary;
    return InkWell(
      onTap: entry.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: entry.destructive
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(entry.icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                entry.label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretRight,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
