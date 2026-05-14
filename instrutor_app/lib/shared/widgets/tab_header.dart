import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'cnhhj_logo.dart';

/// Header padronizado das abas do app: título grande em peso 900 +
/// subtítulo opcional à esquerda, e o ícone do logo CNHhj sempre no
/// canto superior direito (mesma posição em todas as telas).
///
/// Use no topo de cada tab da Home para manter consistência visual.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(width: 12),
        const CnhhjLogo(size: 38, iconOnly: true),
      ],
    );
  }
}
