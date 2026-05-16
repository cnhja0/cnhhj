import '../../models/app_notification.dart';
import '../../models/enums.dart';
import '../../models/instructor.dart';
import '../../models/review.dart';
import '../notification_repository.dart';
import '../review_repository.dart';
import '_seed.dart';

class MockReviewRepository implements ReviewRepository {
  MockReviewRepository({this.notifications});

  /// Quando provido, emite `AppNotification` para o avaliado a cada nova
  /// review recebida. Sem isso, o app fica com feed estático.
  final NotificationRepository? notifications;

  @override
  Future<List<Review>> listReceived(
    String revieweeId, {
    ReviewTarget? target,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return MockState.instance.reviews
        .where((Review r) =>
            r.revieweeId == revieweeId &&
            (target == null || r.target == target))
        .toList(growable: false)
      ..sort((Review a, Review b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Review> create({
    required String bookingId,
    required String reviewerId,
    required String revieweeId,
    required ReviewTarget target,
    required int rating,
    String? comment,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // Em produção, há trigger SQL que impede duplicidade. Aqui simulamos.
    final bool already = MockState.instance.reviews.any(
      (Review r) => r.bookingId == bookingId && r.reviewerId == reviewerId,
    );
    if (already) {
      throw StateError('Você já avaliou esta aula.');
    }

    final DateTime now = DateTime.now();
    final Review r = Review(
      id: 'rev-${now.millisecondsSinceEpoch.toRadixString(36)}',
      bookingId: bookingId,
      reviewerId: reviewerId,
      revieweeId: revieweeId,
      target: target,
      rating: rating,
      comment: comment,
      createdAt: now,
    );
    MockState.instance.reviews.add(r);

    // C3: recalcula averageRating/totalReviews do instrutor. Em produção,
    // isso seria um trigger no DB; aqui replicamos no mock para a UI
    // refletir.
    if (target == ReviewTarget.instructor) {
      final Instructor? inst = MockState.instance.instructors[revieweeId];
      if (inst != null) {
        final List<Review> all = MockState.instance.reviews
            .where((Review e) =>
                e.revieweeId == revieweeId &&
                e.target == ReviewTarget.instructor)
            .toList(growable: false);
        final double avg = all.isEmpty
            ? 0
            : all.map((Review e) => e.rating).reduce((int a, int b) => a + b) /
                all.length;
        MockState.instance.instructors[revieweeId] = inst.copyWith(
          averageRating: avg,
          totalReviews: all.length,
          updatedAt: now,
        );
      }
    }

    // C4: notifica o avaliado. Side-effect; falha não desfaz a review.
    if (notifications != null) {
      try {
        await notifications!.create(
          AppNotification(
            id: 'notif-${now.millisecondsSinceEpoch.toRadixString(36)}-r',
            userId: revieweeId,
            type: NotificationType.review,
            title: 'Você recebeu uma avaliação',
            body: '$rating ★${comment == null || comment.isEmpty ? '' : ' · "$comment"'}',
            createdAt: now,
            actionRoute: '/reviews',
          ),
        );
      } catch (_) {}
    }

    return r;
  }
}
