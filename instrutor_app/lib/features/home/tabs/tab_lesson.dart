import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/instructor.dart';
import '../../../data/models/weekly_availability.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/instructor_repository.dart';
import '../../../shared/widgets/widgets.dart';
import '../home_providers.dart';

/// Aba AULA — configurar a oferta que aparece para os alunos.
///
/// Switch "Recebendo aulas", área de atuação, valor, dias/horários,
/// e pré-visualização do card que o aluno verá. A pré-visualização
/// e o switch são reativos — atualizam ao vivo enquanto o usuário edita.
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
    // Refresh local _instructor on every keystroke so the preview reflects
    // o valor digitado mesmo sem salvar.
    _priceController.addListener(() => setState(() {}));
    _neighborhoodController.addListener(() => setState(() {}));
    _cityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _neighborhoodController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final String userId = ref.read(currentUserIdProvider);
    final Instructor? i =
        await ref.read(instructorRepositoryProvider).getById(userId);
    // L2: carrega disponibilidade semanal salva. Sem isso, ao reabrir a
    // aba o instrutor sempre via "Dom-Sáb vazios" e parecia que tinha
    // perdido a configuração.
    final List<WeeklyAvailability> slots = await ref
        .read(availabilityRepositoryProvider)
        .listForInstructor(userId);
    if (!mounted) return;
    setState(() {
      _instructor = i;
      _neighborhoodController.text = i?.neighborhood ?? '';
      _cityController.text = i?.city ?? '';
      _priceController.text =
          i?.pricePerClass == null ? '' : i!.pricePerClass!.toStringAsFixed(2);
      _state = i?.state;
      _selectedDays
        ..clear()
        ..addAll(slots.map((WeeklyAvailability s) => s.dayOfWeek));
      // Se já há slots salvos, usa o startTime/endTime do primeiro como
      // janela default (MVP: janela única por dia, mesma para todos os
      // dias selecionados).
      if (slots.isNotEmpty) {
        _startTime = slots.first.startTime;
        _endTime = slots.first.endTime;
      }
      _loading = false;
    });
  }

  Future<void> _toggleActive(bool v) async {
    if (_instructor == null) return;
    final String id = _instructor!.id;
    setState(() {
      _instructor = _instructor!.copyWith(isActive: v);
    });
    await ref.read(instructorRepositoryProvider).setActive(id, active: v);
    // Avisa outras abas (Home dashboard) que o instructor mudou.
    ref.invalidate(currentInstructorProvider);
  }

  Future<void> _save() async {
    // L3: valida UF/cidade/bairro antes de tudo. Sem endereço, o aluno
    // não consegue filtrar por região na vitrine.
    final String neighborhood = _neighborhoodController.text.trim();
    final String city = _cityController.text.trim();
    if (_state == null) {
      CnhhjSnack.error(context, 'Selecione a UF.');
      return;
    }
    if (city.length < 2) {
      CnhhjSnack.error(context, 'Informe a cidade.');
      return;
    }
    if (neighborhood.length < 2) {
      CnhhjSnack.error(context, 'Informe o bairro.');
      return;
    }
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
    // Janela horária — startTime tem que ser ANTES de endTime, senão a
    // grade gerada vira intervalos vazios.
    final double startMin = _startTime.hour * 60.0 + _startTime.minute;
    final double endMin = _endTime.hour * 60.0 + _endTime.minute;
    if (endMin <= startMin) {
      CnhhjSnack.error(context, 'O horário "Até" deve ser após "De".');
      return;
    }

    setState(() => _saving = true);
    final String id = ref.read(currentUserIdProvider);
    try {
      // 1) Dados do instrutor (endereço + preço).
      final Instructor updated =
          await ref.read(instructorRepositoryProvider).upsert(
                id,
                InstructorUpdate(
                  neighborhood: neighborhood,
                  city: city,
                  state: _state,
                  pricePerClass: price,
                ),
              );

      // 2) L1: grade semanal — substitui tudo pelo conjunto atual.
      // No MVP é uma janela única por dia, replicada nos dias selecionados.
      final DateTime now = DateTime.now();
      final List<WeeklyAvailability> slots = _selectedDays.map((DayOfWeek d) {
        return WeeklyAvailability(
          id: 'avail-${now.microsecondsSinceEpoch}-${d.value}',
          instructorId: id,
          dayOfWeek: d,
          startTime: _startTime,
          endTime: _endTime,
          createdAt: now,
        );
      }).toList(growable: false);
      await ref
          .read(availabilityRepositoryProvider)
          .replaceAll(id, slots);

      ref.invalidate(currentInstructorProvider);
      if (!mounted) return;
      setState(() => _instructor = updated);
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
    final double? livePrice =
        double.tryParse(_priceController.text.replaceAll(',', '.'));

    return CnhhjLoadingOverlay(
      show: _saving,
      message: 'Salvando...',
      child: CnhhjScaffold(
        // Padding bottom pequeno — gap mínimo entre conteúdo e navbar.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const TabHeader(
                title: 'Configurar aula',
                subtitle: 'Defina disponibilidade, valor e área de atuação',
              ),
              const SizedBox(height: 14),
              CnhhjCard(
                child: Row(
                  children: <Widget>[
                    Icon(
                      inst.isActive
                          ? PhosphorIconsFill.toggleRight
                          : PhosphorIconsRegular.toggleLeft,
                      color: inst.isActive
                          ? AppColors.success
                          : AppColors.textMuted,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Recebendo aulas',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            inst.isActive
                                ? 'Você aparece para os alunos'
                                : 'Sua oferta está pausada',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
                    const _SectionTitle(label: 'ÁREA DE ATUAÇÃO'),
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
                    const _SectionTitle(label: 'VALOR DA AULA'),
                    const SizedBox(height: 12),
                    CnhhjTextField(
                      controller: _priceController,
                      hint: 'R\$ 0,00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      icon: PhosphorIconsRegular.currencyDollar,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CnhhjCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const _SectionTitle(
                        label: 'DATAS DISPONÍVEIS PARA DAR AULAS'),
                    const SizedBox(height: 12),
                    Text(
                      'Dias da semana',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.surface,
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
                                fontWeight: FontWeight.w800,
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
                        fontWeight: FontWeight.w700,
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
                    const _SectionTitle(label: 'PRÉ-VISUALIZAÇÃO'),
                    const SizedBox(height: 12),
                    _PreviewCard(
                      instructor: inst,
                      livePrice: livePrice,
                      liveNeighborhood:
                          _neighborhoodController.text.trim().isEmpty
                              ? null
                              : _neighborhoodController.text.trim(),
                      liveCity: _cityController.text.trim().isEmpty
                          ? null
                          : _cityController.text.trim(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CnhhjPrimaryButton(
                label: 'Salvar',
                icon: PhosphorIconsRegular.check,
                onPressed: _save,
              ),
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
        fontSize: 11,
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
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  PhosphorIconsRegular.clock,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Mini-card mostrando como o aluno verá o instrutor. Recebe os valores
/// LIVE digitados (price, bairro, cidade) — atualiza enquanto o usuário
/// preenche, antes de salvar.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.instructor,
    this.livePrice,
    this.liveNeighborhood,
    this.liveCity,
  });

  final Instructor instructor;
  final double? livePrice;
  final String? liveNeighborhood;
  final String? liveCity;

  @override
  Widget build(BuildContext context) {
    final double? price = livePrice ?? instructor.pricePerClass;
    final String? where = (liveNeighborhood ?? instructor.neighborhood) != null
        ? '${liveNeighborhood ?? instructor.neighborhood}'
            '${(liveCity ?? instructor.city) != null ? ' · ${liveCity ?? instructor.city}' : ''}'
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textPrimary, width: 1.5),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                CnhhjStars(rating: instructor.averageRating, size: 14),
                if (where != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      const Icon(
                        PhosphorIconsRegular.mapPin,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          where,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  price == null || price <= 0
                      ? 'Sem valor definido'
                      : 'R\$ ${price.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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
