import 'package:flutter/material.dart';

/// Paleta de cores do CNHhj, definida no Excalidraw e refletida no Figma.
///
/// Não inventar cores fora desta paleta — se uma situação exige outra cor,
/// validar com o time de design antes.
class AppColors {
  AppColors._();

  // ─── Marca ────────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFFFFD000); // amarelo principal
  static const Color primaryLight   = Color(0xFFFFFAE6); // amarelo xoxo claro
  static const Color primaryLighter = Color(0xFFFEF5C6); // amarelo xoxo escuro (pendente)

  // ─── Estados ──────────────────────────────────────────────────────────
  static const Color success = Color(0xFF47C100); // verde de sucesso/concluído
  static const Color error   = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);

  // ─── Neutros ──────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color textMuted     = Color(0xFF8A8A8A);

  static const Color surface         = Color(0xFFFFFFFF); // cards e inputs
  static const Color surfaceOverlay  = Color(0xFFF5F5F5);
  static const Color divider         = Color(0xFFE0E0E0);
  static const Color disabled        = Color(0xFFBDBDBD);

  // ─── Blur de overlay ──────────────────────────────────────────────────
  static const Color overlayDim = Color(0x66000000); // 40% preto para fundo de modais
}
