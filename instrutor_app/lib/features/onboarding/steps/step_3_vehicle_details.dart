import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../core/services/fipe_providers.dart';
import '../../../core/services/fipe_service.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/enums.dart';
import '../../../shared/widgets/widgets.dart';
import '../onboarding_controller.dart';
import '../onboarding_draft.dart';
import '../wizard_scaffold.dart';

/// Step 3 do wizard — dados do veículo.
///
/// Marca e modelo são selecionados via FIPE (catálogo oficial padronizado).
/// Se a API estiver offline, o usuário pode digitar livre como fallback —
/// não bloqueia o cadastro. Ano, placa e transmissão continuam manuais.
class Step3VehicleDetails extends ConsumerStatefulWidget {
  const Step3VehicleDetails({super.key});

  @override
  ConsumerState<Step3VehicleDetails> createState() =>
      _Step3VehicleDetailsState();
}

class _Step3VehicleDetailsState extends ConsumerState<Step3VehicleDetails> {
  // Texto livre como fallback. Quando a FIPE está disponível, esses
  // controllers são preenchidos a partir da seleção.
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Transmission? _transmission;
  String? _selectedBrandCode;
  String? _selectedBrandName;
  String? _selectedModelName;
  bool _manualMode = false; // toggle para fallback (texto livre)

  // Placa aceita formato antigo (ABC-1234) e Mercosul (ABC-1D23) — máscara
  // permite os dois e o validator decide. 4ª posição é dígito; 5ª pode
  // ser dígito ou letra; 6ª e 7ª dígitos.
  final MaskTextInputFormatter _plateMask = MaskTextInputFormatter(
    mask: 'AAA-#@##',
    filter: <String, RegExp>{
      'A': RegExp(r'[A-Za-z]'),
      '#': RegExp(r'[0-9]'),
      '@': RegExp(r'[A-Za-z0-9]'),
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
    _selectedBrandName = d.vehicleBrand;
    _selectedModelName = d.vehicleModel;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  /// Tipo FIPE — instrutores "ambos" cadastram primeiro o carro; moto vem
  /// no perfil. Sem isso a FIPE não sabe qual catálogo carregar.
  VehicleType get _fipeType {
    final VehicleType? t =
        ref.read(onboardingControllerProvider).draft.vehicleType;
    return t == VehicleType.moto ? VehicleType.moto : VehicleType.carro;
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    if (_transmission == null) {
      CnhhjSnack.error(context, 'Selecione o tipo de transmissão.');
      return;
    }
    final String brand =
        (_manualMode ? _brandController.text : _selectedBrandName ?? '').trim();
    final String model =
        (_manualMode ? _modelController.text : _selectedModelName ?? '').trim();
    if (brand.isEmpty) {
      CnhhjSnack.error(context, 'Selecione a marca do veículo.');
      return;
    }
    if (model.isEmpty) {
      CnhhjSnack.error(context, 'Selecione o modelo do veículo.');
      return;
    }
    ref.read(onboardingControllerProvider.notifier).updateDraft(
          (OnboardingDraft d) => d.copyWith(
            vehicleBrand: brand,
            vehicleModel: model,
            vehicleYear: int.tryParse(_yearController.text),
            vehiclePlate: Validators.normalizePlate(_plateController.text),
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
            if (_manualMode)
              _ManualBrandModelFields(
                brandController: _brandController,
                modelController: _modelController,
                onSwitchToFipe: () => setState(() => _manualMode = false),
              )
            else
              _FipeBrandModelSection(
                type: _fipeType,
                selectedBrandCode: _selectedBrandCode,
                selectedBrandName: _selectedBrandName,
                selectedModelName: _selectedModelName,
                onBrandPicked: (FipeItem b) => setState(() {
                  _selectedBrandCode = b.code;
                  _selectedBrandName = b.name;
                  _selectedModelName = null; // reset modelo ao trocar marca
                }),
                onModelPicked: (FipeItem m) => setState(() {
                  _selectedModelName = m.name;
                }),
                onSwitchToManual: () {
                  setState(() {
                    _manualMode = true;
                    _brandController.text = _selectedBrandName ?? '';
                    _modelController.text = _selectedModelName ?? '';
                  });
                },
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
              validator: Validators.vehicleYear,
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
              hint: 'AAA-0000 ou AAA-0A00',
              inputFormatters: <TextInputFormatter>[_plateMask],
              textInputAction: TextInputAction.done,
              validator: Validators.plate,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloco que carrega marca/modelo direto da FIPE. Mostra estados de
/// loading e erro de forma transparente; em caso de falha, oferece o
/// "Digitar manualmente" como saída.
class _FipeBrandModelSection extends ConsumerWidget {
  const _FipeBrandModelSection({
    required this.type,
    required this.selectedBrandCode,
    required this.selectedBrandName,
    required this.selectedModelName,
    required this.onBrandPicked,
    required this.onModelPicked,
    required this.onSwitchToManual,
  });

  final VehicleType type;
  final String? selectedBrandCode;
  final String? selectedBrandName;
  final String? selectedModelName;
  final ValueChanged<FipeItem> onBrandPicked;
  final ValueChanged<FipeItem> onModelPicked;
  final VoidCallback onSwitchToManual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<FipeItem>> brandsAsync =
        ref.watch(fipeBrandsProvider(type));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        brandsAsync.when(
          loading: () => CnhhjSearchablePicker<String>(
            items: const <PickerItem<String>>[],
            label: 'Marca',
            loading: true,
            onSelected: (_) {},
          ),
          error: (Object err, _) => CnhhjSearchablePicker<String>(
            items: const <PickerItem<String>>[],
            label: 'Marca',
            errorText: 'Não foi possível carregar marcas',
            onRetry: () => ref.invalidate(fipeBrandsProvider(type)),
            onSelected: (_) {},
          ),
          data: (List<FipeItem> brands) => CnhhjSearchablePicker<FipeItem>(
            items: brands
                .map((FipeItem b) =>
                    PickerItem<FipeItem>(value: b, label: b.name))
                .toList(growable: false),
            label: 'Marca',
            hint: 'Selecione a marca',
            searchHint: 'Buscar marca...',
            selectedLabel: selectedBrandName,
            onSelected: (PickerItem<FipeItem> p) => onBrandPicked(p.value),
          ),
        ),
        const SizedBox(height: 12),
        if (selectedBrandCode == null)
          CnhhjSearchablePicker<String>(
            items: const <PickerItem<String>>[],
            label: 'Modelo',
            hint: 'Escolha a marca primeiro',
            enabled: false,
            onSelected: (_) {},
          )
        else
          Consumer(
            builder: (BuildContext c, WidgetRef innerRef, _) {
              final FipeModelsKey key = FipeModelsKey(
                type: type,
                brandCode: selectedBrandCode!,
              );
              final AsyncValue<List<FipeItem>> modelsAsync =
                  innerRef.watch(fipeModelsProvider(key));
              return modelsAsync.when(
                loading: () => CnhhjSearchablePicker<String>(
                  items: const <PickerItem<String>>[],
                  label: 'Modelo',
                  loading: true,
                  onSelected: (_) {},
                ),
                error: (Object err, _) => CnhhjSearchablePicker<String>(
                  items: const <PickerItem<String>>[],
                  label: 'Modelo',
                  errorText: 'Não foi possível carregar modelos',
                  onRetry: () =>
                      innerRef.invalidate(fipeModelsProvider(key)),
                  onSelected: (_) {},
                ),
                data: (List<FipeItem> models) =>
                    CnhhjSearchablePicker<FipeItem>(
                  items: models
                      .map((FipeItem m) =>
                          PickerItem<FipeItem>(value: m, label: m.name))
                      .toList(growable: false),
                  label: 'Modelo',
                  hint: 'Selecione o modelo',
                  searchHint: 'Buscar modelo...',
                  selectedLabel: selectedModelName,
                  onSelected: (PickerItem<FipeItem> p) => onModelPicked(p.value),
                ),
              );
            },
          ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: CnhhjTextLink(
            label: 'Não encontrei meu veículo',
            onPressed: onSwitchToManual,
          ),
        ),
      ],
    );
  }
}

/// Fallback para quando o catálogo FIPE não tem o veículo ou está offline.
class _ManualBrandModelFields extends StatelessWidget {
  const _ManualBrandModelFields({
    required this.brandController,
    required this.modelController,
    required this.onSwitchToFipe,
  });

  final TextEditingController brandController;
  final TextEditingController modelController;
  final VoidCallback onSwitchToFipe;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CnhhjTextField(
          controller: brandController,
          label: 'Marca',
          hint: 'Ex: Volkswagen',
          textInputAction: TextInputAction.next,
          validator: (String? v) =>
              (v == null || v.trim().isEmpty) ? 'Informe a marca' : null,
        ),
        const SizedBox(height: 12),
        CnhhjTextField(
          controller: modelController,
          label: 'Modelo',
          hint: 'Ex: Gol',
          textInputAction: TextInputAction.next,
          validator: (String? v) =>
              (v == null || v.trim().isEmpty) ? 'Informe o modelo' : null,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: CnhhjTextLink(
            label: 'Buscar no catálogo FIPE',
            onPressed: onSwitchToFipe,
          ),
        ),
      ],
    );
  }
}
