import 'enums.dart';

/// Dados específicos do aluno. Espelha a tabela `students`.
class Student {
  const Student({
    required this.id,
    this.cnhPhotoUrl,
    this.desiredCategory,
    this.state,
    this.city,
    this.averageRating = 0,
    this.totalReviews = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? cnhPhotoUrl;
  final VehicleCategory? desiredCategory;
  final String? state;
  final String? city;
  final double averageRating;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student copyWith({
    String? cnhPhotoUrl,
    VehicleCategory? desiredCategory,
    String? state,
    String? city,
    double? averageRating,
    int? totalReviews,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id,
      cnhPhotoUrl: cnhPhotoUrl ?? this.cnhPhotoUrl,
      desiredCategory: desiredCategory ?? this.desiredCategory,
      state: state ?? this.state,
      city: city ?? this.city,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      cnhPhotoUrl: json['cnh_photo_url'] as String?,
      desiredCategory: json['desired_category'] == null
          ? null
          : VehicleCategory.fromJson(json['desired_category'] as String),
      state: json['state'] as String?,
      city: json['city'] as String?,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'cnh_photo_url': cnhPhotoUrl,
        'desired_category': desiredCategory?.toJson(),
        'state': state,
        'city': city,
        'average_rating': averageRating,
        'total_reviews': totalReviews,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
