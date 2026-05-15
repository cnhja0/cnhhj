import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';
import '../../data/models/instructor.dart';
import '../../data/models/review.dart';
import '../../data/providers.dart';
import '../../data/repositories/mock/_seed.dart';
import '../../shared/widgets/widgets.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String userId =
        ref.read(authRepositoryProvider).currentSession?.userId ??
            MockState.currentInstructorId;
    final AsyncValue<List<Review>> async = ref.watch(_reviewsProvider(userId));
    final AsyncValue<Instructor?> instAsync =
        ref.watch(_instructorProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Avaliações'),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.textPrimary),
        ),
        error: (Object err, _) => Center(child: Text('Erro: $err')),
        data: (List<Review> reviews) {
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: <Widget>[
              instAsync.maybeWhen(
                data: (Instructor? i) => _Summary(instructor: i)
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(
                      begin: -0.05,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),
              if (reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: CnhhjEmptyState(
                    icon: PhosphorIconsDuotone.star,
                    message:
                        'Sem avaliações por enquanto.\nApós cada aula, os alunos podem te avaliar.',
                  ),
                )
              else
                for (int i = 0; i < reviews.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReviewCard(review: reviews[i])
                        .animate()
                        .fadeIn(
                          delay: (100 + i * 70).ms,
                          duration: 350.ms,
                        )
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

final FutureProviderFamily<List<Review>, String> _reviewsProvider =
    FutureProvider.family<List<Review>, String>((Ref ref, String userId) {
  return ref
      .watch(reviewRepositoryProvider)
      .listReceived(userId, target: ReviewTarget.instructor);
});

final FutureProviderFamily<Instructor?, String> _instructorProvider =
    FutureProvider.family<Instructor?, String>((Ref ref, String userId) {
  return ref.watch(instructorRepositoryProvider).getById(userId);
});

class _Summary extends StatelessWidget {
  const _Summary({required this.instructor});
  final Instructor? instructor;

  @override
  Widget build(BuildContext context) {
    final double avg = instructor?.averageRating ?? 0;
    final int total = instructor?.totalReviews ?? 0;
    return CnhhjCard(
      border: Border.all(color: AppColors.textPrimary, width: 1.5),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Icon(
                PhosphorIconsFill.star,
                size: 36,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                avg.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          CnhhjStars(rating: avg, size: 22),
          const SizedBox(height: 6),
          Text(
            'Baseado em $total ${total == 1 ? 'avaliação' : 'avaliações'}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final String name =
        MockState.instance.profiles[review.reviewerId]?.fullName ?? 'Aluno';
    final DateFormat df = DateFormat('dd/MM/yyyy', 'pt_BR');
    return CnhhjCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CnhhjAvatar(size: 40, fullName: name),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    CnhhjStars(rating: review.rating.toDouble(), size: 14),
                  ],
                ),
              ),
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
          if (review.comment != null && review.comment!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    PhosphorIconsDuotone.quotes,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      review.comment!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
