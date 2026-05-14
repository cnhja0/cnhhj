import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Card branco padrão do CNHhj: cantos arredondados, **sombra suave**,
/// padding interno generoso. É o container que aparece sobre o fundo amarelo.
///
/// A sombra dá profundidade e separa visualmente do fundo. Para o card
/// ficar "flat" (sem sombra), passe `shadow: false`.
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
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool shadow;
  final Color backgroundColor;

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

    if (shadow) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const <BoxShadow>[
            // Sombra principal (suave, larga)
            BoxShadow(
              color: Color(0x14000000), // ~8% preto
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
            // Sombra de aproximação (curta, faz "tocar" o fundo)
            BoxShadow(
              color: Color(0x0A000000), // ~4% preto
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: card,
      );
    }

    return Padding(padding: margin, child: card);
  }
}
