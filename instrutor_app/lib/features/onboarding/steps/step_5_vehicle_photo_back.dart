import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/widgets.dart';
import '../onboarding_controller.dart';
import '../onboarding_draft.dart';
import '../wizard_scaffold.dart';

class Step5VehiclePhotoBack extends ConsumerStatefulWidget {
  const Step5VehiclePhotoBack({super.key});

  @override
  ConsumerState<Step5VehiclePhotoBack> createState() =>
      _Step5VehiclePhotoBackState();
}

class _Step5VehiclePhotoBackState
    extends ConsumerState<Step5VehiclePhotoBack> {
  File? _photo;

  @override
  void initState() {
    super.initState();
    _photo = ref.read(onboardingControllerProvider).draft.vehiclePhotoBack;
  }

  void _onNext() {
    if (_photo == null) {
      CnhhjSnack.error(context, 'Tire ou escolha uma foto traseira do veículo.');
      return;
    }
    ref.read(onboardingControllerProvider.notifier).updateDraft(
          (OnboardingDraft d) => d.copyWith(vehiclePhotoBack: _photo),
        );
    context.go('/onboarding/6');
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      title: 'Foto traseira do veículo',
      subtitle: 'Tire uma foto 3/4 de trás, mostrando placa e lateral',
      totalSteps: OnboardingController.totalSteps,
      currentStep: 5,
      onPrevious: () => context.go('/onboarding/4'),
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
