import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Botão secundário: outline preto sobre fundo amarelo. Usado quando há
/// uma ação primária e queremos oferecer alternativa visualmente distinta
/// (ex: "Anterior" ao lado de "Próximo", "Cancelar" ao lado de "Confirmar").
class CnhhjSecondaryButton extends StatelessWidget {
  const CnhhjSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );

    final ButtonStyle style = OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      side: const BorderSide(color: AppColors.textPrimary, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      minimumSize: expanded ? const Size.fromHeight(52) : null,
    );

    final Widget button = OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
