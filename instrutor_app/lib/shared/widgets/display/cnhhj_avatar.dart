import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Avatar circular. Carrega de URL com cache; cai num placeholder com as
/// iniciais quando a URL é nula ou falha.
class CnhhjAvatar extends StatelessWidget {
  const CnhhjAvatar({
    super.key,
    this.imageUrl,
    this.fullName,
    this.size = 48,
    this.borderColor,
  });

  final String? imageUrl;
  final String? fullName;
  final double size;
  final Color? borderColor;

  String get _initials {
    final String name = (fullName ?? '').trim();
    if (name.isEmpty) return '?';
    final List<String> parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: GoogleFonts.poppins(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => placeholder,
          errorWidget: (_, __, ___) => placeholder,
        ),
      ),
    );
  }
}
