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

/// Abre o bottom sheet de notificações — não retira o usuário da aba atual.
///
/// Slides up de baixo, pode ser arrastado para fechar ou tocar fora.
/// Mantém o contexto da tela onde o usuário estava.
Future<void> showNotificationsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.overlayDim,
    builder: (BuildContext ctx) => const _NotificationsSheet(),
  );
}

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext ctx, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 32,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              // Drag handle
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const _SheetHeader(),
              const SizedBox(height: 4),
              Expanded(
                child: _NotificationsList(scrollController: scrollController),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetHeader extends ConsumerWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppNotification>> async =
        ref.watch(notificationsProvider);
    final String userId = ref.watch(currentUserIdProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.textPrimary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              PhosphorIconsFill.bellRinging,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Notificações',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                ),
                async.maybeWhen(
                  data: (List<AppNotification> items) {
                    final int unread = items
                        .where((AppNotification n) => n.isUnread)
                        .length;
                    return Text(
                      unread > 0
                          ? '$unread não ${unread == 1 ? 'lida' : 'lidas'}'
                          : 'Tudo lido',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
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
                  size: 16,
                ),
                label: Text(
                  'Marcar lidas',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(PhosphorIconsRegular.x),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _NotificationsList extends ConsumerWidget {
  const _NotificationsList({required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppNotification>> async =
        ref.watch(notificationsProvider);

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.textPrimary),
      ),
      error: (Object err, _) => Center(child: Text('Erro: $err')),
      data: (List<AppNotification> items) {
        if (items.isEmpty) {
          return const CnhhjEmptyState(
            icon: PhosphorIconsDuotone.bellSlash,
            message:
                'Sem notificações por aqui.\nVocê será avisado de novas\nsolicitações, avaliações e lembretes.',
          );
        }
        return ListView.separated(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (BuildContext c, int i) {
            return _NotificationTile(notification: items[i])
                .animate()
                .fadeIn(delay: (i * 40).ms, duration: 240.ms)
                .slideY(
                  begin: 0.06,
                  end: 0,
                  curve: Curves.easeOutCubic,
                );
          },
        );
      },
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
        if (notification.actionRoute != null && context.mounted) {
          Navigator.of(context).pop(); // fecha o sheet
          context.push(notification.actionRoute!);
        }
      },
      backgroundColor:
          unread ? AppColors.surface : AppColors.surface.withOpacity(0.65),
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
