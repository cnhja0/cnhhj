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

import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';
import '../../data/models/instructor.dart';
import '../../data/models/profile.dart';
import '../../data/providers.dart';
import '../../data/repositories/mock/_seed.dart';
import '../../shared/widgets/widgets.dart';
import 'profile_edit_controller.dart';

/// Tela de edição do perfil do instrutor.
///
/// Permite editar foto, nome, CPF, data de nascimento, sexo, telefone e
/// bio profissional. Salva via [profileEditControllerProvider].
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() =>
      _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  // Form
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  DateTime? _birthDate;
  Gender? _gender;
  File? _newAvatar; // foto recém-selecionada (ainda não persistida)
  String? _currentAvatarUrl; // foto que já está salva

  bool _loading = true;
  bool _dirty = false; // marca se há alterações não salvas

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _nameController.addListener(_markDirty);
    _cpfController.addListener(_markDirty);
    _phoneController.addListener(_markDirty);
    _bioController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
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
        _nameController.text = profile.fullName;
        _cpfController.text = profile.cpf ?? '';
        _phoneController.text = profile.phone ?? '';
        _bioController.text = instructor?.bio ?? '';
        _birthDate = profile.birthDate;
        _gender = profile.gender;
        _currentAvatarUrl = profile.avatarUrl;
        _loading = false;
        _dirty = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _pickPhoto() async {
    final ImagePicker picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource?>(
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
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(PhosphorIconsRegular.image),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            if (_newAvatar != null || _currentAvatarUrl != null)
              ListTile(
                leading: const Icon(
                  PhosphorIconsRegular.trash,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Remover foto',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _newAvatar = null;
                    _currentAvatarUrl = null;
                    _dirty = true;
                  });
                },
              ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final XFile? picked =
        await picker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _newAvatar = File(picked.path);
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      CnhhjSnack.error(context, 'Informe sua data de nascimento.');
      return;
    }

    final String userId =
        ref.read(authRepositoryProvider).currentSession?.userId ??
            MockState.currentInstructorId;

    final bool ok = await ref
        .read(profileEditControllerProvider.notifier)
        .save(
          userId: userId,
          fullName: _nameController.text.trim(),
          cpf: _cpfController.text.trim().isEmpty
              ? null
              : _cpfController.text.trim(),
          birthDate: _birthDate,
          gender: _gender,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          avatarUrl: _newAvatar?.path ?? _currentAvatarUrl,
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
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
                              name: _nameController.text,
                              onTap: _pickPhoto,
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
                              title: 'Dados pessoais',
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  CnhhjTextField(
                                    controller: _nameController,
                                    label: 'Nome completo',
                                    icon: PhosphorIconsRegular.user,
                                    textInputAction: TextInputAction.next,
                                    validator: (String? v) =>
                                        (v == null || v.trim().length < 3)
                                            ? 'Informe seu nome completo'
                                            : null,
                                  ),
                                  const SizedBox(height: 10),
                                  CnhhjTextField(
                                    controller: _cpfController,
                                    label: 'CPF',
                                    hint: '000.000.000-00',
                                    icon: PhosphorIconsRegular.identificationCard,
                                    keyboardType: TextInputType.number,
                                    inputFormatters:
                                        <TextInputFormatter>[_cpfMask],
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 10),
                                  CnhhjDateField(
                                    label: 'Data de nascimento',
                                    initialDate: _birthDate,
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now().subtract(
                                        const Duration(days: 365 * 18)),
                                    onChanged: (DateTime d) => setState(() {
                                      _birthDate = d;
                                      _dirty = true;
                                    }),
                                  ),
                                  const SizedBox(height: 10),
                                  CnhhjDropdown<Gender>(
                                    label: 'Sexo',
                                    value: _gender,
                                    items: Gender.values,
                                    itemLabel: (Gender g) => g.label,
                                    onChanged: (Gender? g) => setState(() {
                                      _gender = g;
                                      _dirty = true;
                                    }),
                                  ),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(
                                  delay: 100.ms,
                                  duration: 350.ms,
                                )
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
                                label: 'Telefone',
                                hint: '(11) 91234-5678',
                                icon: PhosphorIconsRegular.phone,
                                keyboardType: TextInputType.phone,
                                inputFormatters:
                                    <TextInputFormatter>[_phoneMask],
                                textInputAction: TextInputAction.next,
                              ),
                            )
                                .animate()
                                .fadeIn(
                                  delay: 200.ms,
                                  duration: 350.ms,
                                )
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
                                .fadeIn(
                                  delay: 300.ms,
                                  duration: 350.ms,
                                )
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
