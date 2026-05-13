import '../../models/enums.dart';
import '../../models/review.dart';
import '../review_repository.dart';
import '_seed.dart';

class MockReviewRepository implements ReviewRepository {
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
    final Review r = Review(
      id: 'rev-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
      bookingId: bookingId,
      reviewerId: reviewerId,
      revieweeId: revieweeId,
      target: target,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    MockState.instance.reviews.add(r);
    return r;
  }
}
