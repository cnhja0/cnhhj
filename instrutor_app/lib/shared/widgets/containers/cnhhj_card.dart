import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Card branco padrão do CNHhj: cantos arredondados, sem sombra (por padrão),
/// padding interno generoso. É o container que aparece sobre o fundo amarelo.
class CnhhjCard extends StatelessWidget {
  const CnhhjCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.borderRadius = 20,
    this.elevation = 0,
    this.backgroundColor = AppColors.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final double elevation;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    final Widget card = Material(
      color: backgroundColor,
      borderRadius: radius,
      elevation: elevation,
      shadowColor: AppColors.overlayDim,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );

    return Padding(padding: margin, child: card);
  }
}
