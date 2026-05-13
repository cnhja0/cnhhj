import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

/// Scaffold consistente para todos os passos do wizard:
/// header com logo + barra de progresso, conteúdo central rolável,
/// rodapé fixo com botões Anterior/Próximo.
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          const CnhhjLogo(size: 56),
          const SizedBox(height: 16),
          OnboardingProgressBar(
            totalSteps: totalSteps,
            currentStep: currentStep,
            dotSize: 12,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: CnhhjCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    child,
                  ],
                ),
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
                    onPressed: onPrevious,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: CnhhjPrimaryButton(
                  label: isLast ? 'Concluir' : nextLabel,
                  onPressed: canGoNext ? onNext : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
