import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Barra de progresso do onboarding: bolinhas conectadas por linhas.
///
/// Definida no Excalidraw:
///   • bolinhas amarelo xoxo escuro (#FEF5C6) = pendente
///   • bolinhas verde (#47C100) = concluído
class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.dotSize = 14,
    this.connectorThickness = 2,
  });

  /// Número total de passos.
  final int totalSteps;

  /// Quantos passos já foram completados (0 = nenhum).
  final int currentStep;

  final double dotSize;
  final double connectorThickness;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(totalSteps * 2 - 1, (int i) {
        if (i.isEven) {
          final int dotIndex = i ~/ 2;
          final bool completed = dotIndex < currentStep;
          return _Dot(size: dotSize, completed: completed);
        }
        final int connectorIndex = (i - 1) ~/ 2;
        final bool completed = connectorIndex < currentStep;
        return _Connector(
          completed: completed,
          thickness: connectorThickness,
        );
      }),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.completed});

  final double size;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: completed ? AppColors.success : AppColors.primaryLighter,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.completed, required this.thickness});

  final bool completed;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Container(
        height: thickness,
        color: completed ? AppColors.success : AppColors.primaryLighter,
      ),
    );
  }
}
