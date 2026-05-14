import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Botão primário do CNHhj: fundo preto, texto branco, cantos arredondados,
/// **feedback de scale-on-press** para sensação tátil.
///
/// É o CTA padrão (Entrar, Salvar, Próximo, Confirmar).
class CnhhjPrimaryButton extends StatefulWidget {
  const CnhhjPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expanded;

  @override
  State<CnhhjPrimaryButton> createState() => _CnhhjPrimaryButtonState();
}

class _CnhhjPrimaryButtonState extends State<CnhhjPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.isLoading || widget.onPressed == null;

    final Widget child = widget.isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
            ),
          )
        : Row(
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

    final ButtonStyle style = ElevatedButton.styleFrom(
      backgroundColor: AppColors.textPrimary,
      foregroundColor: AppColors.surface,
      disabledBackgroundColor: AppColors.disabled,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: widget.expanded ? const Size.fromHeight(52) : null,
      elevation: 0,
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
        child: ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
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
