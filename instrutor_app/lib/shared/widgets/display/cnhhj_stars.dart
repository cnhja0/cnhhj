import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Exibe rating de 1 a 5 estrelas. Pode ser somente leitura ou interativo.
class CnhhjStars extends StatelessWidget {
  const CnhhjStars({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.size = 18,
    this.onChanged,
    this.color,
  });

  /// Pode ser fracionado (3.5 = 3 cheias + 1 meia).
  final double rating;
  final int maxStars;
  final double size;

  /// Se informado, o componente vira interativo e cada toque define o valor.
  final ValueChanged<int>? onChanged;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color starColor = color ?? AppColors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(maxStars, (int i) {
        final double value = (i + 1) - rating;
        final IconData icon = value <= 0
            ? Icons.star_rounded
            : value < 1
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;
        final Widget star = Icon(icon, size: size, color: starColor);
        if (onChanged == null) return star;
        return InkWell(
          onTap: () => onChanged!(i + 1),
          customBorder: const CircleBorder(),
          child: Padding(padding: const EdgeInsets.all(2), child: star),
        );
      }),
    );
  }
}
