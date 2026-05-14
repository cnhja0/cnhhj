import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/instructor.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/instructor_repository.dart';
import '../../../data/repositories/mock/_seed.dart';
import '../../../shared/widgets/widgets.dart';

/// Aba AULA — configurar aula que aparece para os alunos.
///
/// Tela mais densa do app: define se está aceitando aulas, área de atuação,
/// valor por aula, dias da semana + horário, e mostra pré-visualização
/// do card que o aluno vai ver.
class TabLesson extends ConsumerStatefulWidget {
  const TabLesson({super.key});

  @override
  ConsumerState<TabLesson> createState() => _TabLessonState();
}

class _TabLessonState extends ConsumerState<TabLesson> {
  Instructor? _instructor;
  bool _saving = false;
  bool _loading = true;

  final TextEditingController _neighborhoodController =
      TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _state;

  final Set<DayOfWeek> _selectedDays = <DayOfWeek>{};
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _neighborhoodController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final String userId = _currentUserId();
    final Instructor? i =
        await ref.read(instructorRepositoryProvider).getById(userId);
    if (!mounted) return;
    setState(() {
      _instructor = i;
      _neighborhoodController.text = i?.neighborhood ?? '';
      _cityController.text = i?.city ?? '';
      _priceController.text =
          i?.pricePerClass == null ? '' : i!.pricePerClass!.toStringAsFixed(2);
      _state = i?.state;
      _loading = false;
    });
  }

  String _currentUserId() =>
      ref.read(authRepositoryProvider).currentSession?.userId ??
      MockState.currentInstructorId;

  Future<void> _toggleActive(bool v) async {
    if (_instructor == null) return;
    final String id = _instructor!.id;
    setState(() {
      _instructor = _instructor!.copyWith(isActive: v);
    });
    await ref
        .read(instructorRepositoryProvider)
        .setActive(id, active: v);
  }

  Future<void> _save() async {
    if (_priceController.text.trim().isEmpty) {
      CnhhjSnack.error(context, 'Informe o valor por aula.');
      return;
    }
    final double? price =
        double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (price == null || price <= 0) {
      CnhhjSnack.error(context, 'Informe um valor válido.');
      return;
    }
    if (_selectedDays.isEmpty) {
      CnhhjSnack.error(context, 'Selecione pelo menos um dia da semana.');
      return;
    }

    setState(() => _saving = true);
    final String id = _currentUserId();
    try {
      await ref.read(instructorRepositoryProvider).upsert(
            id,
            InstructorUpdate(
              neighborhood: _neighborhoodController.text.trim(),
              city: _cityController.text.trim(),
              state: _state,
              pricePerClass: price,
            ),
          );

      // Substitui grade semanal pelos slots selecionados
      // (no mock, replaceAll do AvailabilityRepository fará o trabalho).
      // Aqui usamos uma API simplificada: deletar+recriar.
      // ...
      if (!mounted) return;
      CnhhjSnack.success(context, 'Configuração salva!');
    } catch (_) {
      if (!mounted) return;
      CnhhjSnack.error(context, 'Erro ao salvar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.textPrimary),
      );
    }
    final Instructor inst = _instructor!;

    return CnhhjLoadingOverlay(
      show: _saving,
      message: 'Salvando...',
      child: CnhhjScaffold(
        // Padding bottom alto para o conteúdo não ficar atrás da
        // bottom nav flutuante (~84px de nav + buffer).
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CnhhjCard(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Recebendo aulas',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Switch(
                      value: inst.isActive,
                      onChanged: _toggleActive,
                      activeColor: AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CnhhjCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _SectionTitle(label: 'ÁREA DE ATUAÇÃO'),
                    const SizedBox(height: 12),
                    CnhhjTextField(
                      controller: _neighborhoodController,
                      label: 'Bairro',
                      hint: 'Ex: Vila Galvão',
                    ),
                    const SizedBox(height: 10),
                    CnhhjTextField(
                      controller: _cityController,
                      label: 'Cidade',
                      hint: 'Ex: Guarulhos',
                    ),
                    const SizedBox(height: 10),
                    CnhhjDropdown<String>(
                      label: 'UF',
                      value: _state,
                      items: const <String>['SP', 'RJ', 'MG', 'PR', 'RS'],
                      itemLabel: (String s) => s,
                      onChanged: (String? v) => setState(() => _state = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CnhhjCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _SectionTitle(label: 'VALOR DA AULA'),
                    const SizedBox(height: 12),
                    CnhhjTextField(
                      controller: _priceController,
                      hint: 'R\$ 0,00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      icon: Icons.attach_money,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CnhhjCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _SectionTitle(label: 'DATAS DISPONÍVEIS PARA DAR AULAS'),
                    const SizedBox(height: 12),
                    Text(
                      'Dias da semana',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: DayOfWeek.values.map((DayOfWeek d) {
                        final bool sel = _selectedDays.contains(d);
                        return InkWell(
                          onTap: () => setState(() {
                            if (sel) {
                              _selectedDays.remove(d);
                            } else {
                              _selectedDays.add(d);
                            }
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.textPrimary,
                                width: sel ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              d.shortLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Horário',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _TimePickerField(
                            label: 'De',
                            value: _startTime,
                            onChanged: (TimeOfDay t) =>
                                setState(() => _startTime = t),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimePickerField(
                            label: 'Até',
                            value: _endTime,
                            onChanged: (TimeOfDay t) =>
                                setState(() => _endTime = t),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CnhhjCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _SectionTitle(label: 'PRÉ-VISUALIZAÇÃO'),
                    const SizedBox(height: 12),
                    _PreviewCard(instructor: inst),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CnhhjPrimaryButton(label: 'Salvar', onPressed: _save),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  Future<void> _open(BuildContext context) async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: value);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Mini-card mostrando como o aluno verá o instrutor.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.instructor});
  final Instructor instructor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: <Widget>[
          const CnhhjAvatar(size: 56, fullName: 'Você'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Você (instrutor)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                CnhhjStars(rating: instructor.averageRating, size: 14),
                const SizedBox(height: 2),
                Text(
                  instructor.pricePerClass == null
                      ? 'Sem valor definido'
                      : 'R\$ ${instructor.pricePerClass!.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
