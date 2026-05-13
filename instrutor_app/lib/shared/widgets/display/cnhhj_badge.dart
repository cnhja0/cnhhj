import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Etiqueta pequena para mostrar status, categoria CNH, ou tipo de veículo.
class CnhhjBadge extends StatelessWidget {
  const CnhhjBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.icon,
  });

  /// Variantes pré-definidas para os casos mais comuns.
  factory CnhhjBadge.status({required String label, required _BadgeKind kind}) {
    final ({Color bg, Color fg}) theme = switch (kind) {
      _BadgeKind.success => (bg: AppColors.success, fg: AppColors.surface),
      _BadgeKind.warning => (bg: AppColors.warning, fg: AppColors.surface),
      _BadgeKind.error   => (bg: AppColors.error,   fg: AppColors.surface),
      _BadgeKind.neutral => (
          bg: AppColors.surfaceOverlay,
          fg: AppColors.textPrimary,
        ),
    };
    return CnhhjBadge(label: label, color: theme.bg, textColor: theme.fg);
  }

  final String label;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: textColor ?? AppColors.textPrimary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

enum _BadgeKind { success, warning, error, neutral }

/// Exposto publicamente sob nome curto para uso externo.
typedef BadgeKind = _BadgeKind;
