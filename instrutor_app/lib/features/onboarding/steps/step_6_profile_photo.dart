import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/widgets.dart';
import '../onboarding_controller.dart';
import '../onboarding_draft.dart';
import '../wizard_scaffold.dart';

class Step6ProfilePhoto extends ConsumerStatefulWidget {
  const Step6ProfilePhoto({super.key});

  @override
  ConsumerState<Step6ProfilePhoto> createState() => _Step6ProfilePhotoState();
}

class _Step6ProfilePhotoState extends ConsumerState<Step6ProfilePhoto> {
  File? _photo;

  @override
  void initState() {
    super.initState();
    _photo = ref.read(onboardingControllerProvider).draft.profilePhoto;
  }

  void _onNext() {
    if (_photo == null) {
      CnhhjSnack.error(context, 'Tire ou escolha uma foto de perfil.');
      return;
    }
    ref.read(onboardingControllerProvider.notifier).updateDraft(
          (OnboardingDraft d) => d.copyWith(profilePhoto: _photo),
        );
    context.go('/onboarding/7');
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      title: 'Foto de perfil',
      subtitle: 'Essa foto vai aparecer para os alunos. Use uma foto nítida do seu rosto',
      totalSteps: OnboardingController.totalSteps,
      currentStep: 6,
      onPrevious: () => context.go('/onboarding/5'),
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
