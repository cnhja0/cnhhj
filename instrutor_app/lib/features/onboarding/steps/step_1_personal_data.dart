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

class Step1PersonalData extends ConsumerStatefulWidget {
  const Step1PersonalData({super.key});

  @override
  ConsumerState<Step1PersonalData> createState() => _Step1PersonalDataState();
}

class _Step1PersonalDataState extends ConsumerState<Step1PersonalData> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Gender? _selectedGender;
  DateTime? _birthDate;

  final MaskTextInputFormatter _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: <String, RegExp>{'#': RegExp(r'[0-9]')},
  );

  final MaskTextInputFormatter _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: <String, RegExp>{'#': RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    final OnboardingDraft d = ref.read(onboardingControllerProvider).draft;
    _nameController.text = d.fullName ?? '';
    _cpfController.text = d.cpf ?? '';
    _phoneController.text = d.phone ?? '';
    _selectedGender = d.gender;
    _birthDate = d.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(onboardingControllerProvider.notifier).updateDraft(
          (OnboardingDraft d) => d.copyWith(
            fullName: _nameController.text.trim(),
            cpf: _cpfController.text.trim(),
            phone: _phoneController.text.trim(),
            gender: _selectedGender,
            birthDate: _birthDate,
          ),
        );
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      CnhhjSnack.error(context, 'Selecione o sexo.');
      return;
    }
    if (_birthDate == null) {
      CnhhjSnack.error(context, 'Informe sua data de nascimento.');
      return;
    }
    _save();
    context.go('/onboarding/2');
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      title: 'Oi! Para fazermos o seu cadastro,',
      subtitle: 'precisamos de algumas informações',
      totalSteps: OnboardingController.totalSteps,
      currentStep: 1,
      onNext: _onNext,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CnhhjTextField(
              controller: _nameController,
              label: 'Nome completo',
              hint: 'Digite seu nome completo',
              textInputAction: TextInputAction.next,
              validator: (String? v) => (v == null || v.trim().length < 3)
                  ? 'Informe seu nome completo'
                  : null,
            ),
            const SizedBox(height: 12),
            CnhhjTextField(
              controller: _cpfController,
              label: 'CPF',
              hint: '000.000.000-00',
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[_cpfMask],
              textInputAction: TextInputAction.next,
              validator: (String? v) =>
                  (v == null || _cpfMask.getUnmaskedText().length != 11)
                      ? 'CPF inválido'
                      : null,
            ),
            const SizedBox(height: 12),
            CnhhjDateField(
              label: 'Data de nascimento',
              initialDate: _birthDate,
              firstDate: DateTime(1900),
              lastDate: DateTime.now()
                  .subtract(const Duration(days: 365 * 18)),
              onChanged: (DateTime d) => setState(() => _birthDate = d),
            ),
            const SizedBox(height: 12),
            CnhhjDropdown<Gender>(
              label: 'Sexo',
              value: _selectedGender,
              items: Gender.values,
              itemLabel: (Gender g) => g.label,
              onChanged: (Gender? g) => setState(() => _selectedGender = g),
            ),
            const SizedBox(height: 12),
            CnhhjTextField(
              controller: _phoneController,
              label: 'Telefone',
              hint: '(11) 91234-5678',
              keyboardType: TextInputType.phone,
              inputFormatters: <TextInputFormatter>[_phoneMask],
              textInputAction: TextInputAction.done,
              validator: (String? v) =>
                  (v == null || _phoneMask.getUnmaskedText().length < 10)
                      ? 'Telefone inválido'
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}
