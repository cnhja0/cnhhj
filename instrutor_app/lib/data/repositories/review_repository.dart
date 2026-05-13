import '../models/enums.dart';
import '../models/review.dart';

abstract class ReviewRepository {
  /// Avaliações recebidas por uma pessoa (instrutor ou aluno).
  Future<List<Review>> listReceived(String revieweeId, {ReviewTarget? target});

  /// Cria nova avaliação ligada a uma booking concluída.
  Future<Review> create({
    required String bookingId,
    required String reviewerId,
    required String revieweeId,
    required ReviewTarget target,
    required int rating,
    String? comment,
  });
}
