import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/booking.dart';
import '../../data/models/enums.dart';
import '../../data/models/profile.dart';
import '../../data/models/review.dart';
import '../../data/models/student.dart';
import '../../data/providers.dart';
import '../../data/repositories/mock/_seed.dart';
import '../../data/repositories/mock/mock_booking_repository.dart';
import '../../shared/widgets/widgets.dart';
import '../home/home_providers.dart';

/// Perfil do aluno visto pelo instrutor (somente leitura).
///
/// Mostrado quando o instrutor toca num card de solicitação para decidir
/// se aceita ou recusa. Privacy first: telefone NUNCA aparece — comunicação
/// é apenas pelo chat in-app.
///
/// Quando navegada via solicitação pendente, aceita query param `bookingId`
/// e mostra rodapé fixo com Aceitar/Recusar. Sem `bookingId`, é só perfil.
class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({
    super.key,
    required this.studentId,
    this.bookingId,
  });

  final String studentId;
  final String? bookingId;

  @override
  ConsumerState<StudentProfileScreen> createState() =>
      _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  Profile? _profile;
  Student? _student;
  Booking? _booking;
  List<Review> _reviews = const <Review>[];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final List<Review> reviews =
        await ref.read(reviewRepositoryProvider).listReceived(
              widget.studentId,
              target: ReviewTarget.student,
            );
    if (!mounted) return;
    setState(() {
      _profile = MockState.instance.profiles[widget.studentId];
      _student = MockState.instance.students[widget.studentId];
      _booking = widget.bookingId == null
          ? null
          : MockState.instance.bookings
              .where((Booking b) => b.id == widget.bookingId)
              .firstOrNull;
      _reviews = reviews;
      _loading = false;
    });
  }

  int? get _age {
    final DateTime? d = _profile?.birthDate;
    if (d == null) return null;
    final DateTime now = DateTime.now();
    int age = now.year - d.year;
    if (now.month < d.month ||
        (now.month == d.month && now.day < d.day)) {
      age--;
    }
    return age;
  }

  Future<void> _respond(BookingStatus status) async {
    if (_busy || _booking == null) return;
    String? reason;
    if (status == BookingStatus.cancelled) {
      reason = await _askReason(context);
      if (reason == null) return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(bookingRepositoryProvider).updateStatus(
            _booking!.id,
            status: status,
            cancellationReason: reason?.isEmpty == true ? null : reason,
            cancelledBy: status == BookingStatus.cancelled
                ? _booking!.instructorId
                : null,
          );
    } on BookingConflictException catch (e) {
      if (!mounted) return;
      final DateFormat df = DateFormat('dd/MM \'às\' HH:mm', 'pt_BR');
      CnhhjSnack.error(
        context,
        'Conflito: já há aula confirmada em '
        '${df.format(e.conflictingWith.scheduledStart)}.',
      );
      setState(() => _busy = false);
      return;
    } catch (_) {
      if (!mounted) return;
      CnhhjSnack.error(context, 'Erro ao processar. Tente novamente.');
      setState(() => _busy = false);
      return;
    }
    ref.invalidate(pendingBookingsProvider);
    ref.invalidate(pendingBookingsCountProvider);
    ref.invalidate(confirmedBookingsCountProvider);
    if (!mounted) return;
    if (status == BookingStatus.confirmed) {
      CnhhjSnack.success(context, 'Aula confirmada!');
    } else {
      CnhhjSnack.info(context, 'Solicitação recusada.');
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          title: const Text('Perfil do aluno'),
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

    final Profile? p = _profile;
    if (p == null) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          title: const Text('Perfil do aluno'),
          leading: IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CnhhjEmptyState(
            icon: PhosphorIconsDuotone.userMinus,
            message: 'Aluno não encontrado.',
          ),
        ),
      );
    }

    final bool showFooter =
        _booking != null && _booking!.status == BookingStatus.pending;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Perfil do aluno'),
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _Header(profile: p, age: _age, student: _student)
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(
                          begin: -0.1,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 14),
                    if (_booking != null)
                      _BookingSummaryCard(booking: _booking!)
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 350.ms)
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                    if (_booking != null) const SizedBox(height: 14),
                    _ReviewsSection(reviews: _reviews, student: _student)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 350.ms)
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                  ],
                ),
              ),
            ),
            if (showFooter)
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: CnhhjSecondaryButton(
                          label: 'Recusar',
                          icon: PhosphorIconsRegular.x,
                          onPressed: _busy
                              ? null
                              : () => _respond(BookingStatus.cancelled),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CnhhjPrimaryButton(
                          label: 'Aceitar',
                          icon: PhosphorIconsRegular.check,
                          onPressed: _busy
                              ? null
                              : () => _respond(BookingStatus.confirmed),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.age, this.student});

  final Profile profile;
  final int? age;
  final Student? student;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = <String>[
      if (age != null) '$age anos',
      if (student?.city != null) student!.city!,
      if (student?.desiredCategory != null)
        'Categoria ${student!.desiredCategory!.name.toUpperCase()}',
    ];

    return CnhhjCard(
      child: Column(
        children: <Widget>[
          CnhhjAvatar(
            size: 96,
            fullName: profile.fullName,
            imageUrl: profile.avatarUrl,
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          if (chips.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                for (final String c in chips)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      c,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          if (student != null) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CnhhjStars(rating: student!.averageRating, size: 16),
                const SizedBox(width: 8),
                Text(
                  student!.totalReviews == 0
                      ? 'Sem avaliações ainda'
                      : '${student!.averageRating.toStringAsFixed(1)} · '
                          '${student!.totalReviews} '
                          '${student!.totalReviews == 1 ? "avaliação" : "avaliações"}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Resumo da solicitação ───────────────────────────────────────────
class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final DateFormat df = DateFormat('EEE, dd \'de\' MMMM · HH:mm', 'pt_BR');
    return CnhhjCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'SOLICITAÇÃO',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _Row(
            icon: PhosphorIconsRegular.clock,
            label: 'Data e hora',
            value: df.format(booking.scheduledStart),
          ),
          if (booking.meetingPoint != null)
            _Row(
              icon: PhosphorIconsRegular.mapPin,
              label: 'Local',
              value: booking.meetingPoint!,
            ),
          if (booking.agreedPrice != null)
            _Row(
              icon: PhosphorIconsRegular.currencyDollar,
              label: 'Valor combinado',
              value: 'R\$ ${booking.agreedPrice!.toStringAsFixed(2)}',
            ),
          if (booking.notes != null && booking.notes!.trim().isNotEmpty)
            _Row(
              icon: PhosphorIconsRegular.note,
              label: 'Observações',
              value: booking.notes!,
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
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

// ─── Reviews ──────────────────────────────────────────────────────────
class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.reviews, this.student});

  final List<Review> reviews;
  final Student? student;

  /// Abrevia "Carlos Silva" → "Carlos S." para privacidade do reviewer.
  /// Não vaza sobrenome completo de um instrutor para um aluno (e vice-versa).
  String _abbreviateName(String full) {
    final List<String> parts = full.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'Anônimo';
    if (parts.length == 1) return parts.first;
    return '${parts.first} ${parts.last.substring(0, 1)}.';
  }

  @override
  Widget build(BuildContext context) {
    return CnhhjCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'AVALIAÇÕES RECEBIDAS',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 6),
              if (reviews.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${reviews.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: <Widget>[
                    Icon(
                      PhosphorIconsRegular.starHalf,
                      size: 32,
                      color: AppColors.textMuted.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Este aluno ainda não foi avaliado.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...reviews.map(
              (Review r) => _ReviewTile(
                review: r,
                reviewerName: _abbreviateName(
                  MockState.instance.profiles[r.reviewerId]?.fullName ??
                      'Instrutor',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.reviewerName});

  final Review review;
  final String reviewerName;

  @override
  Widget build(BuildContext context) {
    final DateFormat df = DateFormat('dd/MM/yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CnhhjStars(rating: review.rating.toDouble(), size: 14),
              const Spacer(),
              Text(
                df.format(review.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '— $reviewerName',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom sheet de motivo da recusa ──────────────────────────────
// Reusa o mesmo padrão de tab_requests.dart — mantemos local pra não
// criar acoplamento entre features.
Future<String?> _askReason(BuildContext context) {
  final TextEditingController controller = TextEditingController();
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Recusar solicitação',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Conte (opcional) o motivo para que o aluno entenda.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText:
                    'Ex: horário indisponível, fora da minha região...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.primary.withOpacity(0.08),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: CnhhjSecondaryButton(
                    label: 'Voltar',
                    onPressed: () => Navigator.of(ctx).pop(null),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CnhhjPrimaryButton(
                    label: 'Recusar',
                    icon: PhosphorIconsRegular.x,
                    onPressed: () =>
                        Navigator.of(ctx).pop(controller.text.trim()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
