import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../data/models/enums.dart';
import '../../../shared/widgets/widgets.dart';
import '../onboarding_controller.dart';
import '../onboarding_draft.dart';
import '../wizard_scaffold.dart';

class Step3VehicleDetails extends ConsumerStatefulWidget {
  const Step3VehicleDetails({super.key});

  @override
  ConsumerState<Step3VehicleDetails> createState() =>
      _Step3VehicleDetailsState();
}

class _Step3VehicleDetailsState extends ConsumerState<Step3VehicleDetails> {
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Transmission? _transmission;

  final MaskTextInputFormatter _plateMask = MaskTextInputFormatter(
    mask: 'AAA-#A##',
    filter: <String, RegExp>{
      'A': RegExp(r'[A-Za-z]'),
      '#': RegExp(r'[0-9]'),
    },
  );

  @override
  void initState() {
    super.initState();
    final OnboardingDraft d = ref.read(onboardingControllerProvider).draft;
    _brandController.text = d.vehicleBrand ?? '';
    _modelController.text = d.vehicleModel ?? '';
    _yearController.text = d.vehicleYear?.toString() ?? '';
    _plateController.text = d.vehiclePlate ?? '';
    _transmission = d.vehicleTransmission;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    if (_transmission == null) {
      CnhhjSnack.error(context, 'Selecione o tipo de transmissão.');
      return;
    }
    ref.read(onboardingControllerProvider.notifier).updateDraft(
          (OnboardingDraft d) => d.copyWith(
            vehicleBrand: _brandController.text.trim(),
            vehicleModel: _modelController.text.trim(),
            vehicleYear: int.tryParse(_yearController.text),
            vehiclePlate: _plateController.text.trim().toUpperCase(),
            vehicleTransmission: _transmission,
          ),
        );
    context.go('/onboarding/4');
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      title: 'Dados do veículo',
      subtitle: 'Conte um pouco sobre o veículo que você usa nas aulas',
      totalSteps: OnboardingController.totalSteps,
      currentStep: 3,
      onPrevious: () => context.go('/onboarding/2'),
      onNext: _onNext,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CnhhjTextField(
              controller: _brandController,
              label: 'Marca',
              hint: 'Ex: Volkswagen',
              textInputAction: TextInputAction.next,
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe a marca' : null,
            ),
            const SizedBox(height: 12),
            CnhhjTextField(
              controller: _modelController,
              label: 'Modelo',
              hint: 'Ex: Gol',
              textInputAction: TextInputAction.next,
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o modelo' : null,
            ),
            const SizedBox(height: 12),
            CnhhjTextField(
              controller: _yearController,
              label: 'Ano',
              hint: 'Ex: 2022',
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              textInputAction: TextInputAction.next,
              validator: (String? v) {
                final int? year = int.tryParse(v ?? '');
                if (year == null || year < 1980 || year > DateTime.now().year + 1) {
                  return 'Ano inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            CnhhjDropdown<Transmission>(
              label: 'Tipo de transmissão',
              value: _transmission,
              items: Transmission.values,
              itemLabel: (Transmission t) => t.label,
              onChanged: (Transmission? t) =>
                  setState(() => _transmission = t),
            ),
            const SizedBox(height: 12),
            CnhhjTextField(
              controller: _plateController,
              label: 'Placa',
              hint: 'AAA-0A00',
              inputFormatters: <TextInputFormatter>[_plateMask],
              textInputAction: TextInputAction.done,
              validator: (String? v) =>
                  (v == null || v.trim().length < 7) ? 'Placa inválida' : null,
            ),
          ],
        ),
      ),
    );
  }
}
