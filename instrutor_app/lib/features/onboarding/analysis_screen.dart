import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

/// Tela "ANÁLISE EM PROCESSO" — visualmente fiel ao Figma, mas como o MVP
/// tem aprovação automática, ela só fica visível por uns 2 segundos antes
/// de auto-navegar para "Cadastro Finalizado".
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      context.go('/onboarding/finished');
    });
  }

  @override
  Widget build(BuildContext context) {
    return CnhhjScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const CnhhjLogo(size: 80),
          const SizedBox(height: 48),
          CnhhjCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons.access_time_filled_rounded,
                  size: 56,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  'ANÁLISE EM PROCESSO',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nossa equipe está confirmando os seus dados e, assim que possível, iremos liberar o seu acesso.\n\nNotificaremos por e-mail quando a liberação for aprovada!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
