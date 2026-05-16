import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

/// Tela "ANÁLISE EM PROCESSO" — visualmente fiel ao Figma. No MVP a
/// aprovação é automática (definida no `signUpWithEmail` do auth mock),
/// então só esperamos uma janela de UI antes de seguir para "Cadastro
/// Finalizado". Quando trocarmos pra Supabase, esta tela passa a observar
/// `Profile.approvalStatus` e só navega quando vira `approved`.
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    // Janela cosmética de 2.5s para o usuário perceber o status. Em
    // produção, substituir por `ref.listen(currentProfileProvider, ...)`
    // detectando transição para ApprovalStatus.approved (e rejected →
    // tela de erro). Hoje o profile já nasce approved no signup.
    Future<void>.delayed(const Duration(milliseconds: 2500), () {
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
          const CnhhjLogo(size: 80)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 40),
          CnhhjCard(
            padding: const EdgeInsets.all(28),
            border: Border.all(color: AppColors.textPrimary, width: 1.5),
            child: Column(
              children: <Widget>[
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    PhosphorIconsDuotone.hourglassMedium,
                    size: 52,
                    color: AppColors.textPrimary,
                  ),
                )
                    .animate(
                        onPlay: (AnimationController c) => c.repeat())
                    .rotate(
                      duration: 1800.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(height: 18),
                Text(
                  'ANÁLISE EM PROCESSO',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nossa equipe está confirmando os seus dados e, assim que possível, iremos liberar o seu acesso.\n\nNotificaremos por e-mail quando a liberação for aprovada!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}
