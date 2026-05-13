import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo oficial do CNHhj.
///
/// Por padrão usa a versão "full" (com letras "CNHhj"). Use `iconOnly: true`
/// para a versão compacta com apenas o "hj" — boa para AppBars, avatares
/// pequenos ou ícones em listas.
class CnhhjLogo extends StatelessWidget {
  const CnhhjLogo({
    super.key,
    this.size = 72,
    this.iconOnly = false,
    this.colorFilter,
  });

  /// Altura desejada (a largura é proporcional ao viewBox do SVG).
  final double size;

  /// Se true, renderiza só o ícone "hj" (quadrado). Padrão `false` (logo cheio).
  final bool iconOnly;

  /// Filtro opcional para tingir o logo (útil para variações em fundos
  /// escuros, por exemplo).
  final ColorFilter? colorFilter;

  static const String _logoAsset = 'assets/images/cnhhj_logo.svg';
  static const String _iconAsset = 'assets/icons/hj_icon.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      iconOnly ? _iconAsset : _logoAsset,
      height: size,
      colorFilter: colorFilter,
      semanticsLabel: 'CNHhj',
    );
  }
}
