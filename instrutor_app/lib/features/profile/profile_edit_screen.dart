import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/services/fipe_providers.dart';
import '../../core/services/fipe_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/enums.dart';
import '../../data/models/instructor.dart';
import '../../data/models/profile.dart';
import '../../data/providers.dart';
import '../../data/repositories/mock/_seed.dart';
import '../../shared/widgets/widgets.dart';
import 'profile_edit_controller.dart';

/// Tela de edição do perfil do instrutor.
///
/// Seções:
///   • Avatar (editável)
///   • Identidade (nome / CPF / data nasc. / sexo) — **somente leitura**.
///     Definidos no cadastro inicial e não podem ser alterados pelo app
///     (integridade dos documentos enviados ao DETRAN).
///   • Contato (celular) — editável.
///   • Sobre você (bio) — editável.
///   • Veículo — editável, com cooldown de 7 dias entre mudanças
///     (anti-fraude: evita instrutor cadastrar 5 carros em 5 dias).
///
/// Os dados do veículo aparecem para o aluno na vitrine.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() =>
      _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  // ─── Form ──────────────────────────────────────────────────────────
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // ─── Identidade (somente leitura — vem do cadastro) ───────────────
  String _fullName = '';
  String? _cpf;
  DateTime? _birthDate;
  Gender? _gender;

  // ─── Avatar (editável) ────────────────────────────────────────────
  File? _newAvatar;
  String? _currentAvatarUrl;

  // ─── Veículo ───────────────────────────────────────────────────────
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  VehicleType? _vehicleType;
  Transmission? _transmission;

  // FIPE state — preenchidos quando o usuário escolhe via picker
  String? _selectedBrandCode;
  String? _selectedBrandName;
  String? _selectedModelName;
  bool _vehicleManualMode = false;

  // Fotos do veículo
  File? _newVehicleFrontPhoto;
  File? _newVehicleBackPhoto;
  String? _currentVehicleFrontUrl;
  String? _currentVehicleBackUrl;

  // Snapshot do instructor original. Usado para decidir se o usuário
  // tocou em algum campo de veículo — só validamos "veículo completo"
  // se houve mudança real, evitando bloquear quem só quer editar foto.
  Instructor? _originalInstructor;

  bool _loading = true;
  bool _dirty = false;

  final MaskTextInputFormatter _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: <String, RegExp>{'#': RegExp(r'[0-9]')},
  );
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _phoneController.addListener(_markDirty);
    _bioController.addListener(_markDirty);
    _brandController.addListener(_markDirty);
    _modelController.addListener(_markDirty);
    _yearController.addListener(_markDirty);
    _plateController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _bioController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _markDirty() {
    // _load() popula os controllers e dispara estes listeners. Guarda
    // contra marcar dirty antes do load terminar.
    if (_loading || _dirty) return;
    setState(() => _dirty = true);
  }

  Future<void> _load() async {
    final String userId =
        ref.read(authRepositoryProvider).currentSession?.userId ??
            MockState.currentInstructorId;

    try {
      final Profile profile =
          await ref.read(authRepositoryProvider).currentProfile();
      final Instructor? instructor =
          await ref.read(instructorRepositoryProvider).getById(userId);
      if (!mounted) return;
      setState(() {
        _originalInstructor = instructor;
        // Identidade — só pra display.
        _fullName = profile.fullName;
        _cpf = profile.cpf;
        _birthDate = profile.birthDate;
        _gender = profile.gender;
        _currentAvatarUrl = profile.avatarUrl;
        // Editáveis.
        _phoneController.text = profile.phone ?? '';
        _bioController.text = instructor?.bio ?? '';

        // Veículo — já cadastrado no onboarding, então pré-popula tudo.
        _vehicleType = instructor?.vehicleType;
        _transmission = instructor?.vehicleTransmission;
        _brandController.text = instructor?.vehicleBrand ?? '';
        _modelController.text = instructor?.vehicleModel ?? '';
        _selectedBrandName = instructor?.vehicleBrand;
        _selectedModelName = instructor?.vehicleModel;
        _yearController.text = instructor?.vehicleYear?.toString() ?? '';
        _plateController.text = instructor?.vehiclePlate ?? '';
        _currentVehicleFrontUrl = instructor?.vehiclePhotoFrontUrl;
        _currentVehicleBackUrl = instructor?.vehiclePhotoBackUrl;

        // UX: quem já tem veículo cadastrado vê os campos como texto
        // editável (modo manual). O picker FIPE não consegue marcar o
        // brand "selecionado" sem ter o código da FIPE (que não guardamos).
        // Se o usuário quiser trocar, clica em "Buscar no catálogo FIPE".
        _vehicleManualMode = instructor?.vehicleBrand?.isNotEmpty == true;

        _loading = false;
        _dirty = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ─── Cooldown de veículo ───────────────────────────────────────────
  static const Duration _vehicleCooldown = Duration(days: 7);

  /// Quanto falta para o instrutor poder mudar o veículo de novo.
  /// `Duration.zero` (ou negativo) = já pode mudar.
  Duration get _vehicleCooldownRemaining {
    final DateTime? last = _originalInstructor?.vehicleLastChangedAt;
    if (last == null) return Duration.zero;
    final Duration elapsed = DateTime.now().difference(last);
    final Duration left = _vehicleCooldown - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  bool get _vehicleLocked => _vehicleCooldownRemaining > Duration.zero;

  String get _cooldownLabel {
    final Duration d = _vehicleCooldownRemaining;
    final int days = d.inDays;
    if (days > 0) return '$days ${days == 1 ? "dia" : "dias"}';
    final int hours = d.inHours;
    if (hours > 0) return '$hours ${hours == 1 ? "hora" : "horas"}';
    final int minutes = d.inMinutes;
    return '$minutes min';
  }

  // ─── Foto de perfil ────────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final _PickOutcome outcome = await _pickImage(canRemove: _hasAvatar());
    switch (outcome.kind) {
      case _PickKind.cancelled:
        return;
      case _PickKind.removed:
        setState(() {
          _newAvatar = null;
          _currentAvatarUrl = null;
          _dirty = true;
        });
        return;
      case _PickKind.picked:
        setState(() {
          _newAvatar = outcome.file;
          _dirty = true;
        });
        return;
    }
  }

  bool _hasAvatar() => _newAvatar != null || _currentAvatarUrl != null;

  Future<_PickOutcome> _pickImage({bool canRemove = false}) async {
    final ImagePicker picker = ImagePicker();
    final _SheetAction? action = await showModalBottomSheet<_SheetAction>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(PhosphorIconsRegular.camera),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.of(ctx).pop(_SheetAction.camera),
            ),
            ListTile(
              leading: const Icon(PhosphorIconsRegular.image),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.of(ctx).pop(_SheetAction.gallery),
            ),
            if (canRemove)
              ListTile(
                leading: const Icon(
                  PhosphorIconsRegular.trash,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Remover foto',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => Navigator.of(ctx).pop(_SheetAction.remove),
              ),
          ],
        ),
      ),
    );

    if (action == null) return const _PickOutcome.cancelled();
    if (action == _SheetAction.remove) return const _PickOutcome.removed();

    final ImageSource source = action == _SheetAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return const _PickOutcome.cancelled();
    return _PickOutcome.picked(File(picked.path));
  }

  Future<void> _pickVehiclePhoto({required bool front}) async {
    final _PickOutcome outcome = await _pickImage();
    if (outcome.kind != _PickKind.picked) return;
    setState(() {
      if (front) {
        _newVehicleFrontPhoto = outcome.file;
      } else {
        _newVehicleBackPhoto = outcome.file;
      }
      _dirty = true;
    });
  }

  // ─── Save ──────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final String userId =
        ref.read(authRepositoryProvider).currentSession?.userId ??
            MockState.currentInstructorId;

    final String brand =
        (_vehicleManualMode ? _brandController.text : _selectedBrandName ?? '')
            .trim();
    final String model =
        (_vehicleManualMode ? _modelController.text : _selectedModelName ?? '')
            .trim();
    final String plate = _plateController.text.trim();
    final String yearStr = _yearController.text.trim();
    final int? parsedYear = int.tryParse(yearStr);

    // Validação half-vehicle: só dispara se o usuário REALMENTE mexeu em
    // algum campo de veículo. Comparamos com o snapshot original — se nada
    // mudou e o original já estava incompleto, não bloqueia (deixa migrar
    // o estado existente).
    final Instructor? orig = _originalInstructor;
    final bool vehicleChanged = orig == null
        ? (_vehicleType != null ||
            brand.isNotEmpty ||
            model.isNotEmpty ||
            yearStr.isNotEmpty ||
            plate.isNotEmpty ||
            _transmission != null)
        : (_vehicleType != orig.vehicleType ||
            brand != (orig.vehicleBrand ?? '') ||
            model != (orig.vehicleModel ?? '') ||
            parsedYear != orig.vehicleYear ||
            _transmission != orig.vehicleTransmission ||
            Validators.normalizePlate(plate) !=
                (orig.vehiclePlate == null
                    ? ''
                    : Validators.normalizePlate(orig.vehiclePlate!)));

    // Mudança de foto do veículo também conta como alteração de veículo
    // (sujeito ao cooldown).
    final bool vehiclePhotoChanged =
        _newVehicleFrontPhoto != null || _newVehicleBackPhoto != null;
    final bool anyVehicleChange = vehicleChanged || vehiclePhotoChanged;

    if (anyVehicleChange && _vehicleLocked) {
      CnhhjSnack.error(
        context,
        'Você pode alterar o veículo a cada 7 dias. '
        'Próxima alteração em $_cooldownLabel.',
      );
      return;
    }

    if (vehicleChanged) {
      final List<String> missing = <String>[
        if (_vehicleType == null) 'tipo',
        if (brand.isEmpty) 'marca',
        if (model.isEmpty) 'modelo',
        if (parsedYear == null) 'ano',
        if (_transmission == null) 'transmissão',
        if (plate.isEmpty) 'placa',
      ];
      if (missing.isNotEmpty) {
        CnhhjSnack.error(
          context,
          'Veículo incompleto. Falta: ${missing.join(", ")}.',
        );
        return;
      }
      final String? plateErr = Validators.plate(plate);
      if (plateErr != null) {
        CnhhjSnack.error(context, 'Placa: $plateErr');
        return;
      }
      final String? yearErr = Validators.vehicleYear(yearStr);
      if (yearErr != null) {
        CnhhjSnack.error(context, 'Ano: $yearErr');
        return;
      }
    }

    final bool ok = await ref
        .read(profileEditControllerProvider.notifier)
        .save(
          userId: userId,
          // Identidade é imutável após cadastro — passa o valor original
          // para o controller (que ainda exige fullName não-nulo). cpf/
          // birthDate/gender NÃO vão; o repo preserva os existentes.
          fullName: _fullName,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          avatarUrl: _newAvatar?.path ?? _currentAvatarUrl,
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          vehicleType: _vehicleType,
          vehicleBrand: brand.isEmpty ? null : brand,
          vehicleModel: model.isEmpty ? null : model,
          vehicleYear: int.tryParse(yearStr),
          vehicleTransmission: _transmission,
          vehiclePlate: plate.isEmpty ? null : Validators.normalizePlate(plate),
          vehicleChanged: anyVehicleChange,
          vehiclePhotoFrontUrl:
              _newVehicleFrontPhoto?.path ?? _currentVehicleFrontUrl,
          vehiclePhotoBackUrl:
              _newVehicleBackPhoto?.path ?? _currentVehicleBackUrl,
        );

    if (!mounted) return;
    if (ok) {
      setState(() => _dirty = false);
      CnhhjSnack.success(context, 'Perfil atualizado!');
      context.pop();
    } else {
      final String? err =
          ref.read(profileEditControllerProvider).errorMessage;
      if (err != null) CnhhjSnack.error(context, err);
    }
  }

  Future<void> _confirmExit() async {
    if (!_dirty) {
      context.pop();
      return;
    }
    final bool? leave = await showCnhhjModal<bool>(
      context: context,
      icon: PhosphorIconsRegular.warning,
      title: 'Sair sem salvar?',
      message: 'Você tem alterações que ainda não foram salvas.',
      primaryLabel: 'Descartar',
      onPrimary: () => Navigator.of(context).pop(true),
      secondaryLabel: 'Cancelar',
      onSecondary: () => Navigator.of(context).pop(false),
    );
    if (leave == true && mounted) context.pop();
  }

  /// Tipo FIPE — moto vs carro. 'ambos' assume carro (instrutor edita
  /// uma frota só aqui no MVP).
  VehicleType get _fipeType {
    return _vehicleType == VehicleType.moto
        ? VehicleType.moto
        : VehicleType.carro;
  }

  @override
  Widget build(BuildContext context) {
    final ProfileEditState state =
        ref.watch(profileEditControllerProvider);

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          title: const Text('Editar perfil'),
          leading: IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.textPrimary),
        ),
      );
    }

    return CnhhjLoadingOverlay(
      show: state.saving,
      message: 'Salvando perfil...',
      child: PopScope(
        canPop: !_dirty,
        onPopInvokedWithResult: (bool didPop, _) {
          if (didPop) return;
          _confirmExit();
        },
        child: Scaffold(
          backgroundColor: AppColors.primary,
          appBar: AppBar(
            title: const Text('Editar perfil'),
            leading: IconButton(
              icon: const Icon(PhosphorIconsRegular.arrowLeft),
              onPressed: _confirmExit,
            ),
            actions: <Widget>[
              if (_dirty)
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'NÃO SALVO',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.surface,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _AvatarEditor(
                              file: _newAvatar,
                              currentUrl: _currentAvatarUrl,
                              name: _fullName,
                              onTap: _pickAvatar,
                            )
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .slideY(
                                  begin: -0.1,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),
                            const SizedBox(height: 16),
                            _Section(
                              title: 'Identidade · não editável',
                              child: _IdentityCard(
                                fullName: _fullName,
                                cpf: _cpf,
                                birthDate: _birthDate,
                                gender: _gender,
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 100.ms, duration: 350.ms)
                                .slideY(
                                  begin: 0.05,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),
                            const SizedBox(height: 12),
                            _Section(
                              title: 'Contato',
                              child: CnhhjTextField(
                                controller: _phoneController,
                                label: 'Celular',
                                hint: '(11) 91234-5678',
                                icon: PhosphorIconsRegular.phone,
                                keyboardType: TextInputType.phone,
                                inputFormatters:
                                    <TextInputFormatter>[_phoneMask],
                                textInputAction: TextInputAction.next,
                                validator: (String? v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? null
                                        : Validators.mobilePhone(v),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 350.ms)
                                .slideY(
                                  begin: 0.05,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),
                            const SizedBox(height: 12),
                            _Section(
                              title: 'Sobre você',
                              child: CnhhjTextField(
                                controller: _bioController,
                                label: 'Bio profissional',
                                hint:
                                    'Conte um pouco sobre você. Ex: anos de experiência, especialidade...',
                                maxLength: 280,
                                maxLines: 4,
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 300.ms, duration: 350.ms)
                                .slideY(
                                  begin: 0.05,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),
                            const SizedBox(height: 12),
                            _Section(
                              title: 'Veículo · visível para o aluno',
                              child: _VehicleSection(
                                locked: _vehicleLocked,
                                cooldownLabel: _cooldownLabel,
                                fipeType: _fipeType,
                                vehicleType: _vehicleType,
                                onVehicleTypeChanged: (VehicleType? t) =>
                                    setState(() {
                                  _vehicleType = t;
                                  // Trocar tipo → marca/modelo carro são
                                  // diferentes dos de moto. Invalida tudo,
                                  // inclusive os campos de modo manual.
                                  _selectedBrandCode = null;
                                  _selectedBrandName = null;
                                  _selectedModelName = null;
                                  _brandController.clear();
                                  _modelController.clear();
                                  _dirty = true;
                                }),
                                manualMode: _vehicleManualMode,
                                onToggleManual: (bool v) => setState(() {
                                  _vehicleManualMode = v;
                                  if (v) {
                                    _brandController.text =
                                        _selectedBrandName ?? '';
                                    _modelController.text =
                                        _selectedModelName ?? '';
                                  }
                                }),
                                brandController: _brandController,
                                modelController: _modelController,
                                yearController: _yearController,
                                plateController: _plateController,
                                plateMask: _plateMask,
                                transmission: _transmission,
                                onTransmissionChanged: (Transmission? t) =>
                                    setState(() {
                                  _transmission = t;
                                  _dirty = true;
                                }),
                                selectedBrandCode: _selectedBrandCode,
                                selectedBrandName: _selectedBrandName,
                                selectedModelName: _selectedModelName,
                                onBrandPicked: (FipeItem b) => setState(() {
                                  _selectedBrandCode = b.code;
                                  _selectedBrandName = b.name;
                                  _selectedModelName = null;
                                  _dirty = true;
                                }),
                                onModelPicked: (FipeItem m) => setState(() {
                                  _selectedModelName = m.name;
                                  _dirty = true;
                                }),
                                frontPhoto: _newVehicleFrontPhoto,
                                frontPhotoUrl: _currentVehicleFrontUrl,
                                backPhoto: _newVehicleBackPhoto,
                                backPhotoUrl: _currentVehicleBackUrl,
                                onPickFront: () =>
                                    _pickVehiclePhoto(front: true),
                                onPickBack: () =>
                                    _pickVehiclePhoto(front: false),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 400.ms, duration: 350.ms)
                                .slideY(
                                  begin: 0.05,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: CnhhjSecondaryButton(
                            label: 'Cancelar',
                            onPressed: _confirmExit,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CnhhjPrimaryButton(
                            label: 'Salvar',
                            icon: PhosphorIconsRegular.check,
                            onPressed: _dirty ? _save : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Editor de Avatar (com botão de câmera sobreposto) ──────────────
class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({
    required this.file,
    required this.currentUrl,
    required this.name,
    required this.onTap,
  });

  final File? file;
  final String? currentUrl;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textPrimary, width: 3),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: file != null
                  ? Image.file(file!, fit: BoxFit.cover)
                  : CnhhjAvatar(
                      size: 120,
                      fullName: name,
                      imageUrl: currentUrl,
                    ),
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Material(
              color: AppColors.textPrimary,
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.primary, width: 3),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    PhosphorIconsFill.camera,
                    color: AppColors.surface,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Seção (card com título) ────────────────────────────────────────
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CnhhjCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Seção de veículo (FIPE + dados) ─────────────────────────────────
class _VehicleSection extends ConsumerWidget {
  const _VehicleSection({
    required this.locked,
    required this.cooldownLabel,
    required this.fipeType,
    required this.vehicleType,
    required this.onVehicleTypeChanged,
    required this.manualMode,
    required this.onToggleManual,
    required this.brandController,
    required this.modelController,
    required this.yearController,
    required this.plateController,
    required this.plateMask,
    required this.transmission,
    required this.onTransmissionChanged,
    required this.selectedBrandCode,
    required this.selectedBrandName,
    required this.selectedModelName,
    required this.onBrandPicked,
    required this.onModelPicked,
    required this.frontPhoto,
    required this.frontPhotoUrl,
    required this.backPhoto,
    required this.backPhotoUrl,
    required this.onPickFront,
    required this.onPickBack,
  });

  /// `true` quando a última alteração foi há menos de 7 dias.
  /// Bloqueia toda a seção e mostra um banner com o countdown.
  final bool locked;
  final String cooldownLabel;
  final VehicleType fipeType;
  final VehicleType? vehicleType;
  final ValueChanged<VehicleType?> onVehicleTypeChanged;
  final bool manualMode;
  final ValueChanged<bool> onToggleManual;

  final TextEditingController brandController;
  final TextEditingController modelController;
  final TextEditingController yearController;
  final TextEditingController plateController;
  final MaskTextInputFormatter plateMask;

  final Transmission? transmission;
  final ValueChanged<Transmission?> onTransmissionChanged;

  final String? selectedBrandCode;
  final String? selectedBrandName;
  final String? selectedModelName;
  final ValueChanged<FipeItem> onBrandPicked;
  final ValueChanged<FipeItem> onModelPicked;

  final File? frontPhoto;
  final String? frontPhotoUrl;
  final File? backPhoto;
  final String? backPhotoUrl;
  final VoidCallback onPickFront;
  final VoidCallback onPickBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (locked) _CooldownBanner(label: cooldownLabel),
        if (locked) const SizedBox(height: 12),
        // AbsorbPointer + Opacity: bloqueia interação sem destruir o
        // layout. O save também rejeita do lado da UI (snack explicativo).
        AbsorbPointer(
          absorbing: locked,
          child: Opacity(
            opacity: locked ? 0.55 : 1.0,
            child: _vehicleFields(),
          ),
        ),
      ],
    );
  }

  Widget _vehicleFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CnhhjDropdown<VehicleType>(
          label: 'Tipo',
          value: vehicleType,
          items: VehicleType.values,
          itemLabel: (VehicleType t) => t.label,
          onChanged: onVehicleTypeChanged,
        ),
        const SizedBox(height: 12),
        if (manualMode)
          _ManualBrandModel(
            brandController: brandController,
            modelController: modelController,
            onSwitchToFipe: () => onToggleManual(false),
          )
        else
          _FipeBrandModel(
            type: fipeType,
            selectedBrandCode: selectedBrandCode,
            selectedBrandName: selectedBrandName,
            selectedModelName: selectedModelName,
            onBrandPicked: onBrandPicked,
            onModelPicked: onModelPicked,
            onSwitchToManual: () => onToggleManual(true),
          ),
        const SizedBox(height: 12),
        CnhhjTextField(
          controller: yearController,
          label: 'Ano',
          hint: 'Ex: 2022',
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          textInputAction: TextInputAction.next,
          validator: (String? v) => (v == null || v.trim().isEmpty)
              ? null
              : Validators.vehicleYear(v),
        ),
        const SizedBox(height: 12),
        CnhhjDropdown<Transmission>(
          label: 'Transmissão',
          value: transmission,
          items: Transmission.values,
          itemLabel: (Transmission t) => t.label,
          onChanged: onTransmissionChanged,
        ),
        const SizedBox(height: 12),
        CnhhjTextField(
          controller: plateController,
          label: 'Placa',
          hint: 'AAA-0000 ou AAA-0A00',
          inputFormatters: <TextInputFormatter>[plateMask],
          textInputAction: TextInputAction.done,
          validator: (String? v) => (v == null || v.trim().isEmpty)
              ? null
              : Validators.plate(v),
        ),
        const SizedBox(height: 14),
        Text(
          'Fotos do veículo',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: _VehiclePhotoTile(
                label: 'Frente',
                file: frontPhoto,
                url: frontPhotoUrl,
                onTap: onPickFront,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _VehiclePhotoTile(
                label: 'Traseira',
                file: backPhoto,
                url: backPhotoUrl,
                onTap: onPickBack,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FipeBrandModel extends ConsumerWidget {
  const _FipeBrandModel({
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
                  onSelected: (PickerItem<FipeItem> p) =>
                      onModelPicked(p.value),
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

class _ManualBrandModel extends StatelessWidget {
  const _ManualBrandModel({
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
        ),
        const SizedBox(height: 12),
        CnhhjTextField(
          controller: modelController,
          label: 'Modelo',
          hint: 'Ex: Gol',
          textInputAction: TextInputAction.next,
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

class _VehiclePhotoTile extends StatelessWidget {
  const _VehiclePhotoTile({
    required this.label,
    required this.file,
    required this.url,
    required this.onTap,
  });

  final String label;
  final File? file;
  final String? url;
  final VoidCallback onTap;

  bool get _hasImage => file != null || (url != null && url!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.textPrimary.withOpacity(0.15),
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (_hasImage)
              file != null
                  ? Image.file(file!, fit: BoxFit.cover)
                  : Image.network(
                      url!,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (BuildContext c, Object e, StackTrace? s) =>
                              const _PhotoPlaceholder(),
                    )
            else
              const _PhotoPlaceholder(),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.surface,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsFill.camera,
                  size: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            PhosphorIconsRegular.car,
            size: 32,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Adicionar',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Resultado do bottom sheet de imagem ────────────────────────────
enum _SheetAction { camera, gallery, remove }
enum _PickKind { cancelled, picked, removed }

class _PickOutcome {
  const _PickOutcome.cancelled()
      : kind = _PickKind.cancelled,
        file = null;
  const _PickOutcome.removed()
      : kind = _PickKind.removed,
        file = null;
  const _PickOutcome.picked(File this.file) : kind = _PickKind.picked;

  final _PickKind kind;
  final File? file;
}

// ─── Identidade somente-leitura ─────────────────────────────────────
/// Card que mostra nome, CPF, data de nascimento e sexo do instrutor sem
/// permitir edição. Esses dados vêm do cadastro inicial e são imutáveis
/// pelo app (integridade dos documentos enviados ao DETRAN).
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.fullName,
    required this.cpf,
    required this.birthDate,
    required this.gender,
  });

  final String fullName;
  final String? cpf;
  final DateTime? birthDate;
  final Gender? gender;

  String? get _birthDateLabel {
    if (birthDate == null) return null;
    final String d = birthDate!.day.toString().padLeft(2, '0');
    final String m = birthDate!.month.toString().padLeft(2, '0');
    return '$d/$m/${birthDate!.year}';
  }

  @override
  Widget build(BuildContext context) {
    final List<({String label, String? value, IconData icon})> rows =
        <({String label, String? value, IconData icon})>[
      (
        label: 'Nome completo',
        value: fullName.isEmpty ? null : fullName,
        icon: PhosphorIconsRegular.user,
      ),
      (
        label: 'CPF',
        value: cpf,
        icon: PhosphorIconsRegular.identificationCard,
      ),
      (
        label: 'Data de nascimento',
        value: _birthDateLabel,
        icon: PhosphorIconsRegular.calendar,
      ),
      (
        label: 'Sexo',
        value: gender?.label,
        icon: PhosphorIconsRegular.userCircle,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < rows.length; i++) ...<Widget>[
          if (i > 0)
            Divider(
              height: 1,
              color: AppColors.textPrimary.withOpacity(0.08),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: <Widget>[
                Icon(
                  rows[i].icon,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        rows[i].label,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rows[i].value ?? '—',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  PhosphorIconsRegular.lockSimple,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Banner de cooldown ─────────────────────────────────────────────
/// Avisa que a próxima alteração no veículo só poderá ocorrer após X dias.
class _CooldownBanner extends StatelessWidget {
  const _CooldownBanner({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            PhosphorIconsFill.hourglassMedium,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
                children: <InlineSpan>[
                  const TextSpan(
                    text: 'Veículo bloqueado para edição.\n',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: 'Você pode alterar os dados a cada 7 dias. '
                        'Próxima alteração disponível em ',
                  ),
                  TextSpan(
                    text: label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
