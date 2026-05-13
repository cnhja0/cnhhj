import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Link textual com sublinhado, em preto. Usado para "Crie sua conta",
/// "Política de Privacidade", "Esqueci minha senha", etc.
class CnhhjTextLink extends StatelessWidget {
  const CnhhjTextLink({
    super.key,
    required this.label,
    this.onPressed,
    this.fontSize = 14,
    this.bold = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double fontSize;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: AppColors.textPrimary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
