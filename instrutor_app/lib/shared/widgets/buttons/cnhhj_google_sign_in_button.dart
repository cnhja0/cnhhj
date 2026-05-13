import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Botão de login com Google (visualmente fiel ao Figma).
///
/// Fundo branco, borda fina, ícone "G" colorido à esquerda e texto preto.
class CnhhjGoogleSignInButton extends StatelessWidget {
  const CnhhjGoogleSignInButton({
    super.key,
    required this.onPressed,
    this.label = 'Acessar com Google',
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const _GoogleGlyph(size: 20),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Glifo "G" colorido do Google, desenhado em CSS-like (sem dependência externa).
/// Aproximação visual do logo oficial — substituir por SVG oficial em produção.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: SweepGradient(
                colors: <Color>[
                  Color(0xFFEA4335), // vermelho
                  Color(0xFFFBBC05), // amarelo
                  Color(0xFF34A853), // verde
                  Color(0xFF4285F4), // azul
                  Color(0xFFEA4335),
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: size * 0.55,
            height: size * 0.55,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            'G',
            style: TextStyle(
              fontSize: size * 0.6,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF4285F4),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
