import 'enums.dart';

/// Avaliação bidirecional ligada a uma aula (booking) concluída.
/// Espelha a tabela `reviews`.
class Review {
  const Review({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.revieweeId,
    required this.target,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String reviewerId;
  final String revieweeId;
  final ReviewTarget target;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      revieweeId: json['reviewee_id'] as String,
      target: ReviewTarget.fromJson(json['target'] as String),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'booking_id': bookingId,
        'reviewer_id': reviewerId,
        'reviewee_id': revieweeId,
        'target': target.toJson(),
        'rating': rating,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
      };
}
