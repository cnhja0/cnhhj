import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/enums.dart';
import '../../../shared/widgets/widgets.dart';
import '../onboarding_controller.dart';
import '../onboarding_draft.dart';
import '../wizard_scaffold.dart';

class Step2VehicleType extends ConsumerStatefulWidget {
  const Step2VehicleType({super.key});

  @override
  ConsumerState<Step2VehicleType> createState() => _Step2VehicleTypeState();
}

class _Step2VehicleTypeState extends ConsumerState<Step2VehicleType> {
  VehicleType? _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(onboardingControllerProvider).draft.vehicleType;
  }

  void _onNext() {
    if (_selected == null) {
      CnhhjSnack.error(context, 'Escolha o tipo de aula que você dá.');
      return;
    }
    // Tipo definido implicitamente as categorias CNH:
    //   carro -> B; moto -> A; ambos -> A + B (modelo AB do enum também serve).
    final List<VehicleCategory> categories = switch (_selected!) {
      VehicleType.carro => <VehicleCategory>[VehicleCategory.B],
      VehicleType.moto => <VehicleCategory>[VehicleCategory.A],
      VehicleType.ambos => <VehicleCategory>[VehicleCategory.A, VehicleCategory.B],
    };
    ref.read(onboardingControllerProvider.notifier).updateDraft(
          (OnboardingDraft d) => d.copyWith(
            vehicleType: _selected,
            categories: categories,
          ),
        );
    context.go('/onboarding/3');
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      title: 'Qual tipo de aula você dá?',
      subtitle: 'Isso define a categoria CNH em que você é credenciado',
      totalSteps: OnboardingController.totalSteps,
      currentStep: 2,
      onPrevious: () => context.go('/onboarding/1'),
      onNext: _onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final VehicleType type in VehicleType.values)
            _Choice(
              type: type,
              selected: _selected == type,
              onTap: () => setState(() => _selected = type),
            ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final VehicleType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textPrimary,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                switch (type) {
                  VehicleType.carro => Icons.directions_car,
                  VehicleType.moto => Icons.two_wheeler,
                  VehicleType.ambos => Icons.commute,
                },
                size: 28,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  type.label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
