import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/widgets.dart';
import '../onboarding_controller.dart';
import '../onboarding_draft.dart';
import '../wizard_scaffold.dart';

class Step4VehiclePhotoFront extends ConsumerStatefulWidget {
  const Step4VehiclePhotoFront({super.key});

  @override
  ConsumerState<Step4VehiclePhotoFront> createState() =>
      _Step4VehiclePhotoFrontState();
}

class _Step4VehiclePhotoFrontState
    extends ConsumerState<Step4VehiclePhotoFront> {
  File? _photo;

  @override
  void initState() {
    super.initState();
    _photo = ref.read(onboardingControllerProvider).draft.vehiclePhotoFront;
  }

  void _onNext() {
    if (_photo == null) {
      CnhhjSnack.error(context, 'Tire ou escolha uma foto frontal do veículo.');
      return;
    }
    ref.read(onboardingControllerProvider.notifier).updateDraft(
          (OnboardingDraft d) => d.copyWith(vehiclePhotoFront: _photo),
        );
    context.go('/onboarding/5');
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      title: 'Foto frontal do veículo',
      subtitle: 'Tire uma foto 3/4 de frente, mostrando placa e lateral',
      totalSteps: OnboardingController.totalSteps,
      currentStep: 4,
      onPrevious: () => context.go('/onboarding/3'),
      onNext: _onNext,
      canGoNext: _photo != null,
      child: CnhhjPhotoPicker(
        initialFile: _photo,
        hint: 'Toque para tirar/escolher a foto',
        onChanged: (File? f) => setState(() => _photo = f),
      ),
    );
  }
}
