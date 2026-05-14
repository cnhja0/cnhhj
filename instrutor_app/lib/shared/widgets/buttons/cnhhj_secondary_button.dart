import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Botão secundário: outline preto sobre fundo amarelo, com scale-on-press.
class CnhhjSecondaryButton extends StatefulWidget {
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
  State<CnhhjSecondaryButton> createState() => _CnhhjSecondaryButtonState();
}

class _CnhhjSecondaryButtonState extends State<CnhhjSecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onPressed == null;

    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.icon != null) ...<Widget>[
          Icon(widget.icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(widget.label),
      ],
    );

    final ButtonStyle style = OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      side: const BorderSide(color: AppColors.textPrimary, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: widget.expanded ? const Size.fromHeight(52) : null,
    );

    final Widget button = AnimatedScale(
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      scale: _pressed ? 0.96 : 1.0,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: disabled ? null : (_) => setState(() => _pressed = true),
        onPointerUp: disabled ? null : (_) => setState(() => _pressed = false),
        onPointerCancel:
            disabled ? null : (_) => setState(() => _pressed = false),
        child: OutlinedButton(
          onPressed: widget.onPressed,
          style: style,
          child: child,
        ),
      ),
    );

    return widget.expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
