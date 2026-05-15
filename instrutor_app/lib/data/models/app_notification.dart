import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';

/// Tipos de notificação que o instrutor recebe. Cada tipo tem um ícone
/// Phosphor e uma cor de destaque associada.
enum NotificationType {
  bookingRequest,
  bookingConfirmed,
  bookingCancelled,
  review,
  system,
  reminder;

  IconData get icon => switch (this) {
        NotificationType.bookingRequest   => PhosphorIconsDuotone.bellRinging,
        NotificationType.bookingConfirmed => PhosphorIconsDuotone.calendarCheck,
        NotificationType.bookingCancelled => PhosphorIconsDuotone.xCircle,
        NotificationType.review           => PhosphorIconsDuotone.star,
        NotificationType.system           => PhosphorIconsDuotone.megaphone,
        NotificationType.reminder         => PhosphorIconsDuotone.alarm,
      };

  Color get tint => switch (this) {
        NotificationType.bookingRequest   => AppColors.primary,
        NotificationType.bookingConfirmed => AppColors.success,
        NotificationType.bookingCancelled => AppColors.error,
        NotificationType.review           => AppColors.primary,
        NotificationType.system           => AppColors.textPrimary,
        NotificationType.reminder         => AppColors.warning,
      };

  String get label => switch (this) {
        NotificationType.bookingRequest   => 'Solicitação',
        NotificationType.bookingConfirmed => 'Confirmada',
        NotificationType.bookingCancelled => 'Cancelada',
        NotificationType.review           => 'Avaliação',
        NotificationType.system           => 'Aviso',
        NotificationType.reminder         => 'Lembrete',
      };

  /// Rota default para esse tipo, usada se a notificação não definir
  /// explicitamente um `actionRoute`. Mantém a navegação coerente.
  String? get defaultRoute => switch (this) {
        NotificationType.bookingRequest   => '/home/solicitacoes',
        NotificationType.bookingConfirmed => '/home/agenda',
        NotificationType.bookingCancelled => '/home/agenda',
        NotificationType.review           => '/reviews',
        NotificationType.reminder         => '/home/agenda',
        NotificationType.system           => null,
      };
}

/// Notificação in-app. Armazenada no banco em produção; no MVP fica
/// apenas em memória (mock seed).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.actionRoute,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  /// Rota para abrir ao tocar (ex: '/home/solicitacoes' para abrir
  /// a lista de pedidos). Null = só marca como lida.
  final String? actionRoute;

  bool get isUnread => readAt == null;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
        actionRoute: actionRoute,
      );
}
