import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/widgets.dart';

/// Aba MAIS — menu com Perfil, Guia, Suporte, Sair.
class TabMore extends ConsumerWidget {
  const TabMore({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> logout() async {
      await ref.read(authRepositoryProvider).signOut();
      if (!context.mounted) return;
      context.go(AppRoutes.login);
    }

    return CnhhjScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ListView(
        children: <Widget>[
          const _UserHeader(),
          const SizedBox(height: 16),
          CnhhjCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _Item(
                  icon: Icons.person_outline,
                  label: 'Perfil',
                  onTap: () {
                    // TODO: navegar para edição de perfil
                  },
                ),
                const Divider(height: 1),
                _Item(
                  icon: Icons.chat_bubble_outline,
                  label: 'Conversas',
                  onTap: () => context.push(AppRoutes.chatList),
                ),
                const Divider(height: 1),
                _Item(
                  icon: Icons.star_outline,
                  label: 'Avaliações recebidas',
                  onTap: () => context.push(AppRoutes.reviewsList),
                ),
                const Divider(height: 1),
                _Item(
                  icon: Icons.menu_book_outlined,
                  label: 'Passo a passo',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _Item(
                  icon: Icons.help_outline,
                  label: 'Guia',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _Item(
                  icon: Icons.support_agent_outlined,
                  label: 'Suporte',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CnhhjCard(
            padding: EdgeInsets.zero,
            child: _Item(
              icon: Icons.logout,
              label: 'Sair',
              destructive: true,
              onTap: logout,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'CNHhj • versão 0.1.0',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserHeader extends ConsumerWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<dynamic>(
      future: ref.read(authRepositoryProvider).currentProfile(),
      builder: (BuildContext ctx, AsyncSnapshot<dynamic> snap) {
        final String name = snap.data?.fullName ?? 'Instrutor';
        return CnhhjCard(
          child: Row(
            children: <Widget>[
              CnhhjAvatar(size: 56, fullName: name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Instrutor de aulas práticas',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color color =
        destructive ? AppColors.error : AppColors.textPrimary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
    );
  }
}
