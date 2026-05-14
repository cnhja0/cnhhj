import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Card branco padrão do CNHhj: cantos arredondados, **sombra suave**,
/// padding interno generoso. É o container que aparece sobre o fundo amarelo.
///
/// Parâmetros opcionais:
/// - `shadow: false` para card "flat" (sem profundidade).
/// - `border` para borda customizada (ex: contorno preto nos cards do grid).
class CnhhjCard extends StatelessWidget {
  const CnhhjCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.borderRadius = 20,
    this.shadow = true,
    this.backgroundColor = AppColors.surface,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool shadow;
  final Color backgroundColor;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    Widget card = Material(
      color: backgroundColor,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (shadow || border != null) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: border,
          boxShadow: shadow
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: card,
      );
    }

    return Padding(padding: margin, child: card);
  }
}
