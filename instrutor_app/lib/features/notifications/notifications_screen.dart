import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/app_notification.dart';
import '../../data/providers.dart';
import '../../shared/widgets/widgets.dart';
import '../home/home_providers.dart';

/// Tela de notificações in-app. Lista alertas (solicitações, lembretes,
/// avaliações, avisos do sistema). Toque marca como lida e opcionalmente
/// navega para a tela relacionada.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppNotification>> async =
        ref.watch(notificationsProvider);
    final String userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notificações'),
        actions: <Widget>[
          async.maybeWhen(
            data: (List<AppNotification> items) {
              final bool hasUnread =
                  items.any((AppNotification n) => n.isUnread);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () async {
                  await ref
                      .read(notificationRepositoryProvider)
                      .markAllAsRead(userId);
                },
                icon: const Icon(
                  PhosphorIconsRegular.checks,
                  size: 18,
                ),
                label: Text(
                  'Marcar todas',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.textPrimary),
        ),
        error: (Object err, _) => Center(child: Text('Erro: $err')),
        data: (List<AppNotification> items) {
          if (items.isEmpty) {
            return const CnhhjEmptyState(
              icon: PhosphorIconsDuotone.bellSlash,
              message:
                  'Sem notificações por aqui.\nVocê será avisado de novas solicitações, avaliações e lembretes de aula.',
            );
          }
          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (BuildContext c, int i) {
              return _NotificationTile(notification: items[i])
                  .animate()
                  .fadeIn(delay: (i * 50).ms, duration: 280.ms)
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool unread = notification.isUnread;

    return CnhhjCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      onTap: () async {
        if (unread) {
          await ref
              .read(notificationRepositoryProvider)
              .markAsRead(notification.id);
        }
        if (!context.mounted) return;
        final String? route =
            notification.actionRoute ?? notification.type.defaultRoute;
        if (route == null) return;
        context.pop();
        context.push(route);
      },
      backgroundColor:
          unread ? AppColors.surface : AppColors.surface.withOpacity(0.7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: notification.type.tint.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              notification.type.icon,
              size: 22,
              color: notification.type.tint == AppColors.primary
                  ? AppColors.textPrimary
                  : notification.type.tint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: notification.type.tint.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notification.type.label.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: notification.type.tint == AppColors.primary
                              ? AppColors.textPrimary
                              : notification.type.tint,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _relative(notification.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight:
                        unread ? FontWeight.w800 : FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.body,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 6, top: 6),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  String _relative(DateTime when) {
    final Duration diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return '${diff.inMinutes}min';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}sem';
  }
}
