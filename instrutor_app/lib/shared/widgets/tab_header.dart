import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/home_providers.dart';
import 'cnhhj_logo.dart';

/// Header padronizado das abas do app: título grande em peso 900 +
/// subtítulo opcional à esquerda. À direita: sino de notificações
/// (badge se há não lidas) + logo CNHhj.
///
/// Use no topo de cada tab da Home para manter consistência visual.
class TabHeader extends ConsumerWidget {
  const TabHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBell = true,
  });

  final String title;
  final String? subtitle;

  /// Mostra o sino de notificações com badge. Padrão `true`.
  final bool showBell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int unread = showBell
        ? ref.watch(unreadNotificationsCountProvider)
        : 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (showBell) ...<Widget>[
          _NotificationBell(unread: unread),
          const SizedBox(width: 8),
        ],
        const CnhhjLogo(size: 36, iconOnly: true),
      ],
    );
  }
}

/// Sino de notificações com badge contendo a contagem de não lidas.
class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unread});
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Material(
          color: AppColors.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.push(AppRoutes.notifications),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                PhosphorIconsRegular.bellRinging,
                size: 22,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        if (unread > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.surface,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
