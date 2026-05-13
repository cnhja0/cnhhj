import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Overlay de carregamento com blur. Use para esconder a tela enquanto
/// uma operação assíncrona pesada está rodando (login, upload de foto, etc.).
class CnhhjLoadingOverlay extends StatelessWidget {
  const CnhhjLoadingOverlay({
    super.key,
    required this.show,
    required this.child,
    this.message,
  });

  final bool show;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        child,
        if (show)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: AppColors.overlayDim,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    if (message != null) ...<Widget>[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.surface,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
