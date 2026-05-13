import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/widgets.dart';
import '../onboarding_controller.dart';
import '../onboarding_draft.dart';
import '../wizard_scaffold.dart';

class Step7Documents extends ConsumerStatefulWidget {
  const Step7Documents({super.key});

  @override
  ConsumerState<Step7Documents> createState() => _Step7DocumentsState();
}

class _Step7DocumentsState extends ConsumerState<Step7Documents> {
  File? _cnh;
  File? _detran;

  @override
  void initState() {
    super.initState();
    final OnboardingDraft d = ref.read(onboardingControllerProvider).draft;
    _cnh = d.cnhPhoto;
    _detran = d.detranCertificate;
  }

  Future<void> _onFinish() async {
    if (_cnh == null || _detran == null) {
      CnhhjSnack.error(
        context,
        'Envie a foto da CNH e do Certificado DETRAN.',
      );
      return;
    }
    ref.read(onboardingControllerProvider.notifier).updateDraft(
          (OnboardingDraft d) =>
              d.copyWith(cnhPhoto: _cnh, detranCertificate: _detran),
        );

    final bool ok =
        await ref.read(onboardingControllerProvider.notifier).submit();
    if (!mounted) return;
    if (ok) {
      context.go('/onboarding/analysis');
    } else {
      final String? err =
          ref.read(onboardingControllerProvider).errorMessage;
      if (err != null) CnhhjSnack.error(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool submitting =
        ref.watch(onboardingControllerProvider).submitting;

    return CnhhjLoadingOverlay(
      show: submitting,
      message: 'Enviando seu cadastro...',
      child: WizardScaffold(
        title: 'Documentos',
        subtitle: 'Envie a foto da sua CNH e do Certificado DETRAN',
        totalSteps: OnboardingController.totalSteps,
        currentStep: 7,
        isLast: true,
        onPrevious: () => context.go('/onboarding/6'),
        onNext: _onFinish,
        canGoNext: _cnh != null && _detran != null && !submitting,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CnhhjPhotoPicker(
              label: 'Foto da CNH',
              initialFile: _cnh,
              hint: 'Foto nítida da CNH aberta',
              onChanged: (File? f) => setState(() => _cnh = f),
            ),
            const SizedBox(height: 16),
            CnhhjPhotoPicker(
              label: 'Certificado DETRAN',
              initialFile: _detran,
              hint: 'Foto do credenciamento DETRAN',
              onChanged: (File? f) => setState(() => _detran = f),
            ),
          ],
        ),
      ),
    );
  }
}
