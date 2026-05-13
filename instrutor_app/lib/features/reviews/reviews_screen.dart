import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
      appBar: AppBar(title: const Text('Avaliações')),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.textPrimary),
        ),
        error: (Object err, _) => Center(child: Text('Erro: $err')),
        data: (List<Review> reviews) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: <Widget>[
              instAsync.maybeWhen(
                data: (Instructor? i) => _Summary(instructor: i),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              if (reviews.isEmpty)
                const CnhhjEmptyState(
                  icon: Icons.star_outline,
                  message: 'Sem avaliações por enquanto.\nApós cada aula, os alunos podem te avaliar.',
                )
              else
                ...reviews.map((Review r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReviewCard(review: r),
                    )),
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
      child: Column(
        children: <Widget>[
          Text(
            avg.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          CnhhjStars(rating: avg, size: 22),
          const SizedBox(height: 4),
          Text(
            'Baseado em $total avaliação${total == 1 ? '' : 'ões'}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
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
              CnhhjAvatar(size: 36, fullName: name),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
