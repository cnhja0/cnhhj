import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Modal central com blur de fundo, fiel ao padrão do Figma.
///
/// Uso:
/// ```dart
/// showCnhhjModal(
///   context: context,
///   title: 'Sem sinal',
///   message: 'Parece que você está sem sinal...',
///   primaryLabel: 'Atualizar',
///   onPrimary: () => Navigator.of(context).pop(),
/// );
/// ```
Future<T?> showCnhhjModal<T>({
  required BuildContext context,
  String? title,
  String? message,
  IconData? icon,
  String? primaryLabel,
  VoidCallback? onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
  bool dismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'modal',
    barrierColor: Colors.transparent,
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (BuildContext ctx, Animation<double> anim, _, __) {
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 6 * anim.value,
          sigmaY: 6 * anim.value,
        ),
        child: Container(
          color: AppColors.overlayDim.withOpacity(0.4 * anim.value),
          child: Center(
            child: Opacity(
              opacity: anim.value,
              child: _ModalCard(
                title: title,
                message: message,
                icon: icon,
                primaryLabel: primaryLabel,
                onPrimary: onPrimary,
                secondaryLabel: secondaryLabel,
                onSecondary: onSecondary,
              ),
            ),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 220),
  );
}

class _ModalCard extends StatelessWidget {
  const _ModalCard({
    this.title,
    this.message,
    this.icon,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String? title;
  final String? message;
  final IconData? icon;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 40, color: AppColors.textPrimary),
                const SizedBox(height: 12),
              ],
              if (title != null)
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              if (message != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              if (primaryLabel != null || secondaryLabel != null) ...<Widget>[
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    if (secondaryLabel != null) ...<Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onSecondary,
                          child: Text(secondaryLabel!),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (primaryLabel != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onPrimary,
                          child: Text(primaryLabel!),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
