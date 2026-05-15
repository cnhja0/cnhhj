import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

/// Scaffold consistente para todos os passos do wizard:
/// header com logo + barra de progresso animada, conteúdo central rolável,
/// rodapé fixo com botões Anterior/Próximo. Cada passo recebe animação
/// de entrada (fade + slide) automaticamente.
class WizardScaffold extends StatelessWidget {
  const WizardScaffold({
    super.key,
    required this.title,
    required this.totalSteps,
    required this.currentStep,
    required this.child,
    this.subtitle,
    this.nextLabel = 'Próximo',
    this.previousLabel = 'Anterior',
    this.onNext,
    this.onPrevious,
    this.isLast = false,
    this.canGoNext = true,
  });

  final String title;
  final String? subtitle;
  final int totalSteps;
  final int currentStep;
  final Widget child;
  final String nextLabel;
  final String previousLabel;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final bool isLast;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    return CnhhjScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              const CnhhjLogo(size: 38, iconOnly: true),
              const SizedBox(width: 10),
              Text(
                'Passo $currentStep de $totalSteps',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OnboardingProgressBar(
            totalSteps: totalSteps,
            currentStep: currentStep,
            dotSize: 12,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: CnhhjCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    child,
                  ],
                ),
              )
                  .animate(key: ValueKey<int>(currentStep))
                  .fadeIn(duration: 320.ms)
                  .slideY(
                    begin: 0.06,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              if (onPrevious != null) ...<Widget>[
                Expanded(
                  child: CnhhjSecondaryButton(
                    label: previousLabel,
                    icon: PhosphorIconsRegular.arrowLeft,
                    onPressed: onPrevious,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: CnhhjPrimaryButton(
                  label: isLast ? 'Concluir' : nextLabel,
                  icon: isLast
                      ? PhosphorIconsRegular.check
                      : PhosphorIconsRegular.arrowRight,
                  onPressed: canGoNext ? onNext : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
